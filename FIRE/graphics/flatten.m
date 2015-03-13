function[im2out] = flatten(im3,dim,transposeflag)

if nargin < 2
    dim = 1;
end
if nargin < 3
    transposeflag = 0;
end

im2 = squeeze(max(im3,[],dim));
if transposeflag 
    im2 = im2';
end

imagesc(im2)

if nargout >= 1
    im2out = im2;
else
    %im2out = 'no output';
end

axis image
colormap gray