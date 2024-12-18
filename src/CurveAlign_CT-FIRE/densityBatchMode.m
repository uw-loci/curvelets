    function DICoutdata = densityBatchMode(ParameterFromCAroi)
        
        DICoutdata = [];  % initilize the DICout for each image
        imageName = ParameterFromCAroi.imageName;       % image name; 
        imageDir =  ParameterFromCAroi.imageFolder;      % image path
        thresholdBG = ParameterFromCAroi.thresholdBG;    % background threshold
        distanceOUT = ParameterFromCAroi.distanceOUT;   % distance threshold from the outside of the ROI
        ROIin_flag = ParameterFromCAroi.ROIin_flag;
        ROIboundary_flag = ParameterFromCAroi.ROIboundary_flag;
        ROIout_flag = ParameterFromCAroi.ROIout_flag;
        densityFlag = ParameterFromCAroi.densityFlag;
        intensityFlag = ParameterFromCAroi.intensityFlag;

        %Get ROInames from the corresponding ROI mat file
%         ROInames =  ParameterFromCAroi.roiName;
        [~,IMGname,~] = fileparts(imageName);
        roiMATnamefull = [IMGname,'_ROIs.mat'];
        if exist(fullfile(imageDir,'ROI_management',roiMATnamefull),'file')
            ROIload = load(fullfile(imageDir,'ROI_management',roiMATnamefull),'separate_rois');
            if isempty (ROIload.separate_rois)
                fprintf('Found ROI file for %s but NO ROI is annotated. This image will be skipped \n',imageName)
                return
            else
                ROInames = fieldnames(ROIload.separate_rois);
                fprintf('Found ROI file for %s and loaded the ROIs successfully \n', imageName); 
            end
        else
            fprintf('NO ROI file was found for %s. This image will be skipped . \n',imageName)
            return
        end

        ROImaskPath = fullfile(imageDir,'ROI_management','ROI_mask');
        ROIfilePath = fullfile(imageDir,'ROI_management');
        
        [~,filenameNE,fileEXT] = fileparts(imageName);
        
        [~,imageNameWithoutformat] = fileparts(imageName);
        imageData = imread(fullfile(imageDir, imageName));
        imageWidth = size(imageData,2); 
        imageHeight = size(imageData,1);
        num_rois = size(ROInames,1);
        maskList = cell(num_rois,1);
        maskOuterList = cell(num_rois,1);
        maskBoundaryList = cell(num_rois,1);
        DICoutput = nan(num_rois,8);
%         DICcolNames = {'Image name','ROI name', 'Intensity-inner','Intensity-boundary','Intensity-outer',...
%             'Density-inner','Density-boundary','Density-outer','Area-inner','Area-outer'}; 
        DICcolNames = {'ROI#','Threshold','Distance','Image name','ROI name', 'Density-inner','Area-inner','Intensity-inner',...
            'Density-outer','Area-outer','Intensity-outer',...
            'Density-boundary','Intensity-boundary'};
        DICoutPath = fullfile(imageDir,'ROI_management','ROI-DICanalysis');
        if ~exist(DICoutPath,'dir')
            mkdir(DICoutPath)
        end
        % fprintf('Output folder for the ROI density/intensity analysis module is : \n  %s  \n',DICoutPath) 
        DICoutFileList = dir(fullfile(DICoutPath,sprintf('DICoutput-%s-*.xlsx',imageNameWithoutformat)));
        if isempty(DICoutFileList)
            DICoutFile = fullfile(DICoutPath,sprintf('DICoutput-%s-1.xlsx',imageNameWithoutformat));
        else
            DICoutFile = fullfile(DICoutPath,sprintf('DICoutput-%s-%d.xlsx',imageNameWithoutformat,length(DICoutFileList)+1));
        end
        ROIname_selected = '';
        for ii = 1:num_rois
            ROIname_selected = [ROIname_selected  ROInames{ii} '  '];
        end
        %default running parameters
%         thresholdBG = 5;    % background threshold
%         distanceOUT = 20;   % distance threshold from the outside of the ROI
%         ROIin_flag=1;
%         ROIboundary_flag=1;
%         ROIout_flag=1;
%         ROImorphology_flag=1;
%         ROIothers_flag = 0;
%         densityFlag = 1;
%         intensityFlag = 1;
        DICtemp = cell(num_rois,1);
        axes = cell(num_rois,1);
        if intensityFlag == 0 && densityFlag == 0
            disp('At least one analysis mode (density/intensity) should be selected')
            figure(guiDICfig)
            return
        end
        fprintf('\n')
        fprintf('Density analysis for %s \n\m',imageName)
    
        %%ROI morphology calculation
%         fprintf('Morphology calculation flag == %d \n',ROImorphology_flag)
        fprintf('Inner calculation flag == %d \n',ROIin_flag)
        fprintf('Boundary calculation flag == %d \n',ROIboundary_flag)
        fprintf('Outer calculation flag == %d \n',ROIout_flag)
        fprintf('Background threshold is set to %3.0f \n',thresholdBG)
        fprintf('Outside distance threshold is set to %3.0f \n', distanceOUT)
        %% intensity calculation
        if intensityFlag == 1
            disp('Calculate intensity related measures of the selected ROI(s)')
        end
        %% density calculation
        if densityFlag == 1
            disp('Calculate density related measures of the selected ROI(s)')
        end
        %% Loop through all ROIs for the calculation
%         DICtemp = cell(num_rois,1);
%         axes = cell(num_rois,1);
        for i = 1:num_rois
             maskName = ['mask for ' imageNameWithoutformat '_' ROInames{i} '.tif.tif'];
             try
                 maskList{i} = imread(fullfile(ROImaskPath,maskName));
             catch
                 automateMaskCreation(ParameterFromCAroi);
                 maskList{i} = imread(fullfile(ROImaskPath,maskName));
             end
             
             maskBoundaryList{i} = bwboundaries(maskList{i},4);  % boundary coordinates
             rowBD = maskBoundaryList{i}{1}(:,1);
             colBD = maskBoundaryList{i}{1}(:,2);
             
             %ROI boundary calculation
             if ROIboundary_flag == 1
                 [intensity, density] = cellIntense(imageData,rowBD,colBD);
                 if intensityFlag == 1
                     DICoutput(i,8) = nanmean(intensity);
                 end
                 if densityFlag == 1
                     DICoutput(i,7) = nansum(density);
                 end
             end
             
             % DICtemp{i,1} = figure('Position',[roiManPos(1)+roiManPos(3)+50*(i-1)  roiManPos(2)+roiManPos(4)*0.60 roiManPos(3)*3.0 roiManPos(3)*1.0],'Tag','DICtemp');
             % axes{i,1}(1) = subplot(1,3,1);
%              imshow(imageData),hold on 
%              plot(colBD,rowBD,'m.-'),xlim([1 512]);ylim([1 512]); 
%              axis ij, colormap('gray'),axis equal tight, axis off
%              title(sprintf('maskOutline-%s',ROInames{i}))
            
             %inner ROI calculation
            if ROIin_flag == 1
                index1In = find( maskList{i}>0);
                DICoutput(i,2) = length(index1In); % area of the inner ROI
                imageTemp = double(imageData).* double(maskList{i});
                index2In = find(imageTemp > thresholdBG);
                if intensityFlag == 1
                    DICoutput(i,3) = nanmean(imageTemp(index2In));
                end
                if densityFlag == 1
                    DICoutput(i,1) = length(index2In);
                end
%                 figure('pos',[50 100 512*imageWidth/max([imageWidth imageHeight]) 512*imageHeight/max([imageWidth imageHeight])],'Tag','DICtemp')
                % figure(DICtemp{i,1})
%                 axes{i,1}(2) = subplot(1,3,2);
%                 imagesc(imageTemp); hold on ;  plot(colBD,rowBD,'m.-');axis ij; colormap('gray'); axis equal tight;axis off;
%                 text(imageWidth*.1,imageHeight*.2, sprintf('%s-Inner: \n Intensity= %d \n Density = %d \n Area= %d \n', ....
%                     ROInames{i},round(DICoutput(i,1)),round(DICoutput(i,4)),round(DICoutput(i,7))),'color','r')
%                 title( sprintf('%s-Inner',ROInames{i}));
            end
              %Outer ROI calculation
             if ROIout_flag == 1
                 % filter to create outer ROI
                 fOuter = fspecial('disk',distanceOUT);
                 fOuter(fOuter >0) = 1;
                 tempThick = imfilter(maskList{i},fOuter);
                 maskOuterList{i} = imsubtract(tempThick,maskList{i});
                 index1Out = find( maskOuterList{i}>0);
                 DICoutput(i,5) = length(index1Out); % area of the outer ROI
                 imageTemp = double(imageData).* double(maskOuterList{i});
                 
                 index2Out = find(imageTemp > thresholdBG);
                 if intensityFlag == 1
                     DICoutput(i,6) = mean(imageTemp(index2Out));
                 end
                 if densityFlag == 1
                     DICoutput(i,4) = length(index2Out);
                 end
%                  figure('pos',[600 100 512*imageWidth/max([imageWidth imageHeight]) 512*imageHeight/max([imageWidth imageHeight])],'Tag','DICtemp')
                % figure(DICtemp{i,1})
                % axes{i,1}(3) = subplot(1,3,3);
%                 imagesc(imageTemp); hold on ;  plot(colBD,rowBD,'m.-');axis ij; colormap('gray'); axis equal tight;axis off;
%                 text(imageWidth*.1,imageHeight*.2, sprintf('%s-Outer: \n Intensity= %d \n Density = %d \n Area= %d \n', ....
%                      ROInames{i},round(DICoutput(i,3)),round(DICoutput(i,6)),round(DICoutput(i,8))),'color','r')
%                  title( sprintf('%s-Outer',ROInames{i}));
             end
%              figure('Position',[roiManPos(1)+roiManPos(3)  roiManPos(2)+roiManPos(4)*0.65 roiManPos(3)*3.2 roiManPos(3)*0.8],'Tag','DICtemp')
%              subplot(1,4,1), imshow(maskList{i}),title(sprintf('mask-%s',ROInames{i}))
%              subplot(1,4,2), imshow(BWborder),title(sprintf('maskBoundary-%s',ROInames{i}))
%              subplot(1,4,3), imshow(maskOuterList{i}),title(sprintf('maskOuter-%s',ROInames{i}))
%              subplot(1,4,4), imshow(imageData),hold on 
%              plot(colBD,rowBD,'m.-'),xlim([1 512]);ylim([1 512]); 
%              axis ij, colormap('gray')
%              title(sprintf('maskOutline-%s',ROInames{i}))
             fprintf('\n ROI=%s-Intensity: \n Inner = %d \n Outer = %d \n  Boundary = %d \n', ...
                 ROInames{i},round(DICoutput(i,3)), round(DICoutput(i,6)),round(DICoutput(i,8)))
             fprintf('\n ROI=%s-Density: \n Inner = %d \n Outer = %d \n Boundary = %d \n', ...
                 ROInames{i},round(DICoutput(i,1)), round(DICoutput(i,4)),round(DICoutput(i,7)))
             fprintf('\n ROI=%s-Area: \n Inner = %d \n Outer = %d \n', ...
                 ROInames{i},round(DICoutput(i,2)), round(DICoutput(i,5)))
             % linkaxes(axes{i,:},'xy');
        end
        %save DIC outputfile
        % create output/return table 
        imageNamesOUT = repmat({imageName},num_rois,1);
        DICoutdata  = [imageNamesOUT,ROInames,num2cell(DICoutput)];
%         xlwrite(DICoutFile,DICcolNames,'DIC','A1');
%         xlwrite(DICoutFile,DICoutData,'DIC','A2');
%         xlwrite(DICoutFile,ROInames,'DIC','B2');
%         xlwrite(DICoutFile,DICoutput,'DIC','C2');
%         fprintf('DIC output is saved at %s \n',DICoutFile)
        %% modified from 'cellIntense' function in tumor trace
        function [intensity, density] = cellIntense(img,r,c)
            % find the intensity of the 8-connect neighborhood around each
            % outline pixel
            % initialize variables
            intensity = nan(length(r),1);
            density = nan(length(r),1);
            for aa = 1:length(r)
                temp1 = nan;
                temp2 = nan;
                if (r(aa)-1) >= 1 && (r(aa)+1) <= size(img,1) && (c(aa)-1) >= 1 && (c(aa)+1) <= size(img,2)
                    tempimg = img((r(aa)-1):(r(aa)+1),(c(aa)-1):(c(aa)+1));
                    indexBG = find(tempimg > thresholdBG);
                    if ~isempty(indexBG)
                        temp1 = mean(tempimg(indexBG));
                        temp2 = length(indexBG);
                    end
                end
                intensity(aa) = temp1;
                density(aa) = temp2;
            end
        end
        
    end