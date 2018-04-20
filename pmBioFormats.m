function [] = pmBioFormats(ff)
%Define pmBioFormats() function that uses Bio-Formats Java library to import
%many types of microscopy image formats and convert them to standard
%supported file formats
%Steps-
%   -2. Check for Bio-Formats is the newest version? bfUpgradeCheck.m, only on 1st
%   run?
%   -1. Check if java class path set correctly for Bio-Formats with
%   bfCheckJavaPath.m. NOT REQUIRED as bf functions will do this already.
%   0. Check Matlab JVM memory is sufficient with bfCheckJavaMemory.m, 
%   only once per run?  This may not be required, as bfopen.m calls
%   bfGetReader.m which calls bfCheckJavaMemory.m, BUT memory may need to 
%   be reset to a higher value by writing default memory size to java.opts 
%   file, and printing message to user with info?
%   1. Parse File path input and if single image or stack
%   2. Use bfGetReader.m to read single image data or bfGetPlane.m with
%   loop for image stack
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
%
%Output:
% Converted image file(s) and/or
% Warning messages
%
%Log:
%   1. January 2018 to May 2018: Andrew S. Leicht student at UW-Madison was
%   tasked with this project, under the supervision of Yuming Liu at LOCI.
%   Development was done with Matlab R2014b (8.4.0.150421) under 
%   Academic license on Ubuntu 17.10.
%
% WILL THERE BE A LICENSE ISSUE WITH BIO-FORMATS GPL?
% Licensed under the 2-Clause BSD license
% Copyright (c) 2009 - 2018, Board of Regents of the University of Wisconsin-Madison
% All rights reserved.
%
%
warning('off','all') % disable all warnings that may confuse user
%1. Parse File path input and if single image or stack
[filePath,fileName,fileExtension] = fileparts(ff); % Parse path/file details
info = imfinfo(ff); % store tif meta-data tags
numSections = numel(info); % # of images in stack
imgsizeX=info.Width; % Get and store image size in X
imgsizeY=info.Height; % Get and store image size in Y


warning('on','all') % Re-enable all warnings
end