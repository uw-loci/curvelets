function sampling(image,samplingFactor)
% This function will resample the image and save the resampled image as
% sample.tif in the program for other program to use.

imgData = imread(image);
sizeImgData = size(imgData);

xg = 1:sizeImgData(1);
yg = 1:sizeImgData(2);
zg = 1:sizeImgData(3);
F = griddedInterpolant({xg,yg,zg},double(imgData));

xq = (0.5:1/samplingFactor:sizeImgData(1))';
yq = (0.5:1/samplingFactor:sizeImgData(2))';

vq = uint8(F({xq,yq,zg}));

imwrite(vq,'sample.tif','tif');

end