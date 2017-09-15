function CurveAlign_cluster(CAPfile, imageName)

% YL08312017: CurveAlign feature extraction using computer clusters. Based on function
% goCAK(CAPfile) and function [fibFeat] = processImage_p(pathName, imgNamefull, tempFolder, ...
% keep, distThresh, makeAssoc, makeMap, makeOver, makeFeat, sliceNum, bndryMode, BoundaryDir, ...
% fibProcMeth, advancedOPT,numSections)

%tempFolder = uigetdir(pathNameGlobal,'Select Output Directory:');
%compile: mcc -m CurveAlignFE_cluster.m
% compile: mcc -m CurveAlignFE_cluster.m -a ./CurveLab-2.1.2/fdct_wrapping_matlab -a ./CircStat2012a  -R '-startmsg,"Starting gocak Windows 64-bit ..."'

if ~isdeployed
    addpath('./CircStat2012a','../../CurveLab-2.1.2/fdct_wrapping_matlab');
    addpath('./ctFIRE','./20130227_xlwrite','./xlscol/')
    addpath(genpath(fullfile('./FIRE')));
    display('Please make sure you have downloaded the Curvelets library from http://curvelet.org')
    %add Matlab Java path
    javaaddpath('./20130227_xlwrite/poi_library/poi-3.8-20120326.jar');
    javaaddpath('./20130227_xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
    javaaddpath('./20130227_xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
    javaaddpath('./20130227_xlwrite/poi_library/xmlbeans-2.3.0.jar');
    javaaddpath('./20130227_xlwrite/poi_library/dom4j-1.6.1.jar');
    javaaddpath('./20130227_xlwrite/poi_library/stax-api-1.0.1.jar');
end

advancedOPT = struct('exclude_fibers_inmaskFLAG',1, 'curvelets_group_radius',10,...
    'seleted_scale',1,'heatmap_STDfilter_size',28,'heatmap_SQUAREmaxfilter_size',12,...
    'heatmap_GAUSSIANdiscfilter_sigma',4, 'plotrgbFLAG',0,'folderROIman','\\image path\ROI_management\',...
    'folderROIana','\\image path\ROI_management\Cropped\','uniROIname','',...
    'cropROI',0,'specifyROIsize',[256 256],'minimum_nearest_fibers',2,'minimum_box_size',32,'fiber_midpointEST',1);
%  %% save the parameters into a txt file
%     filename = fullfile(pathName,['CAPcluster_',fileName1,'.txt']);
%     fid = fopen(filename,'w');
%     % run parameters
%     fprintf(fid,'%s\n',pathName);
%     fprintf(fid,'%s\n' ,fileName);
%     fprintf(fid,'%5.4f\n',keep);
%     fprintf(fid,'%d\n',distThresh);
%     fprintf(fid,'%d\n',makeAssocFlag);
%     fprintf(fid,'%d\n',makeMapFlag);
%     fprintf(fid,'%d\n',makeOverFlag);
%     fprintf(fid,'%d\n',makeFeatFlag);
%     fprintf(fid,'%d\n',sliceIND);
%     fprintf(fid,'%d\n',bndryMode);
%     fprintf(fid,'%d\n',fibMode);
%     fprintf(fid,'%d\n',numSections);
%     fprintf(fid,'%d\n',exclude_fibers_inmaskFLAG);
%     fprintf(fid,'%d\n',plotrgbFLAG);
%     fprintf(fid,'%d\n', seleted_scale);
%     fprintf(fid,'%d\n',curvelets_group_radius);
%     fprintf(fid,'%d\n',minimum_nearest_fibers);
%     fprintf(fid,'%d\n', minimum_box_size);
%     fprintf(fid,'%d\n',fiber_midpointEST);
%     fclose(fid)
%
% CAPfile = 'CAPfile_1B_D3_SHG_ROI_TACS3positive.tif-1.tif.txt';
k = 0;
fid = fopen(CAPfile);
pathName = fgetl(fid); k = k+1;
% pathName = pwd;
fprintf('Line%2d, image diretory: %s \n',k, pathName);
outDir = fullfile(pathName, 'CA_Out');
BoundaryDir = fullfile(pathName,'CA_Boundary');
if ~exist(outDir,'dir')
    mkdir(outDir);
end
if ~exist(BoundaryDir,'dir')
    mkdir(BoundaryDir);
end
fileName = fgetl(fid); k = k + 1;   % string
fileName = imageName; %use the image from the input argument instead;
fprintf('Line%2d, image name: %s \n',k, fileName);
keep = str2num(fgetl(fid)); k = k + 1;
fprintf('Line%2d, fraction of curvelet transform coefficient to be kept= %5.4f \n',k, keep);
distThresh = str2num(fgetl(fid));k = k + 1;
fprintf('Line%2d, distance threshold = %d \n',k, distThresh);
makeAssocFlag = str2num(fgetl(fid)); k = k + 1;  % check box
fprintf('Line%2d, flag to display fiber-boundary association = %d \n',k, makeAssocFlag);
makeMapFlag = str2num(fgetl(fid));   k = k + 1;% check box
fprintf('Line%2d, flag to create heatmap = %d \n',k, makeMapFlag);
makeOverFlag = str2num(fgetl(fid));  k = k + 1; % check box
fprintf('Line%2d, flag to create overlay image = %d \n',k, makeOverFlag);
makeFeatFlag = str2num(fgetl(fid));  k = k + 1; % check box
fprintf('Line%2d, flag to output feature files = %d \n',k, makeFeatFlag);
sliceIND = str2num(fgetl(fid));k = k + 1;
fprintf('Line%2d, index of slice in stack = %d \n',k, sliceIND);
bndryMode = str2num(fgetl(fid)); k = k + 1;% dropdown menu
fprintf('Line%2d, boundary mode = %d, [0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary] \n',k, bndryMode);
fibMode = str2num(fgetl(fid));k = k + 1; % dropdown menu
fprintf('Line%2d, fiber analysis mode = %d, [0: CT; 1:CT-FIRE Segments;2: CT-FIRE fibers;3:CT-FIRE Endpoints]\n',k, fibMode);
numSections = str2num(fgetl(fid));  k = k + 1; %
fprintf('Line%2d, number of sections = %d [stack > 1, single image = 1]\n',k, numSections);
%advanced options
exclude_fibers_inmaskFLAG = str2num(fgetl(fid));  k = k + 1; % check box
fprintf('Line%2d, flag to exclude the fibers within a tiff boundary = %d \n',k, exclude_fibers_inmaskFLAG);
plotrgbFLAG = str2num(fgetl(fid));k = k + 1;
fprintf('Line%2d, flag to display RGB color = %d,[0: donot display; 1: display] \n',k, plotrgbFLAG);
seleted_scale = str2num(fgetl(fid)); k = k + 1;
fprintf('Line%2d, selected scale for curvelet transform analysis = %d, [1 : the second finest scale(default), 2: the third finest scale...] \n',k, seleted_scale);
curvelets_group_radius = str2num(fgetl(fid));k = k + 1; % dropdown menu
fprintf('Line%2d, radius to group curvelets = %d, \n',k, curvelets_group_radius);
minimum_nearest_fibers = str2num(fgetl(fid));  k = k + 1; %
fprintf('Line%2d,  minimum nearest fibers = %d, [should be set as 2^n, n>=1] \n',k, minimum_nearest_fibers);
minimum_box_size = str2num(fgetl(fid));  k = k + 1; % check box
fprintf('Line%2d, minimum box size = %d, [should be set as 2^n, n>=5] \n',k, minimum_box_size);
fiber_midpointEST = str2num(fgetl(fid));  k = k + 1; % check box
fprintf('Line%2d, fiber middle point estimation mode = %d, [1: based on endpoint coordinates; 2:  based on fiber length] \n',k,  fiber_midpointEST);
fclose(fid);
advancedOPT.exclude_fibers_inmaskFLAG = exclude_fibers_inmaskFLAG;
advancedOPT.plotrgbFLAG = plotrgbFLAG;
advancedOPT.seleted_scale = seleted_scale;
advancedOPT.curvelets_group_radius = curvelets_group_radius;
advancedOPT.minimum_nearest_fibers = minimum_nearest_fibers;
advancedOPT.minimum_box_size = minimum_box_size;
advancedOPT.fiber_midpointEST = fiber_midpointEST;

% if loading CT-FIRE data
if fibMode ~= 0
    ctfFnd = '';
    ctfFnd = checkCTFireFiles(pathName, {fileName});
    if (isempty(ctfFnd))
        disp('One or more CT-FIRE files are missing. ');
        return;
    end
end

if isempty(keep)
    %indicates the % of curvelets to process (after sorting by
    %coefficient value)
    keep = .001;
end

if isempty(distThresh)
    %this is default and is in pixels
    distThresh = 100;
end

if bndryMode == 2 || bndryMode == 3
    %check to make sure the proper boundary files exist
    bndryFnd = checkBndryFiles(bndryMode, pathName, fileName);
    if (~isempty(bndryFnd))
        disp('Found all boundary files')
    else
        disp('Boundary file is missing, program quitted')
        return;
    end
end
tic
fprintf('CurveAlign full image analysis on %s is ongoing \n',fileName) %
processImage_p(pathName, fileName, outDir, keep, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, sliceIND, bndryMode,BoundaryDir, fibMode, advancedOPT,numSections);
%% create the overlay image from the saved data
tempFolder2 = fullfile(pathName,'CA_Out','parallel_temp');
if ~exist(tempFolder2,'dir')
    mkdir(tempFolder2);
end
fprintf('creating overlay and heatmap from parallel outputdata: \n')
[~,imgNameP,~ ] = fileparts(fileName);  % imgName: image name without extention
sliceNum = sliceIND;
if numSections > 1
    saveOverData = sprintf('%s_s%d_overlayData.mat',imgNameP,sliceNum);
    saveMapData = sprintf('%s_s%d_procmapData.mat',imgNameP,sliceNum);
else
    saveOverData = sprintf('%s_overlayData.mat',imgNameP);
    saveMapData = sprintf('%s_procmapData.mat',imgNameP);
end
draw_CAoverlay(tempFolder2,saveOverData);
draw_CAmap(tempFolder2,saveMapData);
fprintf('Analysis is done. Took %4.1f seconds \n',toc) %
end