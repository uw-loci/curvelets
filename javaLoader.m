close all;
clear all;

javaaddpath /Users/doot4runner/Desktop/visad-lite.jar
javaaddpath /Users/doot4runner/Desktop/bio-formats.jar
javaaddpath /Users/doot4runner/Desktop

RegionChooser.main('/Users/doot4runner/Desktop/TACS-3k.tif')

img = imread('/Users/doot4runner/Desktop/TACS-3k.tif');
img = double(img(:,:,1));

% Make a go button

but('arg',img);
