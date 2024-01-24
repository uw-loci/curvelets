%headers
    tic
    addpath(genpath('../')); 
    mfn = mfilename;
    

%parameters for preprocessing of image and dist. func. calculation
    p.Nimages   = 255; %last image in seuence
    p.yred      = [];
    p.xred      = [];     
    
%fire parameters
    p = param_example(p); 
       
%plotflag - for plotting intermediate results
    plotflag = 1;
    if plotflag == 1
        ifig     = 0;
        rr = 3; cc = 3;
        figure(1); clf
        pause(0.1);
    elseif plotflag == 2
        rr = 2; cc = 2;        
    end
    
%load image
    fprintf('loading image\n');
    im3 = loadim3('./images',p.Nimages,'s5part1__cmle','.tif',2,p.yred,p.xred);

%run main FIRE code
    data = fire(p,im3,1);  %uses im3 and p as inputs and outputs everything listed below
    
%other outputs
    t_run = toc;  
    fprintf('total run time = %2.1f minutes\n',t_run/60)
    