close all
clear all

global img;

imagefig=figure('units','normalized','position',[0.1 0.1 0.8 0.8]);    
<<<<<<< .mine
img = imread('/Users/doot4runner/Desktop/Curvelets (edited)/images/TACS-3a.jpg');
=======
img = imread('/Users/doot4runner/Desktop/images/TACS-3b.jpg');
%img = imread('/Users/doot4runner/Desktop/test.tif');
>>>>>>> .r92
img = double(img(:,:,1));
figure(1);image(img/4);colormap(gray);axis('image');

hold on

set(imagefig,'windowbuttondownfcn',{@track}); 
% This two functions create the buttons on the figure window labeled "go"
% and "clear"
butGo('arg',img);
butClear;
% This function creates the two text fields that allow the user to set a
% threshold for how far away from the user defined boundary the curvelets
% are calculated
fillDist('arg',img);


