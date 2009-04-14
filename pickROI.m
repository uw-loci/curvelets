function pickROI()
global img;

img = mat2gray(img);
img = roifill(img);

imshow(img);