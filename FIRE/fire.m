function[data] = fire(p,im,plotflag)
%FIRE(p,im,plotflag)
%
%main fire algorithm p = parameter vector, im3 = 3d image,
%and plotflag = 1 gives lots of plots
    
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
            subplot(rr,cc,ifig);
            flatten(im);
            colormap gray
            title(sprintf('%c) Flattened Image',str))
            pause(0.1)
        end
        ax = [1 size(im,2) 1 size(im,3)];

    %smoothing image
        fprintf('  smoothing original image\n');
        ims = round(smooth(im,p.sigma_im));
                
        if plotflag == 1;            
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

    %find crosslinks    
        fprintf('finding nucleation points\n   ')
        xlink = findlocmax(dsm,p.s_xlinkbox,p.thresh_Dxlink);
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

        xlinkin = xlink;
    
    
    %find network
        fprintf('extending nucleation points\n')
        [Xz Fz Vz Rz] = extend_xlink(dsm,round(xlinkin),p);
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
        fprintf('remove danglers and shorties')
        [Xz2 Fz2 Vz2 Rz2] = check_danglers(Xz,Fz,Vz,Rz,p);

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
        1;      

%fiberize network
    fprintf('fiberproc\n');
    [Xa Fa Ea Va Ra] = fiberproc(X,F,R,size(dsm),p);
    %maketext(mfn,Xa,Fa)
    if plotflag == 1 || plotflag == 2
        str  = 'a'+ifig;
        ifig = ifig+1;
        subplot(rr,cc,ifig)
        %flatten(im3(p.zstart:p.zstop,:,:));
        plotfiber(Xa,Fa,2,0,[]); axis image
        title(sprintf('%c) Fiber Network',str))
        set(gca,'XLim',[min(Xa(:,1))  max(Xa(:,1))],...
                'YLim',[min(Xa(:,2))  max(Xa(:,2))]);
        %cet(gca,'Color','k')
        view(0,-90);
        pause(0.1)

    end
    
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
    for k=1:size(Xa,1)
        Xas(k,:) = Xa(k,:).*p.scale;
    end
    M = network_stat(Xas,Fa,Va,Ra);

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
    for ii=1:ifig
        subplot(rr,cc,ii)
        set(gca,'XTick',[],'YTick',[])
    end
    
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