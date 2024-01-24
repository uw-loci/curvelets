function[p] = param_FIREdef(p)

%preprocessing parameters    
    p.sigma_im  =  0;%sqrt(2); %radius of box for smoothing original image
    p.sigma_d   = .3; %radius of box for smoothing of distance function
    p.dtype     = 'cityblock'; %type of distance transform for bwdist 
                               %(cityblock is significantly faster than
                               %Euclidean distance)
    
   %set threshold.  p.thresh_im  is for a percentage of maximum,
   %                p.thresh_im2 is for a hard value
    p.thresh_im = [];
    p.thresh_im2= 5; %34000YL: to be replaced by the main program
                               
                               
%parameters for finding xlinks
    p.thresh_Dxlink = 1.5; %dist fun. threshold for a point to be considered an x-link
    p.s_xlinkbox    = 8; %5; %radius of box in which to check to make sure xlink is a local max of the distance function
    
%parameters for extending xlinks
    p.thresh_LMP    = .2; %threshold for a point to be considered an LMP
    p.thresh_LMPdist=  2; %minimum distance apart for two LMPs
    p.thresh_ext    = cos(70*pi/180); %angle similarity required for a fiber to extend to the next point
    p.lam_dirdecay  = .5; %decay rate of fiber direction (to make it more difficult for a fiber to turn around)
    p.s_minstep     = 2;  %minimum step size
    p.s_maxstep     = 6;  %max step size

%parameters for removing danglers    
    p.thresh_dang_aextend = cos(10*pi/180); %YL: maximum dangle angler difference at cross-link
    p.thresh_dang_L       = 15; %15;     %YL: dangler length threshold
    p.thresh_short_L      = 15; %15;      %YL: short fiber length threshold
        
%parameters for fiber processing 
    p.s_fiberdir    =  4; %number of nodes used for claculating direction of fiber end
    p.thresh_linkd  = 15; %20; %distance for linknig same-oriented fibers
    p.thresh_linka  = cos(-150 *pi/180); %130 degree YL: minimum angle between two fiber ends for linking of the two fibers
    p.thresh_flen   = 15;%%minimum length of a free fiber
    p.thresh_numv   = 3; %minimum number of verties a free fiber can have

%parameters for beam processing    
     p.scale      = [.05 .05 .1]; % change x,y,z scale
%    p.scale      = [1 1 1];  % YL

    p.s_boundthick = 10; %pixels of thickness for image boundary
    p.blist      = 1; %indicates which boundaries are controlled (1=x,2=y,3=z)    
    p.s_maxspace = 5; % YL: maximum spacing between vertices along a fiber
    p.lambda     = .01; %YL: regularization constant for fitting interpolation function to fiber subunits
    
%YL: parameters for calculating angle at each sampling point
   p.ang_interval = 3; %YL: interval for caculate angle at each point
 
    
