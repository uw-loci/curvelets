function CA_ROIanalysis_p(ROIanalysisPAR)
% Parallel CurveAlign ROI analysis
% Input:
%     ROIanalysisPAR.imgName;   %
%     ROIanalysisPAR.imgPath;
%     ROIanalysisPAR.coords;
%     ROIanalysisPAR.bdryImg;
%     ROIanalysisPAR.numSections;
%     ROIanalysisPAR.sliceIND;
%     ROIanalysisPAR.imgPath;
%     ROIanalysisPAR.separate_rois;
%     ROIanalysisPAR.controlP
%         controlP.cropIMGon = cropIMGon;
%         controlP.postFLAG = postFLAG;
%         controlP.bndryMode = bndryMode;
%         controlP.fibMode = fibMode;
%         controlP.file_number_current = ks;
%         controlP.ROIimgDir
%         controlP.ROIpostBatDir
%         controlP.plotrgbFLAG
% Output:
%%
imgName = ROIanalysisPAR.imgName;
imgPath = ROIanalysisPAR.imgPath;
coords = ROIanalysisPAR.coords;
bdryImg = ROIanalysisPAR.bdryImg;
numSections = ROIanalysisPAR.numSections;
sliceIND = ROIanalysisPAR.sliceIND;
separate_rois= ROIanalysisPAR.separate_rois;
%control parameters
controlP = ROIanalysisPAR.controlP;
cropIMGon = controlP.cropIMGon;
postFLAG = controlP.postFLAG;
bndryMode = controlP.bndryMode;
fibMode = controlP.fibMode;
file_number_current = controlP.file_number_current;
ROIpostBatDir = controlP.ROIpostBatDir;
ROIimgDir = controlP.ROIimgDir;
plotrgbFLAG = controlP.plotrgbFLAG;

prlflag = 2;   % 0: no parallel; 1: multicpu version; 2: cluster version

% Load image
if numSections == 1
    IMG = imread(fullfile(imgPath,imgName));
elseif numSections > 1
    IMG = imread(fullfile(imgPath,imgName),sliceIND);
end
if size(IMG,3) > 1
    if advancedOPT.plotrgbFLAG == 0
        IMG = rgb2gray(IMG);
        disp('color image was loaded but converted to grayscale image')
        img = imadjust(IMG);  % YL: only show the adjusted image, but use the original image for analysis
    elseif advancedOPT.plotrgbFLAG == 1
        img = IMG;
        disp('display color image');
    end
end

[~, fileNameNE, ~] = fileparts(imgName);
matfilename = [fileNameNE '_fibFeatures'  '.mat'];
if postFLAG == 1
    IMGctf = fullfile(imgPath,'ctFIREout',['OL_ctFIRE_',fileNameNE,'.tif']);  % CT-FIRE overlay
    matdata_CApost = load(fullfile(imgPath,'CA_Out',matfilename),'fibFeat','tifBoundary','fibProcMeth','distThresh','coords');
    fibFeat_load = matdata_CApost.fibFeat;
    distThresh = matdata_CApost.distThresh;
    tifBoundary = matdata_CApost.tifBoundary;  % 1,2,3: with boundary; 0: no boundary
    % should load load running parameters from the saved file
    bndryMode = tifBoundary;
    coords = matdata_CApost.coords;
    fibProcMeth = matdata_CApost.fibProcMeth; % 0: curvelets; 1,2,3: CTF fibers
    fibMode = fibProcMeth;
    try
        overIMG_name = fullfile(imgPath,'CA_Out',[fileNameNE,'_overlay.tiff']);
        imgOL = imread(overIMG_name);
        OLexistflag = 1;
    catch
        if exist(IMGctf,'file')
            disp(sprintf('%s does not exist \n Use the CT-FIRE overlay image instead',fullfile(imgPath,'CA_Out',[fileNameNE,'_overlay.tiff'])))
            overIMG_name = IMGctf;
        else
            disp(sprintf('%s does not exist \n Use the original image instead',fullfile(imgPath,'CA_Out',[fileNameNE,'_overlay.tiff'])))
            overIMG_name = fullfile(imgPath,imgName);
        end
        imgOL = imread(overIMG_name);
        OLexistflag = 0;
    end
end

guiFig = figure('Visible','off'); 
imagesc(imgOL); hold on;
%
if cropIMGon == 1
    cropFLAG = 'YES';   % analysis based on cropped image
elseif cropIMGon == 0
    cropFLAG = 'NO';    % analysis based on orignal image with the region other than the ROI set to 0.
end
if postFLAG == 0
    postFLAGt = 'NO'; % Yes: use post-processing based on available results in the output folder
elseif postFLAG == 1
    postFLAGt = 'YES'; % Yes: use post-processing based on available results in the output folder
end
if fibMode == 0 % "curvelets"
    modeID = 'Curvelets';
else %"CTF fibers" 1,2,3
    modeID = 'CTF Fibers';
end
if bndryMode == 0
    bndryID = 'NO';
elseif bndryMode == 2 || bndryMode == 3
    bndryID = 'YES';
end

ROIshapes = {'Rectangle','Freehand','Ellipse','Polygon'};

BWcell = bdryImg;
ROInames = fieldnames(separate_rois);
s_roi_num = length(ROInames);


if numSections == 1
    fprintf('CA ROI analysis on %s, Number of ROI = %d, \n',imgName,s_roi_num);
elseif numSections > 1
    fprintf('CA ROI analysis on a slice(%d) of %s, Number of ROI in this slice = %d, \n',...
        sliceIND,imgName,s_roi_num);
end

CA_data_current = cell(s_roi_num+1,14);
columnname = {'No.','Image Label','ROI label','Orentation','Alignment','FeatNum','Methods','Boundary','CROP','POST','Shape','Xc','Yc','Z'};
CA_data_current(1,:) = columnname;

%loop through all the ROIs
for k=1:s_roi_num
    
    ROIshape_ind = separate_rois.(ROInames{k}).shape;
    if cropIMGon == 0     % use ROI mask
        if   ~iscell(separate_rois.(ROInames{k}).shape)
            ROIshape_ind = separate_rois.(ROInames{k}).shape;
            BD_temp = separate_rois.(ROInames{k}).boundary;
            boundary = BD_temp{1};
            BW = roipoly(IMG,boundary(:,2),boundary(:,1));
            yc = separate_rois.(ROInames{k}).xm;
            xc = separate_rois.(ROInames{k}).ym;
            z = sliceIND;
        elseif iscell(separate_rois.(ROInames{k}).shape)
            ROIshape_ind = nan;
            s_subcomps=size(separate_rois.(ROInames{k}).shape,2);
            s1=size(IMG,1);s2=size(IMG,2);
            BW(1:s1,1:s2)=logical(0);
            for m=1:s_subcomps
                boundary = cell2mat(separate_rois.(ROInames{k}).boundary{m});
                BW2 = roipoly(IMG,boundary(:,2),boundary(:,1));
                BW=BW|BW2;
            end
            xc = nan; yc = nan; z = sliceIND;
        end
        ROIimg = IMG.*uint8(BW);
    elseif cropIMGon == 1
        if ROIshape_ind == 1   % use cropped ROI image
            ROIcoords=separate_rois.(ROInames{k}).roi;
            a=round(ROIcoords(1));b=round(ROIcoords(2));c=round(ROIcoords(3));d=round(ROIcoords(4));
            ROIimg = IMG(b:b+d-1,a:a+c-1); % YL to be confirmed
            % add boundary conditions
            if ~isempty(BWcell)
                ROIbw  =  BWcell(b:b+d-1,a:a+c-1);
            else
                ROIbw = [];
            end
            xc = round(a+c/2); yc = round(b+d/2);
            disp('Cropped ROI only works with retanglar shape')
        else
            error('Cropped image ROI analysis for shapes other than rectangle is not availabe so far')
        end
    end
    roiNamelist = ROInames{k};  % roi name on the list
    if numSections > 1
        roiNamefull = [fileNameNE,sprintf('_s%d_',sliceIND),roiNamelist,'.tif'];
    elseif numSections == 1
        roiNamefull = [fileNameNE,'_',roiNamelist,'.tif'];
    end
    if postFLAG == 0
        imwrite(ROIimg,fullfile(ROIimgDir,roiNamefull));
        %add ROI .tiff boundary name
        if ~isempty(BWcell)
            roiBWname = sprintf('mask for %s.tif',roiNamefull);
            if ~exist(fullfile(ROIimgDir,'CA_Boundary'),'dir')
                mkdir(fullfile(ROIimgDir,'CA_Boundary'));
            end
            imwrite(ROIbw,fullfile(ROIimgDir,'CA_Boundary',roiBWname));
            ROIbdryImg = ROIbw;
            ROIcoords =  bwboundaries(ROIbw,4);
        else
            ROIbdryImg = [];
            ROIcoords =  [];
        end
        [~,roiNamefullNE] = fileparts(roiNamefull);
        try
            [~,stats] = processROI(ROIimg, roiNamefullNE, ROIanaBatOutDir, keep, ROIcoords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, 1,infoLabel, bndryMode, ROIbdryImg, ROIimgDir, fibMode, advancedOPT,1);
            ANG_value = stats(1);  % orientation
            ALI_value = stats(5);  % alignment
            % count the number of features from the output feature file
            feaFilename = fullfile(ROIanaBatOutDir,[roiNamefullNE '_fibFeatures.csv']);
            if exist(feaFilename,'file')
                fibNUM = size(importdata(feaFilename),1);
            else
                fibNUM = nan;
            end
        catch EXP1
            ANG_value = nan; ALI_value = nan;
            fibNUM = nan;
            disp(sprintf('%s was skipped in batchc-mode ROI analysis. Error message: %s',roiNamefull,EXP1.message))
        end
        if numSections > 1
            z = sliceIND;
        else
            z = 1;
        end
        CA_data_current(k+1,:) = {file_number_current,sprintf('%s',fileNameNE),...
            sprintf('%s',roiNamelist),sprintf('%.1f',ANG_value),sprintf('%.2f',ALI_value),...
            sprintf('%d',fibNUM),modeID,bndryID,cropFLAG,postFLAGt,ROIshapes{ROIshape_ind},xc,yc,z};
        %                            CA_data_add = {items_number_current,sprintf('%s',fileNameNE),sprintf('%s',roiNamelist),ROIshapes{ROIshape_ind},xc,yc,z,stats(1),stats(5)};
        %         CA_data_current = [CA_data_current;CA_data_add];
        %         set(CA_output_table,'Data',CA_data_current)
        %         set(CA_table_fig,'Visible', 'on'); figure(CA_table_fig)
    elseif postFLAG == 1
        ROIfeasFLAG = 0;
        try
            %plot ROI k
            B=bwboundaries(BW);
            for k2 = 1:length(B)
                boundary = B{k2};
                plot(boundary(:,2), boundary(:,1), 'm', 'LineWidth', 1.5);%boundary need not be dilated now because we are using plot function now
            end
            text(xc-10, yc,sprintf('%s',roiNamelist),'fontsize',5,'color','m')
            clear B k2
            
            fiber_data = [];  % clear fiber_data
            for ii = 1: size(fibFeat_load,1)
                ca = fibFeat_load(ii,4)*pi/180;
                xcf = fibFeat_load(ii,3);
                ycf = fibFeat_load(ii,2);
                if bndryMode == 0
                    if BW(ycf,xcf) == 1
                        fiber_data(ii,1) = k;
                    elseif BW(ycf,xcf) == 0;
                        fiber_data(ii,1) = 0;
                    end
                elseif bndryMode >= 1   % boundary conditions
                    % only count fibers/cuvelets that are within the
                    % specified distance from the boundary  and within the
                    % ROI defined here while excluding those within the tumor
                    fiber_data(ii,1) = 0;
                    % within the outside boundary distance but not within the inside
                    ind2 = find((fibFeat_load(:,28) <= distThresh & fibFeat_load(:,29) == 0) == 1);
                    if ~isempty(find(ind2 == ii))
                        if BW(ycf,xcf) == 1
                            fiber_data(ii,1) = k;
                        end
                    end
                end   %bndryMode
            end  %ii: length of fiber features
            if bndryMode == 0
                featureLABEL = 4;
                featurename = 'Absolute Angle';
            elseif bndryMode >= 1
                featureLABEL = 30 ;
                featurename = 'Relative Angle';
            end
            if numSections == 1
                csvFEAname = [fileNameNE '_' roiNamelist '_fibFeatures.csv']; % csv name for ROI k
                matFEAname = [fileNameNE '_' roiNamelist '_fibFeatures.mat']; % mat name for ROI k
                ROIimgname =  [fileNameNE '_' roiNamelist];
            elseif numSections > 1
                csvFEAname = [fileNameNE sprintf('_s%d_',sliceIND) roiNamelist '_fibFeatures.csv']; % csv name for ROI k
                matFEAname = [fileNameNE sprintf('_s%d_',sliceIND) roiNamelist '_fibFeatures.mat']; % mat name for ROI k
                ROIimgname =  [fileNameNE sprintf('_s%d_',sliceIND) roiNamelist];
            end
            ind = find( fiber_data(:,1) == k);
            fibFeat = fibFeat_load(ind,:);
            fibNUM = size(fibFeat,1);
            % save data of the ROI
            csvwrite(fullfile(ROIpostBatDir,csvFEAname), fibFeat);
            disp(sprintf('%s  is saved', fullfile(ROIpostBatDir,csvFEAname)))
            matdata_CApost.fibFeat = fibFeat;
            save(fullfile(ROIpostBatDir,matFEAname), 'fibFeat','tifBoundary','fibProcMeth','distThresh','coords');
            % statistical analysis on the ROI features;
            ROIfeature = fibFeat(:,featureLABEL);
        catch EXP1
            ROIfeasFLAG = 1;fibNUM = nan;
            fprintf('%s, ROI %d  ROI feature files is skipped. Error message:%s \n',imgName,k,EXP1.message)
        end
        ROIstatsFLAG = 0;
        try
            stats = makeStatsOROI(ROIfeature,ROIpostBatDir,ROIimgname,bndryMode);
            ANG_value = stats(1);  % orientation
            ALI_value = stats(5);  % alignment
        catch EXP2
            ANG_value = nan; ALI_value = nan;
            ROIstatsFLAG = 1;
            fprintf('%s, ROI %d  ROI stats is skipped. Error message:%s \n',imgName,k,EXP2.message)
        end
        if numSections > 1
            z = sliceIND;
        else
            z = 1;
        end
        CA_data_current(k+1,:) = {file_number_current,sprintf('%s',fileNameNE),...
            sprintf('%s',roiNamelist),sprintf('%.1f',ANG_value),sprintf('%.2f',ALI_value),...
            sprintf('%d',fibNUM),modeID,bndryID,cropFLAG,postFLAGt,ROIshapes{ROIshape_ind},xc,yc,z};
        %         CA_data_current = [CA_data_current;CA_data_add];
        %         set(CA_output_table,'Data',CA_data_current)
        %         set(CA_table_fig,'Visible', 'on'); figure(CA_table_fig)
    end %postFLAG
end % k: ROI number
hold off % guiFig
% save overlaid image with ROIname
if postFLAG == 1   % post-processing of the CA features
    if numSections  == 1
        saveOverlayROIname = fullfile(ROIpostBatDir,[fileNameNE,'_overlay_ROIs.tif']);
        saveROIresults = fullfile(ROIpostBatDir,[fileNameNE,'_ROIresults.mat']);
        saveROIresultsXLS = fullfile(ROIpostBatDir,[fileNameNE,'_ROIresults.xlsx']);
    else
        saveOverlayROIname = fullfile(ROIpostBatDir,sprintf('%s_s%d_overlay_ROIs.tif',fileNameNE,sliceIND));
        saveROIresults = fullfile(ROIpostBatDir,sprintf('%s_s%d_ROIresults.mat',fileNameNE,sliceIND));
        saveROIresultsXLS = fullfile(ROIpostBatDir,sprintf('%s_s%d_ROIresults.xlsx',fileNameNE,sliceIND));
    end
    axis image equal;axis off; colormap gray;
    set (gca,'Position',[0 0 1 1]);
    set(guiFig,'PaperUnits','inches','PaperPosition',[0 0 size(IMG,2)/200 size(IMG,1)/200]);
    print(guiFig,'-dtiffn', '-r200', saveOverlayROIname);%YL, '-append'); %save a temporary copy of the image
    save(saveROIresults,'CA_data_current');
    if  prlflag == 2;   % 0: no parallel; 1: multicpu version; 2: cluster version
        xlwrite(saveROIresultsXLS,CA_data_current,'CA ROI post analysis');
    end
    
end

