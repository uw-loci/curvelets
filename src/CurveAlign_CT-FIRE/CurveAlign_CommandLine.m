function CurveAlign_CommandLine(imageFolder,imageExtension,analysisMode,imageIndex)

% 2021.05-modified from the LOCIca_cluster.m
% ----
% 2019.07-Developed LOCIca_cluster.m for LOCI collagen analysis on Cluster
% Integrate CT-FIRE, CurveAlign, CurveAlign ROI analysis into one function
% for CHTC fiber analysis

% Input:
%     imageFolder: folder containing the images to be analysised as well as the parameters files 
%     imageExtension: image format,e.g. '.tif','.jepg' 
%     analysisMode: 0: sequentially CTF-CA-CAroi analysis; 1: CT-FIRE; 2(default):CurveAlign;3:CAroi
%     imageIndex: index range of the selected image,e.g., '1:2', '1,3',
%     'all'(default)
% Depending on the analysis mode, one or more of the following parameter files 
% should be prepared and put into the imageFolder before running the analysis: 
    % ctfpfile = 'CTFP_cluster.txt'; % txt file of CT-FIRE parameters
    % capfile = 'CAP_cluster.txt'; % txt file of CurveAlign parameters
    % caroipfile = 'CAroiP_cluster.txt'; % txt file of CurveAlign ROI analysis parameters
% template to prepare the three txt files is : template_CAparameters.xlsx 


if ~isdeployed
    addpath('./CircStat2012a','../../CurveLab-2.1.2/fdct_wrapping_matlab');
    addpath('./ctFIRE','./20130227_xlwrite','./xlscol/')
    addpath(genpath(fullfile('./FIRE')));
%     display('Please make sure you have downloaded the Curvelets library from http://curvelet.org')
    %add Matlab Java path
    javaaddpath('./20130227_xlwrite/poi_library/poi-3.8-20120326.jar');
    javaaddpath('./20130227_xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
    javaaddpath('./20130227_xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
    javaaddpath('./20130227_xlwrite/poi_library/xmlbeans-2.3.0.jar');
    javaaddpath('./20130227_xlwrite/poi_library/dom4j-1.6.1.jar');
    javaaddpath('./20130227_xlwrite/poi_library/stax-api-1.0.1.jar');
end

imagePath = imageFolder;
% Clear up the content in the 'images' folder
% if exist(imagePath,'dir')
%    rmdir(imagePath,'s');
% end
% if ~exist(imagePath,'dir')
%     mkdir(imagePath);
% end
if nargin== 1
    imageExtension = '.tif';
    analysisMode = '2';
    imageIndex = 'all';
elseif nargin == 2
    analysisMode = '2';
    imageIndex = 'all';
elseif nargin == 3
    imageIndex = 'all';
elseif nargin < 1
    error_message= 'Not enough input arguments';
    fid = fopen( fullfile(imagePath,'error.txt'),'w');
    fprintf(fid,'%s,%s',datestr(datetime('now')),error_message);
    fclose all;
    return
elseif nargin > 4
    error_message= 'Too many input arguments';
    fid = fopen( fullfile(imagePath,'error.txt'),'w');
    fprintf(fid,'%s,%s',datestr(datetime('now')),error_message);
    fclose all;
    return
end

imagelist = dir(fullfile(imagePath,['*' imageExtension]));
[~,dirName] = fileparts(imagePath);
logfile = fullfile(imagePath,sprintf('%s_log.txt',dirName));
fid = fopen(logfile,'w');
if isempty(imagelist)
    log_message = sprintf('No image presents in the specified image folder %s, program quits here',imagePath);
    fprintf(fid,'%s,%s',datestr(datetime('now')),log_message);
    fclose all;
    return
else
    imgNum = length(imagelist);
    log_message = sprintf('The number of image files in %s is %d \n',imagePath,imgNum);
    fprintf('Image list: \n');
    for i = 1:imgNum
        fprintf('%d-%s \n',i,imagelist(i).name);
    end
%     fprintf(fid,'%s,%s',datestr(datetime('now')),log_message);
end

if strcmp(imageIndex,'all')
    fprintf('All %d image(s) within %s will be processed. \n', imgNum,imagePath);
    imageSelected = 1:imgNum;  % index of selected images
else
    imageSelected = str2num(imageIndex);% index of selected images
    fprintf('Selected %d of %d image(s) for the analysis. \n',length(imageSelected),imgNum);
    fprintf('List of selected image(s): \n');
    for i = imageSelected
        fprintf('%d-%s \n',i,imagelist(i).name);
    end
end
pause(2);
%name of the parameters
ctfpfile = 'CTFP_cluster.txt';
capfile = 'CAP_cluster.txt';
caroipfile = 'CAroiP_cluster.txt';
fprintf('CT-FIRE parameters file: %s \n',ctfpfile);
fprintf('CurveAlign parameters file: %s \n',capfile);
fprintf('CurveAlign ROI analysis parameters file: %s \n',caroipfile);
fprintf('Image directory: %s \n',imagePath);
starttime = cputime;
switch str2num(analysisMode)
    case 0     %CT-FIRE, CurveAlign, CA ROI
        for i = imageSelected
            imageName = imagelist(i).name;
            try
                %run CT-FIRE
                tic
                ctFIRE_cluster(ctfpfile,imageName,imagePath);
                CTF_toc = toc;
                fprintf(fid,'%s,%d/%d-1: CT-FIRE analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CTF_toc);
                %run CurveAlign
                tic
                CurveAlign_cluster(capfile,imageName,imagePath);
                CA_toc = toc;
                fprintf(fid,'%s,%d/%d-2: CurveAlign analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CA_toc);
                %run CurveAlign ROI analysis
                tic
                CAroi_cluster(caroipfile,imageName,imagePath);
                CAroi_toc = toc;
                fprintf(fid,'%s,%d/%d-3: CurveAlign ROI analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CAroi_toc);
            catch EXP1
                fprintf(fid,'%s, %s is skipped, error message: %s \n', datestr(datetime('now')),imageName,EXP1.message);
            end
            
        end
        
    case 1  % CT-FIRE
        for i = imageSelected
            imageName = imagelist(i).name;
            try
                %run CT-FIRE
                tic
                ctFIRE_cluster(ctfpfile,imageName,imagePath);
                CTF_toc = toc;
                fprintf(fid,'%s,%d/%d-1: CT-FIRE analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CTF_toc);
                %run CurveAlign
            catch EXP1
                fprintf(fid,'%s, %s is skipped, error message: %s \n', datestr(datetime('now')),imageName,EXP1.message);
            end
            
        end
    case 2  % CurveAlign
        for i = imageSelected
            imageName = imagelist(i).name;
            try
                %run CurveAlign
                tic
                CurveAlign_cluster(capfile,imageName,imagePath);
                CA_toc = toc;
                fprintf(fid,'%s,%d/%d-2: CurveAlign analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CA_toc);
            catch EXP1
                fprintf(fid,'%s, %s is skipped, error message: %s \n', datestr(datetime('now')),imageName,EXP1.message);
            end
        end
    case 3  % CurveAlign ROI analysis
        for i = imageSelected
            imageName = imagelist(i).name;
            try
                %run CurveAlign ROI analysis
                tic
                CAroi_cluster(caroipfile,imageName,imagePath);
                CAroi_toc = toc;
                fprintf(fid,'%s,%d/%d-3: CurveAlign ROI analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CAroi_toc);
            catch EXP1
                fprintf(fid,'%s, %s is skipped, error message: %s \n', datestr(datetime('now')),imageName,EXP1.message);
            end
        end
end
endtime = cputime;
fprintf(fid,'%s,Done! Total running time for process the images in %s is %4.1f seconds \n',datestr(datetime('now')),imagePath,endtime-starttime);
fclose all; % close all files
close all; % close all visible or invisible figures
% rmdir(imagePath,'s');
