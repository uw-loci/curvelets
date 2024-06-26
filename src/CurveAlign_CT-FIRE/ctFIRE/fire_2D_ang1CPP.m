function[data] = fire_2D_ang1CPP(p,im,plotflag)
%FIRE(p,im,plotflag)
%main fire algorithm p = parameter vector, im3 = 3d image,
%and plotflag = 1 gives lots of plots
% gcf20 = figure(20); clf;
% set(gcf20,'name','Fiber extraction in process ... ','numbertitle','off')
if nargin < 3
    plotflag = 1;
end

if plotflag==1
    rr = 3; cc = 3;
elseif plotflag==2
    rr = 1; cc = 2;
else
    rr = 1; cc = 1;
end

ifig = 0;
%plot initial figures 
if plotflag == 1 || 2
    str  = 'a' + ifig;
    ifig = ifig+1;
 % YL: don't plot any figure when plotflag = 0
%     subplot(rr,cc,ifig);
%     flatten(im);
%     colormap gray
%     title(sprintf('%c) Flattened Image',str))
%     pause(0.1)
end
ax = [1 size(im,2) 1 size(im,3)];

%smoothing image
fprintf('  smoothing original image\n');
ims = round(smooth(im,p.sigma_im));

if plotflag == 1
    str  = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    flatten(ims); colormap gray
    title(sprintf('%c) Smoothed Image',str))
    view(0,90)
    axis(ax)
end

%threshold image
if ~isempty(p.thresh_im)
    imt = ims>p.thresh_im*max(ims(:));
else
    imt = ims>p.thresh_im2;
end


if plotflag == 1
    str  = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    flatten(imt*256); colormap gray
    title(sprintf('%c) Thresholded Image',str))
    view(0,90)
    axis(ax)
end

%clear ims

%perform distance transform
fprintf(['  calculating ' p.dtype ' distance to background\n'])
d = single(bwdist(~imt,p.dtype));
%clear imt
dsm = single(smooth(d,p.sigma_d));
clear d;

if plotflag==1
    str  = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    flatten(dsm); colormap gray
    title(sprintf('%c) Smoothed Distance Function',str))
    view(0,90)
    axis(ax)
end

tic;
%find crosslinks
fprintf('finding nucleation points\n   ')
[K J I] = size(dsm);
xlink = findlocmax_native(K,J,I,dsm,p.s_xlinkbox,p.thresh_Dxlink);
%disp(xlink);
%figure;
%plot(xlink(:,1),xlink(:,2),'ro','MarkerFaceColor','r','MarkerSize',4)
%figure;
%size(xlink)
%toc;
%tic;
%xlink = findlocmax(dsm,p.s_xlinkbox,p.thresh_Dxlink);
%figure;
%plot(xlink(:,1),xlink(:,2),'ro','MarkerFaceColor','r','MarkerSize',4)
%size(xlink)
%toc;
if plotflag == 1
    str  = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    flatten(im);
    hold on
    plot3(xlink(:,1),xlink(:,2),xlink(:,3),'ro','MarkerFaceColor','r','MarkerSize',4)
    view(0,90)
    axis(ax)
    title(sprintf('%c) Nucleation Points',str))
    pause(0.1)
end

%xlinkin = cast(xlink,'int32');
xlinkin = xlink;

%find network
fprintf('extending nucleation points\n')
[Xz Fz Vz Rz] = extend_xlink_native(K,J,I,dsm,round(xlinkin),p);
Xz = cast(Xz,'double');
size(Fz,1)
for i = 1:size(Fz,1)
    Fz(i).v = cast(Fz(i).v,'double');
    Fz(i).f = cast(Fz(i).f,'double');
end
for i = 1:size(Vz,1)
    Vz(i).fe = cast(Vz(i).fe,'double');
    Vz(i).f = cast(Vz(i).f,'double');
    Vz(i).vall = cast(Vz(i).vall,'double');
end
Rz = cast(Rz,'double');

%[Xz Fz Vz Rz] = extend_xlink(dsm,round(xlinkin),p);
%size(Xz)
%plot(Xz(:,1),Xz(:,2),'ro','MarkerFaceColor','r','MarkerSize',4); 
%figure;
%toc;
if plotflag == 1
    str  = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    %flatten(dsm);
    hold on
    %plot3bw(dsm)
    plotfiber(Xz,Fz,1,0,'b')
    plot3(xlink(:,1),xlink(:,2),xlink(:,3),'ro','MarkerFaceColor','r','MarkerSize',4)
    axis(ax)
    view(0,-90)
    title(sprintf('%c) Prelim. Network',str))
    axis image
    pause(0.1)
end

%remove danglers and shorties
fprintf('remove danglers and shorties\n')
%[Xz2 Fz2 Vz2 Rz2] = check_danglers(Xz,Fz,Vz,Rz,p);
Xz2 = Xz;
Fz2 = Fz;
Vz2 = Vz;
Rz2 = Rz;
%identify cross-links
xlinkind = zeros(length(Vz),1);
for vi=1:length(Vz)
    if length(Vz(vi).f) > 1
        xlinkind(vi) = 1;
    end
end
xlinknew = Xz(xlinkind==1,:);


if plotflag == 1
    str = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    hold on
    plotfiber(Xz2,Fz2,2,0,'b')
    plot3(xlinknew(:,1),xlinknew(:,2),xlinknew(:,3),'ro','MarkerFaceColor','r')
    axis(ax)
    axis image
    view(0,-90)
    title(sprintf('%c) Danglers Removed',str))
    pause(0.1)
    
end

%return final values
X = Xz2;
F = Fz2;
V = Fz2;
R = Rz2;

%fiberize network
fprintf('fiberproc\n');
%[Xa Fa Ea Va Ra] = fiberproc_native(K,J,I,dsm,X,F,R,p);
Xa = Xz2;
Fa = Fz2;
Va = Vz2;
Ra = Rz2;
Ea = zeros(length(Fa),2);
for i=1:length(Fa)
   Ea(i,1:2) = [Fa(i).v(1) Fa(i).v(end)];
end   
%[Xa Fa Ea Va Ra] = fiberproc(X,F,R,size(dsm),p);
%maketext(mfn,Xa,Fa)
if plotflag == 1 || plotflag == 2
    str  = 'a'+ifig;
    ifig = ifig+1;
    subplot(rr,cc,ifig)
    %flatten(im3(p.zstart:p.zstop,:,:));
    plotfiber(Xa,Fa,2,0,[]); axis image
    title(sprintf('%c) Fiber Network',str))
    %% ym: comment out
    %         set(gca,'XLim',[min(Xa(:,1))  max(Xa(:,1))],...
    %                 'YLim',[min(Xa(:,2))  max(Xa(:,2))]);
    %cet(gca,'Color','k')
    view(0,-90);
    pause(0.1)
    
end

CPPtoc = toc;
fprintf('CPP code for this image takes %5.2f seconds \n', CPPtoc);
%plot full image (as opposed to slice as done earlier, in fire)
%{
    if plotflag==1 && length(p.zrange)>2
        str  = 'a'+ifig;
        ifig = ifig+1;
        subplot(rr,cc,ifig)
        flatten(im3)
        title(sprintf('%c) Full Flattened Image',str))
    end
%}

%compute network stats
Xas = zeros(size(Xa));
%     p.scale = [1 1 1]; % ym
for k=1:size(Xa,1)
    Xas(k,:) = Xa(k,:).*p.scale;
end
M = network_statK(Xas,Fa,Va,Ra);  % ym: modification made in this function

%ym: interpolation of the fibers

[Xai Fai Vai] = fiber2beam(Xas,Fa,Va,Ra,p.s_maxspace,p.lambda,0);
data.Xai = Xai;
data.Fai = Fai;
data.Vai = Vai;

%%ym: calculate angles at individual points for each fiber
SPI = p.ang_interval;               % sampling points interval
FiberAngle = calc_fiberang2(Xas,Fa,SPI)
M.Fang =  FiberAngle;   %

%%ym: calculate angles at individual interpolation points for each fiber
SPI = p.ang_interval;               % sampling points interval
FiberAngleI = calc_fiberang2(Xai,Fai,SPI)
M.FangI =  FiberAngleI;   %


%convert to beams for FEA
fprintf('beamproc\n');
[Xab Fab Vab] = beamproc(Xa,Fa,Va,Ra,p);
%{
    if plotflag == 1
        str  = 'a'+ifig;
        ifig = ifig+1;
        subplot(rr,cc,ifig)
        hold on
        plotfiber(Xab,Fab,2,0,[])
        title(sprintf('%c) Reduced Network',str))
        %axis([min(Xab(:,1)) max(Xab(:,1)) min(Xab(:,2)) max(Xab(:,2))]);
        view(0,-90)
        pause(0.1)
        %cet(gca,'Color','k')
        axis equal
    end
%}
% for ii=1:ifig
%     subplot(rr,cc,ii)
%     set(gca,'XTick',[],'YTick',[])
% end

[Xc Fc Vc] = fiberbreak(Xa,Fa,Va); %breaks fiber up at cross-links

%make output structure
data.X = X;
data.F = F;
data.R = R;

data.Xa= Xa;
data.Fa= Fa;
data.Va= Va;
data.Ea= Ea;
data.Ra= Ra;

data.Xab=Xab;
data.Fab=Fab;
data.Vab=Vab;

data.Xc = Xc;
data.Fc = Fc;
data.Vc = Vc;

data.M = M;

data.xlink = xlink;

% close(gcf20);