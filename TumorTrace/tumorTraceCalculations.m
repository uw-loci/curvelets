
% tumorTraceCalculations.m
% GUI for operating tumorTraceCalculations program
% Modified from TumorTrace.m Written by Carolyn Pehlke, LOCI PhD student in April 2012
% Laboratory for Optical and Computational Instrumentation
% Start on July 2019

function DICoutput = tumorTraceCalculations(ParameterFromCAroi)

DICtempFigures = findobj(0,'Tag','DICtemp');
if ~isempty(DICtempFigures)
    close(DICtempFigures)
end
imageName = ParameterFromCAroi.imageName;
imageDir =  ParameterFromCAroi.imageFolder;
ROInames =  ParameterFromCAroi.roiName;
ROImaskPath = fullfile(imageDir,'ROI_management','ROI_mask');
ROIfilePath = fullfile(imageDir,'ROI_management');

[~,imageNameWithoutformat] = fileparts(imageName);
imageData = imread(fullfile(imageDir, imageName));
imageWidth = size(imageData,2); 
imageHeight = size(imageData,1);
num_rois = size(ROInames,1);
maskList = cell(num_rois,1);
maskOuterList = cell(num_rois,1);
maskBoundaryList = cell(num_rois,1);
DICoutput = nan(num_rois,8);%1. Intensity-inner; 2 Intensity-boundary; 3 Intensity-outer; ...
                            %4 Density-inner; 5 Density-boundary; 
                            %6 Density-outer; 7 Area-inner; 8 Area-outer
DICcolNames = {'ROI name', 'Intensity-inner','Intensity-boundary','Intensity-outer',...
    'Density-inner','Density-boundary','Density-outer','Area-inner','Area-outer'};                            
DICoutPath = fullfile(imageDir,'ROI_management','ROI-DICanalysis');
if ~exist(DICoutPath,'dir')
    mkdir(DICoutPath)
end
fprintf('Output folder for the ROI density/intensity analysis module is : \n  %s  \n',DICoutPath) 
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
thresholdBG = 5;    % background threshold
distanceOUT = 20;  % distance threshold from the outside of the ROI
ROIin_flag=1;
ROIboundary_flag=1;
ROIout_flag=1;
ROImorphology_flag=1;
ROIothers_flag = 0;
densityFlag = 1;
intensityFlag = 1;

%User interface for DIC-Density Intensity Calculation
guiDICfig = findobj(0,'Tag','ROI manager-density intensity calculation');
roi_mang_fig = findobj(0,'Tag','ROI mananger List-CA');
if isempty(roi_mang_fig)
    disp('Launch ROI manager first to do the ROI-based density/intensity calculation')
    return
else
    figure(roi_mang_fig)
end
roiManPos = roi_mang_fig.Position;
DICtemp = cell(num_rois,1);
axes = cell(num_rois,1);

if isempty(guiDICfig)
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    guiDICfig_position = roi_mang_fig.Position;
    guiDICfig_position(4) = round(guiDICfig_position(4)/4);
    guiDICfig = figure('Resize','off','Units','pixels','Position',guiDICfig_position,...
        'Visible','on','MenuBar','none','name','Density Intensity Estimation Module','NumberTitle','off',...
        'Tag','ROI manager-density intensity calculation');
    set(guiDICfig,'Color',defaultBackground)
    
    % panel of output options
    outputPanel = uipanel('Parent', guiDICfig,'Units','normalized','Position',[0 0.275 0.475 0.725],'Title','Output Options');
    %Others-to be added later
    ROIothers_text = uicontrol('Parent',outputPanel,'Style','text','Units','normalized','Position',[0.1 0 0.5 0.175],...
        'String','Others','enable','off');
    ROIothers_radio=uicontrol('Parent',outputPanel,'Style','radiobutton','Units','normalized','Position',[0.55 0.025 0.2 0.2],...
        'Callback',@ROIothers_fn,'enable','off','Value',ROIothers_flag);
    %outer
    ROIout_text=uicontrol('Parent',outputPanel,'Style','text','Units','normalized','Position',[0.1  0.2 0.5 0.175],...
        'String','Outer','enable','on');
    ROIout_radio=uicontrol('Parent',outputPanel,'Style','radiobutton','Units','normalized','Position',[0.55 0.225 0.2 0.2 ],...
        'Callback',@ROIout_fn,'enable','on','Value',ROIout_flag);
    %boundary outline
    ROIboundary_text=uicontrol('Parent',outputPanel,'Style','text','Units','normalized','Position',[0.1  0.4 0.5 0.175],...
        'String','Boundary','enable','on');
    ROIboundary_radio=uicontrol('Parent',outputPanel,'Style','radiobutton','Units','normalized','Position',[0.55 0.425 0.2 0.2 ],...
        'Callback',@ROIboundary_fn,'enable','on','Value',ROIboundary_flag);
    %inner
    ROIin_text=uicontrol('Parent',outputPanel,'Style','text','Units','normalized','Position',[0.1  0.6 0.5 0.175],...
        'String','Inner','enable','on');
    ROIin_radio=uicontrol('Parent',outputPanel,'Style','radiobutton','Units','normalized','Position',[0.55 0.625 0.2 0.2 ],...
        'Callback',@ROIin_fn,'enable','on','Value',ROIin_flag);
    %Morphology
    ROImorphology_text=uicontrol('Parent',outputPanel,'Style','text','Units','normalized','Position',[0.1  0.8 0.5 0.175],...
        'String','Morphology','enable','on');
    ROImorphology_radio=uicontrol('Parent',outputPanel,'Style','radiobutton','Units','normalized','Position',[0.55 0.825 0.2 0.2 ],...
        'Callback',@ROImorphology_fn,'enable','on','Value',ROImorphology_flag);
    % panel of running parameters
    paramPanel = uipanel('Parent', guiDICfig,'Units','normalized','Position',[0.5 0.6 0.5 0.36],'Title','Parameters');
    threshold_text = uicontrol('Parent', paramPanel,'Style','Text','Units','normalized',...
        'Position',[0 0.45 0.5 0.40], 'String','Threshold','TooltipString','Set the background threshold-absolute value');
    threshold_edit =uicontrol('Parent', paramPanel,'Style','Edit','Units','normalized',...
        'Position',[0.5 0.525 0.4 0.40], 'String',num2str(thresholdBG),'TooltipString',...
        'Enter the background threshold-absolute value','Callback',{@threshold_edit_Callback});
    distanceOUT_text = uicontrol('Parent', paramPanel,'Style','Text','Units','normalized',...
        'Position',[0 0 0.5 0.40], 'String','Distance','TooltipString','Set the the outside distance to the ROI outline');
    distanceOUT_edit =uicontrol('Parent', paramPanel,'Style','Edit','Units','normalized',...
        'Position',[0.5 0.05 0.4 0.40], 'String',num2str(distanceOUT),'TooltipString',...
        'Enter the outside distance to the ROI outline','Callback',{@distanceOUT_edit_Callback});
    % panel of analysis mode
    modePanel = uipanel('Parent', guiDICfig,'Units','normalized','Position',[0 0.025 0.475 0.225],'Title','Analysis Mode');
    densityFlag_box=uicontrol('Parent',modePanel,'Style','Checkbox','Units','normalized',...
        'Position',[0.1 0.1 0.45 0.45], 'String','Density','TooltipString','calculate density',...
        'Value',densityFlag,'UserData',1,'Min',0,'Max',1,'Callback',{@densityFlag_Callback});
    intensityFlag_box=uicontrol('Parent',modePanel,'Style','Checkbox','Units','normalized',...
        'Position',[0.55 0.1 0.45 0.45], 'String','Intensity','TooltipString','calculate intensity',...
        'Value',intensityFlag,'UserData',1,'Min',0,'Max',1,'Callback',{@intensityFlag_Callback});
    % message panel
    infoPanel = uipanel('Parent',guiDICfig,'units','normalized','Position',[0.5 0.25 0.5 0.3],...
        'BackGroundColor',defaultBackground,'Title','Message');
    infoMessage = uicontrol('Parent',infoPanel,'Style','text','Units','normalized','Position',[0 0 1 1],...
        'String',sprintf('\n %d ROI(s)selcted including: %s',num_rois,ROIname_selected),'FontSize',9,'BackgroundColor','g','HorizontalAlignment','left');
    % BDCgcf ok  and reset buttons
    DICgcfOK = uicontrol('Parent',guiDICfig,'Style','Pushbutton','String','OK','FontSize',11,...
        'Units','normalized','Position',[0.55 .05 0.2 .2],'BackgroundColor','r','Callback',{@DICgcfOK_Callback});
    DICgcfRESET = uicontrol('Parent',guiDICfig,'Style','Pushbutton','String','Reset','FontSize',11,...
        'Units','normalized','Position',[0.775 .05 0.2 .2],'BackgroundColor','y','Callback',{@DICgcfRESET_Callback});
end

figure(guiDICfig )
return
%% callback functions
%output options
%outer
    function[] = ROIout_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            ROIout_flag = 1;
        else
            ROIout_flag = 0;
        end
    end
% boundary
    function[] = ROIboundary_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            ROIboundary_flag = 1;
        else
            ROIboundary_flag = 0;
        end
    end
%inner
    function[] = ROIin_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            ROIin_flag = 1;
        else
            ROIin_flag = 0;
        end
    end
% morphology
    function[] = ROImorphology_fn(hObject,eventdata,handles)
        if(get(hObject,'Value')==1)
            ROImorphology_flag = 1;
        else
            ROImorphology_flag = 0;
        end
    end
%% running parameters
%background threshold
    function threshold_edit_Callback(hObject,eventdata)
        usr_input = get(threshold_edit,'String');
        usr_input = str2double(usr_input);
        set(threshold_edit,'UserData',usr_input);
        thresholdBG = usr_input;
        fprintf('Image background threshold is set to be %3.0f \n',thresholdBG)
    end
%distance to the boundary
    function distanceOUT_edit_Callback(hObject,eventdata)
        usr_input = get(distanceOUT_edit,'String');
        usr_input = str2double(usr_input);
        set(distanceOUT_edit,'UserData',usr_input);
        distanceOUT = usr_input;
        fprintf('Outside distance threshold is set to be %3.0f \n',distanceOUT)
    end

%% run mode
%densityFlag
    function densityFlag_Callback(hObject,eventdata)
        if get(densityFlag_box,'Value') == 0
            densityFlag =0;
            disp('Density NOT selected')
        elseif get(densityFlag_box,'Value') == 1
            densityFlag = 1;
            disp('Density IS selected')
        end
    end
%intensityFlag
    function intensityFlag_Callback(hObject,eventdata)
        if get(intensityFlag_box,'Value') == 0
            intensityFlag =0;
            disp('Intensity NOT selected')
        elseif get(densityFlag_box,'Value') == 1
            intensityFlag = 1;
            disp('Intensity IS selected')
        end
    end
%%main function
    function DICgcfOK_Callback(hObject,eventdata)
        if intensityFlag == 0 && densityFlag == 0
            disp('At least one analysis mode (density/intensity) should be selected')
            figure(guiDICfig)
            return
        end
        %%ROI morphology calculation
        fprintf('Morphology calculation flag == %d \n',ROImorphology_flag)
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
             maskName = [imageNameWithoutformat '_' ROInames{i} 'mask.tif'];
             maskList{i} = imread(fullfile(ROImaskPath,maskName));
             maskBoundaryList{i} = bwboundaries(maskList{i},4);  % boundary coordinates
             rowBD = maskBoundaryList{i}{1}(:,1);
             colBD = maskBoundaryList{i}{1}(:,2);
             % create border image
             BWborder = logical(zeros(size(imageData)));
             for aa = 1:length(rowBD)
                 BWborder(rowBD(aa),colBD(aa)) = 1;
             end
             %ROI boundary calculation
             if ROIboundary_flag == 1
                 [intensity, density] = cellIntense(imageData,rowBD,colBD);
                 if intensityFlag == 1
                     DICoutput(i,2) = nanmean(intensity);
                 end
                 if densityFlag == 1
                     DICoutput(i,5) = nansum(density);
                 end
             end
             
             
             DICtemp{i,1} = figure('Position',[roiManPos(1)+roiManPos(3)+50*(i-1)  roiManPos(2)+roiManPos(4)*0.60 roiManPos(3)*3.0 roiManPos(3)*1.0],'Tag','DICtemp');
             axes{i,1}(1) = subplot(1,3,1);
             imshow(imageData),hold on 
             plot(colBD,rowBD,'m.-'),xlim([1 512]);ylim([1 512]); 
             axis ij, colormap('gray'),axis equal tight, axis off
             title(sprintf('maskOutline-%s',ROInames{i}))
            
             %inner ROI calculation
            if ROIin_flag == 1
                index1In = find( maskList{i}>0);
                DICoutput(i,7) = length(index1In); % area of the Outer ROI
                imageTemp = double(imageData).* double(maskList{i});
                index2In = find(imageTemp > thresholdBG);
                if intensityFlag == 1
                    DICoutput(i,1) = nanmean(imageTemp(index2In));
                end
                if densityFlag == 1
                    DICoutput(i,4) = length(index2In);
                end
%                 figure('pos',[50 100 512*imageWidth/max([imageWidth imageHeight]) 512*imageHeight/max([imageWidth imageHeight])],'Tag','DICtemp')
                figure(DICtemp{i,1})
                axes{i,1}(2) = subplot(1,3,2);
                imagesc(imageTemp); hold on ;  plot(colBD,rowBD,'m.-');axis ij; colormap('gray'); axis equal tight;axis off;
                text(imageWidth*.1,imageHeight*.2, sprintf('%s-Inner: \n Intensity= %d \n Density = %d \n Area= %d \n', ....
                    ROInames{i},round(DICoutput(i,1)),round(DICoutput(i,4)),round(DICoutput(i,7))),'color','r')
                title( sprintf('%s-Inner',ROInames{i}));
            end
              %Outer ROI calculation
             if ROIout_flag == 1
                 % filter to create outer ROI
                 fOuter = fspecial('disk',distanceOUT);
                 fOuter(fOuter >0) = 1;
                 tempThick = imfilter(maskList{i},fOuter);
                 maskOuterList{i} = imsubtract(tempThick,maskList{i});
             end
             if ROIout_flag == 1
                 index1Out = find( maskOuterList{i}>0);
                 DICoutput(i,8) = length(index1Out); % area of the Outer ROI
                 imageTemp = double(imageData).* double(maskOuterList{i});
                 
                 index2Out = find(imageTemp > thresholdBG);
                 if intensityFlag == 1
                     DICoutput(i,3) = mean(imageTemp(index2Out));
                 end
                 if densityFlag == 1
                     DICoutput(i,6) = length(index2Out);
                 end
%                  figure('pos',[600 100 512*imageWidth/max([imageWidth imageHeight]) 512*imageHeight/max([imageWidth imageHeight])],'Tag','DICtemp')
                figure(DICtemp{i,1})
                axes{i,1}(3) = subplot(1,3,3);
                imagesc(imageTemp); hold on ;  plot(colBD,rowBD,'m.-');axis ij; colormap('gray'); axis equal tight;axis off;
                text(imageWidth*.1,imageHeight*.2, sprintf('%s-Outer: \n Intensity= %d \n Density = %d \n Area= %d \n', ....
                     ROInames{i},round(DICoutput(i,3)),round(DICoutput(i,6)),round(DICoutput(i,8))),'color','r')
                 title( sprintf('%s-Outer',ROInames{i}));
             end
%              figure('Position',[roiManPos(1)+roiManPos(3)  roiManPos(2)+roiManPos(4)*0.65 roiManPos(3)*3.2 roiManPos(3)*0.8],'Tag','DICtemp')
%              subplot(1,4,1), imshow(maskList{i}),title(sprintf('mask-%s',ROInames{i}))
%              subplot(1,4,2), imshow(BWborder),title(sprintf('maskBoundary-%s',ROInames{i}))
%              subplot(1,4,3), imshow(maskOuterList{i}),title(sprintf('maskOuter-%s',ROInames{i}))
%              subplot(1,4,4), imshow(imageData),hold on 
%              plot(colBD,rowBD,'m.-'),xlim([1 512]);ylim([1 512]); 
%              axis ij, colormap('gray')
%              title(sprintf('maskOutline-%s',ROInames{i}))
             fprintf('\n ROI=%s-Intensity: \n Inner = %d \n Boundary = %d \n Outer = %d \n', ...
                 ROInames{i},round(DICoutput(i,1)), round(DICoutput(i,2)),round(DICoutput(i,3)))
             fprintf('\n ROI=%s-Density: \n Inner = %d \n Boundary = %d \n Outer = %d \n', ...
                 ROInames{i},round(DICoutput(i,4)), round(DICoutput(i,5)),round(DICoutput(i,6)))
             fprintf('\n ROI=%s-Area: \n Inner = %d \n Outer = %d \n', ...
                 ROInames{i},round(DICoutput(i,7)), round(DICoutput(i,8)))
             linkaxes(axes{i,:},'xy');
        end
        %save DIC outputfile
        xlswrite(DICoutFile,DICcolNames,'DIC','A1');
        xlswrite(DICoutFile,ROInames,'DIC','A2');
        xlswrite(DICoutFile,DICoutput,'DIC','B2');
        fprintf('DIC output is saved at %s \n',DICoutFile)        
    end
%%
    function DICgcfRESET_Callback(hObject,eventdata)
        if ~isempty(guiDICfig)
            close(guiDICfig)
        end
        clear DICoutput
        DICtempFigures = findobj(0,'Tag','DICtemp');
        if ~isempty(DICtempFigures)
            close(DICtempFigures)
        end
        DICoutput = tumorTraceCalculations(ParameterFromCAroi); 
    end

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

% for i = 1:num_rois
%     if densityFlag == 1;
%         densityValue{i} = calculateDensity(i);
%     end
%
% %     if intensityFlag == 1;
% %         intensityValue{i} = calculateDensity(i);
% %     end
%
% end
%
% end
%
% function densityValue = calculateDensity (ROIselected)
%     return
% end

% function [innerDensity, innerIntensity] = inEstimation(ROIselected)
% if intensityFlag == 1
%     kSize = round(kSize/4);
%     img = double(img)/max(max(double(img)));
%     inImg = immultiply(BWinner,img);
%     inImg = inImg.*(inImg >= 0);
%     innerIntensity = zeros(length(r),1);
% else
%    fprintf('Inner intensity is not calculated for %s \n', ROIselected)
% end
%
% if densityFlag == 1
%     % stuff to compute when densityFlag is set
% else
%     fprintf('Inner density is not calculated for %s \n', ROIselected)
% end
% end


% function boundaryEstimation(ROIselected)
% % border has to be kSize pixels thick
% for bb = 1:length(r)
%     if (r(bb)-kSize) >= 1 &&... % Make sure k pixels above this row there is a value >= 1
%             (r(bb)+kSize) <= size(img,1) &&... % Don't go off the bottom edge
%             (c(bb)-kSize) >= 1 &&... % Make sure k pixels to the left of this column there is a value >= 1
%             (c(bb)+kSize) <= size(img,2)
%         % Don't go off the right edge
%         temp = (inImg((r(bb)-kSize):(r(bb)+kSize),(c(bb)-kSize):(c(bb)+kSize)));
%         temp = mean2(temp);
%     else
%         temp = 0;
%     end
%     innerIntensity(bb) = temp;
% end
%
% end

% 1. Read the mask file that was created before. The actual image is in
%    maskList{i}

% 2. Take the original image and the mask file and calculate the density of
% pixels above the Intensity threshold in the inner ROI
% 3. Find the average intensity of the Inner ROI

% function intensity = cellIntense(img,r,c)
% % initialize variables
% intensity = zeros(length(r),1);
% % find the intensity of the 8-connect neighborhood around each outline
% % pixel
% for aa = 1:length(r)
%     if (r(aa)-1) >= 1 && (r(aa)+1) <= size(img,1) && (c(aa)-1) >= 1 && (c(aa)+1) <= size(img,2)
%         temp = mean2((img((r(aa)-1):(r(aa)+1),(c(aa)-1):(c(aa)+1))));
%     else
%         temp = 0;
%     end
%     intensity(aa) = temp;
% end
%
%
% end


% fprintf('Image %s and its %d ROIs are loaded into density/intensity module \n',imageName, num_rois);
% guiFig = figure('Resize','off','Units','pixels','Position',[100 200 700 700],'Visible','on','MenuBar','none','name','Density Estimation','NumberTitle','off','UserData',0);
% defaultBackground = get(0,'defaultUicontrolBackgroundColor');
% set(guiFig,'Color',defaultBackground)
%
% menuPanel = uipanel('Parent',guiFig,'Position',[.40 .85 .325 .35]);
%
% subPan1 = uipanel('Parent',menuPanel,'Title','Calculations','Position',[.03 .81 .94 .175]);
%
%
% men1 = uicontrol('Parent',subPan1,'Style','popupmenu','Units','normalized','Position',[.0002 .87 .5 .05],'String',{'None','Inner ROI', 'Outer ROI', 'ROI Boundry'},'UserData',[],'Callback',{@popCall1});
%
% % Panel to contain input boxes
% boxPan = uipanel('Parent',guiFig,'Position',[.74 .525 .235 .275]);
%
% % ROI size input box
% ROIbox = uicontrol('Parent',boxPan,'Style','edit','Units','normalized','Position',[.15 .75 .7 .1],'BackgroundColor',[1 1 1],'Callback',{@inROI});
% nameBox = uicontrol('Parent',boxPan,'Style','text','String','Enter ROI width in pixels: ','Units','normalized','Position',[.125 .85 .75 .1]);
%
% % intensity threshold input box
% INTnum = uicontrol('Parent',boxPan,'Style','edit','String','5','Units','normalized','Position',[.15 .3 .7 .1],'BackgroundColor',[1 1 1],'Callback',{@numINT});
% nameINT = uicontrol('Parent',boxPan,'Style','text','String','Intensity Threshold (5 default)','Units','normalized','Position',[.125 .4 .75 .1]);

% fileBox1 = uicontrol('Parent',subPan1,'Style','edit','String','Load File','BackgroundColor',[1 1 1],'Units','normalized','Position',[.01 .05 .6 .25]);
% fileButt1 = uicontrol('Parent',subPan1,'Style','pushbutton','BackgroundColor',[0 .7 1],'String','Browse','Units','normalized','Position',[.7 .05 .25 .25],'Callback',{@buttCall1});

% nameBox1 = uicontrol('Parent',subPan1,'Style','edit','String',' ','BackgroundColor',[1 1 1],'Units','normalized','Position',[.12 .4 .35 .25],'Callback',{@nameCall1});
% nameText1 = uicontrol('Parent',subPan1,'Style','text','String','Name: ','Units','normalized','Position',[.01 .36 .1 .25]);

% panel to contain start and reset buttons
% buttBox = uipanel('Parent',guiFig,'Position',[.74 .825 .235 .135]);
%
% % button to start analysis
% runButt = uicontrol('Parent',buttBox,'Style','pushbutton','String','Run','BackgroundColor',[.2 1 .6],'Units','normalized','Position',[.075 .125 .4 .7],'Callback',{@runProg});
%
% % reset button
% resetButt = uicontrol('Parent',buttBox,'Style','pushbutton','String','Reset','BackgroundColor',[1 .2 .2],'Units','normalized','Position',[.535 .125 .4 .7],'Callback',{@resetGui});
%
% function popCall1(men1,eventdata)
%         str = get(men1,'String');
%         val = get(men1,'Value');
%         switch str{val}
%             case 'None'
%                 set(men1,'UserData',[])
%             case 'Inner ROI'
%                 set(men1,'UserData','Inner ROI')
%             case 'Outer ROI'
%                 set(men1,'UserData','Outer ROI')
%             case 'ROI Boundry'
%                 set(men1,'UserData','ROI Boundry')
%         end
% end
%
% % callback for intensity threshold box
%     function numINT(INTnum,eventdata)
%         int_input = get(INTnum,'String');
%         set(INTnum,'UserData',int_input);
%         set(INTnum,'Enable','off');
%
%
%     end
%
%         function buttCall1(fileButt1,eventdata)
%         [fileName,pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.*'});
%         filePath = fullfile(pathName,fileName);
%         set(fileBox1,'String',fileName)
%         set(fileBox1,'UserData',filePath)
%         end
%
%         function runProg(runButt,eventdata)
%         mens = {men1};
%         % titles = {nameBox1};
%         % files = {fileBox1};
%         tempFolder = uigetdir(' ','Select Output Directory:');
%         end
%
%         for aa = 1:1
%             temp = get(mens{aa},'UserData');
%             anals{aa} = temp;
%             chans(aa) = ~isempty(temp);
%
%             nTemp = get(titles{aa},'UserData');
%             names{aa} = nTemp;
%
%             fTemp = get(files{aa},'UserData');
%             paths{aa} = fTemp;
%
%         end

% %Enter from a GUI window
% thresholdDE = 5;
% flagInner = 1;
% flagOn = 1;
% flagOut = 1;
% Thickness of the intensity on the boundry
% distanceOuter = 100;
% distanceInner = 10;
%
%
% % AJP -- likely here is where we make a call for the density
% % calculation. If a new GUI is needed it will need to be added here
% % too using the window(?) function.
%
%
% % Threshold and find outline of selected cell channel (original code from
% % cellTrace.m
% %
% % Inputs:
% % img = image channel selected for mask
% % intT = intensity threshold
% % firstR = row location of previous starting point, for timeseries analysis
% % firstC = col location of previous starting point, for timeseries analysis
% %
% % Outputs:
% % BW = binary version of original image
% % BWborder = single-pixel outline of cell
% % cent = center of cell
% % r = row locations of outline
% % c = row locations of outline
% % r1 = row starting point for morph analysis
% % c1 = column starting point for morph analysis
% %
% % Written by Carolyn Pehlke
% % Laboratory for Optical and Computational Instrumentation
% % April 2012
% % Adapted for use in CurveAlign by Akhil Patel - July 2019
%
% function [BW,BWborder,BWmask,r,c,r1,c1] = curveAlignCellTrace(img,intT,roiShape)
%
% % Determine if input image is a binary mask, skip thresholding if true
% if ~islogical(img)
%
%     % find appropriate threshold for binarizing image
%     [counts ~] = imhist(img);
%     [maxVal loc] = max(counts);
%     threshVal = intT*maxVal;
%     ind = find(counts < threshVal,5,'first');
%     ind2 = find(ind > loc,1,'first');
%     iVal = ind(ind2)/max(max(double(img)));
%
%     % make binary and find objects in binary image
%     BW = im2bw(img,iVal);
%     BW = bwmorph(BW,'majority',2);
%     BW = bwmorph(BW,'close');
%
% else
%     BW = img;
% end
%
% % STATS = regionprops(BW,'Centroid','Extrema','Area','PixelList');
% %
% % % find largest object in binary image -> cell
% % temp = 1;
% %
% % if length(STATS) > 1
% %     for zz = 1:length(STATS)
% %         if STATS(zz).Area > STATS(temp).Area
% %             temp = zz;
% %         end
% %     end
% % end
% %
% % area = STATS(temp).Area;
% pix = STATS(temp).PixelList;
% pix = roiShape;
% perms = bwperim(BW);
% [rr cc] = find(perms);
% reg = horzcat(cc,rr);
% tf = ismember(reg,pix,'rows');
% TF = horzcat(tf,tf);
% reg = reg.*TF;
%
% % is starting point close enough to original starting point?
% [idx dist] = knnsearch(roiShape,reg);
% [val ind] = min(dist);
% r1 = reg(ind,2);
% c1 = reg(ind,1);
%
% % trace perimeter of cell
% % P = bwtraceboundary(BW,[r1 c1],'NW');
% P = roiShape;
% c = P(:,2); r = P(:,1);
% % create border image
% BWborder = logical(zeros(size(img)));
% for aa = 1:length(r)
%     BWborder(P(aa,1),P(aa,2)) = 1;
% end
%
% % create binary mask
% BWmask = poly2mask(r,c,size(img,1),size(img,2));
% % size criteria for finding correct object
% % testVal = sum(sum(BWmask))/area;
%
% % if the size criteria fails, find new object
% % if testVal < .9
% %
% %     P = bwtraceboundary(BW,[r1 c1],'SW');
% %     BWborder = logical(zeros(size(img)));
% %     c = P(:,2); r = P(:,1);
% %
% %     for aa = 1:length(r)
% %         BWborder(P(aa,1),P(aa,2)) = 1;
% %     end
% %
% %     % create binary mask
% %     BWmask = poly2mask(c,r,size(img,1),size(img,2));
% % end
%
% end
%
% % finds intensity in inner uutline
% % Adapted from Tumor Trace for use in CurveAlign
% % Inputs:
% % img = image for intensity measurement
% % BWinner = binary inner ROI
% % r = row outline locations
% % c = column outline locations
% % kSize = ROI size
% %
% % Outputs:
% % innerIntensity = vector of intensity values
% %
% % Written by Carolyn Pehlke
% % Laboratory for Optical and Computational Instrumentation
% % April 2012
%
% % function innerIntensity = inIntense(img,BWinner,r,c,kSize)
% % kSize = round(kSize/4);
% % img = double(img)/max(max(double(img)));
% % inImg = immultiply(BWinner,img);
% % inImg = inImg.*(inImg >= 0);
% % innerIntensity = zeros(length(r),1);
% %
% % for bb = 1:length(r)
% %     if (r(bb)-kSize) >= 1 && (r(bb)+kSize) <= size(img,1) && (c(bb)-kSize) >= 1 && (c(bb)+kSize) <= size(img,2)
% %         temp = (inImg((r(bb)-kSize):(r(bb)+kSize),(c(bb)-kSize):(c(bb)+kSize)));
% %         temp = mean2(temp);
% %     else
% %         temp = 0;
% %     end
% %     innerIntensity(bb) = temp;
% %
% % end
%
% for i = 1:num_rois
%     roi_shape = separate_rois.(roi_names{i}).roi;
%     row_coordinates = roi_shape(:,1);
%     column_coordinates = roi_shape(:,2);
%     % call (img, row_coordinates, column_coordinates);
%     % Call the intensity function here with r,c and img
%     intensity_threshold = 0.05;
%     [BW,BWborder,BWmask,r,c,r1,c1] = curveAlignCellTrace(IMGdata,intensity_threshold,roi_shape)
% end

%
%  end
end