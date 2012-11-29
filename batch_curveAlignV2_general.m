%batch the curvelet process

clear all;
close all;
clc;

%function batch_curveAlignV2()
%topLevelDir = '.\';
%topLevelDir = 'C:\bredfeldt\Duke DCIS slides- raw images\';
%outDir = 'C:\bredfeldt\duke_results\';

%select an input folder
%input folder must have boundary files and images in it
[FileName,topLevelDir] = uigetfile('*.csv;*.tif;*.jpg','Select any file in the input directory: ');
if isequal(FileName,0)
    disp('Cancelled by user');
    return;
end

outDir = [topLevelDir 'CAV2_output\'];
if ~exist(outDir,'dir')
    mkdir(outDir);
end  

%get directory list in top level dir
fileList = dir(topLevelDir);
%search the directory for boundary files
lenFileList = length(fileList);
bdry_idx = zeros(1,lenFileList);
img_idx = zeros(1,lenFileList);
for i = 1:lenFileList
    if ~isempty(regexp(fileList(i).name,'boundary for', 'once', 'ignorecase'))
        bdry_idx(i) = 1;
    elseif ~isempty(regexp(fileList(i).name,'.tif','once','ignorecase')) || ~isempty(regexp(fileList(i).name,'.jpg','once','ignorecase'))
        img_idx(i) = 1;
    end
        
    
end

bdryTest = ~isempty(find(bdry_idx,1));
if bdryTest
    %if there are boundary files, then only process images with corresponding boundary files
    bdryFiles = fileList(bdry_idx==1);
    numFiles = length(bdryFiles);
    imgFiles(numFiles) = struct('name',[]);
    for i = 1:numFiles
        imgFiles(i).name = bdryFiles(i).name(14:length(bdryFiles(i).name)-4);
    end        
else
    %if there are no boundary files, process all image files
    %find the images in the non boundary files
    imgFiles = fileList(img_idx==1);
    numFiles = length(imgFiles);    
end

if numFiles == 0
    errordlg('Direcory does not contain valid images or boundaries.');
    disp('No valid images or boundaries.');
    return;
end

prompt = {'Enter keep value:','Enter distance thresh (pixels):','Boundary associations? (0 or 1):','Num to process (for demo purposes):'};
dlg_title = 'Input for batch CA';
num_lines = 1;
def = {'0.05','137','0',num2str(numFiles)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
    disp('Cancelled by user');
    return;
end
keep = str2num(answer{1});
distThresh = str2num(answer{2}); %pixels
makeAssoc = str2num(answer{3});
numToProc = str2num(answer{4});
disp(['Will process ' num2str(numToProc) ' images.']);
fileNum = 0;

for j = 1:numToProc
    fileNum = fileNum + 1;
    disp(['file number = ' num2str(fileNum)]);
    coords = []; %start with coords empty
    if bdryTest
        bdryName = bdryFiles(j).name;
        coords = csvread([topLevelDir bdryName]);
        disp(['boundary name = ' bdryName]);                    
    end
    disp('computing curvelet transform');
    imageName = imgFiles(j).name;
    %check if filename is annotated with normal or control
    if ~isempty(regexp(imageName,'control','once','ignorecase')) || ~isempty(regexp(imageName,'normal','once','ignorecase'))
        NorT = 'N';            
    else
        NorT = 'T';            
    end
    
    ff = [topLevelDir imageName];               
    info = imfinfo(ff);
    numSections = numel(info);
    for i = 1:numSections                                             
        img = imread(ff,i,'Info',info);    
        [histData,~,~,values,distances,stats,map] = processImage(img, imageName, outDir, keep, coords, distThresh, makeAssoc, i, 0);
        writeAllHistData2(histData, NorT, outDir, fileNum, stats, imageName, i);
    end
    disp(['done processing ' imageName]);    
end        

disp(['processed ' num2str(fileNum) ' images.']);

%end