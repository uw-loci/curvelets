function[] = im3write(im3,fname,imtype)
%IM3WRITE - stores a 3d image as a set of 2d images
if nargin<3
    imtype = 'tif';
end

for i=1:size(im3,1)
    im = squeeze(uint8(im3(i,:,:)));
    if i==1
        writemode = 'overwrite';
    else
        writemode = 'append';
    end
    imwrite(im,fname,imtype,'WriteMode',writemode) 
end