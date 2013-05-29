%rearrange trentham files so I can use batch process

clear all;
close all;
clc;

%topLevelDir = '.\';
topLevelDir = 'C:\bredfeldt\Trentham\20130328\';
outDir = 'C:\bredfeldt\Trentham\20130328\all_images\';
if ~exist(outDir,'dir')
    mkdir(outDir);
end  

%get directory list in top level dir
dateList = dir(topLevelDir);

%search the directory for boundary files
lenDateList = length(dateList);
%bdry_idx = zeros(1,lenFileList);
%img_idx = zeros(1,lenFileList);
for i = 1:lenDateList
    if isequal(regexp(dateList(i).name,'_'),[3 6]) && length(dateList(i).name) == 8
        fileList = dir([topLevelDir dateList(i).name]);
        lenFileList = length(fileList);
        for j = 1:lenFileList
            if ~isempty(regexp(fileList(j).name,'boundary for', 'once', 'ignorecase'))
                %found a boundary file
                imFileName = [fileList(j).name(14:end-4) '.tif'];
                %check if there is a corresponding image file
                for k = 1:lenFileList
                    if ~isempty(regexp(fileList(k).name,imFileName,'once','ignorecase'))
                        %copy boundary
                        copyfile([topLevelDir dateList(i).name '\' fileList(j).name],outDir);
                        %copy image
                        copyfile([topLevelDir dateList(i).name '\' fileList(k).name],outDir);
                        break;
                    end
                end                
            end  
            
            if ~isempty(regexp(fileList(j).name,'boundary for normal', 'once', 'ignorecase'))
                %found a boundary file
                imFileName = [fileList(j).name(21:end-4) '.tif'];
                %check if there is a corresponding image file
                for k = 1:lenFileList
                    if ~isempty(regexp(fileList(k).name,imFileName,'once','ignorecase'))
                        %copy boundary
                        copyfile([topLevelDir dateList(i).name '\' fileList(j).name],outDir);
                        %copy image
                        copyfile([topLevelDir dateList(i).name '\' fileList(k).name],outDir);
                        break;
                    end
                end                
            end
            
        end
    end
end

