%batch the curvelet process

clear all;
close all;
clc;

%function batch_curveAlignV2()
%topLevelDir = '.\';
topLevelDir = 'D:\bredfeldt\Trentham\';
outDir = 'D:\bredfeldt\Trentham\results\';
if ~exist(outDir,'dir')
    mkdir(outDir);
end  

%get directory list in top level dir
dateList = dir(topLevelDir);

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
                %if fileNum < 280
                %    continue;
                %end                
                disp(['computing curvelet transform']);
                if regexp(bdryName,'normal') > 0
                    imageName = [dateList(i).name ' Trentham ' fileList(j).name(14:length(fileList(j).name)-4) '.tif'];
                    idName = imageName(26:31);
                    leasionNum = imageName(34:35);
                    NorT = 'N';
                    img = imread([curDir '\' imageName]);
                    coords = csvread([curDir '\' bdryName]);
                    [histData,~,~,values,distances,~,map] = processImage(img, imageName, outDir, keep, coords, distThresh, makeAssoc,1,[]);
                    %normStruct(fileNum).bdryName = bdryName;
                    %normStruct(fileNum).imageName = imageName;
                    %normStruct(fileNum).angles = values;
                    %normStruct(fileNum).distances = distances;
                    %save([topLevelDir 'normCAV2_results.mat'],'normStruct');
                else
                    imageName = [dateList(i).name ' Trentham DCIS ' fileList(j).name(14:length(fileList(j).name)-4) '.tif'];
                    idName = imageName(24:29);
                    leasionNum = imageName(32:33);
                    NorT = 'T';
                    img = imread([curDir '\' imageName]);
                    coords = csvread([curDir '\' bdryName]);
                    [histData,~,~,values,distances,stats,map] = processImage(img, imageName, outDir, keep, coords, distThresh, makeAssoc,1,[]);
                    %dcisStruct(fileNum).bdryName = bdryName;
                    %dcisStruct(fileNum).imageName = imageName;
                    %dcisStruct(fileNum).angles = values;
                    %dcisStruct(fileNum).distances = distances;
                    %save([topLevelDir 'dcisCAV2_results.mat'],'dcisStruct');                    
                end
                writeAllHistData(histData,idName,leasionNum,NorT,outDir,fileNum,dateList(i).name,stats);
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