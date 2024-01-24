ctfDEF.mat    % string, default parameter file or previous output data file 
C:\Users\yuming\git201502\knime-curvelets\loci.goCAK.matlab\testfiles  %string, image name
1B_D3_SHG_ROI_TACS3positive.tif-1.tif  %string, image path

postp = 0 % numeric, 0: process an image; 1: post-processing an image, dimensionless
%%fiber extraction parameters
pct = 0.2            %numeric, percentile of the remaining curvelet coeffs, dimensionless
SS = 3;              %numeric,number of the selected scales, dimensionless  
thresh_im2 = 5 % numeric, main adjustable parameters, unit:grayscale intensity , 
xlinkbox = 8 % radius of box in which to check to make sure xlink is a local max of the distance function, pixels
thresh_ext = 70% numeric,, angle similarity required for a fiber to extend to the next point(cos(70*pi/180)),degree
thresh_dang_L = 15; %numeric, dangler length threshold, pixels
thresh_short_L = 15; %numeric, short fiber length threshold, pixels
s_fiberdir  =4; % numeric, number of nodes used for calculating direction of fiber end, dimensionless,
thresh_linkd =  15 %numeric, distance for linking same-oriented fibers, pixels
thresh_linka = 150 % numeric, minimum angle between two fiber ends for linking of the two fibers(cos(-150 *pi/180)), degree
thresh_flen = 15 %numeric, minimum length of a free fiber, pixels

%% parameters for width calculations

wid_opt = 1;     % numeric,choice for width calculation, 1: use all points; 0: use the following parameters, dimensionless
wid_mm = 10;     % numeric,minimum maximum fiber width, pixels
wid_mp = 6;      % numeric,minimum points to apply fiber points selection, [#]
wid_sigma = 1;   %numeric, confidence region, default +- 1, dimensionless
wid_max = 0;     %numeric, calculate the maximum width of each fiber, default 0, not calculate; 1: calculate, dimensionless

%% output image format control
LW1 = 0.5; % numeric, line width for the fibers displayed in the overlaid image, dimensionless
LL1 = 30;  % numeric,threshold of the fiber length, [pixels]
FNL = 99999;% numeric, maximum number of fibers in an individual image, [#]
RES = 300;   % numeric,image resolution of the overlaid image, dpi
widMAX = 15; % numeric, maximum width of any point on a fiber, pixels

% cvs output control
cP.angHV = 1;  %numeric, 1: output angle , 0: don't output angle, dimensionless
cP.lenHV = 1;  %numeric, 1: output length , 0: don't output length, dimensionless
cP.widHV = 1;  %numeric, 1: output width , 0: don't output width, dimensionless
cP.strHV = 1;  %numeric, 1: output straightness , 0: don't output straightness, dimensionless
