function[] = image3_fiber(im,X0,F,pau,dz,fname)
%IMAGE3_FIBER - plots sequentially the images in a stacks and overlays
%fibers
%im = a 3d stack of image, or a cell array of 3d image stacks
%ipt = the indices for points to plot
%pau = the length of the pause duration between images
%loopind = the slices of the 3d stack to plot
%fname = if not empty, the file name of the movie to be created
%
%image3_fiber(im,X0,F,pau,dz,fname)
im = uint8(round(255*double(im-min(im(:)))/double(max(im(:))-min(im(:))))); 
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
if nargin < 6
    fname = [];
end

len = length(IM);
cc = 2;
rr = 1;

clf
if ~isempty(fname)
    clf
    set(gcf,'DoubleBuffer','on');
    set(gca,'NextPlot','replace')
    mov = avifile(fname);
end
for i=1:(size(IM{1},1)-dz)
    im = squeeze(IM{1}(i+round(dz/2),:,:));
    %im = squeeze(mean(IM{1}(i:i+dz,:,:)));
    subplot(rr,cc,1)
        colormap gray    
        imagesc(im);
        title(num2str(i))
        axis image
    subplot(rr,cc,2)
        imagesc(im);
        %image(zeros(size(im)));
        hold on
        plotfiber_slice(X0,F,i,i+dz);
        hold off
        axis image
        title(num2str(i));
    if ~isempty(fname)
        f = getframe(gcf);
        mov = addframe(mov,f);
    end
        pause(pau)
end
if ~isempty(fname)
    mov = close(mov);
end
