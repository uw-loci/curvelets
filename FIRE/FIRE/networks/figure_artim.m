rr = 3; cc = 3;
NF = 120;
seed = 0;
mfn = 'go_artim09';

fdir = sprintf('../networks/%s/N%d_%d%s',mfn,NF,seed);       
fdir2 = fdir;
        
[Xt Ft] = loadtext([fdir2 '/network']);        
[Xt Ft Vt] = trimxfv(Xt,Ft);


fdir = sprintf('../networks/%s/N%d_%d%s',mfn,NF,seed,'');
IM{1}  = loadim3(fdir,256,'im',2);

fdir = sprintf('../networks/%s/N%d_%d%s',mfn,NF,seed,'p');
IM{2}   = loadim3(fdir,256,'im',2);

fdir = sprintf('../networks/%s/N%d_%d%s',mfn,NF,seed,'pn');
IM{3}   = loadim3(fdir,256,'im',2);

clf
subplot(rr,cc,8)
    plotfiber(Xt,Ft,2)
    view(0,-90)    

for i=1:3
    subplot(rr,cc,i)
    imagesc(squeeze(IM{i}(end/2,:,:)));
end
for i=4:6
    subplot(rr,cc,i)
    imagesc(squeeze(max(IM{i-3},[],1)));
end

for i = [1:6 8];
    subplot(rr,cc,i)
        axis([0 128 0 128])
        set(gca,'XTick',[],'YTick',[])
        colormap gray
        %title(tstr{i})        
end
ystr = {'Image Slice','Flattened 3d Image','Fiber Network'};
tstr = {'Fibers','PSF Convolution','PSF + Noise'};

yp = [1 4 8];
tp = [1 2 3];
for i=1:3
    subplot(rr,cc,yp(i))
    ylabel(ystr{i});
    
    subplot(rr,cc,i)
    title(tstr{i});
end

subplotspace('horizontal',-20);
subplotspace('vertical',-20);
setfont(20)