% make a test image

close all;clear all;

% make image
temp = zeros(512);
coll = 50*ones(200,1);
temp(250:449,345) = coll;
temp(250:449,355) = coll;
temp(250:449,365) = coll;
temp(250:449,375) = coll;

img = temp;
figure;image(img);



