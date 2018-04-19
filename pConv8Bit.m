function [] = pConv8Bit(ff)
%Define pConv8Bit() function to convert .tif single image or stack to 8Bit
%Steps-
%   1. Read in a tif file to variable
%   3. Test if image is a stack or if single image
%   2. Determine if the file can be converted
%   4. Convert the file data to 8bit data (unsigned)
%   5. Adjust image brightness for human readability
%   6. Write data to new file with same file name in 8bit-converted folder
%   OPTIONS: user selectable file name/folder?
%
%Input:
%Default input
% ff = 'fullfile(filePath,fileName,fileExtension)'
%
%Log:
%   1. January 2018 to May 2018: Andrew S. Leicht student at UW-Madison was
%   tasked with this project, under the supervision of Yuming Liu at LOCI.
%   Development was done with Matlab R2017b (9.3.0.713579) under Academic
%   license on Ubuntu 16.04 LTS and 17.10.
%
% Licensed under the 2-Clause BSD license
% Copyright (c) 2009 - 2018, Board of Regents of the University of Wisconsin-Madison
% All rights reserved.
% initialize variables used in some callback functions
%
%
warning('off','all') % disable all warnings that may confuse user
%1. Read in tif stack to 3D matrix (XPixels x YPixels x # Images in Stack)
[filePath,fileName,fileExtension] = fileparts(ff); % Parse path/file details
info = imfinfo(ff); % store tif meta-data tags
numSections = numel(info); % # of images in stack
imgsizeX=info.Width; % Get and store image size in X
imgsizeY=info.Height; % Get and store image size in Y

%2. Is the file of a class that we can convert to 8Bit? (RGB, YCbCr, or
%   Grey colorspace? Nonstandard bitdepth, Other than 16, 24, 32 eg. 12bit)
%do type tests here...
%Color type variable setup
ColorT=info.ColorType;
if ischar(ColorT) && (strcmp(ColorT,'truecolor')||strcmp(ColorT,'indexed')||strcmp(ColorT,'grayscale')) % Normal Case
else  % Case for nonstandard color format
    disp('File color format is not recognized, exiting operation.')
    drawnow
    return;
end

%BitDepth tests and variable setup
BitD=info.BitDepth;
if BitD == 8 % 8Bit Case
    %MaxIntensity = 256; % set max intensity for 8Bit source image
    disp('File already is of 8 BitDepth per pixel. Conversion not required, exiting operation.')
    drawnow
    return;
else
    if BitD == 12 % 12Bit Case
        MaxIntensity = 4096; % set max intensity for 12Bit source image
    else
        if BitD == 16 % 16Bit Case
            MaxIntensity = 65535; % set max intensity for 16Bit source image
        else
            if BitD == 24 % 24Bit Case
                MaxIntensity = 16777216; % set max intensity for 24Bit source image
            else
                if BitD == 32 % 32Bit Case
                    MaxIntensity = 4294967296; % set max intensity for 32Bit source image
                else % Case for nonstandard bitdepth
                    disp('File format not recognized, exiting operation.')
                    drawnow
                    return;
                end
            end
        end
    end
end

%3. Multi image stack or single image tif depending on case
if numSections > 1  % for case of multi-image stack
    I = zeros(imgsizeX, imgsizeY, numSections,'uint8'); % make 3D matrix
    %4. Convert the image data slice by slice and store in 3D matrix
    %???make this into a method to simplify code???
    for S = 1:numSections
        ImgOri = imread(ff,S,'Info',info);
        if strcmp(ColorT,'truecolor') % RGB Case
            I(:,:,S) = rgb2gray(ImgOri); % Convert slice to grayscale 8Bit
        else % Other (Grayscale) Case
            %5. Scale relative intensity values of image(s) to increase brightness
            RelMinPxIntensity = double(min(min(ImgOri(:))))/MaxIntensity; % scale min bitdepth pixel value to range [0.0 1.0] per slice
            RelMaxPxIntensity = double(max(max(ImgOri(:))))/MaxIntensity; % scale max bitdepth pixel value to range [0.0 1.0] per slice
            ImgConv = imadjust(ImgOri,[RelMinPxIntensity RelMaxPxIntensity]);
            ImgConv2 = im2uint8(ImgConv); % convert image slice to 8Bit
            I(:,:,S) = ImgConv2;
        end
    end
else
    ImgOri = imread(ff);   % for case when tif is single image
    if strcmp(ColorT,'truecolor') % RGB Case
        I = rgb2gray(ImgOri); % Convert to grayscale 8Bit
    else
        %5. Scale relative intensity values of image to increase brightness
        RelMinPxIntensity = double(min(min(ImgOri(:))))/MaxIntensity; % scale min bitdepth pixel value to range [0.0 1.0]
        RelMaxPxIntensity = double(max(max(ImgOri(:))))/MaxIntensity; % scale max bitdepth pixel value to range [0.0 1.0]
        ImgConv = imadjust(ImgOri,[RelMinPxIntensity RelMaxPxIntensity]); % adjust image brightness
        ImgConv2 = im2uint8(ImgConv); % convert image to 8Bit
        I = ImgConv2;
    end
end
outputFileName = [fileName '_Conv8bit' fileExtension]; % setup output filename
outputFullPath = [filePath filesep outputFileName]; % setup full output path
%6. Write data to newly converted 8Bit tif image in same path as orig file
%???make this into a method to simplify repeated code???
if exist(outputFullPath,'file') == 2% test if file already exists and overwrite first before appending
    disp('File already exists with the same output name and will be overwritten.')
    drawnow
    imwrite(I(:, :, 1), outputFullPath, 'WriteMode', 'overwrite', 'Compression','none');
    for S=2:numSections %
        imwrite(I(:, :, S), outputFullPath, 'WriteMode', 'append', 'Compression','none');
    end
else
    for S=1:numSections
        imwrite(I(:, :, S), outputFullPath, 'WriteMode', 'append', 'Compression','none');
    end
end
%clearvars -except ff % Clean up temporary variables
warning('on','all') % Re-enable all warnings
end