% post-process OUTPUT data on CHTC
addpath('./ctFIRE')
%% Put the CHTC output together 
clear,clc,home
OUT_folder = uigetdir('Output folder');
OUT_results = fullfile(OUT_folder,'results');
pathName = fullfile(OUT_results,'images');
if ~exist(OUT_results,'dir')
   mkdir(OUT_results); 
end

% untar the output tarfiles to the "results" folder
jarfilelist = dir(fullfile(OUT_folder,'OUT*.tar'));
for i = 1:length(jarfilelist)
  fprintf('%d: untar %s \n',i,jarfilelist(i).name);
  untar(fullfile(OUT_folder,jarfilelist(i).name), OUT_results);
end

imagelist = dir(fullfile(pathName,'*.tif'));
image_num = length(imagelist);
if isempty(image_num)
    disp('No image exists')
    return
end

doOverlay = questdlg('Do you wish to generate the overlay images?');

if strcmp(doOverlay, 'Yes')
 
    %% create CT-FIRE overlay images
    tstart = cputime;
    for i = 1:image_num
        try
            ctFIRE_cluster('CTFP_cluster_post.txt',imagelist(i).name);
            disp(i)
        catch EXP1
            fprintf('%s is skipped, error message:%s \n',imagelist(i).name, EXP1.message);
        end
    end
    fprintf('CT-FIRE post-processing takes %f minutes \n', (cputime-tstart)/60)
    
    %% create CA overlay image from the saved data
    tstart = cputime;
    fprintf('creating overlay and heatmap from parallel outputdata: \n')
    tempFolder2 = fullfile(pathName,'CA_Out','parallel_temp');
    if ~exist(tempFolder2,'dir')
        error('NO CA data exists for creating the heatmap and overlay image');
        %     mkdir(tempFolder2);
    end
    for i = 1: image_num
        fprintf('%d/%d: CA post-processing',i,image_num);
        try
            fileName = imagelist(i).name;
            [~,imgNameP,~ ] = fileparts(fileName);  % imgName: image name without extention
            numSections = 1; % Non-stack
            sliceNum = [];
            if numSections > 1
                saveOverData = sprintf('%s_s%d_overlayData.mat',imgNameP,sliceNum);
                saveMapData = sprintf('%s_s%d_procmapData.mat',imgNameP,sliceNum);
            else
                saveOverData = sprintf('%s_overlayData.mat',imgNameP);
                saveMapData = sprintf('%s_procmapData.mat',imgNameP);
            end
            draw_CAoverlay(tempFolder2,saveOverData);
            draw_CAmap(tempFolder2,saveMapData);
        catch EXP2
            fprintf('%s is skipped, error message:%s \n',imagelist(i).name, EXP2.message);
        end
    end
    tend = cputime;
    fprintf('CurveAlign post-processing takes %f minutes \n', (tend-tstart)/60)
    
    % create CA ROI overlay image
    tstart = cputime;
    fprintf('creating CA ROI overlay image from CHTC outputdata: \n')
    parfor i = 1: image_num
        fprintf('%d/%d: CA ROI post-processing',i,image_num);
        try
            CAroi_cluster('CAroiP_cluster_post.txt',imagelist(i).name);
        catch EXP3
            fprintf('%d-%s is skipped, error message:%s \n',i,imagelist(i).name, EXP3.message);
        end
    end
    tend = cputime;
    fprintf('CurveAlign ROI post-processing takes %f minutes \n', (tend-tstart)/60)
end

