function applyThresh()
global img;



img = mat2gray(img);

img = histeq(img);
img = imsubtract(img,.2);

img = roicolor(img,.7,1);
img = filter2(fspecial('average',[2 2]),img);
imshow(img);
%imwrite(img,'threshold.tif','tif','Compression','none');
