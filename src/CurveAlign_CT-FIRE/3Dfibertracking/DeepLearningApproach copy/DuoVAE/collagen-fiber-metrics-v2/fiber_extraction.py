import torch
import torch.nn as nn
import torch.nn.functional as F
from skimage import exposure, io, img_as_uint
import numpy as np
from centerline import CenterLine

class UNet(nn.Module):
    def __init__(self, n_channels, n_classes, n_filters=64, bilinear=False):
        super(UNet, self).__init__()
        self.n_channels = n_channels
        self.n_classes = n_classes
        self.bilinear = bilinear

        self.inc = DoubleConv(n_channels, n_filters)
        self.down1 = Down(n_filters, n_filters*2)
        self.down2 = Down(n_filters*2, n_filters*4)
        self.down3 = Down(n_filters*4, n_filters*8)
        factor = 2 if bilinear else 1
        self.down4 = Down(n_filters*8, n_filters*16 // factor)
        self.up1 = Up(n_filters*16, n_filters*8 // factor, bilinear)
        self.up2 = Up(n_filters*8, n_filters*4 // factor, bilinear)
        self.up3 = Up(n_filters*4, n_filters*2 // factor, bilinear)
        self.up4 = Up(n_filters*2, n_filters, bilinear)
        self.outc = OutConv(n_filters, n_classes)

    def forward(self, x):
        x1 = self.inc(x)
        x2 = self.down1(x1)
        x3 = self.down2(x2)
        x4 = self.down3(x3)
        x5 = self.down4(x4)
        x = self.up1(x5, x4)
        x = self.up2(x, x3)
        x = self.up3(x, x2)
        x = self.up4(x, x1)
        logits = self.outc(x)
        return torch.sigmoid(logits)
        
""" Parts of the U-Net model """

class DoubleConv(nn.Module):
    """(convolution => [BN] => ReLU) * 2"""

    def __init__(self, in_channels, out_channels, mid_channels=None):
        super().__init__()
        if not mid_channels:
            mid_channels = out_channels
        self.double_conv = nn.Sequential(
            nn.Conv2d(in_channels, mid_channels, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(mid_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(mid_channels, out_channels, kernel_size=3, padding=1, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True)
        )

    def forward(self, x):
        return self.double_conv(x)


class Down(nn.Module):
    """Downscaling with maxpool then double conv"""

    def __init__(self, in_channels, out_channels):
        super().__init__()
        self.maxpool_conv = nn.Sequential(
            nn.MaxPool2d(2),
            DoubleConv(in_channels, out_channels)
        )

    def forward(self, x):
        return self.maxpool_conv(x)


class Up(nn.Module):
    """Upscaling then double conv"""

    def __init__(self, in_channels, out_channels, bilinear=True):
        super().__init__()

        # if bilinear, use the normal convolutions to reduce the number of channels
        if bilinear:
            self.up = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=True)
            self.conv = DoubleConv(in_channels, out_channels, in_channels // 2)
        else:
            self.up = nn.ConvTranspose2d(in_channels, in_channels // 2, kernel_size=2, stride=2)
            self.conv = DoubleConv(in_channels, out_channels)

    def forward(self, x1, x2):
        x1 = self.up(x1)
        # input is CHW
        diffY = x2.size()[2] - x1.size()[2]
        diffX = x2.size()[3] - x1.size()[3]

        x1 = F.pad(x1, [diffX // 2, diffX - diffX // 2,
                        diffY // 2, diffY - diffY // 2])
        # if you have padding issues, see
        # https://github.com/HaiyongJiang/U-Net-Pytorch-Unstructured-Buggy/commit/0e854509c2cea854e247a9c615f175f76fbb2e3a
        # https://github.com/xiaopeng-liao/Pytorch-UNet/commit/8ebac70e633bac59fc22bb5195e513d5832fb3bd
        x = torch.cat([x2, x1], dim=1)
        return self.conv(x)


class OutConv(nn.Module):
    def __init__(self, in_channels, out_channels):
        super(OutConv, self).__init__()
        self.conv = nn.Conv2d(in_channels, out_channels, kernel_size=1)

    def forward(self, x):
        return self.conv(x)
    

class FiberExtractor():
    def __init__(self, net):
        self.net = net.eval()
        self.file_list = None
        self.norm_range = None

    def normalization_range(self, p=(0, 100), file_list=None):
        max_val = 0
        min_val = 0
        self.file_list = file_list
        for fname in self.file_list:
            im_arr = io.imread(fname)
            max_val += np.percentile(im_arr, p[0])
            min_val += np.percentile(im_arr, p[1])
        max_val = max_val / len(self.file_list)
        min_val = min_val / len(self.file_list)
        self.norm_range = (min_val, max_val)
        return (min_val, max_val)

    def compute(self, im_arr, norm_range=(0, 65535), adjust_contrast=None):
        im_arr = img_as_uint(im_arr)
        with torch.no_grad():
            if self.norm_range:
                norm_range = self.norm_range
            im_arr = exposure.rescale_intensity(im_arr, in_range=(norm_range[0], norm_range[1]), out_range=(0, 1))
            if adjust_contrast:
                im_arr = [adjust_contrast(im_arr)]
            else:
                im_arr = [im_arr]
            im_tensor = torch.from_numpy(np.vstack(im_arr))[None, :]
            outputs_tensor = self.net(im_tensor.float()[:, None])
            results = outputs_tensor.cpu().numpy()
            results = results.squeeze()
            centerline_res = CenterLine(associate_image=results, draw_from_raw=True)
            self.results = centerline_res.centerline_image
            return self.results

