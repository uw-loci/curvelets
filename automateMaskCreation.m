function automateMaskCreation(maskInfo)
    imageName = maskInfo.imageName;
    imageDir = maskInfo.imageFolder;
    ROInames =  maskInfo.roiName;
    ROImanDir = fullfile(imageDir,'ROI_management');
    mask_DIR = fullfile(ROImanDir,'ROI_mask');
    separate_rois = maskInfo.separate_rois;
    IMG = maskInfo.IMG;
    if ~exist(mask_DIR,'dir')
        mkdir(mask_DIR);
    end
    num_rois = size(ROInames,1);
    for i = 1:num_rois
        [~,filenameNE,fileEXT] = fileparts(imageName);
        mask_savename = ['mask for ' filenameNE '_' (ROInames{i}) fileEXT '.tif'];
        disp(mask_savename)
        BD_temp = separate_rois.(ROInames{i}).boundary;
        boundary = BD_temp{1};
        BW = roipoly(IMG,boundary(:,2),boundary(:,1));
        imwrite(BW,fullfile(mask_DIR,mask_savename),'Compression','none');
    end
    
     

    