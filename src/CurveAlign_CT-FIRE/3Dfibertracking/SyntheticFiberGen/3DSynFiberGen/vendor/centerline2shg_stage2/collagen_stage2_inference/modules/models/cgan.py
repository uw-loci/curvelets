import os
import numpy as np
import itertools

import torch
import torch.nn as nn
from torch.nn import functional as F
from modules.utils.util_model import get_available_devices
import functools

class cGAN(nn.Module):
    def __init__(self, params, is_train, img_channel=1, device='cpu'):
        super().__init__()
        self.device = device
        
        # define model
        self.G = UnetGenerator(input_nc=img_channel, output_nc=img_channel, num_downs=6, ngf=32, norm_layer=nn.BatchNorm2d, use_dropout=is_train).to(self.device)

        if is_train:
            # parameters used for training
            lr = params["train"]["lr"]
            self.w_gan = params["cgan"]["w_gan"]
            self.D_update_interval = params["cgan"]['D_update_interval']
            self.G_warm_up = params["cgan"]['G_warm_up']

            # define model
            self.D = Discriminator(img_channel).to(self.device)

            # optimizers
            G_params = self.G.parameters()
            D_params = self.D.parameters()
            self.optimizer_G = torch.optim.Adam(G_params, lr=lr, amsgrad=True)
            self.optimizer_D = torch.optim.Adam(D_params, lr=lr, amsgrad=True)
            self.D.requires_grad = False # will become True when updating D inside optimize_parameters()

            # for discriminator
            self.register_buffer('real_label', torch.tensor(1.0))
            self.register_buffer('fake_label', torch.tensor(0.0))

            # losses
            self.criterionGAN = nn.BCEWithLogitsLoss()
            self.criterionRecon = nn.L1Loss()

            self.model_names = ['D', 'G']
            self.loss_names = ['G', 'GAN', 'D']
            self.loss_D, self.loss_GAN = None, None
        else:
            self.model_names = ['G']

    def set_input(self, data):
        self.filename = data["filename"]
        self.image = data["image"].to(self.device) # (B, img_channel, 256, 256)
        self.centerline = data["centerline"].to(self.device) # (B, img_channel, 256, 256)

    def optimize_parameters(self, iters, epoch):
        self.image_recon = self.forward(self.centerline)

        # update D
        if (iters % self.D_update_interval== 0) and (iters > self.G_warm_up):
            self.D.requires_grad = True
            self.optimizer_D.zero_grad()
            self.backward_D()
            self.optimizer_D.step()
            self.D.requires_grad = False

        # update G
        self.optimizer_G.zero_grad()
        self.backward_G(iters)
        self.optimizer_G.step()

    def forward(self, centerline):
        image_recon = self.G(centerline)
        return image_recon

    def backward_D(self):
        images_real = torch.cat((self.centerline, self.image), dim=1)
        images_fake  = torch.cat((self.centerline, self.image_recon), dim=1)

        pred_real = self.D(images_real)
        pred_fake = self.D(images_fake.detach())

        is_real = self.real_label.expand_as(pred_real).to(images_real.device)
        is_fake = self.fake_label.expand_as(pred_fake).to(images_fake.device)

        loss_D_real = self.criterionGAN(pred_real, is_real)
        loss_D_fake = self.criterionGAN(pred_fake, is_fake)

        self.loss_D = (loss_D_real + loss_D_fake) * 0.5
        self.loss_D.backward()
        
    def backward_G(self, iters):
        images_fake = torch.cat((self.centerline, self.image_recon), dim=1)
        pred_fake = self.D(images_fake)

        is_real = self.real_label.expand_as(pred_fake).to(images_fake.device)
        self.loss_GAN = self.criterionGAN(pred_fake, is_real)

        self.loss_recon = self.criterionRecon(self.image_recon, self.image)

        if iters > self.G_warm_up:
            self.loss_G = self.loss_recon + self.w_gan*self.loss_GAN
        else:
            self.loss_G = self.loss_recon
        self.loss_G.backward()

class Discriminator(nn.Module):
    def __init__(self, img_channel):
        super().__init__()
        self.D = nn.Sequential(
            nn.Conv2d(2*img_channel, 32, kernel_size=4, stride=2, padding=1, bias=True), # 128
            nn.LeakyReLU(0.2, inplace=True),
            nn.Conv2d(32, 64, kernel_size=4, stride=2, padding=1, bias=False), # 64
            nn.BatchNorm2d(64),
            nn.LeakyReLU(0.2, inplace=True),
            nn.Conv2d(64, 128, kernel_size=4, stride=2, padding=1, bias=False), # 32
            nn.BatchNorm2d(128),
            nn.LeakyReLU(0.2, inplace=True),
            nn.Conv2d(128, 256, kernel_size=4, stride=2, padding=1, bias=False), # 16
            nn.BatchNorm2d(256),
            nn.LeakyReLU(0.2, inplace=True),
            nn.Conv2d(256, 1, kernel_size=4, stride=1, padding=1, bias=True)
        )

    def forward(self, I):
        pred = self.D(I)
        return pred


class UnetGenerator(nn.Module):
    """Create a Unet-based generator"""

    def __init__(self, input_nc, output_nc, num_downs, ngf=64, norm_layer=nn.BatchNorm2d, use_dropout=False):
        """Construct a Unet generator
        Parameters:
            input_nc (int)  -- the number of channels in input images
            output_nc (int) -- the number of channels in output images
            num_downs (int) -- the number of downsamplings in UNet. For example, # if |num_downs| == 7,
                                image of size 128x128 will become of size 1x1 # at the bottleneck
            ngf (int)       -- the number of filters in the last conv layer
            norm_layer      -- normalization layer
        We construct the U-Net from the innermost layer to the outermost layer.
        It is a recursive process.
        """
        super(UnetGenerator, self).__init__()
        # construct unet structure
        unet_block = UnetSkipConnectionBlock(ngf * 8, ngf * 8, input_nc=None, submodule=None, norm_layer=norm_layer, innermost=True)  # add the innermost layer
        for i in range(num_downs - 5):          # add intermediate layers with ngf * 8 filters
            unet_block = UnetSkipConnectionBlock(ngf * 8, ngf * 8, input_nc=None, submodule=unet_block, norm_layer=norm_layer, use_dropout=use_dropout)
        # gradually reduce the number of filters from ngf * 8 to ngf
        unet_block = UnetSkipConnectionBlock(ngf * 4, ngf * 8, input_nc=None, submodule=unet_block, norm_layer=norm_layer)
        unet_block = UnetSkipConnectionBlock(ngf * 2, ngf * 4, input_nc=None, submodule=unet_block, norm_layer=norm_layer)
        unet_block = UnetSkipConnectionBlock(ngf, ngf * 2, input_nc=None, submodule=unet_block, norm_layer=norm_layer)
        self.model = UnetSkipConnectionBlock(output_nc, ngf, input_nc=input_nc, submodule=unet_block, outermost=True, norm_layer=norm_layer)  # add the outermost layer

    def forward(self, input):
        """Standard forward"""
        return self.model(input)


class UnetSkipConnectionBlock(nn.Module):
    """Defines the Unet submodule with skip connection.
        X -------------------identity----------------------
        |-- downsampling -- |submodule| -- upsampling --|
    """

    def __init__(self, outer_nc, inner_nc, input_nc=None,
                 submodule=None, outermost=False, innermost=False, norm_layer=nn.BatchNorm2d, use_dropout=False):
        """Construct a Unet submodule with skip connections.
        Parameters:
            outer_nc (int) -- the number of filters in the outer conv layer
            inner_nc (int) -- the number of filters in the inner conv layer
            input_nc (int) -- the number of channels in input images/features
            submodule (UnetSkipConnectionBlock) -- previously defined submodules
            outermost (bool)    -- if this module is the outermost module
            innermost (bool)    -- if this module is the innermost module
            norm_layer          -- normalization layer
            use_dropout (bool)  -- if use dropout layers.
        """
        super(UnetSkipConnectionBlock, self).__init__()
        self.outermost = outermost
        if type(norm_layer) == functools.partial:
            use_bias = norm_layer.func == nn.InstanceNorm2d
        else:
            use_bias = norm_layer == nn.InstanceNorm2d
        if input_nc is None:
            input_nc = outer_nc
        downconv = nn.Conv2d(input_nc, inner_nc, kernel_size=4,
                             stride=2, padding=1, bias=use_bias)
        downrelu = nn.LeakyReLU(0.2, True)
        downnorm = norm_layer(inner_nc)
        uprelu = nn.ReLU(True)
        upnorm = norm_layer(outer_nc)

        if outermost:
            upconv = nn.ConvTranspose2d(inner_nc * 2, outer_nc,
                                        kernel_size=4, stride=2,
                                        padding=1)
            down = [downconv]
            up = [uprelu, upconv, nn.Tanh()]
            # up = [uprelu, upconv]
            model = down + [submodule] + up
        elif innermost:
            upconv = nn.ConvTranspose2d(inner_nc, outer_nc,
                                        kernel_size=4, stride=2,
                                        padding=1, bias=use_bias)
            down = [downrelu, downconv]
            up = [uprelu, upconv, upnorm]
            model = down + up
        else:
            upconv = nn.ConvTranspose2d(inner_nc * 2, outer_nc,
                                        kernel_size=4, stride=2,
                                        padding=1, bias=use_bias)
            down = [downrelu, downconv, downnorm]
            up = [uprelu, upconv, upnorm]

            if use_dropout:
                model = down + [submodule] + up + [nn.Dropout(0.5)]
            else:
                model = down + [submodule] + up

        self.model = nn.Sequential(*model)

    def forward(self, x):
        if self.outermost:
            return self.model(x)
        else:   # add skip connections
            return torch.cat([x, self.model(x)], 1)