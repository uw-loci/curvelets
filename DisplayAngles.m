close all;
clear all;
cd '/home/doot4runner/Documents/Research/finding collagen/Wrapping/TACS Images' 
% img = imread('1.jpg'); 
% img = imread('TACS-2a.jpg'); 
% img = imread('TACS-2b.tif'); 
% img = imread('TACS-2c.tif'); 
% img = imread('TACS-2d.jpg'); 
% img = imread('TACS-2e.jpg'); 
% img = imread('TACS-2f.jpg'); 
% img = imread('TACS-2g.tif'); 
% img = imread('TACS-2h.tif'); 
% img = imread('TACS-2i.tif'); 
% img = imread('TACS-2j.tif'); 
% img = imread('TACS-2k.tif'); 
% img = imread('TACS-2l.tif'); 
% img = imread('TACS-3a.jpg'); 
% img = imread('TACS-3b.jpg'); 
% img = imread('TACS-3c.jpg'); 
% img = imread('TACS-3d.jpg'); 
% img = imread('TACS-3e.tif'); 
% img = imread('TACS-3f.tif'); 
% img = imread('TACS-3g.tif'); 
 img = imread('TACS-3h.tif'); 
% img = imread('TACS-3j.tif'); 
% img = imread('TACS-3k.tif'); 
% img = imread('TACS-3l.tif'); 
cd '/home/doot4runner/Documents/Research/finding collagen/Wrapping'
tic
[C_new,curvelet] = CurveCollagen(img,.01,4,3/4);
load img_add
toc
%CurveCollagen(image, pctg, numAngle, keep)

