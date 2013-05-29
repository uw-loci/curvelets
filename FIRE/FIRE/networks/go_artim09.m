%a series of small artificial images
%it is 128x128x128
%they are supposed to represent the confocal fluorescent from Sept 06
%so the resolution is .1 microns per pixel, postproc can get it up to .2 in
%z 
    %addpath ../../; updatepath
    fpref = mfilename;
%parameters for generating an artificial image
    q.scale     = .1; %micron/pixel
    q.fiberD    = .5; %micron fiber diameter
    q.sigma     =  0; %micron - standard dev of image blurring
    q.wid       = 256;%number of pixels to make image
    q.D         = q.fiberD/q.scale/q.wid ; %maximum distance 2 nodes can be from each other such taht a fiber is defined
    q.Linc      = q.D/3;
    q.coltype   = 'fixedlen'; %collision type - how to handle fiber collisions
    q.Lmax      = 20/q.scale/q.wid; %maximum length of fiber
    q.Lp        = 12/q.scale/q.wid; %persistence length
    q.rseed     = 0;
    
    q.postsigma = [6 1 1];
    q.postnoise = 5;
    
    %make kernel
        fiberdiam  = q.fiberD/q.scale;
        q.kernel   = double(sphere_filter(fiberdiam));
        
%create fake image and it's network parameters
    NFrange = 30 %[30 45 60 90 120];
    seedrange= [0:4];% 1 2 3 4 5];
    %LPrange = [.1 .2 .4 .8 1.2 1.6 2.0];

    clear LPy LPz LP3
    tic;
    %for k=1:length(LPrange)
    for j=1:length(seedrange)       
    for i=1:length(NFrange)
        
        q.NF = NFrange(i);    
        q.rseed = seedrange(j);  
        fprintf('%d Fibers, Number %d\n',q.NF,j);
        
        %create fake image and it's network parameters 
            if exist(['./' fpref],'dir')~=7
                eval(['!mkdir ' fpref ]);
            end
            fdir = sprintf('%s/N%d_%d',fpref,q.NF,q.rseed);
            [im Xt Ft Et Vt] = makevol(q,q.kernel,0,fdir);
            maketext([fdir '/network'],Xt,Ft)
            
        %convolve with a point spread function
            imp = smooth(single(im),q.postsigma);
            imp = imp/max(imp(:))*255;
            imp = uint8(imp);
            im3write(imp,[fdir 'p']);
            maketext([fdir 'p/network'],Xt,Ft)            
        %add gaussian white noise
            impn= single(imp) + q.postnoise*single(randn(size(imp)));
            impn= impn/max(impn(:))*255;
            impn= uint8(impn);
            im3write(impn,[fdir 'pn']);
            maketext([fdir 'pn/network'],Xt,Ft)                        
        %calculate LP
            clf; plotfiber(Xt,Ft,2,0,[],'none','k'); pause(.01)          
    end
    end
