function colorSeg()

RGB = imread('../2B_D9_ROI1 copy.tif');
imshow(RGB)
L = imsegkmeans(RGB,2); % separate the image(RGB) into 2 groups
B = labeloverlay(RGB,L);
imshow(B)

end

function segByColor()

RGB = imread('../2B_D9_ROI1 copy.tif');
lab_he = rgb2lab(RGB);
ab = lab_he(:,:,2:3);
ab = im2single(ab);
nColors = 3;
% repeat the clustering 3 times to avoid local minima
pixel_labels = imsegkmeans(ab,nColors,'NumAttempts',3);

mask1 = pixel_labels==1;
cluster1 = RGB .* uint8(mask1);
imshow(cluster1)

end

