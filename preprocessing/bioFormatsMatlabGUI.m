function bioFormatsMatlabGUI
clear,clc, home, 
if ~isdeployed
    addpath(genpath(fullfile('./../bfmatlab')));
end
% don't want multiple windows open at the same time.
figs = findall(0,'Type','figure','Tag','bfWindow');
if ~isempty(figs)
    delete(figs)
end
scaleBarFigs = findall(0,'Type','figure','Tag','scaleBarFig');
if ~isempty(scaleBarFigs)
    delete(scaleBarFigs)
end
BFmergedfigure = findobj(0,'Tag','BF-MAT figure');
if ~isempty(BFmergedfigure)
    delete(BFmergedfigure)
end

svsOpenFig = findobj(0,'Tag','svs open options');
if ~isempty(svsOpenFig)
    delete(svsOpenFig)
end

% define the font size used in the GUI
fz1 = 9 ; % font size for the title of a panel
fz2 = 10; % font size for the text in a panel
fz3 = 12; % font size for the button
fz4 = 14; % biggest fontsize size

%% remember the path to the last opened file
if exist('lastPATH_BF.mat','file')
    lastPATHname = importdata('lastPATH_BF.mat');
    if isequal(lastPATHname,0)
        lastPATHname = '';
    end
else
    %use current directory
    lastPATHname = '';
end
global r; 
valList = {1,1,1,1}; 
ff = ''; 
ImgData = {}; 
stackSizeX = 0; 
stackSizeY = 0; 
stackSizeZ = 0; 
seriesCount = 0; 
nChannels = 0; 
nTimepoints = 0; 
nFocalplanes = 0; 
voxelSizeXdouble = []; 
voxelSizeYdouble = [];
voxelSizeZdouble = []; 
scaleBar = 1; 
heightPix = 2; 
scaleBarPos=''; 
fColor = ''; 
scaleBarCheck = 0; 
fontNo = 0; 
boldText = 0; 
overlayVal = 0; 
hideText = 0 ; 
I = [];
set(0,'units','pixels');
windowSize = get(0,'ScreenSize');

BFcontrol = struct('imagePath','','imageName','','seriesCount',1,'nChannels',1,...
    'nTimepoints',1,'nFocalplanes',1,'mergechannelFlag',0,'colormap','gray','iseries',1,'ichannel',1,...
    'iTimepoint',1,'iFocalplane',1);
BFobjects = cell(1,5); %{'Series','Channel','Timepoint','Focalplane','mergechannelFlag'};
%initialize the axes for BF visualization
axVisualization = '';
sliderObjects = cell(1,4);

% Create figure window
fig = uifigure('Resize', 'on', 'Position',...
    [20*(windowSize(3)/1600) 350*(windowSize(4)/900) 500*(windowSize(3)/1600) 490*(windowSize(4)/900)], ...
    'Tag', 'bfWindow','Resize','on');
fig.Name = "Bio-Formats MATLAB Importer and Exporter";
% Create UI components
lbl_1 = uipanel(fig,'Title','Import','FontSize',14,'FontWeight','bold','BorderWidth',1,'Position',...
    [fig.Position(3)*0.025 fig.Position(4)*0.89  fig.Position(3)*0.475 fig.Position(4)*0.1]);
btn_1 = uibutton(lbl_1,'Position',[0.20*lbl_1.Position(3) lbl_1.InnerPosition(4)*0.1 0.60*lbl_1.Position(3) lbl_1.InnerPosition(4)*0.60],...
    'Text','Individual Image','ButtonPushedFcn',@import_Callback);
% btn_2b = uibutton(lbl_1,'Position',[0.525*lbl_1.Position(3) lbl_1.InnerPosition(4)*0.1 0.45*lbl_1.Position(3) lbl_1.InnerPosition(4)*0.60],...
%     'Text','Image Folder','ButtonPushedFcn',@importFolder_Callback);

lbl_2 = uibuttongroup(fig,'Title','Export','FontSize',14,'FontWeight','bold','BorderWidth',1,'Position',...
    [fig.Position(3)*0.025 fig.Position(4)*0.475 fig.Position(3)*0.475 fig.Position(4)*0.40],'Enable','off');

exportRadioList = {'Current Image','Each Focal Plane','Each Time Point','Each Channel', 'Each Plane OME-TIFF','Each Plane MATLAB 8-bit'}; 
numberofButtons = length(exportRadioList);
xShift = 0.2;
heightStart = 1.25;
heightStartShift = 1.0;
heightShift = floor(lbl_2.InnerPosition(4)/(numberofButtons))-2;
%exportBG = uiradiobutton(lbl_2,"Position",[10 10 lbl_2.Position(3)*.75 lbl_2.Position(4)*.75 ]);
for iBG = 1:numberofButtons
    exportBG{iBG} = uiradiobutton(lbl_2, 'Text', exportRadioList{iBG},'Position',...
        [lbl_2.InnerPosition(3)*xShift lbl_2.InnerPosition(4)-heightShift*(heightStart+heightStartShift*(iBG-1)) lbl_2.InnerPosition(3)*0.8 heightShift]);
end

tarea = uitextarea(fig,'Position',[fig.Position(3)*0.025 fig.Position(4)*0.025 fig.Position(3)*0.475 fig.Position(4)*0.425]);
tarea.Value= {'Information Window'};
%%
viewingOptionsPanel = uipanel(fig,'Title','Viewing options','FontSize',14,'FontWeight','bold','Enable','off');
viewingOptionsPanel.Position = [fig.Position(3)*0.525 fig.Position(4)*0.485 fig.Position(3)*0.465 fig.Position(4)*0.50];
dimensionLabelWidth = viewingOptionsPanel.InnerPosition(3)*0.5;
dimensionLabelHeight = viewingOptionsPanel.InnerPosition(4)*0.175;
dimensionLabelX = viewingOptionsPanel.InnerPosition(3)*0.05;
dimensionLabelY = viewingOptionsPanel.InnerPosition(4)*0.775;
dimensionNumberX = viewingOptionsPanel.InnerPosition(3)*0.55;
dimensionNumberY = dimensionLabelY;
dimensionHightShift = dimensionLabelHeight*1.025; 
dimensionNumberWidth = viewingOptionsPanel.InnerPosition(3)*0.3;
dimensionNumberHeight = dimensionLabelHeight;

lbl_series = uilabel(viewingOptionsPanel,'Position',[dimensionLabelX dimensionLabelY dimensionLabelWidth dimensionLabelHeight],'Text','Series');
lbl_Channel  = uilabel(viewingOptionsPanel,'Position',[dimensionLabelX dimensionLabelY-dimensionHightShift*1 dimensionLabelWidth dimensionLabelHeight],'Text','Channel');
lbl_Timepoints = uilabel(viewingOptionsPanel,'Position',[dimensionLabelX dimensionLabelY-dimensionHightShift*2 dimensionLabelWidth dimensionLabelHeight],'Text','Timepoints');
lbl_Focalplanes = uilabel(viewingOptionsPanel,'Position',[dimensionLabelX dimensionLabelY-dimensionHightShift*3 dimensionLabelWidth dimensionLabelHeight],'Text','Focalplanes');
numField_4 = uieditfield(viewingOptionsPanel,'numeric','Position',[dimensionNumberX dimensionNumberY dimensionNumberWidth dimensionNumberHeight],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_4,event) getSeries_Callback(numField_4,event));
numField_1 = uieditfield(viewingOptionsPanel,'numeric','Position',[dimensionNumberX dimensionNumberY-dimensionHightShift*1 dimensionNumberWidth dimensionNumberHeight],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_1,event) getChannel_Callback(numField_1,event));
numField_2 = uieditfield(viewingOptionsPanel,'numeric','Position',[dimensionNumberX dimensionNumberY-dimensionHightShift*2 dimensionNumberWidth dimensionNumberHeight],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_2,event) getTimepoints_Callback(numField_2,event));
numField_3 = uieditfield(viewingOptionsPanel,'numeric','Position',[dimensionNumberX dimensionNumberY-dimensionHightShift*3 dimensionNumberWidth dimensionNumberHeight],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event));

% mergeBoxName = uilabel(fig,'Position',[dimensionLabelX-30 dimensionNumberY-dimensionHightShift*4.25 100 20],'Text','Merge channels');
mergeChannelCheck = uicheckbox(viewingOptionsPanel,'Text','Merge channels','Position',[dimensionLabelX*1.25 dimensionNumberY-dimensionHightShift*4.15 150 20], 'Value',0, ...
    'ValueChangedFcn',@(mergeChannelCheck,event) mergeChannelCheck_Callback(mergeChannelCheck,event));

BFobjects{1} = numField_4; %series
BFobjects{2} = numField_1; % channel
BFobjects{3} = numField_2; % timepoint
BFobjects{4} = numField_3;  % focoalplane;
BFobjects{5} = mergeChannelCheck;  % merge channel 

% lbl_4 = uilabel(mainGrid,'Text','Metadata','FontSize',14,'FontWeight','bold');
% lbl_4.Layout.Row = 2;
% lbl_4.Layout.Column = 2;
metadataPanel = uipanel('Parent',fig,'Position',[fig.Position(3)*0.525 fig.Position(4)*0.10 fig.Position(3)*0.465 fig.Position(4)*0.365], ...
    'Title', 'Displaying options','FontSize',14,'FontWeight','bold','Enable','off');

btn_3 = uibutton(metadataPanel,'Position',...
    [metadataPanel.InnerPosition(3)*0.05 metadataPanel.InnerPosition(4)*0.80 metadataPanel.InnerPosition(3)*0.90 metadataPanel.InnerPosition(4)*0.15],...
    'Text','Original metadata','ButtonPushedFcn',@dispmeta_Callback);
btn_4 = uibutton(metadataPanel,'Position',...
    [metadataPanel.InnerPosition(3)*0.05 metadataPanel.InnerPosition(4)*0.625 metadataPanel.InnerPosition(3)*0.90 metadataPanel.InnerPosition(4)*0.15],...
    'Text','OME-XML metadata', 'Enable','on',...
    'ButtonPushedFcn',@disOMEpmeta_Callback);

%% scale bar 
% scaleBarLabel = uilabel(fig,'Position',[320 80 120 20],'Text','Scale Bar');
scaleBarInit = uibutton(metadataPanel,'Position', ...
    [metadataPanel.InnerPosition(3)*0.005 metadataPanel.InnerPosition(4)*0.45 metadataPanel.InnerPosition(3)*0.40 metadataPanel.InnerPosition(4)*0.15],...
    'Text','Scale Bar',...
      'ButtonPushedFcn', @setScaleBar);
scaleBarInit = uilabel(metadataPanel,'Position', ...
        [metadataPanel.InnerPosition(3)*0.425 metadataPanel.InnerPosition(4)*0.45 metadataPanel.InnerPosition(3)*0.40 metadataPanel.InnerPosition(4)*0.15],...
    'Text','Pixel size(um)');
pixelInput = uieditfield(metadataPanel,'text','Position', ...
        [metadataPanel.InnerPosition(3)*0.825 metadataPanel.InnerPosition(4)*0.45 metadataPanel.InnerPosition(3)*0.165 metadataPanel.InnerPosition(4)*0.15],...
        'Value', '');
% color map options
color_lbl = uilabel(metadataPanel,'Position',...
    [metadataPanel.InnerPosition(3)*0.05 metadataPanel.InnerPosition(4)*0.10 metadataPanel.InnerPosition(3)*0.30 metadataPanel.InnerPosition(4)*0.25],...
    'Text','Colormap');
% color_lbl = uilabel(fig,'Position',[320 50 80 20],'Text','Colormap');
color = uidropdown(metadataPanel,'Position',...
    [metadataPanel.InnerPosition(3)*0.35 metadataPanel.InnerPosition(4)*0.10 metadataPanel.InnerPosition(3)*0.64 metadataPanel.InnerPosition(4)*0.25],...
    'ValueChangedFcn',@setColor); 
color.Items = ["Default Colormap" "MATLAB Color: JET" "MATLAB Color: Gray" "MATLAB Color: hsv"...
    "MATLAB Color: Hot" "MATLAB Color: Cool"];

% reset button
btnReset = uibutton(fig,'push','Position',[290*(windowSize(3)/1600) 10*(windowSize(4)/900) 60*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Reset',...
    'ButtonPushedFcn',@resetImg_Callback,'Enable','off');
% ok button [horizonal vertical element_length element_height]
btnSave = uibutton(fig,'Position',[360*(windowSize(3)/1600) 10*(windowSize(4)/900) 60*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Save','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@save_Callback,'Enable','off');
% cancel button 
btnCancel = uibutton(fig,'Position',[430*(windowSize(3)/1600) 10*(windowSize(4)/900) 60*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Cancel','ButtonPushedFcn',@exit_Callback,'Enable','off');
%% set colormap
    function setColor(src,event)
        colormap = color.Value; 
        switch colormap
            %         "Default Colormap" "MATLAB Color: JET" "MATLAB Color: Gray" "MATLAB Color: hsv"...
            %     "MATLAB Color: Hot" "MATLAB Color: Cool"
            case 'Default Colormap'
                BFcontrol.colormap = 'gray';  
%                 imgcolorMaps = ImgData(BFcontrol.iSeries,3); 
%                 if(isempty(imgcolorMaps{1}))
%                     BFcontrol.colormap = 'gray';                
%                 else
%                     BFcontrol.colormap = imgcolorMaps{1}(1,:);
%                 end
            case 'MATLAB Color: JET'
                BFcontrol.colormap = 'jet'; 
            case 'MATLAB Color: Gray'
                BFcontrol.colormap = 'gray'; 
            case 'MATLAB Color: hsv'
                BFcontrol.colormap = 'hsv'; 
            case 'MATLAB Color: Hot'
                BFcontrol.colormap = 'hot'; 
            case 'MATLAB Color: Cool'
                BFcontrol.colormap = 'cool'; 
        end
        BFvisualziation(BFcontrol,axVisualization,pixelInput);
        
    end

%% Create the function for the import callback
    function  import_Callback(hObject,eventdata,handles)
%         [seriesCount,nChannels,nTimepoints,nFocalplanes]
        f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]); %create a dummy figure so that uigetfile doesn't minimize our GUI
        [fileName, pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg;*.svs;*.png';'*.*'},'File Selector',lastPATHname,'MultiSelect','off');
        delete(f); %delete the dummy figure
        [fPath, fName, fExt] = fileparts(fileName);
        if isequal(fileName,0)
            disp('User selected Cancel')
            return;
        else
            disp(['User selected ', fullfile(pathName,fileName)])
            lastPATHname = pathName;
            save('lastPATH_BF.mat','lastPATHname');
        end
        switch lower(fExt)
            case '.svs'
                import_svs(fileName, pathName);
                return;
        end
        ff = fullfile(pathName,fileName);
        d = uiprogressdlg(fig,'Title','Loading file',...
        'Indeterminate','on','Cancelable','on');
        r = bfGetReader(ff);
        seriesCount = r.getSeriesCount();
        nChannels = r.getSizeC(); 
        nTimepoints = r.getSizeT(); 
        nFocalplanes = r.getSizeZ(); 
        btn_1.UserData=struct("ff",ff,"r",r,"seriesCount",seriesCount,...
        "nChannels",nChannels,"nTimepoints",nTimepoints,"nFocalplanes",nFocalplanes);
   % read metaData
        omeMeta = r.getMetadataStore();
        stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
        stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
        stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
        try
            voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % in µm
            voxelSizeXdouble = voxelSizeX.doubleValue();                                  % The numeric value represented by this object after conversion to type double
            voxelSizeY = omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER); % in µm
            voxelSizeYdouble = voxelSizeY.doubleValue();                                  % The numeric value represented by this object after conversion to type double
            tarea.Value = [tarea.Value; {sprintf('\n Pixel size informaiton found \n')}];
        catch
            voxelSizeXdouble=[];
            voxelSizeYdouble = [];
            tarea.Value = [tarea.Value; {sprintf('\n Pixel size informaiton unavailable \n')}];
        end
        if  ~isempty(voxelSizeXdouble)
            set(pixelInput,'Value',sprintf('%4.3f',voxelSizeXdouble));
        else
            set(pixelInput,'Value','');
        end
        cellArrayText{1,1} = sprintf('%s : %s', 'Filename', fileName);
        cellArrayText{2,1} = sprintf('%s : %d', 'Series', seriesCount);
        cellArrayText{3,1} = sprintf('%s : %d', 'Channel', nChannels);
        cellArrayText{4,1} = sprintf('%s : %d', 'TimePoints', nTimepoints);
        cellArrayText{5,1} = sprintf('%s : %d', 'Focal Planes', nFocalplanes);
        cellArrayText{6,1} = sprintf('%s : %d', 'Image Width', stackSizeX);
        cellArrayText{7,1} = sprintf('%s : %d', 'Image Height', stackSizeY);
        tarea.Value=[tarea.Value; cellArrayText];
        handles.seriesCount=r.getSeriesCount();
        handles.nChannels=r.getSizeC();
        handles.nTimepoints=r.getSizeT();
        handles.nFocalplanes=r.getSizeZ();
        close(d)
        %Initialize the visualization function
        BFcontrol.imagePath = pathName;  %path to image folder
        BFcontrol.imageName = fileName;
        BFcontrol.seriesCount = seriesCount;
        BFcontrol.nChannels = nChannels;
        BFcontrol.nTimepoints = nTimepoints;
        BFcontrol.nFocalplanes = nFocalplanes;
        BFcontrol.iSeries = seriesCount; numField_4.Value =   BFcontrol.iSeries;
        BFcontrol.iChannel = 1; numField_1.Value = BFcontrol.iChannel;
        BFcontrol.iTimepont = 1; numField_2.Value = BFcontrol.iTimepoint;
        BFcontrol.iFocalplane = 1; numField_3.Value = BFcontrol.iFocalplane;
        [axVisualization, sliderObjects] = BFinMatlabFigureSlider(BFcontrol,BFobjects);

        if  BFcontrol.nChannels> 1
            set(BFobjects{5},'Enable','on')
            set(BFobjects{2},'Enable','on')
            set(BFobjects{2},'Limits',[1 BFcontrol.nChannels],'Tooltip',sprintf('Max number of channels is %d',BFcontrol.nChannels));
        else
            set(BFobjects{5},'Enable','off')
            set(BFobjects{2},'Enable','off')
        end
        if  BFcontrol.seriesCount> 1
            set(BFobjects{1},'Enable','on')
            set(BFobjects{1},'Limits',[1 BFcontrol.seriesCount],'Tooltip',sprintf('Max number of series is %d',BFcontrol.seriesCount));
        else
            set(BFobjects{1},'Enable','off')
        end
        if  BFcontrol.nFocalplanes> 1
            set(BFobjects{4},'Enable','on')
            set(BFobjects{4},'Limits',[1 BFcontrol.nFocalplanes],'Tooltip',sprintf('Max number of focal planes is %d',BFcontrol.nFocalplanes));
        else
            set(BFobjects{4},'Enable','off')
        end
        if  BFcontrol.nTimepoints> 1
            set(BFobjects{3},'Enable','on')
            set(BFobjects{3},'Limits',[1 BFcontrol.nTimepoints],'Tooltip',sprintf('Max number of time points is %d',BFcontrol.nTimepoints));
        else
            set(BFobjects{3},'Enable','off')
        end
        set(lbl_2, 'Enable', 'on');
        set(btnSave, 'Enable', 'on');
        set(btnCancel,'Enable','on');
        set(btnReset,'Enable','on');
        set(viewingOptionsPanel,'Enable','on');
        set(metadataPanel,'Enable','on');
    end

%% import svs 
    function import_svs(fileName, pathName)
        defaultBackground = get(0,'defaultUicontrolBackgroundColor');
        svsfig = figure('Resize','on','Color',defaultBackground,'Units','normalized','Position',[0.3 0.1 0.4 0.8],'Visible','on',...
        'MenuBar','none','name','Bio-formats series options','NumberTitle','off','UserData',0,'Tag','svs open options');
        ff = fullfile(pathName,fileName);
        r = bfGetReader(ff);
   % read metaData
        omeMeta = r.getMetadataStore();
        seriesCount = r.getSeriesCount();
        xStackSizes = zeros(seriesCount, 1);
        yStackSizes = zeros(seriesCount, 1);
        for seriesNumber = 0:(seriesCount-1)
            xStackSizes(seriesNumber + 1) = omeMeta.getPixelsSizeX(seriesNumber).getValue(); % image width, pixels
            yStackSizes(seriesNumber + 1) = omeMeta.getPixelsSizeY(seriesNumber).getValue(); % image height, pixels
        end
        stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
        boxes = cell(seriesCount, 1);
        for i=1:seriesCount
            boxes{i} = ['checkbox' num2str(i)];
        end
        ySpacing = 0;
        hsr = uibuttongroup('parent',svsfig,'title','Series selection', 'visible','on','Units','normalized','Position',[0 0 1 0.95], ...
            'FontSize', 20);
        for i = 1:seriesCount
            boxes{i} = uicontrol('Parent',hsr,'Style','radiobutton','String',...
                strcat('Series ',int2str(i),':  ',int2str(xStackSizes(i)),' x ',int2str(yStackSizes(i))),...
                'Units','normalized','Position',[.075 0.8-ySpacing .8 .125],'FontSize',14);
                ySpacing = ySpacing + 0.12;
        end
        imgRun = uicontrol('Parent',svsfig,'Style','pushbutton','String','Ok',...
            'FontSize',14,'Units','normalized','Position',[0.13 0.01 0.1 0.04],...
            'Callback',{@getCheckboxValues,boxes,r,fileName,pathName});
        imgCancel = uicontrol('Parent',svsfig,'Style','pushbutton','String','Cancel',...
            'FontSize',14,'Units','normalized','Position',[0.01 0.01 0.11, 0.04],...
            'Callback',{@exitsvs,svsfig});
    end

%% get checkbox values

    function getCheckboxValues(src,event,boxes,r,fileName,pathName)
        checkBoxVals = zeros(length(boxes),1);
        for i = 1:length(checkBoxVals)
            checkBoxVals(i,1) = get(boxes{i},'Value');
        end
        load_svs_series(checkBoxVals,r,fileName,pathName)
    end

%%
    function exitsvs(src,eventData,svsfig)
        close(svsfig)
    end

%% load svs series
    function load_svs_series(boxVals,r,fileName,pathName,hObject,handles)
        % seriesCount = length(BoxValues);
        seriesNumber = find(boxVals == 1);
        stackSizeX = r.getMetadataStore().getPixelsSizeX(seriesNumber-1).getValue();
        stackSizeY = r.getMetadataStore().getPixelsSizeY(seriesNumber-1).getValue();
        nChannels = r.getSizeC(); 
        nTimepoints = r.getSizeT(); 
        nFocalplanes = r.getSizeZ(); 
        btn_1.UserData=struct("ff",ff,"r",r,"seriesCount",seriesCount,...
        "nChannels",nChannels,"nTimepoints",nTimepoints,"nFocalplanes",nFocalplanes);
        cellArrayText{1,1} = sprintf('%s : %s', 'Filename', fileName);
        cellArrayText{2,1} = sprintf('%s : %d', 'Series Total', seriesCount);
        cellArrayText{3,1} = sprintf('%s : %d', 'Series Selected', seriesNumber);
        cellArrayText{4,1} = sprintf('%s : %d', 'Channel', nChannels);
        cellArrayText{5,1} = sprintf('%s : %d', 'TimePoints', nTimepoints);
        cellArrayText{6,1} = sprintf('%s : %d', 'Focal Planes', nFocalplanes);
        cellArrayText{7,1} = sprintf('%s : %d', 'Image Width', stackSizeX);
        cellArrayText{8,1} = sprintf('%s : %d', 'Image Height', stackSizeY);
        tarea.Value=[tarea.Value; cellArrayText];
        handles.seriesCount=seriesCount;
        handles.nChannels=r.getSizeC();
        handles.nTimepoints=r.getSizeT();
        handles.nFocalplanes=r.getSizeZ();
        %Initialize the visualization function
        BFcontrol.imagePath = pathName;  %path to image folder
        BFcontrol.imageName = fileName;
        BFcontrol.seriesCount = seriesCount;
        BFcontrol.nChannels = nChannels;
        BFcontrol.nTimepoints = nTimepoints;
        BFcontrol.nFocalplanes = nFocalplanes;
        BFcontrol.iSeries = find(boxVals == 1); numField_4.Value = BFcontrol.iSeries;
        BFcontrol.iChannel = 1; numField_1.Value = BFcontrol.iChannel;
        BFcontrol.iTimepont = 1; numField_2.Value = BFcontrol.iTimepoint;
        BFcontrol.iFocalplane = 1; numField_3.Value = BFcontrol.iFocalplane;
        [axVisualization, sliderObjects] = BFinMatlabFigureSlider(BFcontrol,BFobjects);

        if  BFcontrol.nChannels> 1
            set(BFobjects{5},'Enable','on')
            set(BFobjects{2},'Enable','on')
            set(BFobjects{2},'Limits',[1 BFcontrol.nChannels],'Tooltip',sprintf('Max number of channels is %d',BFcontrol.nChannels));
        else
            set(BFobjects{5},'Enable','off')
            set(BFobjects{2},'Enable','off')
        end
        if  BFcontrol.seriesCount> 1
            set(BFobjects{1},'Enable','on')
            set(BFobjects{1},'Limits',[1 BFcontrol.seriesCount],'Tooltip',sprintf('Max number of series is %d',BFcontrol.seriesCount));
        else
            set(BFobjects{1},'Enable','off')
        end
        if  BFcontrol.nFocalplanes> 1
            set(BFobjects{4},'Enable','on')
            set(BFobjects{4},'Limits',[1 BFcontrol.nFocalplanes],'Tooltip',sprintf('Max number of focal planes is %d',BFcontrol.nFocalplanes));
        else
            set(BFobjects{4},'Enable','off')
        end
        if  BFcontrol.nTimepoints> 1
            set(BFobjects{3},'Enable','on')
            set(BFobjects{3},'Limits',[1 BFcontrol.nTimepoints],'Tooltip',sprintf('Max number of time points is %d',BFcontrol.nTimepoints));
        else
            set(BFobjects{3},'Enable','off')
        end
        set(sliderObjects{1},'Enable','off'); % for svs file, donot enable the slider for the change of series number
        set(btnSave, 'Enable', 'on');
        set(btnCancel,'Enable','on');
        set(btnReset,'Enable','on');
        set(viewingOptionsPanel,'Enable','on');
        set(metadataPanel,'Enable','on');
        set(numField_4,'Enable','off');
        set(lbl_2, 'Enable', 'off');

    end



%% get channel
    function getChannel_Callback(numField_1,event)
        valList{1} = event.Value;
        sprintf('%s : %d', 'User entered:', valList{1});
        BFcontrol.iChannel = event.Value;
        sliderObjects{2}.Value = event.Value;
        BFvisualziation(BFcontrol,axVisualization);
    end
%% get timepoints
    function getTimepoints_Callback(numField_2,event)
        valList{2} = event.Value;
        sprintf('%s : %d', 'User entered:', valList{2});
        BFcontrol.iTimepoint = event.Value;
        sliderObjects{3}.Value = event.Value;
        BFvisualziation(BFcontrol,axVisualization);
    end
%% get focalplanes
    function getFocalPlanes_Callback(numField_3,event)      
        valList{3} = event.Value; 
        sprintf('%s : %d', 'User entered:', valList{3});
        BFcontrol.iFocalplane = event.Value;
        sliderObjects{4}.Value = event.Value;
        BFvisualziation(BFcontrol,axVisualization);
    end
%% get series 
    function getSeries_Callback(numField_4,event)      
        valList{4} = event.Value; 
        sprintf('%s : %d', 'User entered:', valList{4});
        BFcontrol.iSeries = event.Value;
        sliderObjects{1}.Value = event.Value;
        BFvisualziation(BFcontrol,axVisualization);
    end
%% merge channels
    function mergeChannelCheck_Callback(mergeChannelCheck,event)
        if nChannels>3|| nChannels < 2
            fprintf('Only support merge of two and three channels \n')
            mergeChannelCheck.Value = 0;
            set(BFobjects{2},'Enable','on')
        else
            if event.Value == 1
                set(BFobjects{2},'Enable','off')
            else
                set(BFobjects{2},'Enable','on')
            end
            BFcontrol.mergechannelFlag = event.Value;
            mergeChannelCheck.Value = event.Value;
            sliderObjects{1}.Value = event.Value;
            BFvisualziation(BFcontrol,axVisualization);
        end
    end
%% 
    function dispmeta_Callback(src,eventdata)
        iSeries = valList{4};
        d = uiprogressdlg(fig,'Title','Reading Original Metadata',...
        'Indeterminate','on','Cancelable','on');
        [~,~,fExt] = fileparts(ff);
        if strcmp (fExt,'.svs')
            tarea.Value = [tarea.Value; {'This is a .svs file. click OME-XML Data to import the meta data information'}];
            return
        else
            ImgData = bfopen(ff);
        end
        
        if iSeries == 1
            metadata = ImgData{1, 2};
%             newStr = split(metadata,","); 
            subject = metadata.get('Subject');
            title = metadata.get('Title');
            metadataKeys = metadata.keySet().iterator();
            if metadata.size == 0
                tarea.Value = [tarea.Value; {sprintf('No meta data was found')}];
            else
                for i=1:metadata.size()
                    key = metadataKeys.nextElement();
                    value = metadata.get(key);
                    try

                    if  isa(value,'double')
                        tarea.Value = [tarea.Value; {sprintf('%s = %d', key, value)}];
                    else
                        tarea.Value = [tarea.Value; {sprintf('%s = %s', key, value)}];
                    end
                    catch exp1
                        tarea.Value =  [tarea.Value; {sprintf('Key %s error:%s', key, exp1.message)}];
                    end
                end
            end
                %Data identification function
                %method1: if else, check type before printing 
                %method2: separate by , split() failed
            close(d) 
        else 
            if valList{4}>1
                metadata = ImgData{iSeries, 2}; 
%                 metadata = r.getSeriesMetadata();
                subject = metadata.get('Subject');
                title = metadata.get('Title');
                metadataKeys = metadata.keySet().iterator();
                for i=1:metadata.size()
                    key = metadataKeys.nextElement();
                    value = metadata.get(key);
                    try
                        if  isa(value,'double')
                            tarea.Value = [tarea.Value; {sprintf('%s = %d', key, value)}];
                        else
                            tarea.Value = [tarea.Value; {sprintf('%s = %s', key, value)}];
                        end
                    catch exp1
                        tarea.Value =  [tarea.Value; {sprintf('Key %s error:%s', key, exp1.message)}];
                    end

                end
                close(d)
            end
            
        end
        
    end
%% 
    function  disOMEpmeta_Callback(hObject,src)
%         [stackSizeX,stackSizeY,stackSizeZ,voxelSizeXdouble]
%             omeData = r.getGlobalMetadata();
%             omeMeta = r.getMetadataStore();
        iSeries = valList{4};
        d = uiprogressdlg(fig,'Title','Reading OME Metadata',...
        'Indeterminate','on','Cancelable','on');
        try
            if iSeries==1
                omeMeta = r.getMetadataStore();
                %             stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
                %             stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
                %             stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
                voxelSizeXdefaultValue = omeMeta.getPixelsPhysicalSizeX(0).value();           % returns value in default unit
                voxelSizeXdefaultUnit = omeMeta.getPixelsPhysicalSizeX(0).unit().getSymbol(); % returns the default unit type
                voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % in µm
                voxelSizeXdouble = voxelSizeX.doubleValue();                                  % The numeric value represented by this object after conversion to type double
                voxelSizeY = omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER); % in µm
                voxelSizeYdouble = voxelSizeY.doubleValue();                                  % The numeric value represented by this object after conversion to type double
                % voxelSizeZ = omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER); % in µm
                % voxelSizeZdouble = voxelSizeZ.doubleValue();                                  % The numeric value represented by this object after conversion to type double
                omeXML = char(omeMeta.dumpXML());
                handles.voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER);
                cellArrayText{1,1} = sprintf('%s : %4.3f', 'Pixel X', voxelSizeXdouble);
                cellArrayText{2,1} = sprintf('%s : %4.3f', 'Pixel Y', voxelSizeYdouble);
                cellArrayText{3,1} = sprintf('%s : %d', 'image width', stackSizeX);
                cellArrayText{4,1} = sprintf('%s : %d', 'image height', stackSizeY);
                %             cellArrayText{5} = sprintf('%s : %d', 'value in default unit', voxelSizeXdefaultValue)
                %             cellArrayText{5} = sprintf('%s : %d', 'default unit', voxelSizeXdefaultUnit)
                tarea.Value = [tarea.Value;cellArrayText;{omeXML}];
                % fprintf(omeXML)
                close(d)
            else
                if iSeries>1
                    r.setSeries(iSeries - 1);
                    omeMeta = r.getMetadataStore();
                    %                 omeMeta = ImgData{iSeries, 4};
                    stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
                    stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
                    stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
                    voxelSizeXdefaultValue = omeMeta.getPixelsPhysicalSizeX(0).value();           % returns value in default unit
                    voxelSizeXdefaultUnit = omeMeta.getPixelsPhysicalSizeX(0).unit().getSymbol(); % returns the default unit type
                    voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % in µm
                    voxelSizeXdouble = voxelSizeX.doubleValue();                                  % The numeric value represented by this object after conversion to type double
                    voxelSizeY = omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER); % in µm
                    voxelSizeYdouble = voxelSizeY.doubleValue();                                  % The numeric value represented by this object after conversion to type double
                    omeXML = char(omeMeta.dumpXML());
                    handles.stackSizeX = omeMeta.getPixelsSizeX(0).getValue();
                    handles.stackSizeY = omeMeta.getPixelsSizeY(0).getValue();
                    handles.stackSizeY = omeMeta.getPixelsSizeZ(0).getValue();
                    handles.voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER);
                    cellArrayText{1,1} = sprintf('%s : %d', 'Pixel X', voxelSizeXdouble);
                    cellArrayText{2,1} = sprintf('%s : %d', 'Pixel Y', voxelSizeYdouble);
                    tarea.Value = [tarea.Value;cellArrayText;{omeXML}];
                    % fprintf('%s \n', omeXML)
                    close(d)
                end

            end
            if  ~isempty(voxelSizeXdouble)
                set(pixelInput,'Value',sprintf('%4.3f',voxelSizeXdouble));
                set(pixelInput,'Enable','off');
            else
                set(pixelInput,'Value','');
                set(pixelInput,'Enable','on');
            end
        catch exp1
            tarea.Value = [tarea.Value;{sprintf('OME meta data is not displayed. Error message: %s', exp1.message)}];
        end
        
    end

%% function dispSplitImages(hObject,src,eventData,handles)
    function setScaleBar(src,event,hObject)
        if isempty(pixelInput.Value)
            uialert(fig,'Must enter pixel size in micrometers to use Scale Bar','Invalid Input');
            return;
        end

        scaleBarFigs = findall(0,'Type','figure','Tag','scaleBarFig');
        if ~isempty(scaleBarFigs)
            delete(scaleBarFigs)
        end
        
        scaleBarFig = figure('Resize','on','Color',get(0,'defaultUicontrolBackgroundColor'),'Units',...
            'normalized','Position',[0.185 0.2 0.14 0.3],'Visible','on','Tag','scaleBarFig',...
            'MenuBar','none','name','Scale Bar Options','NumberTitle','off','UserData',0);
        
        label1 = uicontrol('Parent',scaleBarFig,'Style','text','String','Width in microns','FontSize',12,'Units','normalized','Position',[0.05 0.8 .5 .125]);
        enterLabel1 = uicontrol('Parent',scaleBarFig,'Style','edit','String','10','BackgroundColor','w','UserData',[10],'Units','normalized','Position',[0.6 0.835 .14 .125],'Callback',{@get_textbox_data1});

        label2 = uicontrol('Parent',scaleBarFig,'Style','text','String','Height in pixels','FontSize',12,'Units','normalized','Position',[0.05 0.65 .5 .125]);
        enterLabel2 = uicontrol('Parent',scaleBarFig,'Style','edit','String','2','BackgroundColor','w','UserData',[2],'Units','normalized','Position',[0.6 0.685 .14 .125],'Callback',{@get_textbox_data2});

        label3 = uicontrol('Parent',scaleBarFig,'Style','text','String','Font size','FontSize',12,'Units','normalized','Position',[0.05 0.5 .5 .125]);
        enterLabel3 = uicontrol('Parent',scaleBarFig,'Style','edit','String','8','BackgroundColor','w','UserData',[8],'Units','normalized','Position',[0.6 0.535 .14 .125],'Callback',{@get_textbox_data3});
        
        label4 = uicontrol('Parent',scaleBarFig,'Style','text','String','Font color','FontSize',12,'Units','normalized','Position',[0.05 0.35 .5 .125]);
        enterDropdown1 = uicontrol('Parent',scaleBarFig,'Style','popupmenu','String',{'White';'Black';'Cyan'; 'Red'},...
            'FontSize',fz2,'Units','normalized','Position',[0.475 0.35 0.4 0.125],...
            'Value',1);

        label5 = uicontrol('Parent',scaleBarFig,'Style','text','String','Position','FontSize',12,'Units','normalized','Position',[0.05 0.25 .5 .125]);
        enterDropdown2 = uicontrol('Parent',scaleBarFig,'Style','popupmenu','String',{'Upper right';'Upper left';'Lower right'; 'Lower left'},...
            'FontSize',fz2,'Units','normalized','Position',[0.475 0.25 0.4 0.125],...
            'Value',1);
        
        overlayCheck = uicontrol('Parent',scaleBarFig,'Style','checkbox','String',...
        'Overlay','Units','normalized','Position',[.25 0.2 0.75 .05],'FontSize',12,'Value',1);
        
        boldTextCheck = uicontrol('Parent',scaleBarFig,'Style','checkbox','String',...
        'Bold text','Units','normalized','Position',[.25 0.15 0.75 .05],'FontSize',12);

        hideTextCheck = uicontrol('Parent',scaleBarFig,'Style','checkbox','String',...
        'Hide text','Units','normalized','Position',[.25 0.1 0.75 .05],'FontSize',12);

        scaleBarBtn = uicontrol('Parent',scaleBarFig,'Style','pushbutton','String','Ok',...
            'FontSize',12,'Units','normalized','Position',[0.64 0.02 0.15 0.05],...
            'Callback',{@getScaleBarValue,enterLabel1,enterLabel2,enterLabel3,enterDropdown1,...
            enterDropdown2,overlayCheck,boldTextCheck,hideTextCheck});

        scaleBarCancel = uicontrol('Parent',scaleBarFig,'Style','pushbutton','String','Cancel',...
            'FontSize',12,'Units','normalized','Position',[0.82 0.02 0.15, 0.05],...
            'Callback',{@closeScaleBar,scaleBarFig});
        scaleBarCheck = 1; 
    end

%%

    function get_textbox_data1(enterLabel1,eventdata)
        usr_input = get(enterLabel1,'String');
        usr_input = str2double(usr_input);
        set(enterLabel1,'UserData',usr_input)
    end

    function get_textbox_data2(enterLabel2,eventdata)
        usr_input = get(enterLabel2,'String');
        usr_input = str2double(usr_input);
        set(enterLabel2,'UserData',usr_input)
    end

    function get_textbox_data3(enterLabel3,eventdata)
        usr_input = get(enterLabel3,'String');
        usr_input = str2double(usr_input);
        set(enterLabel3,'UserData',usr_input)
    end

%% 
 function closeScaleBar(src,event,scaleBarFig)     
        close(scaleBarFig); 
        scaleBarCheck = 0; 
    end

%% 
    function getScaleBarValue(src,event,width,heightPixels,fontSize,fontcolor,position,overlayCheck,boldTextCheck,hideTextCheck)
        colors = ["white" "black" "cyan" "red"];
        scaleBar = get(width,'UserData'); 
        scaleBarPos = get(position,'Value');
        heightPix = get(heightPixels,'UserData');
        fColor = colors(get(fontcolor,'Value')); 
        fontNo = get(fontSize,'UserData'); 
        overlayVal = get(overlayCheck,'Value'); 
        boldText = get(boldTextCheck,'Value'); 
        hideText = get(hideTextCheck,'Value'); 
        BFvisualziation(BFcontrol,axVisualization,pixelInput);
    end

%% visualization function
    function BFvisualziation(BFcontrol,axVisualization,pixelsizeSet)
       
        iS = numField_4.Value;
        iZ = numField_3.Value;
        iC = numField_1.Value;
        iT = numField_2.Value;
        r.setSeries(iS - 1);       
        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
        if BFcontrol.mergechannelFlag == 0
            I = bfGetPlane(r, iPlane);
        else % merge channel box is checked 
            imageData = nan(stackSizeY,stackSizeX,nChannels);
            for iC = 1:nChannels
                iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                imageData(:,:,iC) = bfGetPlane(r, iPlane);
            end
            if nChannels == 2
                I = uint8(imfuse(imageData(:,:,1), imageData(:,:,2)));
            else
                I = uint8(imageData);
            end
        end
        BFfigure = findobj(0,'Tag','BF-MAT figure');
        figure(BFfigure);
        figureTitle = sprintf('%dx%dx%d pixels, Z=%d/%d,  Channel= %d/%d, Timepoint=%d/%d,pixelSize=%3.2f um, Series=%d/%d',...
            stackSizeX,stackSizeY,stackSizeZ,iZ,nFocalplanes,iC,nChannels,iT,nTimepoints,voxelSizeXdouble,iS,seriesCount);
        title(figureTitle,'FontSize',10,'Parent',axVisualization);
        imagesc(I,'Parent',axVisualization);
        set(axVisualization,'YTick',[],'XTick',[]);
        axis image equal
  
        colormap(axVisualization,BFcontrol.colormap);
        if BFcontrol.mergechannelFlag == 1
            if nChannels == 2 || nChannels == 3
                set(sliderObjects{2},'Enable','off')
            end

        else
            if nChannels > 1
                set(sliderObjects{2},'Enable','on')
            end

        end

        
        if nargin == 3 & ~isempty(pixelsizeSet.Value)
            
            voxelSizeXdouble = str2double(pixelsizeSet.Value);
            voxelSizeYdouble =voxelSizeXdouble;
            units = '\mum';
            if overlayVal == 1
                switch scaleBarPos
                    case 1
                        [row, col, ~] = size(I);
                        x = round([col-(2*(scaleBar/voxelSizeXdouble)), col-(scaleBar/voxelSizeXdouble)]);
                        y = round([row*.05, row*.05]);
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        if hideText == 0
                            if boldText == 1
                                text(round(((x(1)+x(2))/2)-col/51.2),round(row*.07),[num2str(round(scaleBar)) units],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                                hold on;
                            else
                                text(round(((x(1)+x(2))/2)-col/51.2),round(row*.07),[num2str(round(scaleBar)) units],'FontSize', fontNo,'Color',fColor);
                                hold on;
                            end
                        end
                    case 2
                        [row, col, ~] = size(I);
                        x = [scaleBar/voxelSizeXdouble, 2*(scaleBar/voxelSizeXdouble)];
                        y = round([row*.05, row*.05]);
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        if hideText == 0
                            if boldText == 1
                                text(round(((x(1)+x(2))/2)-10),round(row*.07),[num2str(round(scaleBar)) units],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                                hold on;
                            else
                                text(round(((x(1)+x(2))/2)-10),round(row*.07),[num2str(round(scaleBar)) units],'FontSize', fontNo,'Color',fColor);
                                hold on;
                            end
                        end

                    case 3
                        [row, col, ~] = size(I);
                        x = [col-(2*(scaleBar/voxelSizeXdouble)), col-(scaleBar/voxelSizeXdouble)];
                        y = round([row*.93, row*.93]);

                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        if hideText == 0
                            if boldText == 1
                                text(round(((x(1)+x(2))/2)-col/51.2),round(row*.95),[num2str(round(scaleBar)) units],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                                hold on;
                            else
                                text(round(((x(1)+x(2))/2)-col/51.2),round(row*.95),[num2str(round(scaleBar)) units],'FontSize', fontNo,'Color',fColor);
                                hold on;
                            end
                        end
                    case 4
                        [row, col, ~] = size(I);
                        x = [scaleBar/voxelSizeXdouble, 2*(scaleBar/voxelSizeXdouble)];
                        y = round([row*.93, row*.93]);
                        line(x,y,'LineWidth',heightPix,'Color',fColor,'Parent',axVisualization);
                        if hideText == 0
                            if boldText == 1
                                text(round(((x(1)+x(2))/2)-10),round(row*.95),[num2str(round(scaleBar)) units],'FontWeight','bold','FontSize', fontNo,'Color',fColor);
                                hold on;
                            else
                                text(round(((x(1)+x(2))/2)-10),round(row*.95),[num2str(round(scaleBar)) units],'FontSize', fontNo,'Color',fColor);
                                hold on;
                            end
                        end
                end
            end
        end % discplay scale bar
    end
%% save button callback to save images using bfsave function
    function save_Callback (src,eventData)
% exportRadioList = {'Current Image','Each Focal Plane','Each Time Point','Each Channel',...
% 'Each Plane OME-TIFF','Each Plane MATLAB 8-bit'}; 
        for iB = 1: numberofButtons
            if exportBG{iB}.Value == 1
               exportType = exportBG{iB}.Text;
               break
            end
        end
        iS = numField_4.Value;
        r.setSeries(iS - 1);
        switch exportType 
            case 'Current Image'
                selpath = uigetdir(BFcontrol.imagePath);
           
                % 'dimensionOrder', 'XYZCT'
                iZ = numField_3.Value;
                iC = numField_1.Value;
                iT = numField_2.Value;
                if BFcontrol.mergechannelFlag == 1
                    tarea.Value = [tarea.Value; {'Saving current image MATLAB 8-bit or color image... '}];
                    drawnow
                    saveProgressDLG = uiprogressdlg(fig,'Title','Exporting current merged image',...
                        'Indeterminate','on','Cancelable','on');
                    imageData = nan(stackSizeY,stackSizeX,nChannels);
                    for iC = 1:nChannels
                        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                        imageData(:,:,iC) = bfGetPlane(r, iPlane);
                    end
                    if nChannels == 2
                        I = uint8(imfuse(imageData(:,:,1), imageData(:,:,2)));
                    else
                        I = uint8(imageData);
                    end

                    outputName2 = fullfile(selpath,sprintf('CurrentMerged-%dChannels-Z%d-T%d_%s_MAT8bit.tif',nChannels,iZ,iT,BFcontrol.imageName));
                    imwrite(I, outputName2);
                    tarea.Value = [tarea.Value;{'Current merged image saving completed'}];
                    close(saveProgressDLG)
                    return
                else
                    tarea.Value = [tarea.Value; {'Saving current image to ome.tif file with meta data and MATLAB 8-bit grayscale image... '}];
                    drawnow
                    saveProgressDLG = uiprogressdlg(fig,'Title','Exporting current plane',...
                        'Indeterminate','on','Cancelable','on');
                    iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                    I1 = bfGetPlane(r, iPlane);
                    metadata = createMinimalOMEXMLMetadata(I1);
                    if ~isempty(voxelSizeXdouble) && ~isempty(voxelSizeYdouble)
                        pixelSize = ome.units.quantity.Length(java.lang.Double(voxelSizeXdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeX(pixelSize,0);
                        metadata.setPixelsPhysicalSizeY(pixelSize, 0);
                    end
                    if ~isempty(voxelSizeZdouble)
                        pixelSizeZ = ome.units.quantity.Length(java.lang.Double(voxelSizeZdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeZ(pixelSizeZ,0);
                    end
                    outputName1 = fullfile(selpath,sprintf('Current-C%d-Z%d-T%d_%s.ome.tif',iC,iZ,iT,BFcontrol.imageName));
                    bfsave(I1, outputName1, 'metadata', metadata);
                    outputName2 = fullfile(selpath,sprintf('Current-C%d-Z%d-T%d_%s_MAT8bit.tif',iC,iZ,iT,BFcontrol.imageName));
                    imwrite(uint8(255*mat2gray(I1)), outputName2);
                    tarea.Value = [tarea.Value;{'Current plane saving completed'}];
                    close(saveProgressDLG)
                end
            case 'Each Focal Plane'
                if nFocalplanes == 1
                    tarea.Value = [tarea.Value;...
                        {sprintf(' \n Image with more than one focal planes is needed to conduct this focalplanes splitting operation \n')}];
                    return
                end
                selpath = uigetdir(BFcontrol.imagePath, 'Pick an output folder');
                tarea.Value = [tarea.Value; {'Saving each focal plane to an image with meta data... '}];
                drawnow
                saveProgressDLG = uiprogressdlg(fig,'Title','Exporting each focal plane',...
                    'Indeterminate','on','Cancelable','on');
                for iZ = 1: nFocalplanes
                    I = [];
                    if nChannels ==1 && nTimepoints == 1
                        iC = 1;iT = 1;
                        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                        I = bfGetPlane(r, iPlane);
                    elseif nChannels > 1 && nTimepoints == 1
                        iT = 1;
                        for iC = 1:nChannels
                            iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                            I(:,:,1,iC,1) = bfGetPlane(r, iPlane);
                        end
                    elseif nChannels > 1 && nTimepoints > 1
                        for iC = 1:nChannels
                            for iT = 1:nTimepoints
                                iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                                I(:,:,1,iC,iT) = bfGetPlane(r, iPlane);
                            end
                        end
                    else
                        error('Reading error')
                    end
                    metadata = createMinimalOMEXMLMetadata(I);
                    if ~isempty(voxelSizeXdouble) && ~isempty(voxelSizeYdouble)
                        pixelSize = ome.units.quantity.Length(java.lang.Double(voxelSizeXdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeX(pixelSize,0);
                        metadata.setPixelsPhysicalSizeY(pixelSize, 0);
                    end
                    if ~isempty(voxelSizeZdouble)
                        pixelSizeZ = ome.units.quantity.Length(java.lang.Double(voxelSizeZdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeZ(pixelSizeZ,0);
                    end
                    outputName = fullfile(selpath,sprintf('Z%d_%s.ome.tif',iZ,BFcontrol.imageName));
                    bfsave(I, outputName, 'metadata', metadata);
                end
                tarea.Value = [tarea.Value;{'Each Z plane saved separatey'}];
                close(saveProgressDLG)
            case 'Each Time Point'
                if nTimepoints == 1
                    tarea.Value = [tarea.Value;...
                        {sprintf(' \n Image with more than one time frames is needed to conduct this timepoints splitting operation \n')}];
                    return
                end
                selpath = uigetdir(BFcontrol.imagePath, 'Pick an output folder');
                tarea.Value = [tarea.Value; {'Saving each time point to an image with meta data... '}];
                drawnow
                saveProgressDLG = uiprogressdlg(fig,'Title','Exporting each timepoint',...
                    'Indeterminate','on','Cancelable','on');
                for iT = 1: nTimepoints
                    I = [];
                    if nChannels ==1 && nFocalplanes == 1
                        iZ = 1;iC = 1;
                        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                        I = bfGetPlane(r, iPlane);
                    elseif nChannels > 1 && nFocalplanes == 1
                        iZ = 1;
                        for iC = 1:nChannels
                            iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                            I(:,:,1,iC,1) = bfGetPlane(r, iPlane);
                        end
                    elseif nChannels > 1 && nFocalplanes > 1
                        for iT = 1:nChannels
                            for iZ = 1:nFocalplanes
                                iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                                I(:,:,iZ,iC,1) = bfGetPlane(r, iPlane);
                            end
                        end
                    else
                        error('Reading error')
                    end
                    metadata = createMinimalOMEXMLMetadata(I);
                    if ~isempty(voxelSizeXdouble) && ~isempty(voxelSizeYdouble)
                        pixelSize = ome.units.quantity.Length(java.lang.Double(voxelSizeXdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeX(pixelSize,0);
                        metadata.setPixelsPhysicalSizeY(pixelSize, 0);
                    end
                    if ~isempty(voxelSizeZdouble)
                        pixelSizeZ = ome.units.quantity.Length(java.lang.Double(voxelSizeZdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeZ(pixelSizeZ,0);
                    end
                    outputName = fullfile(selpath,sprintf('T%d_%s.ome.tif',iT,BFcontrol.imageName));
                    bfsave(I, outputName, 'metadata', metadata);
                end
                tarea.Value = [tarea.Value;{'Each time point saved separatey'}];
                close(saveProgressDLG)
            case 'Each Channel'
                if nChannels == 1
                   tarea.Value = [tarea.Value;...
                       {sprintf(' \n Multiple channel image is needed to conduct this channel splitting operation \n')}];
                   return
                end
                selpath = uigetdir(BFcontrol.imagePath, 'Pick an output folder');
                tarea.Value = [tarea.Value; {'Saving ome.tiff file with meta data... '}];
                drawnow
                saveProgressDLG = uiprogressdlg(fig,'Title','Exporting individal channel',...
                    'Indeterminate','on','Cancelable','on');
                for iC = 1: nChannels
                    I = [];
                    if nTimepoints ==1 && nFocalplanes == 1
                        iZ = 1;iT = 1;
                        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                        I = bfGetPlane(r, iPlane);
                    elseif nTimepoints > 1 && nFocalplanes == 1
                        iZ = 1;
                        for iT = 1:nTimepoints
                            iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                            I(:,:,1,1,iT) = bfGetPlane(r, iPlane);
                        end
                    elseif nTimepoints > 1 && nFocalplanes > 1
                        for iT = 1:nTimepoints
                            for iZ = 1:nFocalplanes
                                iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                                I(:,:,iZ,1,iT) = bfGetPlane(r, iPlane);
                            end
                        end
                    else
                        error('Reading error')
                    end
                    metadata = createMinimalOMEXMLMetadata(I);
                    if ~isempty(voxelSizeXdouble) && ~isempty(voxelSizeYdouble)
                        pixelSize = ome.units.quantity.Length(java.lang.Double(voxelSizeXdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeX(pixelSize,0);
                        metadata.setPixelsPhysicalSizeY(pixelSize, 0);
                    end
                    if ~isempty(voxelSizeZdouble)
                        pixelSizeZ = ome.units.quantity.Length(java.lang.Double(voxelSizeZdouble), ome.units.UNITS.MICROMETER);
                        metadata.setPixelsPhysicalSizeZ(pixelSizeZ,0);
                    end
                    outputName = fullfile(selpath,sprintf('C%d_%s.ome.tif',iC,BFcontrol.imageName));
                    bfsave(I, outputName, 'metadata', metadata);
                end
                tarea.Value = [tarea.Value;{'Each channel saved separatey'}];
                close(saveProgressDLG)
 
            case 'Each Plane OME-TIFF' 
                selpath = uigetdir(BFcontrol.imagePath);
                tarea.Value = [tarea.Value; {'Saving ome.tiff file with meta data... '}];
                drawnow
                % 'dimensionOrder', 'XYZCT'
                noCZT = nChannels*nFocalplanes*nTimepoints;
                iii = 0;
                saveProgressDLG = uiprogressdlg(fig,'Title','Exporting file',...
                    'Indeterminate','on','Cancelable','on');
                for iC = 1: nChannels
                    for iZ = 1:nFocalplanes
                        for iT = 1:nTimepoints
                            iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                            I1 = bfGetPlane(r, iPlane);
                            metadata = createMinimalOMEXMLMetadata(I1);
                            if ~isempty(voxelSizeXdouble) && ~isempty(voxelSizeYdouble)
                                pixelSize = ome.units.quantity.Length(java.lang.Double(voxelSizeXdouble), ome.units.UNITS.MICROMETER);
                                metadata.setPixelsPhysicalSizeX(pixelSize,0);
                                metadata.setPixelsPhysicalSizeY(pixelSize, 0);
                            end
                            if ~isempty(voxelSizeZdouble)
                                pixelSizeZ = ome.units.quantity.Length(java.lang.Double(voxelSizeZdouble), ome.units.UNITS.MICROMETER);
                                metadata.setPixelsPhysicalSizeZ(pixelSizeZ,0);
                            end
                            outputName = fullfile(selpath,sprintf('C%d-Z%d-T%d_%s.ome.tif',iC,iZ,iT,BFcontrol.imageName));
                            bfsave(I1, outputName, 'metadata', metadata);
                            iii = iii+1;
                        end
                    end
                end
                tarea.Value = [tarea.Value;{'ome.tiff file saving completed'}];
                close(saveProgressDLG)
            case 'Each Plane MATLAB 8-bit'
                selpath = uigetdir(BFcontrol.imagePath);
                tarea.Value = [tarea.Value; {'Saving MATLAB 8-bit'}];
                drawnow
                % 'dimensionOrder', 'XYZCT'
                noCZT = nChannels*nFocalplanes*nTimepoints;
                iii = 0;
                saveProgressDLG = uiprogressdlg(fig,'Title','Exporting MATLAB 8-bit file',...
                    'Indeterminate','on','Cancelable','on');
                for iC = 1: nChannels
                    for iZ = 1:nFocalplanes
                        for iT = 1:nTimepoints
                            iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
                            I1 = bfGetPlane(r, iPlane);
                            outputName = fullfile(selpath,sprintf('C%d-Z%d-T%d_%s_MAT8bit.tif',iC,iZ,iT,BFcontrol.imageName));
                            imwrite(uint8(255*mat2gray(I1)), outputName);
                            iii = iii+1;
                        end
                    end
                end
                tarea.Value = [tarea.Value;{'MATLAB 8-bit file saving completed'}];
                close(saveProgressDLG)
        end
    end

%% reset button callback
    function resetImg_Callback(resetClear, eventData)
        if exist('BFdata')
            bioformatsMatlabGUI(BFdata)
        else
            bioFormatsMatlabGUI()
        end
    end

%% cancel button to close the window
    function exit_Callback(src,eventData)
        figs = findall(0,'Type','figure','Tag','bfWindow');
        if ~isempty(figs)
            delete(figs)
        end
        scaleBarFigs = findall(0,'Type','figure','Tag','scaleBarFig');
        if ~isempty(scaleBarFigs)
            delete(scaleBarFigs)
        end
        BFmergedfigure = findobj(0,'Tag','BF-MAT figure');
        if ~isempty(BFmergedfigure)
            delete(BFmergedfigure)
        end

        svsOpenFig = findobj(0,'Tag','svs open options');
        if ~isempty(svsOpenFig)
            delete(svsOpenFig)
        end

    end
end

