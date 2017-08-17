function [BDmask] = BDcreationHE2(BDCparameters)
%
%August 09,2017: this function was originally developed by Adib Keikhosravi, a
% LOCI graduate student, to automatically generate the tumor boundary based
% on the epithelial cells segmentation and cluster from the RGB bright field
% HE image that is pre-registrated with the SHG image. This output mask will
% be used in CurveAlign. The function is pushed to the github for a verison
% control and will be incorporated into the CurveAlign.
% input:BDCparameters
% BDCparameters.HEfilepath: HE file path;
% BDCparameters.HEfilename: HE file name;
% BDCparameters.pixelpermicron: pixel per micron ratio of the HE image;
% BDCparameters.areaThreshold: threshold of the segmented areas;
% BDCparameters.SHGfilepath: SHG image file path ;
% Output: BDmask: mask for the boundary

% Yl08/09/2017: variable name change
HEfilepath = BDCparameters.HEfilepath;
HEfilename = BDCparameters.HEfilename;
pixelpermicron = BDCparameters.pixelpermicron;
areaThreshold = BDCparameters.areaThreshold;
SHGfilepath = BDCparameters.SHGfilepath;
IMGpath = fullfile(HEfilepath,HEfilename);
%%
pixpermic=pixelpermicron;
HE=im2double(imread(IMGpath));
if (pixpermic > 2)
    HEdata=imresize(HE,2/pixpermic);
    pixpermic=2;
else
    HEdata = HE;
end

r=HEdata(:,:,1);
g=HEdata(:,:,2);
b=HEdata(:,:,3);
mean_r=mean(mean(r));
mean_g=mean(mean(g));
mean_b=mean(mean(b));

std_r=std(std(r));
std_g=std(std(g));
std_b=std(std(b));

HEdata = imadjust(HEdata,[0 0 0;mean_r+2*std_r mean_g+2*std_g mean_b+2*std_b],[0 0 0; 1 1 1]);
HEgray=rgb2gray(HEdata);
HEthresh=graythresh(HEgray);
BW_gray=im2bw(HEgray,HEthresh);
%figure;imshow(BW_gray)

[m, n, pp]=size(HEdata);
[orig_row, orig_col, orig_depth]=size(HE);


%%HSV analysis

I = rgb2hsv(HEdata);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.500;
channel1Max = 0.790;

% Define thresholds for channel 2 based on histogram settings
channel2Min = graythresh(I(:,:,2));
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.000;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
%figure;imshow(BW)
BW=bwareaopen(BW,150);
% Initialize output masked image based on input image.
maskednucleiImage = HEdata;

% Set background pixels where BW is false to zero.
se = strel('disk',ceil(pixpermic/2));

BW_nuclei=imopen(BW,se);
%figure;imshow(BW_nuclei)

maskednucleiImage(repmat(~BW_nuclei,[1 1 3])) = 0;
%figure;imshow(maskednucleiImage)

% figure;imshowpair(BW_mask,HEdata)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert RGB image to chosen color space
HEhsv = rgb2hsv(HEdata);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.837;
channel1Max = 0.066;

% Define thresholds for channel 2 based on histogram settings
channel2Min = graythresh(HEhsv(:,:,2));
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.000;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
BW_collagen = ( (HEhsv(:,:,1) >= channel1Min) | (HEhsv(:,:,1) <= channel1Max) ) & ...
    (HEhsv(:,:,2) >= channel2Min ) & (HEhsv(:,:,2) <= channel2Max) & ...
    (HEhsv(:,:,3) >= channel3Min ) & (HEhsv(:,:,3) <= channel3Max);
BW_collagen=bwareaopen(BW_collagen,100);
se = strel('disk',ceil(pixpermic));
BW_collagen=imdilate(BW_collagen,se);
%figure;imshowpair(BW_collagen1,BW)
% BW_collagen=bwareaopen(BW_collagen,round((60*pixpermic)^2));
se = strel('disk',round(3*pixpermic));
BW_collagen1 = imclose(BW_collagen,se);
%figure;imshow(BW_collagen1)


% Create mask based on chosen histogram thresholds
BW_nobackground = (HEhsv(:,:,2) >= channel2Min );
% %figure;imshow(BW_nobackground)

epith_cell=maskednucleiImage;
%figure;imshow(epith_cell_BW)

epith_cell_BW=im2bw(rgb2gray(epith_cell),0.001).*(~BW_collagen1).*BW_nobackground;
se = strel('disk',round(5*pixpermic));
epith_cell_BW_open = imdilate(epith_cell_BW,se);
BWx= imfill(epith_cell_BW_open,'holes');
BWy=bwareaopen(~BWx,round((60*pixpermic)^2));
mask_image=bwareaopen(~BWy,round((35*pixpermic)^2));
se = strel('disk',round(4*pixpermic));
mask_image1 = imdilate(mask_image,se).*(~BW_collagen1);
% B = imgaussfilt(mask_image1,50);
h=fspecial('gaussian',101,25);
B=imfilter(mask_image1,h,'replicate','corr');

%figure,imshow(B)
mask_temp=imresize(B, [orig_row, orig_col]);
mask_bw=im2bw(mask_temp,graythresh(mask_temp));
% mask_bw=im2bw(mask,0.4);

BDmask=mask_bw;

%%Save results
try
    savePath = fullfile(SHGfilepath,'CA_Boundary');
    maskName = ['mask for ' strrep(HEfilename,'HE','SHG') '.tif'];
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
    
catch
    savePath = fullfile(HEfilepath,'CA_Boundary');
    maskName = ['mask for ' strrep(HEfilename,'HE','SHG') '.tif'];
    if ~exist(savePath,'dir')
        mkdir(savePath);
    end
        
end
imwrite(BDmask,fullfile(savePath,maskName))
disp(sprintf('%s was saved at %s',maskName,savePath))

end

