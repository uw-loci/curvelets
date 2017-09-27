function LOCIca_cluster(jobtarfile,imageextension,mode)

% LOCI collagen analysis on Cluster
% Integrate CT-FIRE, CurveAlign, CurveAlign ROI analysis into one function
% for CHTC fiber analysis
% Input: 
%Fixed input file name
% % ctfpfile: txt file of CT-FIRE parameters
% % capfile: txt file of CurveAlign parameters
% % caroipfile: txt file of CurveAlign ROI analysis parameters

% : tar file include the images and other related files, such as
% ROI file
% imageextension: '.tif','.tiff', etc
% mode: 0: default, sequentially CTF-CA-CAroi analysis; 1: CT-FIRE; 2:CurveAlign;3:CAroi
% Output
%  saved as tar file contains all the output in the subfolders of 'ctFIREout','CAout','CA_Roi'
% CHTC server will return this tar file
% tar file for each job

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

imagePath = fullfile('./','images')
% Clear up the content in the 'images' folder
if exist(imagePath,'dir')
   rmdir(imagePath,'s');
end
if ~exist(imagePath,'dir')
    mkdir(imagePath);
end

untar(jobtarfile,imagePath);
imagelist = dir(fullfile('./images',['*' imageextension]))
logfile = fullfile('./images',sprintf('%s_log.txt',jobtarfile));
fid = fopen(logfile,'w');
if isempty(imagelist)
    log_message = sprintf('No image presents in the specified tar file %s, program quits here',jobtarfile);  
    fprintf(fid,'%s,%s',datestr(datetime('now')),log_message);
    fclose all;
    return
else
imgNum = length(imagelist);
log_message = sprintf('The number of image files in %s is %d',jobtarfile,imgNum);
fprintf(fid,'%s,%s',datestr(datetime('now')),log_message);
    
end
%name of the parameters
ctfpfile = 'CTFP_cluster.txt';
capfile = 'CAP_cluster.txt';
caroipfile = 'CAroiP_cluster.txt';
fprintf('CT-FIRE parameters file: %s \n',ctfpfile);
fprintf('CurveAlign parameters file: %s \n',capfile);
fprintf('CurveAlign ROI analysis parameters file: %s \n',caroipfile);
fprintf('JOB tar file: %s \n',jobtarfile);
starttime = cputime;
for i = 1:imgNum
    imageName = imagelist(i).name;
    try
        %run CT-FIRE
        tic
        ctFIRE_cluster(ctfpfile,imageName);
        CTF_toc = toc;
        fprintf(fid,'%s,%d/%d-1: CT-FIRE analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CTF_toc);
        %run CurveAlign
        tic
        CurveAlign_cluster(capfile,imageName);
        CA_toc = toc;
        fprintf(fid,'%s,%d/%d-2: CurveAlign analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CA_toc);
        %run CurveAlign ROI analysis
        tic
        CAroi_cluster(caroipfile,imageName);
        CAroi_toc = toc;
        fprintf(fid,'%s,%d/%d-3: CurveAlign ROI analysis on %s is done,taking %4.3f seconds \n',datestr(datetime('now')),i,imgNum,imageName,CAroi_toc);
    catch EXP1
        fprintf(fid,'%s, %s is skipped, error message: %s \n', datestr(datetime('now')),imageName,EXP1.message);
    end
end
endtime = cputime;
fprintf(fid,'%s,Done! Total running time for %s is %4.1f seconds \n',datestr(datetime('now')),jobtarfile,endtime-starttime);
fclose all; % close all files
close all; % close all visible or invisible figures
tar(sprintf('OUTPUT_%s',jobtarfile),'./images/');
rmdir(imagePath,'s');
