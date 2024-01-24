function[] = image3_tree(im,t,pau,dz)
%IMAGE3_FIBER - plots sequentially the images in a stacks and overlays
%fibers
%im = a 3d stack of image, or a cell array of 3d image stacks
%ipt = the indices for points to plot
%pau = the length of the pause duration between images
%loopind = the slices of the 3d stack to plot
%fname = if not empty, the file name of the movie to be created

eps = 1e-10;

if ~iscell(im)
    IM{1} = im;
else
    IM    = im;
end
if nargin < 4
    pau = .01;
end
if nargin < 5
    dz = 10;
end

len = length(IM);
cc = 2;
rr = 1;

[X0 E] = tree2graph(t);

clf
colormap gray    
for i=1:(size(IM{1},1)-dz)
        im = squeeze(mean(IM{1}(i:i+dz,:,:)));
        subplot(rr,cc,1)
            imagesc(im);
            title(num2str(i))
            axis image
        subplot(rr,cc,2)
            imagesc(im);
            hold on
            plotfiber_slice(X0,E,i,i+dz);
            hold off
            axis image
            title(num2str(i));
        pause(pau)
end

