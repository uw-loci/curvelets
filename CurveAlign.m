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

% To deploy this:
% 1. type mcc -m CurveAlign.m -R '-startmsg,"Starting_Curve_Align Beta V3.0"' at
% the matlab command prompt

clc;
clear all;
close all;

if ~isdeployed
    addpath('./CircStat2012a','./CurveLab-2.1.2/fdct_wrapping_matlab');
end

global imgName
global ssU   % screen size of the user's display
global OS    % mac or mc operating system

OS = 1; % 1: windows; 0: MAC

set(0,'units','pixels')
ssU = get(0,'screensize');

if exist('lastParams.mat','file')
    %use parameters from the last run of curveAlign
    lastParamsGlobal = load('lastParams.mat');
    pathNameGlobal = lastParamsGlobal.pathNameGlobal;
    if isequal(pathNameGlobal,0)
        pathNameGlobal = '';
    end
    keepValGlobal = lastParamsGlobal.keepValGlobal;
    if isempty(keepValGlobal)
        keepValGlobal = 0.001;
    end
    distValGlobal = lastParamsGlobal.distValGlobal;
    if isempty(distValGlobal)
        distValGlobal = 100;
    end
else
    %use default parameters
    pathNameGlobal = '';
    keepValGlobal = 0.001;
    distValGlobal = 100;
end

P = NaN*ones(16,16);
P(1:15,1:15) = 2*ones(15,15);
P(2:14,2:14) = ones(13,13);
P(3:13,3:13) = NaN*ones(11,11);
P(6:10,6:10) = 2*ones(5,5);
P(7:9,7:9) = 1*ones(3,3);

guiCtrl = figure('Resize','on','Units','pixels','Position',[50 75 500 650],'Visible','off','MenuBar','none','name','CurveAlign Beta V3.0','NumberTitle','off','UserData',0);
guiFig = figure('Resize','on','Units','pixels','Position',[525 125 600 600],'Visible','off','MenuBar','none','name','CurveAlign Figure','NumberTitle','off','UserData',0);

guiRank1 = figure('Resize','on','Units','normalized','Position',[0.30 0.35 0.78*ssU(4)/ssU(3) 0.55],'Visible','off','MenuBar','none','name','CA Features List','NumberTitle','off','UserData',0);
guiRank2 = figure('Resize','on','Units','normalized','Position',[0.75 0.50 0.65*ssU(4)/ssU(3) 0.48],'Visible','off','MenuBar','none','name','Feature Normalized Difference (Pos-Neg)','NumberTitle','off','UserData',0);
guiRank3 = figure('Resize','on','Units','normalized','Position',[0.75 0.02 0.65*ssU(4)/ssU(3) 0.48],'Visible','off','MenuBar','none','name','Feature Classification Importance','NumberTitle','off','UserData',0);


defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiFig,'Color',defaultBackground);
set(guiRank1,'Color',defaultBackground);
set(guiRank2,'Color',defaultBackground);
set(guiRank3,'Color',defaultBackground);

set(guiCtrl,'Visible','on');

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);

%Label for fiber mode drop down
fibModeLabel = uicontrol('Parent',guiCtrl,'Style','text','String','- Fiber analysis method',...
    'HorizontalAlignment','left','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0.5 .88 .5 .1]);
%drop down box for fiber analysis mode selection (CT-FIRE requires input data from CT-FIRE program)
fibModeDrop = uicontrol('Parent',guiCtrl,'Style','popupmenu','Enable','on','String',{'CT','CT-FIRE Segments','CT-FIRE Fibers','CT-FIRE Endpoints'},...
    'Units','normalized','Position',[.0 .88 .5 .1],'Callback',{@fibModeCallback});

%Label for boundary mode drop down
bndryModeLabel = uicontrol('Parent',guiCtrl,'Style','text','String','- Boundary method',...
    'HorizontalAlignment','left','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0.5 .82 .5 .1]);
%boundary mode drop down box, allows user to select which type of boundary analysis to do
bndryModeDrop = uicontrol('Parent',guiCtrl,'Style','popupmenu','Enable','on','String',{'No Boundary','Draw Boundary','CSV Boundary','Tiff Boundary'},...
    'Units','normalized','Position',[.0 .82 .5 .1],'Callback',{@bndryModeCallback});

%checkbox for batch mode option
%batchModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Batch-mode','Min',0,'Max',3,'Units','normalized','Position',[.0 .93 .5 .1]);

% button to select an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Image(s)','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .78 .3 .05],'callback','ClickedCallback','Callback', {@getFile});
imgLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[.3 .72 .5 .1]);

% button to select a boundary file
%loadBoundary = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get CSV','FontUnits','normalized','FontSize',.4,'UserData',[],'Units','normalized','Position',[.0 .76 .3 .05],'callback','ClickedCallback','Callback', {@boundIn});
%boundLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','Enable','off','HorizontalAlignment','left','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[.3 .70 .5 .1]);

%% feature ranking button
% button to process an output feature mat files
fRanking = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Feature Ranking',...
    'FontUnits','normalized','FontSize',.4,'UserData',[],'Units','normalized','Position',[.65 .78 .3 .05],...
    'callback','ClickedCallback','Callback', {@featR});

% button to run measurement
imgRun = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[0 .0 .5 .05]);

% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[.5 .0 .5 .05],'callback','ClickedCallback','Callback',{@resetImg});

% text box for taking in curvelet threshold "keep"
keepLab1 = uicontrol('Parent',guiCtrl,'Style','text','String','Enter fraction of coefs to keep, as decimal:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .50 .75 .1]);
keepLab2 = uicontrol('Parent',guiCtrl,'Style','text','String',' (default is .001)','FontUnits','normalized','FontSize',.15,'Units','normalized','Position',[0.25 .475 .3 .1]);
enterKeep = uicontrol('Parent',guiCtrl,'Style','edit','String',num2str(keepValGlobal),'BackgroundColor','w','Min',0,'Max',1,'UserData',[keepValGlobal],'Units','normalized','Position',[.75 .55 .25 .05],'Callback',{@get_textbox_data});

distLab = uicontrol('Parent',guiCtrl,'Style','text','String','Enter distance from boundary to evaluate, in pixels:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .425 .75 .1]);
enterDistThresh = uicontrol('Parent',guiCtrl,'Style','edit','String',num2str(distValGlobal),'BackgroundColor','w','Min',0,'Max',1,'UserData',[distValGlobal],'Units','normalized','Position',[.75 .475 .25 .05],'Callback',{@get_textbox_data2});

% panel to contain output checkboxes
guiPanel = uipanel('Parent',guiCtrl,'Title','Select Output Options: ','Units','normalized','Position',[0 .2 1 .225]);

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Reconstructed Image','Min',0,'Max',3,'Units','normalized','Position',[.075 .8 .8 .1]);

% checkbox to display a histogram
makeHist = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .65 .8 .1]);

% checkbox to output list of values
makeValues = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .5 .8 .1]);

% checkbox to show curvelet boundary associations
makeAssoc = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Bdry Assoc','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .35 .8 .1]);

% checkbox to create a feature output file
makeFeat = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Feature List','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.6 .8 .8 .1]);

% checkbox to create an overlay image
makeOver = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Overlay Output','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.6 .65 .8 .1]);

% checkbox to create a map image
makeMap = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','off','String','Map Output','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.6 .5 .8 .1]);


% listbox containing names of active files
%listLab = uicontrol('Parent',guiCtrl,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[0 .6 1 .1]);
%imgList = uicontrol('Parent',guiCtrl,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[0 .425 1 .25]);
% slider for scrolling through stacks
slideLab = uicontrol('Parent',guiCtrl,'Style','text','String','Stack image selected:','Enable','off','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .64 .75 .1]);
stackSlide = uicontrol('Parent',guiCtrl,'Style','slide','Units','normalized','position',[0 .62 1 .1],'min',1,'max',100,'val',1,'SliderStep', [.1 .2],'Enable','off');

infoLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Choose methods, then click Get Image(s) button; Or Click Feature Ranking for ranking CA extracted features.','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .1 .9 .1],'BackgroundColor','g');

% set font
set([guiPanel keepLab1 keepLab2 distLab infoLabel enterKeep enterDistThresh makeValues makeRecon makeHist makeAssoc imgOpen fRanking imgRun imgReset slideLab],'FontName','FixedWidth')
set([keepLab1 keepLab2 distLab],'ForegroundColor',[.5 .5 .5])
set([imgOpen fRanking imgRun imgReset],'FontWeight','bold')
set([keepLab1 keepLab2 distLab slideLab infoLabel],'HorizontalAlignment','left')


%initialize gui
set([imgRun makeHist makeRecon enterKeep enterDistThresh makeValues],'Enable','off')
set([makeRecon makeHist makeValues],'Value',3)
%set(guiFig,'Visible','on')

% initialize variables used in some callback functions
coords = [-1000 -1000];
aa = 1;
imgSize = [0 0];
rows = [];
cols = [];
ff = '';
pathName = '';
fileName = '';
bndryFnd = '';
ctfFnd = '';
numSections = 0;
info = [];

%global flags, indicating the method chosen by the user
fibMode = 0;
bndryMode = 0;

%text for the info box to help guide the user.
note1 = 'Click Get Image(s). ';
note2 = 'CT-FIRE file(s) must be in same dir as images. ';
note3T = 'Tiff ';
note3C = 'CSV ';
note3 = 'boundary files must be in same dir as images and conform to naming convention. See users guide. ';

%--------------------------------------------------------------------------
% callback function for fiber analysis mode drop down
    function fibModeCallback(source,eventdata)
        str = get(source,'String');
        val = get(source,'Value');
        switch str{val};
            case 'CT'
                set(infoLabel,'String',note1);
                set(bndryModeDrop,'String',{'No Boundary','Draw Boundary','CSV Boundary','Tiff Boundary'});
                set(bndryModeDrop,'Value',1);
                fibMode = 0;
                bndryModeCallback(bndryModeDrop,0);
            case 'CT-FIRE Segments'
                set(infoLabel,'String',[note1 note2]);
                set(bndryModeDrop,'String',{'No Boundary','Tiff Boundary'});
                set(bndryModeDrop,'Value',1);
                fibMode = 1;
                bndryModeCallback(bndryModeDrop,0);
            case 'CT-FIRE Fibers'
                set(infoLabel,'String',[note1 note2]);
                set(bndryModeDrop,'String',{'No Boundary','Tiff Boundary'});
                set(bndryModeDrop,'Value',1);
                fibMode = 2;
                bndryModeCallback(bndryModeDrop,0);
            case 'CT-FIRE Endpoints'
                set(infoLabel,'String',[note1 note2]);
                set(bndryModeDrop,'String',{'No Boundary','Tiff Boundary'});
                set(bndryModeDrop,'Value',1);
                fibMode = 3;
                bndryModeCallback(bndryModeDrop,0);
        end
    end

%--------------------------------------------------------------------------
% callback function for boundary mode drop down
    function bndryModeCallback(source,eventdata)
        str = get(source,'String');
        val = get(source,'Value');
        switch str{val};
            case 'No Boundary'
                if fibMode == 0
                    set(infoLabel,'String',[note1]);
                else
                    set(infoLabel,'String',[note1 note2]);
                end
                bndryMode = 0;
            case 'Draw Boundary'
                if fibMode == 0
                    set(infoLabel,'String',[note1]);
                else
                    set(infoLabel,'String',[note1 note2]);
                end
                bndryMode = 1;
            case 'CSV Boundary'
                if fibMode == 0
                    set(infoLabel,'String',[note1 note3C note3]);
                else
                    set(infoLabel,'String',[note1 note2 note3c note3]);
                end
                bndryMode = 2;
            case 'Tiff Boundary'
                if fibMode == 0
                    set(infoLabel,'String',[note1 note3T note3]);
                else
                    set(infoLabel,'String',[note1 note2 note3T note3]);
                end
                bndryMode = 3;
        end
    end
%--------------------------------------------------------------------------
% callback function for imgOpen
    function getFile(imgOpen,eventdata)
        
        [fileName pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg';'*.*'},'Select Image',pathNameGlobal,'MultiSelect','on');
        
        if isequal(pathName,0)
            return;
        end
        
        pathNameGlobal = pathName;
        save('lastParams.mat','pathNameGlobal','keepValGlobal','distValGlobal');
        
        %What to do if the image is a stack? How should the interface be designed?
        % Just display first image of stack, but process all images in stack?
        % Should all image histograms be included together or separate? -Separate
        % What about the boundary files?
        %   Use one boundary file per stack, or one per image in the stack? -Either
        % Should try to stack up output images if possible, but display one at a
        % time
        % Put each output into a different line in the output file for stats,
        % compass, values
        
        if iscell(fileName) %check if multiple files were selected
            numFiles = length(fileName);
            set(imgLabel,'String',[num2str(numFiles) ' files selected.']);
            %do not open any files for viewing
            
            %do not allow boundary drawing in batch mode
            if fibMode == 0 && bndryMode == 1 %CT only mode, and draw boundary
                disp('Cannot draw boundaries in batch mode.');
                set(infoLabel,'String','Cannot draw boundaries in batch mode.');
                return;
            end
            
        else
            numFiles = 1;
            set(imgLabel,'String',fileName);
            %open file for viewing
            
            ff = fullfile(pathName,fileName);
            info = imfinfo(ff);
            numSections = numel(info);
            
            if numSections > 1
                img = imread(ff,1,'Info',info);
                set(stackSlide,'max',numSections);
                set(stackSlide,'Enable','on');
                %                 set(wholeStack,'Enable','on');
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
            
            %files = {fileName};
            setappdata(imgOpen,'img',img);
            setappdata(imgOpen,'type',info(1).Format)
            colormap(gray);
            
            set(guiFig,'UserData',0)
            
            if ~get(guiFig,'UserData')
                set(guiFig,'WindowKeyPressFcn',@startPoint)
                coords = [-1000 -1000];
                aa = 1;
            end
            set(guiFig,'Visible','on');
            
            %Make filename to be a CELL array,
            % makes handling filenames more general, saves code.
            fileName = {fileName};
        end
        
        
        %Give instructions about what to do next
        if fibMode == 0
            %CT only mode
            set(infoLabel,'String','Enter a coefficient threshold in the "keep" edit box. ');
            set([keepLab1 keepLab2],'ForegroundColor',[0 0 0])
            set(enterKeep,'Enable','on');
        else
            %CT-FIRE mode (in this mode, CT-FIRE output files must be present)
            ctfFnd = checkCTFireFiles(pathName, fileName);
            if (~isempty(ctfFnd))
                set(infoLabel,'String','');
            else
                set(infoLabel,'String','One or more CT-FIRE files are missing.');
                return;
            end
            
        end
        str = get(infoLabel,'String'); %store whatever is the message so far, so we can add to it
        
        if bndryMode == 1
            %Alt click a boundary
            set(enterDistThresh,'Enable','on');
            set(infoLabel,'String',[str 'Alt-click a boundary. Enter distance value. Click Run.']);
        elseif bndryMode == 2 || bndryMode == 3
            %check to make sure the proper boundary files exist
            bndryFnd = checkBndryFiles(bndryMode, pathName, fileName);
            if (~isempty(bndryFnd))
                %Found all boundary files
                set(enterDistThresh,'Enable','on');
                set(infoLabel,'String',[str 'Enter distance value. Click Run.']);
                set(makeAssoc,'Enable','on');
            else
                %Missing one or more boundary files
                set(infoLabel,'String',[str 'One or more boundary files are missing.']);
                return;
            end
        else
            %boundary mode = 0, no boundary
            set(infoLabel,'String',[str 'Click Run.']);
        end
        
        set(imgRun,'Callback',{@runMeasure});
        set(imgOpen,'Enable','off');
        set(fRanking,'Enable','off');
        
        set([makeRecon makeHist makeValues makeFeat makeOver makeMap imgRun],'Enable','on');
        set([makeRecon makeHist makeValues],'Enable','off') % yl,default output
        %disable method selection
        set(bndryModeDrop,'Enable','off');
        set(fibModeDrop,'Enable','off');
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

%%--------------------------------------------------------------------------
%callback function for feature ranking button
function featR(featRanking,eventdata)
   
    set(bndryModeDrop,'Enable','off');
    set(fibModeDrop,'Enable','off');
    set(imgOpen,'Enable','off');
    set(infoLabel,'String','Feature Ranking is ongoing');

    
    fibFeatDir = uigetdir(pathNameGlobal,'Select Fiber feature Directory:');
    % [fileName pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg';'*.*'},'Select Image',pathNameGlobal,'MultiSelect','on');
     pathNameGlobal = fibFeatDir;
     save('lastParams.mat','pathNameGlobal','keepValGlobal','distValGlobal');
     if OS == 1
         fibFeatDir = [fibFeatDir,'\'];
     elseif OS == 0
         fibFeatDir = [fibFeatDir,'/'];
     end
    fileList = dir(fibFeatDir);
    lenFileList = length(fileList);
    feat_idx = zeros(1,lenFileList);

    %Search for feature files
    for i = 1:lenFileList
        if ~isempty(regexp(fileList(i).name,'fibFeatures.mat', 'once', 'ignorecase'))
            feat_idx(i) = 1;
        end
    end
    featFiles = fileList(feat_idx==1);
    lenFeatFiles = length(featFiles);
    %Compile a big array of features in RAM
    obsFileIdx = zeros(lenFeatFiles,1);
    totFeat = 0;
    for i = 1:lenFeatFiles
        %Find how many observations are in each file
        obsName = featFiles(i).name;
        bff = [fibFeatDir obsName];
        feat = load(bff);
        [lenFeat widFeat] = size(feat.fibFeat);
        totFeat = totFeat + lenFeat;
        obsFileIdx(i) = totFeat;
        IMGname1{i,1} = obsName(1:end-16);  % original image name of the feature name
    end
    %Allocate space for complete feature array (For all images)
    compFeat = zeros(totFeat,widFeat+1);
    compFeatMeta(lenFeatFiles) = struct('imageName',[],'topLevelDir',[],'fireDir',[],'outDir',[],'numToProc',[],'fibProcMeth',[],'keep',[],'distThresh',[]);

    %Put together big array
    prevTot = 1;
    totFeat = 0;
    for i = 1:lenFeatFiles
        obsName = featFiles(i).name;
        bff = [fibFeatDir obsName];
        feat = load(bff);
        [lenFeat widFeat] = size(feat.fibFeat);
        totFeat = totFeat + lenFeat; %Pointer to last array position
        compFeat(prevTot:totFeat,1:end-1) = feat.fibFeat; %Add to array
        compFeat(prevTot:totFeat,end) = zeros(lenFeat,1)+i; %Add index into meta data array
        compFeatMeta(i).imageName = feat.imgNameP;
        prevTot = totFeat+1; %Pointer to first array position
    end
    featNames = feat.featNames;

    %Save feature array and meta array to disk
    compFeatFF = [fibFeatDir 'compFeat.mat'];
    % save(compFeatFF,'compFeat','compFeatMeta');

    %%
    %Read from file just to check
    temp = load(compFeatFF);
    compFeat = temp.compFeat;
    compFeatMeta = temp.compFeatMeta;

    %% Train based on image annotations as a whole
    %load files for image labels 
%     labelMeta = [1 0 0 0 1 0 0 1 0 0 0 1 1 1 1 1]; %label for each of 16 training images (label image as a whole)
% fibFeatDir2 = [pwd '\CurveAlignTestImages\TrainingSets20131113\CA_Out\'];
% for i = 1:lenFeatFiles
%     obsNameS{i} = featFiles(i).name;
%     xlswrite([fibFeatDir2,'annotation.xlsx'], labelMeta(i),'sheet1',['A',num2str(i)]);
%     xlswrite([fibFeatDir2,'annotation.xlsx'], {obsNameS{i}(1:end-16)},'sheet1',['B',num2str(i)]);
%      
% end
% clear obsNameS

  [labelMeta2 IMGname2] = xlsread([fibFeatDir,'annotation.xlsx']);
  for i = 1:length(IMGname1)
      for j = 1:length(IMGname2)
          if strcmp(IMGname1(i),IMGname2(j))
              labelMeta(1,i) = labelMeta2(j,1);
              break;
          end
      end
  end
%    
% labelMeta2', labelMeta, pause   % check the annotation

    [lenFeat widFeat] = size(compFeat); %get size of the complete feature matrix (including meta index)
    labelObs = zeros(lenFeat,1); %The label for each observation
    for i = 1:lenFeat
        labelObs(i) = labelMeta(compFeat(i,end)); %last col contains index to metaData
    end
    labelObs = logical(labelObs);

    %show featurelist
    figure(guiRank1);
    fz1 = 9;
    for i = 1:length(featNames)
        if i<13
            text(0,1-0.08*i,sprintf('%d: %s',i,featNames{i}),'fontsize',fz1);
        elseif i > 12 && i < 25
            text(0.34,1-0.08*(i-12),sprintf('%d: %s',i,featNames{i}),'fontsize',fz1);
        elseif i > 24
            text(0.68,1-0.08*(i-24),sprintf('%d: %s',i,featNames{i}),'fontsize',fz1);
        end
    end
    axis(gca,'off')
                

        %1. fiber Key into CTFIRE list
        %2. row
        %3. col
        %4. abs ang
        %5. fiber weight
        %6. total length
        %7. end to end length
        %8. curvature
        %9. width
        %10. dist to nearest 2
        %11. dist to nearest 4
        %12. dist to nearest 8
        %13. dist to nearest 16
        %14. mean dist
        %15. std dist
        %16. box density 32
        %17. box density 64
        %18. box density 128
        %19. alignment of nearest 2
        %20. alignment of nearest 4
        %21. alignment of nearest 8
        %22. alignment of nearest 16
        %23. mean align
        %24. std align
        %25. box alignment 32
        %26. box alignment 64
        %27. box alignment 128
        %28. nearest dist to bound
        %29. inside epi region
        %30. nearest relative boundary angle
        %31. extension point distance
        %32. extension point angle
        %33. boundary point row
        %34. boundary point col

    posObs = compFeat(labelObs,:); %positive fiber observations
    negObs = compFeat(~labelObs,:); %negative fiber observations

    posM = nanmean(posObs); %average over observations
    negM = nanmean(negObs);
    posStd = nanstd(posObs);
    negStd = nanstd(negObs);

    compM = [posM; negM]; %composite matrix
    compStd = [posStd; negStd];
    maxM = nanmax(compM); %max between positive and neg
    compMN(1,:) = compM(1,:)./maxM; %normalize
    compMN(2,:) = compM(2,:)./maxM;
    compStdN(1,:) = compStd(1,:)./maxM;
    compStdN(2,:) = compStd(2,:)./maxM;
   % YL add gui
    % feats = [6 8:9 14:18 23:32]; %Best feature set
    featsDef = '6, 8:9, 14:18, 23:32'; %Best feature set

    name='Select features to be ranked';
    % prompt= featNames';
    prompt = {'Selected features'};
    numlines=1;
    defaultanswer= {featsDef};
    % updatepnum = defaultanswer;[5 7 10 15:20];
    % promptud = prompt(updatepnum);
    %  defaultud=defaultanswer(updatepnum);
    %     FIREp = inputdlg(prompt,name,numlines,defaultanswer);
    options.Resize='on';
    options.WindowStyle='normal';
    options.Interpreter='tex';
    featsIN = inputdlg(prompt,name,numlines,defaultanswer,options);

    if length(featsIN)== 1
        feats = str2num(featsIN{1});
    else
        disp('Please confirm or update the selected fiber features')
        featsIN = 0;
    end

    
    %feats = [28:32];
    featNamesS = featNames(feats); %throw out names that are not included
    lenSubFeats = length(feats);

    %Now make each image an observation by calculating the mean over fibers
    imgObsM = zeros(lenFeatFiles,widFeat);
    for i = 1:lenFeatFiles    
        imgObsM(i,:) = nanmean(compFeat(compFeat(:,end) == i,:));
    end

    %check to make sure these features can classify the training set
    SVMStruct = svmtrain(imgObsM(:,feats),labelMeta,'showplot','true');
    if lenSubFeats == 2
        xlabel(featNamesS(1));
        ylabel(featNamesS(2));
    end
    v = svmclassify(SVMStruct,imgObsM(:,feats));
    labelMeta = labelMeta';
    tp = sum((v(:,1) == labelMeta(:,1) & labelMeta(:,1) == 1));
    tn = sum((v(:,1) == labelMeta(:,1) & labelMeta(:,1) == 0));
    fp = sum((v(:,1) ~= labelMeta(:,1) & labelMeta(:,1) == 0));
    fn = sum((v(:,1) ~= labelMeta(:,1) & labelMeta(:,1) == 1));
    sens = tp/(tp+fn);
    spec = tn/(fp+tn);   
    disp(sprintf('mean sensitivity: %4.2f',mean(sens)));
    disp(sprintf('mean specificity: %4.2f',mean(spec)));

    %Plot normalized average feature values for each class
    figure(guiRank2);
    %set(gcf,'Position',[1 1 1000 750]);
    difCompMN = compMN(1,:) - compMN(2,:);
    difCompStd = sqrt(compStdN(1,:).^2 + compStdN(2,:).^2); % YL: compStdN(2,:).^2?
    difMN = difCompMN(:,feats);
    difStdS = difCompStd(:,feats);
    [difS, idxS] = sort(difMN);
    barh(difS);
    featNamesS1 = featNamesS(idxS); %Sorted name list
    difStdS = difStdS(idxS)./10; %shrink to make plotable
    %xlim([0.2 1.0]);
    set(gca,'YTick',1:lenSubFeats,'YTickLabel',featNamesS1);
    set(gca,'XGrid','off','YGrid','on');
    xlabel('Normalized Difference (Pos-Neg)');
    for i = 1:lenSubFeats
        %plot relative error
        yp = lenSubFeats-i+1;
        line([difS(i)-difStdS(yp) difS(i)+difStdS(yp)],[i i],'Color','g');
    end
    
    
    text(min(difS)-max(difStdS),lenSubFeats+2.85,sprintf('Sensitivity: %4.2f; Specificity: %4.2f',mean(sens),mean(spec)),'color','r');
    
    %Plot feature rank
    wtSVM = SVMStruct.Alpha'*SVMStruct.SupportVectors;
    absWt = wtSVM.^2;
    [absWtS, idxS] = sort(absWt); %Sort based on importance
    figure(guiRank3); barh(absWtS); %plot bar graph
    %set(gcf,'Position',[1 1 1000 750]);
    featNamesS = featNamesS(idxS); %sort feature names
    set(gca,'YTick',1:lenSubFeats,'YTickLabel',featNamesS);
    xlabel('Classification Importance');
    text(min(absWtS),lenSubFeats+2.85,sprintf('Sensitivity: %4.2f; Specificity: %4.2f',mean(sens),mean(spec)),'color','r');

    %Save rank to file
%     fibFeatDir2 = pwd;
    featRankFF = [fibFeatDir 'featRank.txt'];
    fid = fopen(featRankFF,'w+');
    difMNS = difMN(idxS);
    for i = 1:lenSubFeats
        fprintf(fid,'%d\t%s\t%f\t%f\r\n',i,featNamesS{i},absWtS(i),difMNS(i));
    end   
    fclose(fid);

    %% Try to use each fiber as an observation
%     compFeat(isnan(compFeat)) = 0;
%     folds = 50;
%     rndIdx = logical(round(rand(lenFeat,1)*(0.5+1/folds)));
%     %train
%     SVMStruct = svmtrain([compFeat(rndIdx,feats)],labelObs(rndIdx),'kernel_function','linear','showplot','true');
%     if lenSubFeats == 2
%         xlabel(featNamesS(1));
%         ylabel(featNamesS(2));
%     end
%     v = svmclassify(SVMStruct,compFeat(:,feats));
%     tp = sum((v(:,1) == labelObs(:,1) & labelObs(:,1) == 1));
%     tn = sum((v(:,1) == labelObs(:,1) & labelObs(:,1) == 0));
%     fp = sum((v(:,1) ~= labelObs(:,1) & labelObs(:,1) == 0));
%     fn = sum((v(:,1) ~= labelObs(:,1) & labelObs(:,1) == 1));
%     sens = tp/(tp+fn);
%     spec = tn/(fp+tn);   
%     disp(sprintf('mean sensitivity: %f',mean(sens)));
%     disp(sprintf('mean specificity: %f',mean(spec)));
% 
%     wtSVM = SVMStruct.Alpha'*SVMStruct.SupportVectors;
%     absWt = wtSVM.^2;
%     figure(300); barh(absWt);

%      set([makeRecon makeHist makeValues makeFeat makeOver makeMap imgRun],'Enable','on');
%      set([makeRecon makeHist makeValues],'Enable','off') % yl,default output
   
  
%    set(fibModeDrop,'Enable','off');
   set(infoLabel,'String','Feature Ranking is done');

end  % featR
%--------------------------------------------------------------------------
% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        %tempFolder = uigetdir(pathNameGlobal,'Select Output Directory:');
        if OS == 1
            outDir = [pathName '\CA_Out\'];   % for PC
        elseif OS == 0
            outDir = [pathName '/CA_Out/'];     % for MAC
        end
        if ~exist(outDir,'dir')
            mkdir(outDir);
        end
        
        %         IMG = getappdata(imgOpen,'img');
        keep = get(enterKeep,'UserData');
        distThresh = get(enterDistThresh,'UserData');
        keepValGlobal = keep;
        distValGlobal = distThresh;
        save('lastParams.mat','pathNameGlobal','keepValGlobal','distValGlobal');
        
        set([imgRun makeHist makeRecon enterKeep enterDistThresh imgOpen makeValues makeAssoc makeFeat makeMap makeOver],'Enable','off')
        
        if isempty(keep)
            %indicates the % of curvelets to process (after sorting by
            %coefficient value)
            keep = .001;
        end
        
        if isempty(distThresh)
            %this is default and is in pixels
            distThresh = 100;
        end
        
        if bndryMode == 2 || bndryMode == 3
            setappdata(guiFig,'boundary',1)
        elseif bndryMode == 0
            coords = []; %no boundary
            bdryImg = [];
        else
            [fileName2,pathName] = uiputfile('*.csv','Specify output file for boundary coordinates:',pathNameGlobal);
            fName = fullfile(pathName,fileName2);
            csvwrite(fName,coords);
        end
        
        %check if user directed to output boundary association lines (where
        %on the boundary the curvelet is being compared)
        makeAssocFlag = get(makeAssoc,'Value') == get(makeAssoc,'Max');
        
        makeFeatFlag = get(makeFeat,'Value') == get(makeFeat,'Max');
        makeOverFlag = get(makeOver,'Value') == get(makeOver,'Max');
        makeMapFlag = get(makeMap,'Value') == get(makeMap,'Max');
        %check to see if we should process the whole stack or current image
        %wholeStackFlag = get(wholeStack,'Value') == get(wholeStack,'Max');
        
        
        %loop through all images in batch list
        for k = 1:length(fileName)
            disp(['Processing image # ' num2str(k) ' of ' num2str(length(fileName)) '.']);
            [~, imgName, ~] = fileparts(fileName{k});
            ff = [pathName fileName{k}];
            info = imfinfo(ff);
            numSections = numel(info);
            
            %Get the boundary data
            if bndryMode == 2
                coords = csvread([pathName bndryFnd{k}]);
            elseif bndryMode == 3
                bff = [pathName bndryFnd{k}];
                bdryImg = imread(bff);
                [B,L] = bwboundaries(bdryImg,4);
                coords = B;%vertcat(B{:,1});
%                  coords = vertcat(B{2:end,1});
            end
            
            %loop through all sections if image is a stack
            for i = 1:numSections
                
                if numSections > 1
                    IMG = imread(ff,i,'Info',info);
                    set(stackSlide,'Value',i);
                    slider_chng_img(stackSlide,0);
                else
                    IMG = imread(ff);
                end
                if size(IMG,3) > 1
                    %if rgb, pick one color
                    IMG = IMG(:,:,1);
                end
                
                figure(guiFig);
                IMG = imadjust(IMG);
                imshow(IMG,'Parent',imgAx);
              
                if bndryMode == 1 || bndryMode == 2   % csv boundary
                     bdryImg = [];
                     [fibFeat] = processImage(IMG, imgName, outDir, keep, coords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, i, infoLabel, bndryMode, bdryImg, pathName, fibMode, 0,numSections);
                else %bndryMode = 3  tif boundary
                     
                     [fibFeat] = processImage(IMG, imgName, outDir, keep, coords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, i, infoLabel, bndryMode, bdryImg, pathName, fibMode, 0,numSections);
                end
            end
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
%         set([enterKeep enterDistThresh makeValues makeHist makeRecon],'Enable','on')
        set([enterKeep enterDistThresh],'Enable','on')
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