
function [ImgData, I] = pmBioFormats_v2(ff,OutputFolder,BioFOptionFlag)
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
%   ~6 Man hours of work coding and testing. 5/31/18
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
%numSections = getSeriesCount(ff); % # of images in stack
%2. Read in image data
switch BioFOptionFlag
    case 1 %full file reading and parsing
        ImgData = bfopen(ff); %read entire file (slower than bfGetReader for large files)
        I = ImgData{1,1}{1,1}; %outpout image pixel values for single image
    case 2 %extract image plane(s) from file only
        ImgData = bfopen(ff);
        r = bfGetReader(ff); %get reader type required for file
        channel = r.getSizeC();  
        timepoint = r.getSizeT();
        section  = r.getSizeZ();
        numSeries = r.getSeriesCount();
        %fprintf('Reading series #%d', numSeries);
        if numSeries == 1 %for single images
            series1 = ImgData{1,1}; 
            series1 = ImgData{1, 1}; 
            omeMeta = ImgData{1, 4};
            stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
            stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
@ -75,27 +75,19 @@ switch BioFOptionFlag
            voxelSizeXdefaultValue = omeMeta.getPixelsPhysicalSizeX(0).value();           % returns value in default unit
            voxelSizeXdefaultUnit = omeMeta.getPixelsPhysicalSizeX(0).unit().getSymbol(); % returns the default unit type
            for plane_count = 1:r.getImageCount();   
                plane_all = []; 
                plane_all = {}; 
                plane_all = series1(:,1);
%                 omeMeta = reader.getMetadataStore();
%                 series1_plane1 = bfGetPlane(reader, 1);
%                 plane_all = bfGetPlane(r, plane_count);
            end             
%             imagesc(plane_all); 
            %imshow(I, []);%display the image (w/ image processing box)
             bfsave(plane_all, OutputFolder);
%             bfsave(plane_all, 'metadata.ome.tiff', 'metadata', metadata);
%             bfsave(plane_all, OutputFolder);
%             bfsave(I, outputPath, 'Compression', compression)
        else
            series_all = [];
            %there should be s by 4 matrix in ImgData.
            series_all = ImgData(:,1);
            %extract only the plane Data out. expected a size x array, with
            %m by 2 array in each cell
            for s = 1:numSeries 
                for p = 1:r.getImageCount();
                    plane_all = []; 
                    plane_all = series_all(:,1); %extract plane from each series
                    plane_all = bfGetPlane(); %extract plane from each series
                end 
            end
        end
@ -103,7 +95,8 @@ switch BioFOptionFlag
    case 3 %3. write image data to file only
        ImgData = bfopen(ff); %read entire file
        r = bfGetReader(ff); %get reader type required for file
        bfsave(ImgData, OutputFolder); %write to OME-Tiff
        I=bfGetPlane(r,1); 
        bfsave(I, OutputFolder,'Compression', 'LZW'); %write to OME-Tiff
end
warning('on','all') % Re-enable all warnings
end