function showRecon(C,imgName)

% showRecon.m
% This function performs the inverse FDCT transform (see http//curvelet.org) and displays the reconstructed image.
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010

    Y = ifdct_wrapping(C,0);

    figure('Name',[imgName,' - Curvelet Reconstruction']);
    imagesc(real(Y))
    colormap(lines)