function showImg(im,imgName)

% showImg.m
% This function displays the image im
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010

figure('Name',[imgName,' - Original']);
imagesc(im)
colormap(gray)