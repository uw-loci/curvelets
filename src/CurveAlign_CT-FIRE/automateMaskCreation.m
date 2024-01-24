function automateMaskCreation(maskInfo)
    imageName = maskInfo.imageName;
    imageDir = maskInfo.imageFolder;
    try
        ROImanDir = fullfile(imageDir,'ROI_management');
        mask_DIR = fullfile(ROImanDir,'ROI_mask');
        if ~exist(mask_DIR,'dir')
            mkdir(mask_DIR);
        end
        IMG = imread(fullfile(imageDir,imageName));
        %Get ROInames from the corresponding ROI mat file
        [~,IMGname,~] = fileparts(imageName);
        roiMATnamefull = [IMGname,'_ROIs.mat'];
        load(fullfile(imageDir,'ROI_management',roiMATnamefull),'separate_rois')
        ROInames = fieldnames(separate_rois);
        num_rois = size(ROInames,1);
        for i = 1:num_rois
            [~,filenameNE,fileEXT] = fileparts(imageName);
            mask_savename = ['mask for ' filenameNE '_' (ROInames{i}) fileEXT '.tif'];
            BD_temp = separate_rois.(ROInames{i}).boundary;
            boundary = BD_temp{1};
            BW = roipoly(IMG,boundary(:,2),boundary(:,1));
            imwrite(BW,fullfile(mask_DIR,mask_savename),'Compression','none');
            fprintf('Mask file %s created \n', mask_savename)
        end
        
    catch  ME
        fprintf('Mask creation for %s failed, error message: %s \n', imageName, ME.message)
        
    end
    

    