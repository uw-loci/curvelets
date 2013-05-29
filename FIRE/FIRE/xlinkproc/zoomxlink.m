function[] = zoomxlink(im3,X,F,V,ixlink,r,movieflag)

if nargin < 6
    r = 20;
end
if nargin < 7
    movieflag = 0;
end

nx= size(X,1);

x  = X(ixlink,:);

vall = V(ixlink).vall;
fadd = [];
for vi = vall
    fadd = [fadd V(vi).f];
end
fadd = unique(fadd);
Fx = F(fadd);

m = max(1,x-r);
M = min(fliplr(size(im3)),x+r);

ix = m(1):M(1);
iy = m(2):M(2);
iz = m(3):M(3);

D = max(abs( X - ones(nx,1)*x),[],2);
inear = find(D<r);
for ii = length(inear):-1:1
    if length(V(inear(ii)).f) < 2
        inear(ii,:) = [];
    end
end

Xold = X;
X = X - ones(nx,1)*m + 1;

imflat = squeeze(max(im3(iz,iy,ix),[],1));

clf

imagesc(imflat); colormap gray
hold on
plot3bw(im3(iz,iy,ix));
plotfiber(X,Fx,4,2);
plot3(X(ixlink,1),X(ixlink,2),X(ixlink,3),'ro','MarkerFaceColor','y','MarkerSize',25,'LineWidth',5)
plot3(X(inear,1) ,X(inear,2),X(inear,3),'yo','MarkerFaceColor','y','MarkerSize',15)    
title(sprintf('%d of %d',ixlink,length(V)));

if movieflag
    pause
    for z = iz    
        cla
        imagesc(squeeze(im3(z,iy,ix))); colormap gray
        plotfiber(X,Fx,4,2);
        plot3(X(ixlink,1),X(ixlink,2),X(ixlink,3),'ro','MarkerFaceColor','y','MarkerSize',25,'LineWidth',5)
        plot3(X(inear,1) ,X(inear,2),X(inear,3),'yo','MarkerFaceColor','y','MarkerSize',15)    
        title(sprintf('%d in (%d,%d)',z,min(iz),max(iz)));        
        pause
    end
end
1;




