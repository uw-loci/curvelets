function res = bpass(arr,lnoise,lobject)
% 
% ; NAME:
% ;               bpass
% ; PURPOSE:
% ;               Implements a real-space bandpass filter which suppress 
% ;               pixel noise and long-wavelength image variations while 
% ;               retaining information of a characteristic size.
% ;
% ; CATEGORY:
% ;               Image Processing
% ; CALLING SEQUENCE:
% ;               res = bpass( image, lnoise, lobject )
% ; INPUTS:
% ;               image:  The two-dimensional array to be filtered.
% ;               lnoise: Characteristic lengthscale of noise in pixels.
% ;                       Additive noise averaged over this length should
% ;                       vanish. MAy assume any positive floating value.
% ;               lobject: A length in pixels somewhat larger than a typical
% ;                       object. Must be an odd valued integer.
% ; OUTPUTS:
% ;               res:    filtered image.
% ; PROCEDURE:
% ;               simple 'wavelet' convolution yields spatial bandpass filtering.
% ; NOTES:
% ; MODIFICATION HISTORY:
% ;               Written by David G. Grier, The University of Chicago, 2/93.
% ;               Greatly revised version DGG 5/95.
% ;               Added /field keyword JCC 12/95.
% ;               Memory optimizations and fixed normalization, DGG 8/99.
%                 Converted to Matlab by D.Blair 4/2004-ish
%                 Fixed some bugs with conv2 to make sure the edges are
%                 removed D.B. 6/05
%                 Removed inadvertent image shift ERD 6/05
%                 Added threshold to output.  Now sets all pixels with
%                 negative values equal to zero.  Gets rid of ringing which
%                 was destroying sub-pixel accuracy, unless window size in
%                 cntrd was picked perfectly.  Now centrd gets sub-pixel
%                 accuracy much more robustly ERD 8/24/05
% ;
% ;       This code 'bpass.pro' is copyright 1997, John C. Crocker and 
% ;       David G. Grier.  It should be considered 'freeware'- and may be
% ;       distributed freely in its original form when properly attributed.
% 
%   

  b = double(lnoise);
  w = round(lobject);
  N = 2*w + 1;
  
  % Gaussian Convolution kernel
  
  sm = 0:N-1;
  r = (sm - w)/(2 * b);
  gx = exp( -r.^2) / (2 * b * sqrt(pi));
  gy = gx';
    
  %Boxcar average kernel: background
  
  bx = zeros(1,N)  + 1/N;
  by = bx';
  % Do some convolutions with the matrix and our kernels
  
  res = arr;
  g = conv2(res,gx,'valid');
  tmpg = g;
  g = conv2(tmpg,gy,'valid');
  tmpres = res;
  res = conv2(tmpres,bx,'valid');
  tmpres = res;
  res = conv2(tmpres,by,'valid');
  tmpg= 0;
  tmpres=0;
  arr_res=zeros(size(arr));
  arr_g = zeros(size(arr));
  
  arr_res((lobject+1):end-lobject,(lobject+1):end-lobject) = res;
  arr_g((lobject+1):end-lobject,(lobject+1):end-lobject) = g; 
  %res = arr_g-arr_res;  
  res=max(arr_g-arr_res,0);
  