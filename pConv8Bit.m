function [] = pConv8Bit(ff)
%Define pConv8Bit() function to convert .tif single image or stack to 8Bit
%Steps-
%   1. Read in a tif file to variable
%   2. Test if image is a stack or if single image, OR have user select this?
%   3. Determine if the file can be converted
%   4. Convert the file data to 8bit data (unsigned)
%   5. Adjust image brightness for human readability
%   6. Write data to new file with same file name in 8bit-converted folder
%   OPTIONS: user selectable file name/folder?
%
%Input:
% ff = fullfile(filePath,fileName,fileExtension)
%
%Log:
%   1. January 2018 to May 2018: Andrew S. Leicht student at UW-Madison was
%   tasked with this project, under the supervision of Yuming Liu at LOCI.
%   Development was done with Matlab R2017b (9.3.0.713579) under Academic
%   license on Ubuntu 16.04 LTS.
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
%2. Multi image stack or single image tif depending on case
if numSections > 1  % for case of multi-image stack
    I = zeros(imgsizeX, imgsizeY, numSections,'uint8'); % make 3D matrix
    %3. Is the file of a class that we can convert to 8Bit? (RGB, YCbCr, or
    %   Grey colorspace? Nonstandard bitdepth, Other than 16, 24, 32 eg. 12bit)
    
    %do type test here...
    
    %4. Convert the image data slice by slice and store in 3D matrix
    %???make this into a method to simplify code???
    for S = 1:numSections
        ImgOri = imread(ff,S,'Info',info);
        ImgConv = im2uint8(ImgOri);
        %I(:,:,S) = ImgConv;
        %5. Scale relative intensity values of image(s) to increase brightness
        %I(:,:,S) = imadjust(img_conv); %saturates some pixels incorrectly
        RelMaxPxIntensity = double(max(max(ImgConv(:))))/255; % scale to range [0.0 1.0] per slice
        ImgConv2 = imadjust(ImgConv,[0.0 RelMaxPxIntensity]);
        I(:,:,S) = ImgConv2;
    end
else
    ImgOri = imread(ff);   % for case when tif is single image
    ImgConv = im2uint8(ImgOri);
    RelMaxPxIntensity = double(max(max(ImgConv(:))))/255; % scale max pixel value to range [0.0 1.0]
    ImgConv2 = imadjust(ImgConv,[0.0 RelMaxPxIntensity]);
    I = ImgConv2;
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


