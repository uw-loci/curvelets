function [] = pmAutoThresh(ff,OutputFolder)
%Define pmAutoThresh() function that will automatically threshold and
%image file with the method of users choice
%Steps-
%   1. Setup variables
%   2. Read in image data
%   3. Apply automatic thresholding method set by option flags
%   4. Write thresholded data to mask file
%
%Input:
%Full file path to image file to threshold
%Default input
% ff = 'fullfile(filePath,fileName,fileExtension)'
% OutputFolder = Path to output folder
% Options flags for thresholding method selection
%
%Output:
% Threshholded image mask? file(s) and/or
% Warning messages
%
%Log:
%   1. January 2018 to May 2018: Andrew S. Leicht student at UW-Madison was
%   tasked with this project, under the supervision of Yuming Liu at LOCI.
%   Development was done with Matlab R2014b (8.4.0.150421) under
%   Academic license on Ubuntu 17.10.
%   ~?? Man hours of work coding and testing.
%
% Licensed under the 2-Clause BSD license
% Copyright (c) 2009 - 2018, Board of Regents of the University of Wisconsin-Madison
% All rights reserved.
%
%
%1. Setup Variables
[filePath,fileName,fileExtension] = fileparts(ff); % Parse path/file details
info = imfinfo(ff); % store tif meta-data tags
numSections = numel(info); % # of images in stack
outputFileName = [fileName '_Mask' fileExtension]; % setup output filename
outputFullPath = fullfile(OutputFolder,outputFileName); % setup full output path
ThreshMethFlag = 1;%set flag to select threshold method
% (1) Global Otsu method; (2) Multilevel Otsu Method;
% (3) Fixed threshold chosen with minimax principle; (4) Fixed-form 
% threshold yielding minimax performance multiplied by a small factor
Mthreshlvl = 7;%setup number of threshold bins (n+1 levels segmentation) for Otsu multiple threshold method
%have above levels user configurable with input or auto optimized with test here?
PseudoC = 0;%flag for (1)PseudoColor or (0)Grayscale mask
% test if file already exists and overwrite first before appending
if exist(outputFullPath,'file') == 2
    delete(outputFullPath);
end
%Do operations on stack or single image
if numSections > 1  % for case of multi-image stack
    for S = 1:numSections
        ImgOri = imread(ff,S,'Info',info);%2. read in image slicewise
        switch ThreshMethFlag
            case 1 %3. Use Global Otsu Method to threshold images
                [thresh,EM] = graythresh(ImgOri);
                I = im2bw(ImgOri, thresh);%output as binary mask
                fprintf('Automatic Image Thresholding done with a %f Effectiveness Metric for slice %u.\n',EM,S)
                drawnow
            case 2 %3. Use Multilevel Otsu Method to threshold images with (Mthreshlvl+1) levels
                [thresh,EM] = multithresh(ImgOri,Mthreshlvl);%add optimization to vary Mthreshlvl's per slice to maximize EM?
                seg_I = imquantize(ImgOri,thresh);
                if PseudoC == 1
                    I = label2rgb(seg_I);%output Pseudocolor mask
                else
                    if PseudoC == 0
                        I = mat2gray(seg_I);%output Grayscale mask
                    else
                        disp('PseudoColor option flag set incorrectly, exiting operation.')
                        drawnow
                        return;
                    end
                end
                fprintf('Automatic Image Thresholding done with a %f Effectiveness Metric for slice %u.\n',EM,S)
                drawnow
            case 3 %3. Fixed threshold chosen with minimax principle
                thresh = thselect(ImgOri,'minimaxi');
                seg_I = imquantize(ImgOri, thresh);
                I = mat2gray(seg_I);%output binary mask
            case 4 %3. Fixed-form threshold yielding minimax performance multiplied by a small factor
                thresh = thselect(ImgOri,'sqtwolog');
                seg_I = imquantize(ImgOri, thresh);
                I = mat2gray(seg_I);%output binary mask
        end
        imwrite(I, outputFullPath, 'WriteMode', 'append', 'Compression','none');%4. write slice to file
    end
else
    ImgOri = imread(ff);%2. for case when tif is single image
    switch ThreshMethFlag
        case 1 %3. Use Global Otsu Method to threshold image
            [thresh,EM] = graythresh(ImgOri);
            I = im2bw(ImgOri, thresh);%output as binary mask
            fprintf('Automatic Image Thresholding done with %f Effectiveness Metric.\n',EM)
            drawnow
        case 2 %3. Use Multilevel Otsu Method to threshold image with (Mthreshlvl+1) levels
            [thresh,EM]= multithresh(ImgOri,Mthreshlvl);
            seg_I = imquantize(ImgOri,thresh);
            if PseudoC == 1
                I = label2rgb(seg_I);%output Pseudocolor mask
            else
                if PseudoC == 0
                    I = mat2gray(seg_I);%output Grayscale mask
                else
                    disp('PseudoColor option flag set incorrectly, exiting operation.')
                    drawnow
                    return;
                end
                fprintf('Automatic Image Thresholding done with %f Effectiveness Metric.\n',EM)
                drawnow
            end
        case 3 %3. Fixed threshold chosen with minimax principle
                thresh = thselect(ImgOri,'minimaxi');
                seg_I = imquantize(ImgOri, thresh);
                I = mat2gray(seg_I);%output binary mask
            case 4 %3. Fixed-form threshold yielding minimax performance multiplied by a small factor
                thresh = thselect(ImgOri,'sqtwolog');
                seg_I = imquantize(ImgOri, thresh);
                I = mat2gray(seg_I);%output binary mask
    end
    imwrite(I, outputFullPath, 'WriteMode', 'overwrite', 'Compression','none');%4. write to file
end
return;
end