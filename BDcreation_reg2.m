% function [registered_img]= Hue_int_reg(HE_img,SHG_img,SHG_PPM)

function [registered_img]=BDcreation_reg2(BDCparameters)
% function [registered_image]=BDcreation_reg(HE_image,SHG_image,pixelpermicron)

% YL August 28,2017: this function was originally developed by Adib Keikhosravi, a
% LOCI graduate student, to automatically registrate RGB bright field
% HE image with the correspoinding SHG image. This output registered image will
% be used for later segmentaion. The function is pushed to the github for a verison
% control.
% input:BDCparameters
% BDCparameters.HEfilepath: HE file path;
% BDCparameters.HEfilename: HE file name;
% BDCparameters.pixelpermicron: pixel per micron ratio of the HE image;
% BDCparameters.areaThreshold: threshold of the segmented areas; (for possible future use in segmentation)
% BDCparameters.SHGfilepath: SHG image file path ;
% Output: registered_image: registered,image

HEfilepath = BDCparameters.HEfilepath;
HEfilename = BDCparameters.HEfilename;
SHGfilename = HEfilename;
SHG_PPM = BDCparameters.pixelpermicron;
SHGfilepath = BDCparameters.SHGfilepath;
HE_img = fullfile(HEfilepath,HEfilename);
SHG_img = fullfile(SHGfilepath,SHGfilename);

pixpermic = SHG_PPM;
HE = im2double(imread(HE_img));
SHG = im2double(imread(SHG_img));

if (pixpermic > 2)
fixedSHG=imresize(SHG,2/pixpermic);
pixpermic=2;
else 
    fixedSHG=SHG;
end

RGB=imresize(HE,size(fixedSHG));

r=RGB(:,:,1);
g=RGB(:,:,2);
b=RGB(:,:,3);
mean_r=mean(mean(r));
mean_g=mean(mean(g));
mean_b=mean(mean(b));

std_r=std(std(r));
std_g=std(std(g));
std_b=std(std(b));

%yl error fix: IMADJUST: LOW_IN, HIGH_IN, LOW_OUT and HIGH_OUT must be in the range [0.0, 1.0].
HIGH_IN_r = mean_r+2*std_r;
HIGH_IN_g = mean_g+2*std_g;
HIGH_IN_b = mean_b+2*std_b;
if HIGH_IN_r > 1
    HIGH_IN_r = 1;
end
if HIGH_IN_g > 1
    HIGH_IN_g = 1;
end
if HIGH_IN_b > 1
    HIGH_IN_b = 1;
end

HEdata = imadjust(RGB,[0 0 0;HIGH_IN_r HIGH_IN_g HIGH_IN_b],[0 0 0; 1 1 1]);

HEgray=rgb2gray(HEdata);
HEthresh=graythresh(HEgray);
BW_gray=im2bw(HEgray,HEthresh);
%%%figure;imshow(BW_gray)

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
BW = (I(:,:,1) >= channel1Min) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min) & (I(:,:,3) <= channel3Max);
%%%figure;imshow(BW)
BW=bwareaopen(BW,150);
% Initialize output masked image based on input image.
maskednucleiImage = HEdata;

% Set background pixels where BW is false to zero.
se = strel('disk',ceil(pixpermic/2));

BW_nuclei=imopen(BW,se);
%%%figure;imshow(maskednucleiImage)

maskednucleiImage(repmat(~BW_nuclei,[1 1 3])) = 0;

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

%%figure;imshow(BW_collagen)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
pixelpermicron=pixpermic;
gray_nuclei=im2double(rgb2gray(maskednucleiImage));
h_nuclei = fspecial('gaussian',floor(pixelpermicron), 0.5);
nuclei_filtered = imfilter(im2double(gray_nuclei),h_nuclei);
BW_nuclei=im2bw(im2double(nuclei_filtered),0.001);
BW_nuclei_discard = bwareaopen(BW_nuclei, ceil(50*pixelpermicron^2));
se = strel('disk',floor(pixelpermicron));
BW_nuclei_dilated = imdilate(BW_nuclei_discard,se);
BW_nuclei_filled = imfill(BW_nuclei_dilated,'holes');
HE_collagen_BW=BW_collagen.*(~BW_nuclei_filled);
% HE_collagen_BW=im2bw(HE_collagen_exclude,0.01);
BW_discard = bwareaopen(HE_collagen_BW, ceil(pixelpermicron^2));
HE_collagen_exclude=HE_collagen_BW.*BW_discard;
%%figure;imshow(HE_collagen_exclude)

HEmoving=HE_collagen_exclude;
% HEmoving=imresize(HE_collagen_exclude,size(fixedSHG));
[optimizer,metric] = imregconfig('multimodal');
disp(optimizer);
disp(metric);
optimizer.InitialRadius = optimizer.InitialRadius/3.5;
movingRegisteredAdjustedInitialRadius = imregister(HEmoving, fixedSHG, 'affine', optimizer, metric);
optimizer.MaximumIterations = 700;
tformSimilarity = imregtform(HEmoving,fixedSHG,'similarity',optimizer,metric);
RfixedSHG = imref2d(size(fixedSHG));
tformSimilarity.T;
[movingRegisteredAffineWithIC treg tform]= imreg_new3(HEmoving,fixedSHG,'affine',optimizer,metric,...
    'InitialTransformation',tformSimilarity);
HERmoving=imref2d(size(HEmoving));
B = imwarp(HE,HERmoving,tform,'OutputView',RfixedSHG,'FillValues',255);
registered_img = imresize(B,size(SHG));

% save results
savePath = fullfile(HEfilepath,'HE_registered');
if ~exist(savePath,'dir')
    mkdir(savePath);
end
imwrite(registered_img,fullfile(savePath,HEfilename))
disp(sprintf('registered image %s was saved at %s',HEfilename,savePath))

function [movingReg,Rreg,tform] = imreg_new3(varargin)
        %IMREGISTER Register two 2-D or 3-D images using intensity metric optimization.
        %
        %
        
        tform = imregtform(varargin{:});
        
        % Rely on imregtform to input parse and validate. If we were passed
        % spatially referenced input, use spatial referencing during resampling.
        % Otherwise, just use identity referencing objects for the fixed and
        % moving images.
        spatiallyReferencedInput = isa(varargin{2},'imref2d') && isa(varargin{4},'imref2d');
        if spatiallyReferencedInput
            moving  = varargin{1};
            Rmoving = varargin{2};
            Rfixed  = varargin{4};
        else
            moving = varargin{1};
            fixed = varargin{2};
            if (tform.Dimensionality == 2)
                Rmoving = imref2d(size(moving));
                Rfixed = imref2d(size(fixed));
            else
                Rmoving = imref3d(size(moving));
                Rfixed = imref3d(size(fixed));
            end
        end
        
        % Transform the moving image using the transform estimate from imregtform.
        % Use the 'OutputView' option to preserve the world limits and the
        % resolution of the fixed image when resampling the moving image.
        [movingReg,Rreg] = imwarp(moving,Rmoving,tform,'OutputView',Rfixed);
        
        
    end
end
