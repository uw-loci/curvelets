function[] = image3(im,pau,pt,loopind,fname)
%IMAGE3 - plots sequentially the images in a stacks
%im = a 3d stack of image, or a cell array of 3d image stacks
%ipt = the indices for points to plot
%pau = the length of the pause duration between images
%loopind = the slices of the 3d stack to plot
%fname = if not empty, the file name of the movie to be created
%
%image3(im,pau,pt,loopind,fname)
clf
eps = 1e-10;

if ~iscell(im)
    IM{1} = im;
else
    IM    = im;
end
if nargin<2
    pau = .01;
end
if nargin<3
    pt  = [];
end
if nargin<4
    loopind = 1:size(IM{1},1);
end
if isempty(loopind)
    loopind = 1:size(IM{1},1);
end
if nargin<5
    fname = [];
end

len = length(IM);

cc = ceil(sqrt(len));
rr = ceil(len/cc);

colormap gray

if ~isempty(fname)
    figure
    
    set(gcf,'DoubleBuffer','on');
    set(gca,'NextPlot','replace')
    mov = avifile(fname);
end
for i=loopind
    for j=1:length(IM)

        subplot(rr,cc,j)
        im = squeeze(IM{j}(i,:,:,:));
        image(im);
        axis image
        title(num2str(i));

        if ~isempty(pt)
            ind = find(abs(pt(:,3)-i)<=1);
            if ~isempty(ind)
                hold on
                plot(pt(ind,1),pt(ind,2),'ro','MarkerFaceColor','r');
                hold off
            end
        end
        pause(pau);

        if ~isempty(fname)

            colormap gray
            f = getframe(gcf);
            mov = addframe(mov,f);
        end
    end
end
if ~isempty(fname)
    mov = close(mov);
end

