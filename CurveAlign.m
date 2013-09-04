function CurveAlign

% CurveAlign.m - Curvelet transform wrapper for collagen alignment
% analysis.
%
% Inputs
%   Batch-mode  Allows the user to process a directory of images
%   Images      tif or jpg images to be processed
%   Keep        keep the largest X% of the curvelet coefficients
%   Dist        Distance from the boundary to use in analysis
%   Outputs     Checkboxes for selecting outputs
%
% Optional Inputs
%   Boundary    To create a boundary, hold down the 'alt' key
%               and use the mouse to select the endpoints or load a  
%               boundary csv file.
%
% Outputs
%   CSV files   hist.csv = histogram
%               stats.csv = statistical analysis summary
%               values.csv = list of angles for each curvelet coefficient
%
%   Images      overlay.tiff = curvelets overlayed on image
%               rawmap.tiff = curvelet angles mapped to grey level
%               procmap.tiff = processed map image
%               reconstructed.tiff = reconstruction of the thresholded
%               curvelet coefficients
% 
%
% By Jeremy Bredfeldt and Carolyn Pehlke Laboratory for Optical and
% Computational Instrumentation 2013

% ----Change Log--------------------------------------------
% JB Sept 2012
% Made windows modular so we can now resize the image and results windows. This helps
% with selecting the proper boundary points and seeing the results.
% Added new pointer for selecting points on the images, shows up when alt key is pressed.
% Added distance from boundary evaluation and new overlay output, showing
% which curvelets are considered in the measurement.

% JB Nov 2012
% Added functionality for stacks, removed multi-image selection (would like
% to put this back eventually)
% Added map output to get an understanding of the spacial grouping of
% aligned curvelets

% JB Feb 2013
% Added batch mode to process all images and/or boundaries in a folder
% Added tif boundary mode to allow the boundary to be a mask tif file.
% Added option to use output from FIRE as the input to the fiber analysis algorithm

% To deploy this:
% 1. type mcc -m CurveAlign.m -R '-startmsg,"Starting_Curve_Align"' at
% the matlab command prompt

%clc;
clear all;
close all;

addpath('./CircStat2012a','./CurveLab-2.1.2/fdct_wrapping_matlab');

global imgName

P = NaN*ones(16,16);
P(1:15,1:15) = 2*ones(15,15);
P(2:14,2:14) = ones(13,13);
P(3:13,3:13) = NaN*ones(11,11);
P(6:10,6:10) = 2*ones(5,5);
P(7:9,7:9) = 1*ones(3,3);

guiCtrl = figure('Resize','on','Units','pixels','Position',[25 75 300 650],'Visible','off','MenuBar','none','name','CurveAlign V2.2','NumberTitle','off','UserData',0);
guiFig = figure('Resize','on','Units','pixels','Position',[340 125 600 600],'Visible','off','MenuBar','none','name','CurveAlign Figure','NumberTitle','off','UserData',0);
guiRecon = figure('Resize','on','Units','pixels','Position',[340 415 300 300],'Visible','off','MenuBar','none','name','CurveAlign Reconstruction','NumberTitle','off','UserData',0);
guiHist = figure('Resize','on','Units','pixels','Position',[340 105 600 600],'Visible','off','MenuBar','none','name','CurveAlign Histogram','NumberTitle','off','UserData',0);
guiCompass = figure('Resize','on','Units','pixels','Position',[340 405 300 300],'Visible','off','MenuBar','none','name','CurveAlign Compass','NumberTitle','off','UserData',0);
guiTable = figure('Resize','on','Units','pixels','Position',[340 395 450 300],'Visible','off','MenuBar','none','name','CurveAlign Results Table','NumberTitle','off','UserData',0);

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiFig,'Color',defaultBackground);
set(guiRecon,'Color',defaultBackground);
set(guiHist,'Color',defaultBackground);
set(guiCompass,'Color',defaultBackground);
set(guiTable,'Color',defaultBackground);

set(guiCtrl,'Visible','on');
%set(guiFig,'Visible','on');
%set(guiRecon,'Visible','on');
%set(guiHist,'Visible','on');
%set(guiCompass,'Visible','on');
%set(guiTable,'Visible','on');

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);

reconPanel = uipanel('Parent',guiRecon,'Units','normalized','Position',[0 0 1 1]);
reconAx = axes('Parent',reconPanel,'Units','normalized','Position',[0 0 1 1]);

histPanel = axes('Parent',guiHist);

compassPanel = axes('Parent',guiCompass);

valuePanel = uitable('Parent',guiTable,'ColumnName','Angles','Units','normalized','Position',[0 0 .35 1]);
rowN = {'Mean','Median','Variance','Std Dev','Coef of Alignment','Skewness','Kurtosis','Omni Test','red pixels','yellow pixels','green pixels','evaluated pixels'};
statPanel = uitable('Parent',guiTable,'RowName',rowN,'Units','normalized','Position',[.35 0 .65 1]);

%checkbox for batch mode option
batchModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Batch-mode','Min',0,'Max',3,'Units','normalized','Position',[.0 .93 .5 .1]);

% button to select an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Images','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[0 .85 .5 .1],'callback','ClickedCallback','Callback', {@getFile});

% button to select a boundary in a .csv file
loadBoundary = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Boundary','FontUnits','normalized','FontSize',.25,'UserData',[],'Units','normalized','Position',[.5 .85 .5 .1],'callback','ClickedCallback','Callback', {@boundIn});

% button to run measurement
imgRun = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[0 .75 .5 .1]);

% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.5 .75 .5 .1],'callback','ClickedCallback','Callback',{@resetImg});

% text box for taking in curvelet threshold "keep"
keepLab1 = uicontrol('Parent',guiCtrl,'Style','text','String','Enter % of coefs to keep, as decimal:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .50 .75 .1]);
keepLab2 = uicontrol('Parent',guiCtrl,'Style','text','String','(default is .001)','FontUnits','normalized','FontSize',.15,'Units','normalized','Position',[0.25 .475 .3 .1]);
enterKeep = uicontrol('Parent',guiCtrl,'Style','edit','String','.001','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.75 .55 .25 .05],'Callback',{@get_textbox_data});

distLab = uicontrol('Parent',guiCtrl,'Style','text','String','Enter distance from boundary to evaluate, in pixels:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .425 .75 .1]);
enterDistThresh = uicontrol('Parent',guiCtrl,'Style','edit','String','100','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.75 .475 .25 .05],'Callback',{@get_textbox_data2});

% panel to contain output checkboxes
guiPanel = uipanel('Parent',guiCtrl,'Title','Select Output: ','Units','normalized','Position',[0 .2 1 .225]);

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Reconstructed Image','Min',0,'Max',3,'Units','normalized','Position',[.075 .8 .8 .1]);

% checkbox to display a histogram
makeHist = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .65 .8 .1]);

% checkbox to display a compass plot
makeCompass = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Compass Plot','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .5 .8 .1]);

% checkbox to output list of values
makeValues = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .35 .8 .1]);

% checkbox to show curvelet boundary associations
makeAssoc = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Bdry Assoc','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .2 .8 .1]);

% checkbox to process whole stack
wholeStack = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Whole Stack','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .05 .8 .1]);

% listbox containing names of active files
%listLab = uicontrol('Parent',guiCtrl,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[0 .6 1 .1]);
%imgList = uicontrol('Parent',guiCtrl,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[0 .425 1 .25]);
% slider for scrolling through stacks
slideLab = uicontrol('Parent',guiCtrl,'Style','text','String','Stack image selected:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .64 .75 .1]);
stackSlide = uicontrol('Parent',guiCtrl,'Style','slide','Units','normalized','position',[0 .62 1 .1],'min',1,'max',100,'val',1,'SliderStep', [.1 .2],'Enable','off');

infoLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Click Get Images button.','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .05 .75 .1]);

% set font
set([guiPanel keepLab1 keepLab2 distLab infoLabel enterKeep enterDistThresh makeCompass makeValues makeRecon  makeHist makeAssoc wholeStack imgOpen imgRun imgReset loadBoundary slideLab],'FontName','FixedWidth')
set([keepLab1 keepLab2 distLab],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset loadBoundary],'FontWeight','bold')
set([keepLab1 keepLab2 distLab slideLab infoLabel],'HorizontalAlignment','left')

%initialize gui
set([imgRun makeHist makeRecon enterKeep enterDistThresh makeValues makeCompass loadBoundary],'Enable','off')
set([makeRecon makeHist makeCompass makeValues wholeStack],'Value',3)
%set(guiFig,'Visible','on')

% initialize variables used in some callback functions
coords = [-1000 -1000];
aa = 1;
imgSize = [0 0];
rows = [];
cols = [];
ff = '';
numSections = 0;
info = [];

%--------------------------------------------------------------------------
% callback function for imgOpen
    function getFile(imgOpen,eventdata)
        
        if (get(batchModeChk,'Value') == get(batchModeChk,'Max'))
            %start batch mode
            batch_curveAlign(infoLabel);
            CurveAlign
        else
        
            [fileName pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg';'*.*'},'Select Image','MultiSelect','off');

            %What to do if the image is a stack? How should the interface be designed?
            % Just display first image of stack, but process all images in stack?
            % Should all image histograms be included together or separate? -Separate 
            % What about the boundary files?
            %   Use one boundary file per stack, or one per image in the stack? -Either
            % Should try to stack up output images if possible, but display one at a
            % time
            % Put each output into a different line in the output file for stats,
            % compass, values
            ff = fullfile(pathName,fileName);        
            info = imfinfo(ff);
            numSections = numel(info);

            if numSections > 1
                img = imread(ff,1,'Info',info);            
                set(stackSlide,'max',numSections);
                set(stackSlide,'Enable','on');
                set(wholeStack,'Enable','on');
                set(stackSlide,'SliderStep',[1/(numSections-1) 3/(numSections-1)]);
                set(stackSlide,'Callback',{@slider_chng_img});
                set(slideLab,'String','Stack image selected: 1');
            else
                img = imread(ff);
            end

            if size(img,3) > 1
                %if rgb, pick one color
                img = img(:,:,1);
            end
            figure(guiFig);
            img = imadjust(img);
            imshow(img,'Parent',imgAx);
            imgSize = size(img);
            %displayImg(img,imgPanel)

            %files = {fileName};
            setappdata(imgOpen,'img',img);
            %info = imfinfo(ff);
            imgType = strcat('.',info(1).Format);
            imgName = getFileName(imgType,fileName);
            setappdata(imgOpen,'type',info(1).Format)
            colormap(gray);

            set([keepLab1 keepLab2 distLab],'ForegroundColor',[0 0 0])
            set(guiFig,'UserData',0)

            if ~get(guiFig,'UserData')
                set(guiFig,'WindowKeyPressFcn',@startPoint)
                coords = [-1000 -1000];
                aa = 1;
            end

            %set(imgList,'String',files)
            %set(imgList,'Callback',{@showImg})
            set(imgRun,'Callback',{@runMeasure});
            set([makeRecon makeHist makeCompass makeValues imgRun loadBoundary enterKeep],'Enable','on');
            set(imgOpen,'Enable','off');
            set(guiFig,'Visible','on');                

            set(infoLabel,'String','Alt-click a boundary, browse to a boundary file, or click run for no boundary analysis.');

            %set(t1,'Title','Image')
        end

    end
%--------------------------------------------------------------------------
% callback function for stack slider
    function slider_chng_img(hObject,eventdata)
        idx = round(get(hObject,'Value'));
        img = imread(ff,idx,'Info',info);
        set(imgAx,'NextPlot','new');
        img = imadjust(img);
        imshow(img,'Parent',imgAx);
        set(imgAx,'NextPlot','add');      
        if ~isempty(coords) %if there is a boundary, draw it now
            plot(imgAx,coords(:,1),coords(:,2),'r');
            plot(imgAx,coords(:,1),coords(:,2),'*y');
        end
        setappdata(imgOpen,'img',img);
        
        set(slideLab,'String',['Stack image selected: ' num2str(idx)]);
    end

%--------------------------------------------------------------------------
% callback function for enterKeep text box
    function get_textbox_data(enterKeep,eventdata)
        usr_input = get(enterKeep,'String');
        usr_input = str2double(usr_input);
        set(enterKeep,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% callback function for enterDistThresh text box
    function get_textbox_data2(enterDistThresh,eventdata)
        usr_input = get(enterDistThresh,'String');
        usr_input = str2double(usr_input);
        set(enterDistThresh,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% callback function for loadBoundary button
    function boundIn(loadBoundary,eventdata)
        [fileName,pathName] = uigetfile('*.csv','Select file containing boundary points: ');
        inName = fullfile(pathName,fileName);
        set(loadBoundary,'UserData',1);
        setappdata(guiFig,'boundary',1);
        set([enterKeep enterDistThresh imgRun makeHist makeRecon makeValues makeCompass],'Enable','On');
        coords = csvread(inName);
        hold(imgAx); 
        plot(imgAx,coords(:,1),coords(:,2),'r');
        plot(imgAx,coords(:,1),coords(:,2),'*y');
        set(makeAssoc,'Enable','on');
        set(enterDistThresh,'Enable','on');
        %hold off
        %set(loadBoundary,'Enable','Off');        
    end
    
%--------------------------------------------------------------------------
% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        tempFolder = uigetdir(' ','Select Output Directory:');
        IMG = getappdata(imgOpen,'img');
        keep = get(enterKeep,'UserData');
        distThresh = get(enterDistThresh,'UserData');
        %reconPanel = uipanel(t3,'Units','normalized','Position',[0 0 1 1]);
        %boundingbox = get(tabGroup,'Position');
        %width = boundingbox(3);
        %height = boundingbox(4);
                    
        set([imgRun makeHist makeRecon wholeStack enterKeep enterDistThresh imgOpen loadBoundary makeCompass makeValues makeAssoc],'Enable','off')
        
        if isempty(keep)
            %indicates the % of curvelets to process (after sorting by
            %coefficient value)
            keep = .001;
        end
        
        if isempty(distThresh)
            %this is default and is in pixels
            distThresh = 100;
        end        
        
        if get(loadBoundary,'UserData')
            setappdata(guiFig,'boundary',1)
        elseif ~get(guiFig,'UserData')
            coords = [];
        else
            [fileName,pathName] = uiputfile('*.csv','Specify output file for boundary coordinates:');
            fName = fullfile(pathName,fileName);
            csvwrite(fName,coords);
        end
                
        %check if user directed to output boundary association lines (where
        %on the boundary the curvelet is being compared)
        makeAssocFlag = get(makeAssoc,'Value') == get(makeAssoc,'Max');
        
        %check to see if we should process the whole stack or current image
        wholeStackFlag = get(wholeStack,'Value') == get(wholeStack,'Max');
        if ~wholeStackFlag
            %force numSections to be 1
            numSections = 1;
            %read the currently selected image
        end
                               
        %loop through all sections if image is a stack
        for i = 1:numSections                                    
            if numSections > 1  
                IMG = imread(ff,i,'Info',info);
                set(stackSlide,'Value',i);
                slider_chng_img(stackSlide,0);
            end
            
            [histData,recon,comps,values,dist,stats,map] = processImage(IMG,imgName,tempFolder,keep,coords,distThresh,makeAssocFlag,i,infoLabel,0,0,[]);
            h = histData'; r = recon; c = comps; v = values; s = stats;
            
            if infoLabel, set(infoLabel,'String','Plotting histogram.'); end
            if (get(makeHist,'Value') == get(makeHist,'Max'))
                %set(guiHist,'Title','Histogram')
                set(makeHist,'UserData',1)
                setappdata(makeHist,'data',histData) 
                x = h(1,:);
                n = h(2,:);           
                bar(x,n,'Parent',histPanel)
                if ~isempty(coords)
                    xlim(histPanel,[0 90]);
                else
                    xlim(histPanel,[0 180]);
                end
                set(guiHist,'Visible','on');
            end
            
            if infoLabel, set(infoLabel,'String','Plotting reconstruction.'); end
            if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                %set(guiRecon,'Title','Reconstruction')
                set(makeRecon,'UserData',1)
                setappdata(makeRecon,'data',recon)
                %displayImg(r,reconPanel)
                imshow(r,'Parent',reconAx);
                set(guiRecon,'Visible','on');
            end
            
            if infoLabel, set(infoLabel,'String','Plotting compass graph.'); end
            if (get(makeCompass,'Value') == get(makeCompass,'Max'))
                %set(t4,'Title','Compass Plot')
                set(makeCompass,'Userdata',1)
                setappdata(makeCompass,'data',comps)
                U = c(1,:);
                V = c(2,:);
                compass(compassPanel,U,V)
                set(guiCompass,'Visible','on');
            end
            
            if infoLabel, set(infoLabel,'String','Displaying spreadsheet.'); end
            if(get(makeValues,'Value') == get(makeValues,'Max'))
                %set(guiTable,'Title','Values')
                set(makeValues,'Userdata',1)
                setappdata(makeValues,'data',values)
                setappdata(makeValues,'stats',stats)
                set(valuePanel,'Data',v)
                set(statPanel,'Data',s)
                set(guiTable,'Visible','on');
            end

            %set(enterKeep,'String',[])
            set([keepLab1 keepLab2 distLab],'ForegroundColor',[.5 .5 .5])
            %set([makeRecon makeHist,makeValues makeCompass],'Value',0)

            
        end
        if infoLabel, set(infoLabel,'String','Done. Click Reset to start over.'); end
        
    end            
%--------------------------------------------------------------------------
% keypress function for the main gui window
    function startPoint(guiFig,evnt)
        if strcmp(evnt.Key,'alt')
        
            set(guiFig,'WindowKeyReleaseFcn',@stopPoint)
            set(guiFig,'WindowButtonDownFcn',@getPoint)
            set(guiFig,'Pointer','custom','PointerShapeCData',P,'PointerShapeHotSpot',[8,8]);
                      
        end
    end
    
%--------------------------------------------------------------------------
% boundary creation function that records the user's mouse clicks while the
% alt key is being held down
    function getPoint(guiFig,evnt2)
       
       figSize = get(guiFig,'Position');
       aspectImg = imgSize(2)/imgSize(1); %horiz/vert
       aspectFig = figSize(3)/figSize(4); %horiz/vert
       if aspectImg < aspectFig
           %vert limiting dimension
           scaleImg = figSize(4)/imgSize(1);
           vertOffset = 0;
           horizOffset = round((figSize(3) - scaleImg*imgSize(2))/2);
       else
           %horiz limiting dimension
           scaleImg = figSize(3)/imgSize(2);
           vertOffset = round((figSize(4) - scaleImg*imgSize(1))/2);
           horizOffset = 0;           
       end
       
       if ~get(guiFig,'UserData') 
           coords(aa,:) = get(guiFig,'CurrentPoint')
           %convert the selected point from guiFig coords to actual image
           %coordinages
           curRow = round((figSize(4)-(coords(aa,2) + vertOffset))/scaleImg)
           curCol = round((coords(aa,1) - horizOffset)/scaleImg)
           rows(aa) = curRow;
           cols(aa) = curCol;
           aa = aa + 1;

           figure(guiFig);
           hold on;
           ca = get(guiFig,'CurrentAxes');
           plot(ca,cols,rows,'r');
           plot(ca,cols,rows,'*y');
           %plot(ca,50,50,'r');
           %plot(ca,50,50,'*y');
           
           setappdata(guiFig,'rows',rows);
           setappdata(guiFig,'cols',cols);
       end
    end

%--------------------------------------------------------------------------
% terminates boundary creation when the alt key is released
    function stopPoint(guiFig,evnt4)
            
            set(guiFig,'UserData',1)
            set(guiFig,'WindowButtonUpFcn',[]) 
            set(guiFig,'WindowKeyPressFcn',[])
            setappdata(guiFig,'boundary',1)
            coords(:,2) = getappdata(guiFig,'rows');
            coords(:,1) = getappdata(guiFig,'cols');
            set([enterKeep enterDistThresh makeValues makeHist makeRecon],'Enable','on')
            set(guiFig,'Pointer','default');
            set(makeAssoc,'Enable','on');
            set(enterDistThresh,'Enable','on');
    
    end

%--------------------------------------------------------------------------
% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        CurveAlign
    end

end    