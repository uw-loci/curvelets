%rearrange trentham files so I can use batch process

clear all;
close all;
clc;

%topLevelDir = '.\';
topLevelDir = 'C:\bredfeldt\Trentham\20130328\z = 1.5 images';
outDir = 'C:\bredfeldt\Trentham\20130328\z = 1.5 images\all_images\';
if ~exist(outDir,'dir')
    mkdir(outDir);
end  

%get directory list in top level dir
dateList = dir(topLevelDir);

%search the directory for boundary files
lenDateList = length(dateList);
%bdry_idx = zeros(1,lenFileList);
%img_idx = zeros(1,lenFileList);
% for i = 1:lenDateList
%     if isequal(regexp(dateList(i).name,'_'),[3 6]) && length(dateList(i).name) == 8
%         fileList = dir([topLevelDir dateList(i).name]);
%         lenFileList = length(fileList);
%         for j = 1:lenFileList
%             if ~isempty(regexp(fileList(j).name,'boundary for', 'once', 'ignorecase'))
%                 %found a boundary file
%                 
%                 %check if this is normal or DCIS                
%                 if ~isempty(regexp(fileList(j).name,'normal', 'once', 'ignorecase'))
%                     imFileName = [fileList(j).name(14:end-4) '.tif'];
%                 else
%                     imFileName = ['DCIS ' fileList(j).name(14:end-4) '.tif'];
%                 end
%                 %check if there is a corresponding image file
%                 imFndFlag = 0;
%                 for k = 1:lenFileList
%                     if ~isempty(regexp(fileList(k).name,imFileName,'once','ignorecase'))
%                         %copy boundary
%                         copyfile([topLevelDir dateList(i).name '\' fileList(j).name],outDir);
%                         %copy image
%                         copyfile([topLevelDir dateList(i).name '\' fileList(k).name],outDir);
%                         disp(['Found boundary: ' fileList(j).name]);
%                         disp(['Found image: ' fileList(k).name]);
%                         imFndFlag = 1;                        
%                         break;                                            
%                     end
%                 end                
%                 if imFndFlag == 0
%                     disp(['Found boundary: ' fileList(j).name ' but no image file!']);
%                 end
%             end                      
%         end
%     end
% end

%check to make sure there are no repeats
outFileList = dir(outDir);
for i = 1:length(outFileList)
    sameCnt = 0;
    for j = 3:length(outFileList)
        s1 = outFileList(i).name;
        s2 = outFileList(j).name;
        t1 = regexp(s1,s2,'once');
        if ~isempty(t1);
            sameCnt = sameCnt + 1;
        end
    end
    if sameCnt > 1
        disp('repeat!');
    else
        disp([int2str(i) ' good.']);
    end
end



