function [ImagData, I] = pmBioFormats(ff,OutputFolder,BioFOptionFlag)
%Define pmBioFormats() function that uses Bio-Formats Java library to import
%many types of microscopy image formats and convert them to standard
%supported file formats
%Steps-
%   -1. Check for Bio-Formats is the newest version? bfUpgradeCheck.m, only on 1st
%   run?
%   0. Check Matlab JVM memory is sufficient with bfCheckJavaMemory.m,
%   only once per run?  This may not be required?, as bfopen.m calls
%   bfGetReader.m which calls bfCheckJavaMemory.m, BUT memory may need to
%   be reset to a higher value by writing default memory size to java.opts
%   file, and printing message to user with info?
%   1. Parse File path input and if single image or stack
%   2. Use Bio-Formats to read in single image or image stack
%   3. Write image data to output file
%   ?4. Use bfopen.m or bfOpen3DVolume.m OR converted data to display
%   converted image file(s)
%   ?Add Functionality to allow bfInitLogging('DEBUG') to be set for
%   troubleshooting perhaps with commented out lines or debug flag?
%
%Input:
%Full file path to image file to import
%Default input
% ff = 'fullfile(filePath,fileName,fileExtension)'
% OutputFolder = Path to output folder
% BioFOptionFlag = Options: (1) read in and parse entire file;
% (2) read in image array slices (faster); (3) write to OME-Tiff
%
%Output:
% Converted image file(s) and image array I
% and/or Warning messages
%
%Log:
%   1. January 2018 to May 2018: Andrew S. Leicht student at UW-Madison was
%   tasked with this project, under the supervision of Yuming Liu at LOCI.
%   Development was done with Matlab R2014b (8.4.0.150421) under
%   Academic license on Ubuntu 17.10.
%   ~4 Man hours of work coding and testing. 5/23/18
%
% WILL THERE BE A LICENSE ISSUE WITH BIO-FORMATS GPL?
% Licensed under the 2-Clause BSD license
% Copyright (c) 2009 - 2018, Board of Regents of the University of Wisconsin-Madison
% All rights reserved.
%
%

%add path to access Bio-Formats funct
BFdir = dir('./bfmatlab*');
p = strcat('./',BFdir.name);
addpath(p);
%import bioformats_package.jar; %import bioformats package REQUIRED?????
warning('off','all') % disable all warnings that may confuse user
%1. Parse File path input and if single image or stack
[filePath,fileName,fileExtension] = fileparts(ff); % Parse path/file details
info = imfinfo(ff); % store tif meta-data tags
numSections = numel(info); % # of images in stack
imgsizeX=info.Width; % Get and store image size in X
imgsizeY=info.Height; % Get and store image size in Y
%2. Read in image data
switch BioFOptionFlag
    case 1 %full file reading and parsing
        ImgData = bfopen(ff); %read entire file (slower than bfGetReader for large files)
        I = ImgData{1,1}{1,1}; %outpout image pixel values for single image
    case 2 %extract image plane(s) from file only
        r = bfGetReader(ff); %get reader type required for file
        if numSections == 1 %for single images
            I = bfGetPlane(r,1); %Get single image
        else %for image stacks read in image slices
            for S = 1:numSections
                I(S) = bfGetPlane(r,S);
            end
        end
    case 3 %3. write image data to file only
        ImgData = bfopen(ff); %read entire file
        bfsave(ImgData, OutputFolder); %write to OME-Tiff
end
warning('on','all') % Re-enable all warnings
end