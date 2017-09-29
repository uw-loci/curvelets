
function ctFIRE_cluster(CTFPfile, ImageName)

%YLSeptember 2017: modified from goCTFK for cluster uses

%Feb, 2015: modified from runMeasure() fuction in ctFIRE.m for the curvelet-knime integration
%% headless CT-FRIE to be used as a node in KNIME
%% Input include the fiber extraction parameters including:
% pathname,
% filename
% updated parameters
% width calculation options
% length threshold
%
%% output
%        .mat file
%        overlaid image
%        csv files for fiber width, fiber length, fiber straightness, and fiber angle
%% To compile:
%  %mcc -m goCTFK.m -a ./ -R '-startmsg,"starting CT-FIRE cluster version,...."'

home;clc;
if (~isdeployed)
    addpath('./CurveLab-2.1.2/fdct_wrapping_matlab');
    addpath(genpath(fullfile('./FIRE')));
    addpath('./20130227_xlwrite');
    addpath('.');
    addpath('./xlscol/');
    display('Please make sure you have downloaded the Curvelets library from http://curvelet.org')
    
end

fid = fopen(CTFPfile);
ctfDEFname = fgetl(fid);
load(ctfDEFname,'cP','ctfP');

imgPath = fgetl(fid);
imgName = fgetl(fid);
% imgPath = './'; %current path
imgName = ImageName;
% figure; imshow(fullfile(imgPath,imgName))
dirout = fullfile(imgPath,'ctFIREout');
if ~exist(dirout,'dir')
    mkdir(dirout);
end
disp(sprintf('dirout= %s',dirout))

cP.postp = str2num(fgetl(fid));%1 % numeric, 0: process an image; 1: post-processing an image, dimensionless

ctfP.pct = str2num(fgetl(fid));%0.2            %numeric, percentile of the remaining curvelet coeffs, dimensionless
ctfP.SS = str2num(fgetl(fid));%3;              %numeric,number of the selected scales, dimensionless
ctfP.value.thresh_im2 = str2num(fgetl(fid));%5 % numeric, main adjustable parameters, unit:grayscale intensity
ctfP.value.xlinkbox = str2num(fgetl(fid));%8 % radius of box in which to check to make sure xlink is a local max of the distance function
ctfP.value.thresh_ext = cos(str2num(fgetl(fid))*pi/180);%70% numeric,, angle similarity required for a fiber to extend to the next point(cos(70*pi/180))
ctfP.value.thresh_dang_L = str2num(fgetl(fid));%15; %numeric, dangler length threshold, in pixels
ctfP.value.thresh_short_L = str2num(fgetl(fid));%15; %numeric, short fiber length threshold, in pixels
ctfP.value.s_fiberdir  = str2num(fgetl(fid));%4; % numeric, number of nodes used for calculating direction of fiber end, dimensionless,
ctfP.value.thresh_linkd =  str2num(fgetl(fid));%15 %numeric, distance for linking same-oriented fibers, dimensions
ctfP.value.thresh_linka = cos(str2num(fgetl(fid))*pi/180);% % numeric, minimum angle between two fiber ends for linking of the two fibers(cos(-150 *pi/180)), degree
ctfP.value.thresh_flen = str2num(fgetl(fid)); %15 %numeric, minimum length of a free fiber, pixels

% width calculation module, should put this into the parameters file
% initialize the width calculation parameters
widcon = struct('wid_opt',1,'wid_mm',10,'wid_mp',6,'wid_sigma',1,'wid_max',0);
% widcon = cP.widcon;     % use width calculation parameters from mat data
cP.widcon.wid_opt = str2num(fgetl(fid));%1;     % numeric,choice for width calculation, 1: use all points; 0: use the following parameters;
cP.widcon.wid_mm = str2num(fgetl(fid));%10;     % numeric,minimum maximum fiber width
cP.widcon.wid_mp = str2num(fgetl(fid)); %6;      % numeric,minimum points to apply fiber points selection
cP.widcon.wid_sigma = str2num(fgetl(fid)); %1;   %numeric, confidence region, default +- 1
cP.widcon.wid_max = str2num(fgetl(fid)); %0;     %numeric, calculate the maximum width of each fiber, deault 0, not calculate; 1: caculate
widcon = cP.widcon;
% BINa = '';     % automaticallly estimated BINs number

%         IMG = getappdata(imgOpen,'img');
cP.LW1 = str2num(fgetl(fid)); %2; % line width for the fibers displayed in the overlaid image, [dimensionless]
cP.LL1 = str2num(fgetl(fid)); %30;  % threshold of the fiber length, [pixels]
cP.FNL = str2num(fgetl(fid)); %99999;% maximum number of fibers in an individual image, [#]
cP.RES = str2num(fgetl(fid)); %300;   % image resolution of the overlaid image, [dpi]
cP.widMAX = str2num(fgetl(fid)); %15; % maximum width of any point on a fiber, [pixels]
BINs = 10;  % number of bins in the histogram,  [#]
RO =  1;   % 1: CT-FIRE, 2:FIRE, 3: both,       [dimensionless]


% cvs output control
cP.angHV = str2num(fgetl(fid)); %1;  %numeric, 1: output angle , 0: don't output angle
cP.lenHV = str2num(fgetl(fid)); %1;  %numeric, 1: output length , 0: don't output length
cP.widHV = str2num(fgetl(fid)); %1;  %numeric, 1: output width , 0: don't output width
cP.strHV = str2num(fgetl(fid)); %1;  %numeric, 1: output straigthness , 0: don't output straightness

%add plotflag control
cP.plotflag = str2num(fgetl(fid)); %1;  %numeric, 1: draw CTrec and OL image , 0: don't use graphic  ;
fclose(fid);   % finish reading the parameters from the .txt file

openimg = 1;% 1: open an image, 0: batch mode getappdata(imgOpen, 'openImg');
openmat = 0; % 1:   open .mat file for postprocessing; 0: new analysis getappdata(imgOpen, 'openMat');
openstack = 0; % 1: process a stack; 0: process a single image getappdata(imgOpen,'openstack');

%         cP.slice = [];  cP.stack = [];  % initialize stack option
if openimg
    if openstack == 1
        
        cP.stack = openstack;
        sslice = getappdata(imgOpen,'totslice'); % selected slices
        cP.ws = 1 ;  % 1:process whole stack 0: based on the user input% getappdata(hsr,'wholestack')
        disp(sprintf('cp.ws = %d',cP.ws));
        
        if cP.ws == 1 % process whole stack
            cP.sselected = sslice;      % slices selected
            
            for iss = 1:sslice
                cP.slice = iss;
                set(infoLabel,'String','Analysis is ongoing ...');
                cP.widcon = widcon;
                [OUTf OUTctf] = ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP,iss);
                soutf(:,:,iss) = OUTf;
                OUTctf(:,:,iss) = OUTctf;
            end
            
            set(infoLabel,'String','Analysis is done');
        else
            srstart = getappdata(hsr,'srstart');
            srend = getappdata(hsr,'srend');
            cP.sselected = srend - srstart + 1;      % slices selected
            
            for iss = srstart:srend
                img = imread([imgPath imgName],iss);
                cP.slice = iss;
                cP.widcon = widcon;
                [OUTf OUTctf] = ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP,iss);
                soutf(:,:,iss) = OUTf;
                OUTctf(:,:,iss) = OUTctf;
            end
            
        end
        
    else
        disp('process an image')
        
        disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
            imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
        cP.widcon = widcon;
        
        [OUTf OUTctf] = ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP);
        
        disp('Fiber extration is done, confirm or change parameters for post-processing');
        
    end
    
else  % process multiple files
    
    if openmat ~= 1
        filelist = cell2struct(multiimg,'name',1);
        fnum = length(filelist);
        
        % YL 2014-01-16: add image stack analysis, only consider
        % multiple files are all images or all stacks
        ff = [imgPath, filelist(1).name];
        info = imfinfo(ff);
        numSections = numel(info);
        
        if numSections == 1   % process multiple images
            for fn = 1:fnum
                imgName = filelist(fn).name;
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                cP.widcon = widcon;
                ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP);
            end
            
        elseif  numSections > 1% process multiple stacks
            %                     cP.ws == 1; % process whole stack
            cP.stack = 1;
            for ms = 1:fnum   % loop through all the stacks
                imgName = filelist(ms).name;
                ff = [imgPath, imgName];
                info = imfinfo(ff);
                numSections = numel(info);
                sslice = numSections;
                cP.sselected = sslice;      % slices selected
                
                for iss = 1:sslice
                    img = imread([imgPath imgName],iss);
%                     figure(guiFig);
%                     img = imadjust(img);
%                     imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                    %                     imshow(img,'Parent',imgAx);
                    
                    cP.slice = iss;
                    disp('Analysis is ongoing ...')
                    cP.widcon = widcon;
                    [OUTf OUTctf] = ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP);
                    soutf(:,:,iss) = OUTf;
                    OUTctf(:,:,iss) = OUTctf;
                end
            end
        end
        disp('Analysis is done');
        
    else
        
        
    end
    
    
end




return
end
