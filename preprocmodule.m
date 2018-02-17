function [] = preprocmodule()
%PREPROCMODULE function summary: GUI Module for Image Preprocessing
%   GUI Module with image processing methods to prepare microscopy images
%   for CurveAlign/CT-FIRE Collagen fiber analysis methods.
%
%Input:
%   Args...
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

% outputArg1 = inputArg1;
% outputArg2 = inputArg2;


%Define pConv8Bit() function to convert .tiff single image or stack to 8Bit
%Steps-
%   1. Read in a tiff file to variable
%   2. Test if image is a stack or if single image, OR have user select this?
%   3. Determine if the file can be converted
%   4. Convert the file data to 8bit data (signed or unsigned?)
%   5. Write data to new file with same file name in 8bit-converted folder
%   OPTIONS: user selectable file name/folder?
    function pConv8Bit(ff)
        %1. Read in tiff stack to 3D matrix (XPixels x YPixels x # Images in Stack)
        %set(imgLabel,'String',fileName);
        %open file
        ff = fullfile(pathName,fileName);
        info = imfinfo(ff); % store tif meta-data tags
        numSections = numel(info); % # of images in stack
        imgsizeX=info.Width;
        imgsizeY=info.Height;
        %2. Multi image stack or single image tiff depending on case
        if numSections > 1  % for case of multi-image stack
            I = zeros(imgsizeX, imgsizeY, numSections,'uint8');%make 3D matrix
            %3. Is the file of a class that we can convert to 8Bit? (RGB, YCbCr, or
            %   Grey colorspace? Nonstandard bitdepth, Other than 16, 24, 32 eg. 12bit)
            
            %do type test here...
            
            %4. Convert the image data slice by slice and store in 3D matrix
            for S = 1:numSections
                img_ori = imread(ff,S,'Info',info);
                img_conv = im2uint8(img_ori);
                I(:,:,S) = img_conv;
            end
        else
            I = imread(ff);   % for case when tiff is single image
        end
        %5. Write data to newly converted 8Bit tif image
        outputFileName = [fileName '_Conv8bit.tif'];
        for S=1:numSections
            imwrite(I(:, :, S), outputFileName, 'WriteMode', 'append', 'Compression','none');
        end
    end
end

