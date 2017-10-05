function CAroi_cluster(CAroiPfile,ImageName)
%YL 2017/9: develop a version of CAroi running on cluster
%YL 2017/09/11: add ROI POST analysis for CT-FIRE-based CA analysis

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

%parameters list

% pathName = ImagePath;   %image directory
% ROImanDir = fullfile(pathName,'ROI_management');
% ROIanaBatOutDir = fullfile('./','CA_ROI','Batch','ROI_analysis','CA_Out');
% ROIimgDir = fullfile(pathName,'CA_ROI','Batch','ROI_analysis');
% ROIanaBatOutDir = fullfile(ROIimgDir,'CA_Out');
% ROImanDir = fullfile(pathName,'ROI_management');
% ROIanaDir = fullfile(pathName,'CA_ROI','Batch');
% ROIDir = fullfile(pathName,'CA_ROI');
% BoundaryDir = fullfile(pathName,'CA_Boundary');
% % folders for CA post ROI analysis of multiple(Batch-mode) images
% ROIpostBatDir = fullfile(pathName,'CA_ROI','Batch','ROI_post_analysis');
% fileName = ImageName;   %full image name with fomrat extension
% 
% stack_flag = 0; %1: stack; 0: non-stack
% fibMode = 1; % dropdown menu: 0: CT; 1:CT-FIRE Segments;2: CT-FIRE fibers;3:'CT-FIRE Endpoints'
% bndryMode = 0; % dropdown menu: 0:No Boundary; 1: Draw Boundary; 2: CSV Boundary; 3: Tiff Boundary
% postFLAG = 1;
% cropIMGon = 0;
% plotrgbFLAG = 0;    % 0: donot display RGB image; 1: display RGB image
% prlflag = 2;   % 0: no parallel; 1: multicpu version; 2: cluster version

k = 0;
fid = fopen(fullfile('./',CAroiPfile));
fprintf('%s \n',fgetl(fid))
pathName = fgetl(fid);
fprintf('  %s \n',pathName)
ROImanDir = fullfile(pathName,'ROI_management');
ROIanaBatOutDir = fullfile('./','CA_ROI','Batch','ROI_analysis','CA_Out');
ROIimgDir = fullfile(pathName,'CA_ROI','Batch','ROI_analysis');
ROIanaBatOutDir = fullfile(ROIimgDir,'CA_Out');
ROImanDir = fullfile(pathName,'ROI_management');
ROIanaDir = fullfile(pathName,'CA_ROI','Batch');
ROIDir = fullfile(pathName,'CA_ROI');
BoundaryDir = fullfile(pathName,'CA_Boundary');
% folders for CA post ROI analysis of multiple(Batch-mode) images
ROIpostBatDir = fullfile(pathName,'CA_ROI','Batch','ROI_post_analysis');

fprintf('%s \n',fgetl(fid))
fileName = fgetl(fid);
fileName = ImageName;
fprintf('  %s \n',fileName)

fprintf('%s \n',fgetl(fid))
stack_flag = str2num(fgetl(fid));
fprintf('  %d \n',stack_flag);

fprintf('%s \n',fgetl(fid))
fibMode = str2num(fgetl(fid));
fprintf('  %d \n',fibMode);

fprintf('%s \n',fgetl(fid))
bndryMode = str2num(fgetl(fid));
fprintf('  %d \n',bndryMode);

fprintf('%s \n',fgetl(fid))
postFLAG = str2num(fgetl(fid));
fprintf('  %d \n',postFLAG);

fprintf('%s \n',fgetl(fid))
cropIMGon = str2num(fgetl(fid));
fprintf('  %d \n',cropIMGon);

fprintf('%s \n',fgetl(fid))
plotrgbFLAG = str2num(fgetl(fid));
fprintf('  %d \n',plotrgbFLAG);

fprintf('%s \n',fgetl(fid))
prlflag = str2num(fgetl(fid));
fprintf('  %d \n',prlflag);

fprintf('%s \n',fgetl(fid))
plotflag = str2num(fgetl(fid));
fprintf('  %d \n',plotflag);

fprintf('%s \n',fgetl(fid))
CAroi_postflag = str2num(fgetl(fid));
fprintf('  %d \n',CAroi_postflag);

%%
[~,fileNameNE,fileEXT] = fileparts(fileName) ;
error_file = fullfile('./images', [fileNameNE '_CAroi_error.txt']);
if ~exist('./images','dir')
    mkdir('./images')
end
%delete the error file 
if exist(error_file,'file')
    delete(error_file)
end

if stack_flag == 0
    filename_temp = ImageName;
    matfilename = [fileNameNE '_fibFeatures'  '.mat'];
    CAfndflag = 1; %List of the files flagged as blank
    if exist(fullfile(pathName,'CA_Out',matfilename),'file')
        matdata_CApost = load(fullfile(pathName,'CA_Out',matfilename),'tifBoundary','fibProcMeth');
        if matdata_CApost.fibProcMeth ~=  fibMode || matdata_CApost.tifBoundary ~=  bndryMode;
            disp(sprintf('%s has NOT been analyzed with the specified fiber mode or boundary mode.',fileNameNE))
            CAfndflag = 0;
        end
        
    else
        CAfndflag = 0;
        disp(sprintf(' %s does NOT exist \n',fullfile(pathName,'CA_Out',matfilename)))
    end
elseif stack_flag == 1
    error_message = 'CurveAlign ROI analysis on Cluster doesnot support stack analysis';
    fid = fopen(error_file,'w');
    fprintf(fid,'%s\n',error_message);
    fclose(fid);
    return
end
% quit if CA results donot exist
CAmissing_ind = find(CAfndflag == 0);
CAmissing_num = length(CAmissing_ind);
if CAmissing_num > 0
    note_temp1 = 'Does NOT have  previous full-size image analysis with the specified fiber and boundary mode';
    note_temp2 = 'Prepare the full-size results before ROI post-processing';
    error_message = sprintf(' %s. \n %s',note_temp1,note_temp2);
    disp(error_message)
    fid = fopen(error_file,'w');
    fprintf(fid,'%s\n',error_message);
    fclose(fid);
    return
else
    % load running parameters from the saved file
    matdata_CApost = load(fullfile(pathName,'CA_Out',matfilename),'fibFeat','tifBoundary','fibProcMeth','distThresh','coords');
    fibFeat_load = matdata_CApost.fibFeat;
    distThresh = matdata_CApost.distThresh;
    tifBoundary = matdata_CApost.tifBoundary;  % 1,2,3: with boundary; 0: no boundary
    if tifBoundary ~= bndryMode
        error_message = 'CA full image analysis uses different boundary mode compared to the specified one here';
        disp(error_message)
        fid = fopen(error_file,'w');
        fprintf(fid,'%s\n',error_message);
        fclose(fid);
        return
        %     else
        %        bndryMode = tifBoundary;
    end
    fibProcMeth = matdata_CApost.fibProcMeth; % 0: curvelets; 1,2,3: CTF fibers
    if fibProcMeth ~= fibMode
        error_message = 'CA full image analysis uses different fiber analysis mode compared to the specified one here';
        disp(error_message)
        fid = fopen(error_file,'w');
        fprintf(fid,'%s\n',error_message);
        fclose(fid);
        return
        %     else
        %         fibMode = fibProcMeth;
    end
    coords = matdata_CApost.coords;
    if cropIMGon == 0;
        cropFLAG = 'NO';
    end
    % analysis based on orignal full image analysis
    if fibMode == 0 % "curvelets"
        modeID = 'Curvelets';
    else %"CTF fibers" 1,2,3
        modeID = 'CTF Fibers';
    end
    if bndryMode == 0
        bndryID = 'NO';
    elseif bndryMode == 2 || bndryMode == 3
        bndryID = 'YES';
    end
    postFLAGt = 'YES';
end

%Get the boundary data
bdryImg = [];  %%   bdryImg = the actual boundary image, this is only used for output overlay images
if bndryMode == 3
    bff = fullfile(BoundaryDir,sprintf('mask for %s.tif',imgNamefull));
    bdryImg = imread(bff);
end

% check ROI file
ROIfndflag = nan(1,1); %1: Image has ROI,default; 0: Image doesnot have ROI
roiMATnamefull = [fileNameNE,'_ROIs.mat'];
if exist(fullfile(ROImanDir,roiMATnamefull),'file')
    disp(sprintf('Found ROI for %s',fileName))
    ROIfndflag = 1;
    load(fullfile(ROImanDir,roiMATnamefull),'separate_rois')
else
    disp(sprintf('ROI for %s not exist',fileName));
    ROIfndflag = 0;
end

ROImissing_ind = find(ROIfndflag == 0);
ROImissing_num = length(ROImissing_ind);
if ROImissing_num > 0
    if ROImissing_num == 1
        fprintf('%d image doesnot have corresponding ROI files \n',ROImissing_num);
    end
    fileName = [];
    error_message = ('Image ROI analysis is skipped for the POST ROI analysis due to lack of corresponding ROI file');
    disp(error_message);
    fid = fopen(error_file,'w');
    fprintf(fid,'%s\n',error_message);
    fclose(fid);
    return

end


if postFLAG == 0
    error_message = 'CurveAlign direct ROI analysis running on cluster is under development.'
    disp(error_message);
    fid = fopen(error_file,'w');
    fprintf(fid,'%s\n',error_message);
    fclose(fid);
    return
elseif  postFLAG == 1 % % post-processing of the CA features
    if(exist(ROIpostBatDir,'dir')==0)%check for ROI folder
        mkdir(ROIpostBatDir);
    end
    matfilename = [fileNameNE '_fibFeatures'  '.mat'];
    %     IMG = imread(IMGname);
    IMGctf = fullfile(pathName,'ctFIREout',['OL_ctFIRE_',fileNameNE,'.tif']);  % CT-FIRE overlay
    if(exist(fullfile(pathName,'CA_Out',matfilename),'file')~=0)%~=0 instead of ==1 because returned value equals to 2
        
        try
            overIMG_name = fullfile(pathName,'CA_Out',[fileNameNE,'_overlay.tiff']);
            OLexistflag = 1;
        catch
            OLexistflag = 0;
            if exist(IMGctf,'file')
                disp(sprintf('%s does not exist \n Use the CT-FIRE overlay image instead',fullfile(pathName,'CA_Out',[fileNameNE,'_overlay.tiff'])))
                overIMG_name = IMGctf;
            else
                disp(sprintf('%s does not exist \n Use the original image instead',fullfile(pathName,'CA_Out',[fileNameNE,'_overlay.tiff'])))
                overIMG_name = fullfile(pathName,fileName{k});
            end
        end
    else
        error_message = sprintf('CurveAlign feature file %s does not exist.', fullfile(pathName,'CA_Out',matfilename));
        disp(error_message)
        fid = fopen(error_file,'w');
        fprintf(fid,'%s\n',error_message);
        fclose(fid);
        return
    end
end

controlP.cropIMGon = cropIMGon;
controlP.postFLAG = postFLAG;
controlP.bndryMode = bndryMode;
controlP.fibMode = fibMode;
controlP.file_number_current = 1;
controlP.plotrgbFLAG = plotrgbFLAG;
controlP.ROIpostBatDir = ROIpostBatDir;
controlP.ROIimgDir = ROIimgDir;
controlP.prlflag = prlflag;
controlP.plotflag = plotflag;
controlP.CAroi_postflag = CAroi_postflag;
ROIanalysisPAR_all.imgName = fileName;
ROIanalysisPAR_all.imgPath = pathName;
ROIanalysisPAR_all.coords = coords;
ROIanalysisPAR_all.bdryImg = bdryImg;
ROIanalysisPAR_all.numSections = 1;
ROIanalysisPAR_all.sliceIND = [];
ROIanalysisPAR_all.separate_rois = separate_rois;
ROIanalysisPAR_all.controlP = controlP;

CA_ROIanalysis_p(ROIanalysisPAR_all)

end


