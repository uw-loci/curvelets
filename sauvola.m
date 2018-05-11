function [thresh,I] = sauvola(image, varargin)
%SAUVOLA local thresholding.
%   BW = SAUVOLA(IMAGE) performs local thresholding of a two-dimensional 
%   array IMAGE with Sauvola algorithm.
%      
%   BW = SAUVOLA(IMAGE, [M N], THRESHOLD, PADDING) performs local 
%   thresholding with M-by-N neighbourhood (default is 3-by-3) and 
%   threshold THRESHOLD between 0 and 1 (default is 0.34). 
%   To deal with border pixels the image is padded with one of 
%   PADARRAY options (default is 'replicate').
%       
%   Example
%   -------
%       imshow(sauvola(imread('eight.tif'), [150 150]));
%
%   See also PADARRAY, RGB2GRAY
%   For method description see:
%       http://www.dfki.uni-kl.de/~shafait/papers/Shafait-efficient-binarization-SPIE08.pdf
%   Contributed by Jan Motl (jan@motl.us)
%
% Copyright (c) 2013, yzan
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% * Redistributions of source code must retain the above copyright
% notice, this list of conditions and the following disclaimer.
% * Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in
% the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%   $Revision: 1.1 $  $Date: 2013/03/09 16:58:01 $
%Internal Functions
function image = averagefilter(image, varargin)
%AVERAGEFILTER 2-D mean filtering.
%   B = AVERAGEFILTER(A) performs mean filtering of two dimensional 
%   matrix A with integral image method. Each output pixel contains 
%   the mean value of the 3-by-3 neighborhood around the corresponding
%   pixel in the input image. 
%
%   B = AVERAGEFILTER(A, [M N]) filters matrix A with M-by-N neighborhood.
%   M defines vertical window size and N defines horizontal window size. 
%   
%   B = AVERAGEFILTER(A, [M N], PADDING) filters matrix A with the 
%   predefinned padding. By default the matrix is padded with zeros to 
%   be compatible with IMFILTER. But then the borders may appear distorted.
%   To deal with border distortion the PADDING parameter can be either
%   set to a scalar or a string: 
%       'circular'    Pads with circular repetition of elements.
%       'replicate'   Repeats border elements of matrix A.
%       'symmetric'   Pads array with mirror reflections of itself. 
%
%   Comparison
%   ----------
%   There are different ways how to perform mean filtering in MATLAB. 
%   An effective way for small neighborhoods is to use IMFILTER:
%
%       I = imread('eight.tif');
%       meanFilter = fspecial('average', [3 3]);
%       J = imfilter(I, meanFilter);
%       figure, imshow(I), figure, imshow(J)
%
%   However, IMFILTER slows down with the increasing size of the 
%   neighborhood while AVERAGEFILTER processing time remains constant.
%   And once one of the neighborhood dimensions is over 21 pixels,
%   AVERAGEFILTER is faster. Anyway, both IMFILTER and AVERAGEFILTER give
%   the same results.
%
%   Remarks
%   -------
%   The output matrix type is the same as of the input matrix A.
%   If either dimesion of the neighborhood is even, the dimension is 
%   rounded down to the closest odd value. 
%
%   Example
%   -------
%       I = imread('eight.tif');
%       J = averagefilter(I, [3 3]);
%       figure, imshow(I), figure, imshow(J)
%
%   See also IMFILTER, FSPECIAL, PADARRAY.
%   Contributed by Jan Motl (jan@motl.us)
%   $Revision: 1.2 $  $Date: 2013/02/13 16:58:01 $
% Parameter checking.
numvarargs = length(varargin);
if numvarargs > 2
    error('myfuns:somefun2Alt:TooManyInputs', ...
        'requires at most 2 optional inputs');
end
optargs = {[3 3] 0};            % set defaults for optional inputs
optargs(1:numvarargs) = varargin;
[window, padding] = optargs{:}; % use memorable variable names
m = window(1);
n = window(2);

if ~mod(m,2) m = m-1; % check for even window sizes
end

if ~mod(n,2) n = n-1;
end

if (ndims(image)~=2)            % check for color pictures
    display('The input image must be a two dimensional array.')
    display('Consider using rgb2gray or similar function.')
    return
end
% Initialization.
[rows, columns] = size(image);   % size of the image

% Pad the image.
imageP  = padarray(image, [(m+1)/2 (n+1)/2], padding, 'pre');
imagePP = padarray(imageP, [(m-1)/2 (n-1)/2], padding, 'post');

% Always use double because uint8 would be too small.
imageD = double(imagePP);

% Matrix 't' is the sum of numbers on the left and above the current cell.
t = cumsum(cumsum(imageD),2);

% Calculate the mean values from the look up table 't'.
imageI = t(1+m:rows+m, 1+n:columns+n) + t(1:rows, 1:columns)...
    - t(1+m:rows+m, 1:columns) - t(1:rows, 1+n:columns+n);

% Now each pixel contains sum of the window. But we want the average value.
imageI = imageI/(m*n);

% Return matrix in the original type class.
image = cast(imageI, class(image));
end
% Initialization of main function
numvarargs = length(varargin);      % only want 3 optional inputs at most
if numvarargs > 3
    error('myfuns:somefun2Alt:TooManyInputs', ...
     'Possible parameters are: (image, [m n], threshold, padding)');
end
optargs = {[3 3] 0.34 'replicate'}; % set defaults
 
optargs(1:numvarargs) = varargin;   % use memorable variable names
[window, k, padding] = optargs{:};

if ndims(image) ~= 2
    error('The input image must be a two-dimensional array.');
end

% Convert to double
image = double(image);

% Mean value
mean = averagefilter(image, window, padding);

% Standard deviation
meanSquare = averagefilter(image.^2, window, padding);
deviation = (meanSquare - mean.^2).^0.5;

% Sauvola
R = max(deviation(:));
thresh = mean.*(1 + k * (deviation / R-1));
I = (image > thresh);
end
