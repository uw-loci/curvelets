
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

fprintf('Image %s and its %d ROIs are loaded into density/intensity module \n',imageName, num_rois);
% %Enter from a GUI window
% thresholdDE = 5;
% flagInner = 1;
% flagOn = 1;
% flagOut = 1;
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
% % pix = STATS(temp).PixelList;
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
% % finds intensity in inner ROI
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

% % main GUI figure
% guiFig = figure('Resize','off','Units','pixels','Position',[100 200 700 700],'Visible','on','MenuBar','none','name','Density Estimator','NumberTitle','off','UserData',0);
% defaultBackground = get(0,'defaultUicontrolBackgroundColor');
% set(guiFig,'Color',defaultBackground)
% 
% % panel containing popup menus
% menuPanel = uipanel('Parent',guiFig,'Position',[.025 .05 .7 .91]);
% subPan1 = uipanel('Parent',menuPanel,'Title','Channel 1','Position',[.03 .81 .94 .175]);
% subPan2 = uipanel('Parent',menuPanel,'Title','Channel 2','Position',[.03 .61 .94 .175]);
% su% bPan3 = uipanel('Parent',menuPanel,'Title','Channel 3','Position',[.03 .41 .94 .175]);
% su% bPan4 = uipanel('Parent',menuPanel,'Title','Channel 4','Position',[.03 .21 .94 .175]);
% su% bPan5 = uipanel('Parent',menuPanel,'Title','Channel 5','Position',[.03 .01 .94 .175]);
% 
% % popup menus
% men1 = uicontrol('Parent',subPan1,'Style','popupmenu','Units','normalized','Position',[.0002 .87 .5 .05],'String',{'None','Mask/Morphology'},'UserData',[],'Callback',{@popCall1});
% men2 = uicontrol('Parent',subPan2,'Style','popupmenu','Units','normalized','Position',[.0002 .87 .5 .05],'String',{'None','Inner Intensity','Outer Intensity','Outline Intensity','Alignment'},'UserData',[],'Callback',{@popCall2});
% % men3 = uicontrol('Parent',subPan3,'Style','popupmenu','Units','normalized','Position',[.0002 .87 .5 .05],'String',{'None','Inner Intensity','Outer Intensity','Outline Intensity','Alignment'},'UserData',[],'Callback',{@popCall3});
% % men4 = uicontrol('Parent',subPan4,'Style','popupmenu','Units','normalized','Position',[.0002 .87 .5 .05],'String',{'None','Inner Intensity','Outer Intensity','Outline Intensity','Alignment'},'UserData',[],'Callback',{@popCall4});
% % men5 = uicontrol('Parent',subPan5,'Style','popupmenu','Units','normalized','Position',[.0002 .87 .5 .05],'String',{'None','Inner Intensity','Outer Intensity','Outline Intensity','Alignment'},'UserData',[],'Callback',{@popCall5});
% 
% % analysis selection radio buttons
% analButt = uibuttongroup('Parent',guiFig,'Position',[.74 .65 .235 .15],'SelectionChangeFcn',{@analSelect});
% % grangerButt = uicontrol('Style','Radio','String','Timeseries Analysis','Units','Normalized','Position',[.05 .225 .9 .15],'Parent',analButt);
% curveButt = uicontrol('Style','Radio','String','Compare Curves','Units','Normalized','Position',[.05 .625 .9 .15],'Parent',analButt);
% set(analButt,'SelectedObject',[])
% 
% % Panel to contain input boxes
% boxPan = uipanel('Parent',guiFig,'Position',[.74 .05 .235 .575]);
% % ROI size input box
% ROIbox = uicontrol('Parent',boxPan,'Style','edit','Units','normalized','Position',[.15 .75 .7 .1],'BackgroundColor',[1 1 1],'Callback',{@inROI});
% nameBox = uicontrol('Parent',boxPan,'Style','text','String','Enter ROI width in pixels: ','Units','normalized','Position',[.125 .85 .75 .1]);
% 
% % Number of regions input box
% ROInum = uicontrol('Parent',boxPan,'Style','edit','Units','normalized','Position',[.15 .525 .7 .1],'BackgroundColor',[1 1 1],'Callback',{@numROI});
% namenum = uicontrol('Parent',boxPan,'Style','text','String','Enter desired number of ROIs: ','Units','normalized','Position',[.125 .625 .75 .1]);
% 
% % intensity threshold input box
% INTnum = uicontrol('Parent',boxPan,'Style','edit','String','0.05','Units','normalized','Position',[.15 .3 .7 .1],'BackgroundColor',[1 1 1],'Callback',{@numINT});
% nameINT = uicontrol('Parent',boxPan,'Style','text','String','Intensity Threshold (0.05 default)','Units','normalized','Position',[.125 .4 .75 .1]);
% 
% % curvelets threshold input box
% CURVnum = uicontrol('Parent',boxPan,'Style','edit','String','0.001','Units','normalized','Position',[.15 .075 .7 .1],'BackgroundColor',[1 1 1],'Callback',{@numCURV});
% nameCURV = uicontrol('Parent',boxPan,'Style','text','String','Curvelet Coefficient Threshold','Units','normalized','Position',[.125 .175 .75 .1]);
% 
% % boxes and buttons to browse and load files 
% fileBox1 = uicontrol('Parent',subPan1,'Style','edit','String','Load File','BackgroundColor',[1 1 1],'Units','normalized','Position',[.01 .05 .6 .25]);
% fileButt1 = uicontrol('Parent',subPan1,'Style','pushbutton','BackgroundColor',[0 .7 1],'String','Browse','Units','normalized','Position',[.7 .05 .25 .25],'Callback',{@buttCall1});
% 
% fileBox2 = uicontrol('Parent',subPan2,'Style','edit','String','Load File','BackgroundColor',[1 1 1],'Units','normalized','Position',[.01 .05 .6 .25]);
% fileButt2 = uicontrol('Parent',subPan2,'Style','pushbutton','BackgroundColor',[0 .7 1],'String','Browse','Units','normalized','Position',[.7 .05 .25 .25],'Callback',{@buttCall2});
% 
% % fileBox3 = uicontrol('Parent',subPan3,'Style','edit','String','Load File','BackgroundColor',[1 1 1],'Units','normalized','Position',[.01 .05 .6 .25]);
% % fileButt3 = uicontrol('Parent',subPan3,'Style','pushbutton','BackgroundColor',[0 .7 1],'String','Browse','Units','normalized','Position',[.7 .05 .25 .25],'Callback',{@buttCall3});
% 
% % fileBox4 = uicontrol('Parent',subPan4,'Style','edit','String','Load File','BackgroundColor',[1 1 1],'Units','normalized','Position',[.01 .05 .6 .25]);
% % fileButt4 = uicontrol('Parent',subPan4,'Style','pushbutton','BackgroundColor',[0 .7 1],'String','Browse','Units','normalized','Position',[.7 .05 .25 .25],'Callback',{@buttCall4});
% 
% % fileBox5 = uicontrol('Parent',subPan5,'Style','edit','String','Load File','BackgroundColor',[1 1 1],'Units','normalized','Position',[.01 .05 .6 .25]);
% % fileButt5 = uicontrol('Parent',subPan5,'Style','pushbutton','BackgroundColor',[0 .7 1],'String','Browse','Units','normalized','Position',[.7 .05 .25 .25],'Callback',{@buttCall5});
% 
% % name input boxes for each channel
% nameBox1 = uicontrol('Parent',subPan1,'Style','edit','String',' ','BackgroundColor',[1 1 1],'Units','normalized','Position',[.12 .4 .35 .25],'Callback',{@nameCall1});
% nameText1 = uicontrol('Parent',subPan1,'Style','text','String','Name: ','Units','normalized','Position',[.01 .36 .1 .25]);
% nameBox2 = uicontrol('Parent',subPan2,'Style','edit','String',' ','BackgroundColor',[1 1 1],'Units','normalized','Position',[.12 .4 .35 .25],'Callback',{@nameCall2});
% nameText2 = uicontrol('Parent',subPan2,'Style','text','String','Name: ','Units','normalized','Position',[.01 .36 .1 .25]);
% % nameBox3 = uicontrol('Parent',subPan3,'Style','edit','String',' ','BackgroundColor',[1 1 1],'Units','normalized','Position',[.12 .4 .35 .25],'Callback',{@nameCall3});
% % nameText3 = uicontrol('Parent',subPan3,'Style','text','String','Name: ','Units','normalized','Position',[.01 .36 .1 .25]);
% % nameBox4 = uicontrol('Parent',subPan4,'Style','edit','String',' ','BackgroundColor',[1 1 1],'Units','normalized','Position',[.12 .4 .35 .25],'Callback',{@nameCall4});
% % nameText4 = uicontrol('Parent',subPan4,'Style','text','String','Name: ','Units','normalized','Position',[.01 .36 .1 .25]);
% % nameBox5 = uicontrol('Parent',subPan5,'Style','edit','String',' ','BackgroundColor',[1 1 1],'Units','normalized','Position',[.12 .4 .35 .25],'Callback',{@nameCall5});
% % nameText5 = uicontrol('Parent',subPan5,'Style','text','String','Name: ','Units','normalized','Position',[.01 .36 .1 .25]);
% 
% % panel to contain start and reset buttons
% buttBox = uipanel('Parent',guiFig,'Position',[.74 .825 .235 .135]);
% % button to start analysis
% runButt = uicontrol('Parent',buttBox,'Style','pushbutton','String','Run','BackgroundColor',[.2 1 .6],'Units','normalized','Position',[.075 .125 .4 .7],'Callback',{@runProg});
% 
% % reset button
% resetButt = uicontrol('Parent',buttBox,'Style','pushbutton','String','Reset','BackgroundColor',[1 .2 .2],'Units','normalized','Position',[.535 .125 .4 .7],'Callback',{@resetGui});
% 
% % callback function for analysis selection buttons
% 
%     function analSelect(source, eventdata)
%        getButt = get(get(source,'SelectedObject'),'String');
%        set(analButt,'UserData',getButt)
%        if strcmp(getButt,'Compare Curves')
%            set(ROInum,'Enable','off')
%            set(namenum,'Enable','off')
%        elseif strcmp(getButt,'Timeseries Analysis')
%            set(ROInum,'Enable','on')
%            set(namenum,'Enable','on')
%        end
%         
%     end
% % callbacks for browse pushbuttons
% 
%     function buttCall1(fileButt1,eventdata)
%         [fileName,pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.*'});
%         filePath = fullfile(pathName,fileName);
%         set(fileBox1,'String',fileName)
%         set(fileBox1,'UserData',filePath)
%     end
% 
%     function buttCall2(fileButt2,eventdata)
%         [fileName,pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.*'});
%         filePath = fullfile(pathName,fileName);
%         set(fileBox2,'String',fileName)
%         set(fileBox2,'UserData',filePath)
%     end
% 
% %    function buttCall3(fileButt3,eventdata)
% %        [fileName,pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.*'});
% %        filePath = fullfile(pathName,fileName);
% %        set(fileBox3,'String',fileName)
% %        set(fileBox3,'UserData',filePath)
% %    end
% 
% %    function buttCall4(fileButt4,eventdata)
% %        [fileName,pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.*'});
% %        filePath = fullfile(pathName,fileName);
% %        set(fileBox4,'String',fileName)
% %        set(fileBox4,'UserData',filePath)
% %    end
% 
% %    function buttCall5(fileButt5,eventdata)
% %        [fileName,pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.*'});
% %        filePath = fullfile(pathName,fileName);
% %        set(fileBox5,'String',fileName)
% %        set(fileBox5,'UserData',filePath)
% %    end
% 
% % callback functions for name boxes
%     function nameCall1(nameBox1,eventdata)
%         usr_input = get(nameBox1,'String');
%         set(nameBox1,'UserData',usr_input)
%         set(nameBox1,'Enable','off')
%     end
% 
%     function nameCall2(nameBox2,eventdata)
%         usr_input = get(nameBox2,'String');
%         set(nameBox2,'UserData',usr_input)
%         set(nameBox2,'Enable','off')
%     end
% 
% %    function nameCall3(nameBox3,eventdata)
% %        usr_input = get(nameBox3,'String');
% %        set(nameBox3,'UserData',usr_input)
% %        set(nameBox3,'Enable','off')
% %    end
% 
% %    function nameCall4(nameBox4,eventdata)
% %        usr_input = get(nameBox4,'String');
% %        set(nameBox4,'UserData',usr_input)
% %        set(nameBox4,'Enable','off')
% %    end
% 
% %    function nameCall5(nameBox5,eventdata)
% %        usr_input = get(nameBox5,'String');
% %        set(nameBox5,'UserData',usr_input)
% %        set(nameBox5,'Enable','off')
% %    end
% 
% % callback for ROI input box
%     function inROI(ROIbox,eventdata)
%         roi_input = get(ROIbox,'String');
%         set(ROIbox,'UserData',roi_input)
%         set(ROIbox,'Enable','off')
%     end
% 
% % callback for ROI number input box
%     function numROI(ROInum,eventdata)
%         num_input = get(ROInum,'String');
%         set(ROInum,'UserData',num_input);
%         set(ROInum,'Enable','off');
%     end
% 
% % callback for intensity threshold box
%     function numINT(INTnum,eventdata)
%         int_input = get(INTnum,'String');
%         set(INTnum,'UserData',int_input);
%         set(INTnum,'Enable','off');
%     end
% 
% % callback for curvelet threshold box
%     function numCURV(CURVnum,eventdata)
%         curv_input = get(CURVnum,'String');
%         set(CURVnum,'UserData',curv_input);
%         set(CURVnum,'Enable','off');
%     end
% 
% % callbacks for the popupmenus
% 
%     function popCall1(men1,eventdata)
%         str = get(men1,'String');
%         val = get(men1,'Value');
%         switch str{val}
%             case 'None'
%                 set(men1,'UserData',[])
%             case 'Mask/Morphology'
%                 set(men1,'UserData','Mask/Morphology')
%         end
% 
%                
%     end
% 
%     function popCall2(men2,eventdata)
%         str = get(men2,'String');
%         val = get(men2,'Value');
%         switch str{val}
%             case 'None'
%                 set(men2,'UserData',[])
%             case 'Inner Intensity'
%                 set(men2,'UserData','Inner Intensity')
%             case 'Outer Intensity'
%                 set(men2,'UserData','Outer Intensity')
%             case 'Outline Intensity'
%                 set(men2,'UserData','Outline Intensity')
%             case 'Alignment'
%                 set(men2,'UserData','Alignment')
%         end
%                
%     end
% 
%     function popCall3(men3,eventdata)
%         str = get(men3,'String');
%         val = get(men3,'Value');
%         switch str{val}
%             case 'None'
%                 set(men3,'UserData',[])
%             case 'Inner Intensity'
%                 set(men3,'UserData','Inner Intensity')
%             case 'Outer Intensity'
%                 set(men3,'UserData','Outer Intensity')
%             case 'Outline Intensity'
%                 set(men3,'UserData','Outline Intensity')
%             case 'Alignment'
%                 set(men3,'UserData','Alignment')
%         end
%                
%     end
% 
%     function popCall4(men4,eventdata)
%         str = get(men4,'String');
%         val = get(men4,'Value');
%         switch str{val}
%             case 'None'
%                 set(men4,'UserData',[])
%             case 'Inner Intensity'
%                 set(men4,'UserData','Inner Intensity')
%             case 'Outer Intensity'
%                 set(men4,'UserData','Outer Intensity')
%             case 'Outline Intensity'
%                 set(men4,'UserData','Outline Intensity')
%             case 'Alignment'
%                 set(men4,'UserData','Alignment')
%         end
%                
%     end
% 
%     function popCall5(men5,eventdata)
%         str = get(men5,'String');
%         val = get(men5,'Value');
%         switch str{val}
%             case 'None'
%                 set(men5,'UserData',[])
%             case 'Inner Intensity'
%                 set(men5,'UserData','Inner Intensity')
%             case 'Outer Intensity'
%                 set(men5,'UserData','Outer Intensity')
%             case 'Outline Intensity'
%                 set(men5,'UserData','Outline Intensity')
%             case 'Alignment'
%                 set(men5,'UserData','Alignment')
%         end
%                
%     end
% 
% % run button callback function
% % collect channel names, filenames, number of channels, desired analysis. 
% % pass to readTrace.m 
%     function runProg(runButt,eventdata)
%         mens = {men1,men2,men3,men4,men5};
%         titles = {nameBox1,nameBox2,nameBox3,nameBox4,nameBox5};
%         files = {fileBox1,fileBox2,fileBox3,fileBox4,fileBox5};
%         tempFolder = uigetdir(' ','Select Output Directory:');
%         
%         for aa = 1:5
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
%         
%         locs = find(chans);
%         num = sum(chans);
%         
%         for bb = 1:length(locs)
%             name{bb} = names{locs(bb)};
%             path{bb} = paths{locs(bb)};
%             analy{bb} = anals{locs(bb)};
%         end
%         ROI = str2double(get(ROIbox,'UserData'));
%         numR = str2double(get(ROInum,'UserData'));
%         intT = str2double(get(INTnum,'UserData'));
%         if isnan(intT)
%             intT = 0.05;
%         end
%         curvT = str2double(get(CURVnum,'UserData'));
%         if isnan(curvT)
%             curvT = 0.001;
%         end
%         
%         isOn = get(analButt,'UserData');
%         switch isOn
%             case 'Compare Curves'
%                 readTrace(num,name,path,analy,tempFolder,intT,curvT,ROI);
%             case 'Timeseries Analysis'
%                 readTrace(num,name,path,analy,tempFolder,intT,curvT,ROI,numR); 
%         end
%     end
% 
% % reset button callback function    
%     function resetGui(resetButt,eventdata)
%         clear all
%         close all
%         densityEestimation
%     end
% 
% end
