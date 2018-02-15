function [outputArg1,outputArg2] = preprocmodule(inputArg1,inputArg2)
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


outputArg1 = inputArg1;
outputArg2 = inputArg2;


%Define pConv8Bit() function to convert .tiff single image or stack to 8Bit
%Steps-
%   1. Read in a tiff file to variable
%   2. Test if image is a stack or if single image, OR have user select this?
%   3. Determine if the file can be converted
%   4. Convert the file data to 8bit data (signed or unsigned?)
%   5. Write data to new file with same file name in 8bit-converted folder
%   OPTIONS: user selectable file name/folder?
    function pConv8Bit(Filename,options)
%1. Read in tiff stack

        
    end
end

