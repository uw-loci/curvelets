%a series of small artificial images
%it is 128x128x128
%they are supposed to represent the confocal fluorescent from Sept 06
%so the resolution is .1 microns per pixel, postproc can get it up to .2 in
%z 
    addpath ../initproc:../graphics:../fiberproc
    fpref = mfilename;
    writeflag = 0;
    imageflag = 0;
%parameters for generating an artificial image
%lowercase units are in microns, upercase are in pixels or normalized to
%one.
    q.scale     = .05; %micron/pixel
    q.d         = .075; %fiber diameter (microns)
    q.wid       = 25.6; %width of image (microns

    q.lambda    =   1/10.4;  %1/microns - mean of exponentially dist. fiber length of Lmax
    q.mu        =   3.2;%mu for lognormally distributed persistence length
    q.sigma     =   1.3;%sigma for lognormally distributed persistence length
    
    q.lstep     = 1; %micron
    
    q.D         = q.d/q.scale; %maximum distance 2 nodes can be from each other such taht a fiber is defined    
    q.W         = q.wid/q.scale;    
    q.Dmerge    = q.D*4; %distance for merging x-links     
    
    q.Lstep     = q.lstep/q.scale; %micron
    q.coltype   = 'fixedlen'; %collision type - how to handle fiber collisions

    q.rseed     = 0;

    q.zstep     = 2; %take every other step in the z-direction    
    q.postsigma = [6 1 1];
    q.postnoise = 5;
    
    %make kernel
        fiberdiam  = q.d/q.scale;
        q.kernel   = double(sphere_filter(fiberdiam));
        
%create fake image and it's network parameters
    DensCol = 1360; %mg/mL
    DensGel = [1];% mg/mL
    
    NFrange = ceil( DensGel/DensCol*(q.wid)^3/(pi*(q.d/2)^2)/(1/q.lambda) ); %[30 45 60 90 120];
    seedrange= 0;% 1 2 3 4 5];
    %LPrange = [.1 .2 .4 .8 1.2 1.6 2.0];

    clear LPy LPz LP3
    tic;
    %for k=1:length(LPrange)
    for j=1:length(seedrange)       
    for i=1:length(NFrange)
        
        q.NF = NFrange(i);  
        
        q.lmax = -1/q.lambda*log(rand(q.NF,1));
        q.lp   = exp( q.sigma*randn(q.NF,1) + q.mu);
        
        q.Lmax      = q.lmax/q.scale; %maximum length of fiber (microns->pixels)
        q.Lp        = q.lp/q.scale; %persistence length

        
        q.rseed = seedrange(j);  
        fprintf('%d Fibers, Number %d\n',q.NF,j);
        
        %create fake image and it's network parameters 
            if writeflag == 1
                if exist(['./' fpref],'dir')~=7
                    eval(['!mkdir ' fpref ]);
                end
            end
            fdir = sprintf('%s/N%d_%d',fpref,q.NF,q.rseed);
            
            [Xt Ft Xp Fp] = rand3dnet(q);
            Rt = q.d/2*ones(size(Xt(:,1)));
            
            if imageflag == 1
                im = makevol(q,q.kernel,0,fdir,'tif',writeflag);
            end
            if writeflag == 1
                maketext([fdir '/network'],Xt,Ft)
            end
            
        %convolve with a point spread function
            if imageflag==1
                imspace = im(1:q.zstep:end,:,:);

                sig = q.postsigma;
                sig(1) = sig(1)/q.zstep;

                imp = smooth(single(imspace),sig);
                imp = imp/max(imp(:))*255;
                imp = uint8(imp);
            end                        
            if writeflag == 1
                im3write(imp,[fdir 'p']);            
                maketext([fdir 'p/network'],Xt,Ft)
            end
            
        %add gaussian white noise
            if imageflag==1
                impn= single(imp) + q.postnoise*single(randn(size(imp)));
                impn= impn/max(impn(:))*255;
                impn= uint8(impn);
            end
            if writeflag == 1;
                im3write(impn,[fdir 'pn']);
                maketext([fdir 'pn/network'],Xt,Ft)                        
            end
            
        %cplot results
            clf
            subplot(2,2,1)
                plotfiber(Xt,Ft,2,0,'k','none','r'); pause(.01)          
                title('true network')
                axis([0 W 0 W])
            subplot(2,2,2)
                title('apparent x-linked network')
                plotfiber(Xp,Fp,2,0,'k','none','r'); pause(.01)          
                axis([0 W 0 W])
    end
    end
