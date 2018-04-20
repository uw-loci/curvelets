function [] = pmAutoThresh(ff)
%Define pmAutoThresh() function that will automatically threshold and
%image file with the method of users choice
%Steps-
%   1. Parse File path input and if single image or stack
%   2. Read in image data
%   3. Apply automatic thresholding method set by option flags
%   4. Write thresholded data to mask file?
%
%Input:
%Full file path to image file to threshold
%Default input
% ff = 'fullfile(filePath,fileName,fileExtension)'
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
%
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