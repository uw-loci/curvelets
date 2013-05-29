%batch the curvelet process

clear all;
close all;
clc;

%function batch_curveAlignV2()
%topLevelDir = '.\';
topLevelDir = 'C:\bredfeldt\Duke DCIS slides- raw images\';
outDir = 'C:\bredfeldt\duke_results\';

%select an input folder
%input folder must have boundary files and images in it
%topLevelDir = uigetdir(' ','Select Input Directory: ');
%outDir = [topLevelDir '\CAV2_output\'];

if ~exist(outDir,'dir')
    mkdir(outDir);
end  

%get directory list in top level dir
dateList = dir(topLevelDir);
%search the directory for boundary files

%if there are boundary files, process corresponding images

%if there are no boundary files, process all images

prompt = {'Enter keep value:','Enter distance thresh (pixels):','Boundary associations? (0 or 1):','Num to process (for demo purposes):'};
dlg_title = 'Input for batch CA';
num_lines = 1;
def = {'0.05','137','0','1e7'};
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
NorT = 'T'; %normal or tumor
for i = 1:length(dateList)
%for i = 1:1
    if isequal(regexp(dateList(i).name,'_'),[3 6]) && length(dateList(i).name) == 8
        %if the 3rd and 6th chars are underscores, trust this as a real directory
        curDir = [topLevelDir dateList(i).name];                      
        
        fileList = dir(curDir);
        for j = 1:length(fileList)        
            if regexp(fileList(j).name,'Boundary for') > 0
                fileNum = fileNum + 1;
                bdryName = fileList(j).name;
                disp(['file number = ' num2str(fileNum)]);
                disp(['boundary name = ' bdryName]);
                if fileNum < 7
                    continue;
                end                
                disp(['computing curvelet transform']);
                imageName = [dateList(i).name ' ' fileList(j).name(14:length(fileList(j).name)-4) '.tif'];
                idName = imageName(15:18);
                
                if regexp(imageName,'control') > 0
                    NorT = 'N';
                    leasionNum = imageName(29:30);
                else
                    NorT = 'T';
                    leasionNum = imageName(21:22);
                end
                img = imread([curDir '\' imageName]);
                coords = csvread([curDir '\' bdryName]);
                [histData,~,~,values,distances,~,map] = processImage(img, imageName, outDir, keep, coords, distThresh, makeAssoc);
                writeAllHistData(histData,idName, leasionNum, NorT, outDir, fileNum);
                disp(['done processing ' imageName]);
                if fileNum == numToProc
                    break;
                end
            end
        end        
    end
end
disp(['processed ' num2str(fileNum) ' images.']);

%end