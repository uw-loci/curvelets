
% densityEestimation.m
% GUI for operating densityEestimation program
% Modified from TumorTrace.m Written by Carolyn Pehlke, LOCI PhD student in April 2012
% Laboratory for Optical and Computational Instrumentation
% Start on July 2019

function densityEestimation(ParameterFromCAroi)

imageName = ParameterFromCAroi.imageName; 
imageDir =  ParameterFromCAroi.imageFolder;
ROInames =  ParameterFromCAroi.roiName;
ROImaskPath = fullfile(imageDir,'ROI_management','ROI_mask');
ROIfilePath = fullfile(imageDir,'ROI_management');

[~,imageNameWihoutformat] = fileparts(imageName);  
imageData = imread(fullfile(imageDir, imageName));
num_rois = size(ROInames,1);
maskList = cell(num_rois,1);
for i = 1:num_rois
    maskName = [imageNameWihoutformat '_' ROInames{i} 'mask.tif'];
    maskList{i} = imread(fullfile(ROImaskPath,maskName)); 
end

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
 end
