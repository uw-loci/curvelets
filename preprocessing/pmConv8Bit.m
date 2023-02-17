function [] = pmConv8Bit(ff,OutputFolder)
%Define pmConv8Bit() function to convert .tif single image or stack to 8Bit
%Steps-
%   1. Setup Variables
%   2. Determine if the file can be converted
%   3. Test if image is a stack or if single image
%   4. Convert the file data to 8bit data (unsigned)
%   5. Adjust image brightness for human readability
%   6. Write data to new file with same file name in 8bit-converted folder
%   OPTIONS: user selectable output folder
%
%Input:
% Full file path to image file to convert to 8Bit, and output folder
%Default input
% ff = 'fullfile(filePath,fileName,fileExtension)'
% OutputFolder = Path to output folder
%
%Output:
% Converted image .tif file(s) and/or
% Warning messages
%
%Log:
%   1. January 2018 to May 2018: Andrew S. Leicht student at UW-Madison was
%   tasked with this project, under the supervision of Yuming Liu at LOCI.
%   Development was done with Matlab R2014b (8.4.0.150421) and R2017b
%   (9.3.0.713579) under Academic license on Ubuntu 16.04 LTS and 17.10.
%   ~40 Man hours of work coding and testing. 4/18/18
%
% Licensed under the 2-Clause BSD license
% Copyright (c) 2009 - 2018, Board of Regents of the University of Wisconsin-Madison
% All rights reserved.
%
%
warning('off','all') % disable all warnings that may confuse user
%1. Setup Variables
[filePath,fileName,fileExtension] = fileparts(ff); % Parse path/file details
info = imfinfo(ff); % store tif meta-data tags
numSections = numel(info); % # of images in stack
imgsizeX=info.Width; % Get and store image size in X
imgsizeY=info.Height; % Get and store image size in Y

%2. Is the file of a class that we can convert to 8Bit? (RGB, YCbCr, or
%   Grey colorspace? Nonstandard bitdepth, Other than 16, 24, 32 eg. 12bit)
%Color type variable setup
ColorT=info.ColorType;
if ischar(ColorT) && (strcmp(ColorT,'truecolor')||strcmp(ColorT,'indexed')||strcmp(ColorT,'grayscale')) % Normal Case
else  % Case for nonstandard color format
    disp('File color format is not recognized, exiting operation.')
    return;
end
%BitDepth tests and variable setup
BitD=info.BitDepth;
if BitD == 8 % 8Bit Case
    %MaxIntensity = 256; % set max intensity for 8Bit source image
    disp('File already is of 8 BitDepth per pixel. Conversion not required, exiting operation.')
    drawnow
    return;
elseif BitD == 12 || BitD == 16 || BitD == 24|| BitD == 32
    MaxIntensity = 2^BitD-1;
else
    disp('File format not recognized, exiting operation.')
    return;
end
outputFileName = [fileName fileExtension]; % setup output filename
outputFullPath = fullfile(OutputFolder,outputFileName); % setup full output path
if exist(outputFullPath,'file') == 2% test if file already exists and overwrite first before appending
    delete(outputFullPath);
end
%3. Multi image stack or single image tif depending on case
if numSections > 1  % for case of multi-image stack
    %Convert the image data slice by slice
    for S = 1:numSections
        ImgOri = imread(ff,S,'Info',info);
        if strcmp(ColorT,'truecolor') % RGB Case
            I = rgb2gray(ImgOri); %4. Convert slice to grayscale 8Bit
        else % Other (Grayscale) Case
            %5. Scale relative intensity values of image(s) to increase brightness
            RelMinPxIntensity = double(min(min(ImgOri(:))))/MaxIntensity; % scale min bitdepth pixel value to range [0.0 1.0] per slice
            RelMaxPxIntensity = double(max(max(ImgOri(:))))/MaxIntensity; % scale max bitdepth pixel value to range [0.0 1.0] per slice
            ImgConv = imadjust(ImgOri,[RelMinPxIntensity RelMaxPxIntensity]);
            ImgConv2 = im2uint8(ImgConv); %4. convert image slice to 8Bit
            I = ImgConv2;
        end
        imwrite(I, outputFullPath, 'WriteMode', 'append', 'Compression','none');%6. write to file
    end
else
    ImgOri = imread(ff);   %3. for case when tif is single image
    if strcmp(ColorT,'truecolor') % RGB Case
        I = rgb2gray(ImgOri); %4. Convert to grayscale 8Bit
    else
        %5. Scale relative intensity values of image to increase brightness
        RelMinPxIntensity = double(min(min(ImgOri(:))))/MaxIntensity; % scale min bitdepth pixel value to range [0.0 1.0]
        RelMaxPxIntensity = double(max(max(ImgOri(:))))/MaxIntensity; % scale max bitdepth pixel value to range [0.0 1.0]
        ImgConv = imadjust(ImgOri,[RelMinPxIntensity RelMaxPxIntensity]); % adjust image brightness
        ImgConv2 = im2uint8(ImgConv); %4. convert image to 8Bit
        I = ImgConv2;
    end
    imwrite(I, outputFullPath, 'WriteMode', 'overwrite', 'Compression','none');%6. write to file
    return;
end
warning('on','all') % Re-enable all warnings
end