close all
clear all

global img;

imagefig=figure('units','normalized','position',[0.1 0.1 0.8 0.8]);    
img = imread('/Users/doot4runner/Desktop/TACS-3k.tif');
img = double(img(:,:,1));
image(img/2);colormap(gray);axis('image');

hold on

set(imagefig,'windowbuttondownfcn',{@track}); 
butGo('arg',img);
butClear;


