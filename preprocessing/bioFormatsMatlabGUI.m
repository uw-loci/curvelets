function bioFormatsMatlabGUI
clear,clc, home, close all
addpath(genpath(fullfile('./../bfmatlab')));

% don't want multiple windows open at the same time.
figs = findall(0,'Type','figure','Tag','bfWindow');
if ~isempty(figs)
    delete(figs)
end

scaleBarFigs = findall(0,'Type','figure','Tag','scaleBarFig');
if ~isempty(scaleBarFigs)
    delete(scaleBarFigs)
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
global Img;
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
voxelSizeXdouble = []; % 
voxelSizeYdouble = [];
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
fig = uifigure('Resize', 'on', 'Position',[20*(windowSize(3)/1600) 155*(windowSize(4)/900) 500*(windowSize(3)/1600) 390*(windowSize(4)/900)], 'Tag', 'bfWindow');

% fig = uifigure('Position',[100 100 500 390]);
fig.Name = "bfGUI";
% fig.UserData = struct("ff",'',"r",'',"Img",'',"ImgData",[]);

% Manage app layout
main = uigridlayout(fig);
main.ColumnWidth = {250*(windowSize(3)/1600),'1x'};
% main.ColumnWidth = {250,250};
main.RowHeight = {110*(windowSize(4)/900), 110*(windowSize(4)/900), 120*(windowSize(4)/900)};
% main.RowHeight = {110,110,120};

% Create UI components
lbl_1 = uilabel(main,'Position',[100*(windowSize(3)/1600) 450*(windowSize(4)/900) 50*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Import','FontSize',14,'FontWeight','bold');
% lbl_1 = uilabel(main,'Position',[100 450 50 20],'Text','Import','FontSize',14,'FontWeight','bold');
lbl_1.Layout.Row = 1;
lbl_1.Layout.Column = 1;
btn_1 = uibutton(fig,'push','Position',[100*(windowSize(3)/1600) 320*(windowSize(4)/900) 50*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Load','ButtonPushedFcn',@import_Callback);
% btn_1 = uibutton(fig,'push','Position',[100 320 50 20],'Text','Load',...
%     'ButtonPushedFcn',@import_Callback);

% down sampling option temporarily disable 
% ds = uidropdown(fig,'Position',[100 280 100 20]);
% ds.Items = ["Sampling 1" "Sampling 2" "Sampling 3"];

lbl_2 = uilabel(main,'Text','Export','FontSize',14,'FontWeight','bold');
lbl_2.Layout.Row = 2;
lbl_2.Layout.Column = 1;
ss = uidropdown(fig,'Position',[100*(windowSize(3)/1600) 200*(windowSize(4)/900) 120*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'ValueChangedFcn',@save_Callback);
% ss = uidropdown(fig,'Position',[100 220 120 20], 'ValueChangedFcn',@save_Callback);
ss.Items = ["Regular" "MATLAB readable" "Metadata"];
btn_2 = uibutton(fig,'Position',[100*(windowSize(3)/1600) 165*(windowSize(4)/900) 50*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Save','ButtonPushedFcn',@export_Callback);
% btn_2 = uibutton(fig,'Position',[100 170 50 20],'Text','Save','ButtonPushedFcn',@export_Callback);

lbl_3 = uilabel(main);
lbl_3.Text = 'Info';
lbl_3.Layout.Row = 3;
lbl_3.Layout.Column = 1;
tarea = uitextarea(main);
tarea.Layout.Row = 3;
tarea.Layout.Column = 1;
tarea.Value= 'This area displays info';


% lbl_5 = uilabel(main,'Text','Split Windows','FontSize',14,'FontWeight','bold');
% lbl_5.Layout.Row = 0.5;
% lbl_5.Layout.Column = 2;
dimensionLabelWidth = 80*(windowSize(3)/1600);
dimensionLabelHeight = 20*(windowSize(4)/900);
dimensionLabelX = 15*(windowSize(3)/1600);
dimensionLabelY = 110*(windowSize(4)/900);
dimensionNumberX = 85*(windowSize(3)/1600);
dimensionNumberY = 110*(windowSize(4)/900);
dimensionHightShift = 25*(windowSize(4)/900); 

dimensionNumberWidth = 50*(windowSize(3)/1600);
dimensionNumberHeight = 20*(windowSize(4)/900);


% dimensionLabelWidth = 80;
% dimensionLabelHeight = 20;
% dimensionLabelX = 310;
% dimensionLabelY = 340;
% dimensionNumberX = 390;
% dimensionNumberY = 340;
% dimensionHightShift = 25; 
% 
% dimensionNumberWidth = 50;
% dimensionNumberHeight = 20;

viewingOptionsPanel = uipanel(fig,'Title','Viewing options','FontSize',14,'FontWeight','bold');
viewingOptionsPanel.Position = [275*(windowSize(3)/1600) 225*(windowSize(4)/900) 227*(windowSize(3)/1600) 167*(windowSize(4)/900)];
% viewingOptionsPanel = uipanel(fig,'Units','normalized','Position',[0.55 0.55  0.55 0.45],...
%     'Title', 'Viewing options','FontSize',14,'FontWeight','bold');
% viewingOptionsPanel = uipanel('Parent',fig,'Units','normalized','Position',[0.5 0.55  0.5 0.45],...
%     'Title', 'Viewing options','FontSize',14,'FontWeight','bold');
% lbl_series = uilabel('Parent',viewingOptionsPanel,'Units','normalized',...
%     'Position',[dimensionLabelX dimensionLabelY dimensionLabelWidth dimensionLabelHeight],'Text','Series');
% numField_4 = uieditfield('Parent',viewingOptionsPanel,'Units','normalized',...
%     'Position',[dimensionLabelX+dimensionLabelWidth dimensionLabelY dimensionNumberWidth dimensionNumberHeight],...
%     'Value', 1,'ValueChangedFcn',@(numField_4,event) getSeries_Callback(numField_4,event));

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
mergeChannelCheck = uicheckbox(viewingOptionsPanel,'Text','Merge channels','Position',[dimensionLabelX-10 dimensionNumberY-dimensionHightShift*4.25 150 20], 'Value',0, ...
    'ValueChangedFcn',@(mergeChannelCheck,event) mergeChannelCheck_Callback(mergeChannelCheck,event));

% lbl_5 = uilabel(fig,'Position',[370 360 80 20],'Text','Split Windows','FontSize',14,'FontWeight','bold');
% lbl_series = uilabel(fig,'Position',[370 360 80 20],'Text','Series');
% lbl_Channel  = uilabel(fig,'Position',[370 330 80 20],'Text','Channel');
% lbl_Timepoints = uilabel(fig,'Position',[370 300 80 20],'Text','Timepoints');
% lbl_Focalplanes = uilabel(fig,'Position',[370 270 80 20],'Text','Focalplanes');
% numField_4 = uieditfield(fig,'numeric','Position',[435 360 50 20],'Limits',[0 1000],...
%     'Value', 1,'ValueChangedFcn',@(numField_4,event) getSeries_Callback(numField_4,event));
% numField_1 = uieditfield(fig,'numeric','Position',[435 330 50 20],'Limits',[0 1000],...
%     'Value', 1,'ValueChangedFcn',@(numField_1,event) getChannel_Callback(numField_1,event));
% numField_2 = uieditfield(fig,'numeric','Position',[435 300 50 20],'Limits',[0 1000],...
%     'Value', 1,'ValueChangedFcn',@(numField_2,event) getTimepoints_Callback(numField_2,event));
% numField_3 = uieditfield(fig,'numeric','Position',[435 270 50 20],'Limits',[0 1000],...
%     'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event));
BFobjects{1} = numField_4; %series
BFobjects{2} = numField_1; % channel
BFobjects{3} = numField_2; % timepoint
BFobjects{4} = numField_3;  % focoalplane;
BFobjects{5} = mergeChannelCheck;  % merge channel 

% lbl_4 = uilabel(main,'Text','Metadata','FontSize',14,'FontWeight','bold');
% lbl_4.Layout.Row = 2;
% lbl_4.Layout.Column = 2;
metadataPanel = uipanel('Parent',fig,'Position',[275*(windowSize(3)/1600) 145*(windowSize(4)/900) 227*(windowSize(3)/1600) 80*(windowSize(4)/900)], ...
    'Title', 'Metadata viewing','FontSize',14,'FontWeight','bold');

btn_3 = uibutton(metadataPanel,'Position',[15*(windowSize(3)/1600) 30*(windowSize(4)/900) 150*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
    'Text','Display Metadata','ButtonPushedFcn',@dispmeta_Callback);
% btn_3 = uibutton(fig,'Position',[300 175 130 20],'Text','Display Metadata',...
%     'ButtonPushedFcn',@dispmeta_Callback);
btn_4 = uibutton(metadataPanel,'Position',[15*(windowSize(3)/1600) 5*(windowSize(4)/900) 150*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','Display OME-XML Data'...
    ,'ButtonPushedFcn',@disOMEpmeta_Callback);
% btn_4 = uibutton(fig,'Position',[300 150 150 20],'Text','Display OME-XML Data'...
%     ,'ButtonPushedFcn',@disOMEpmeta_Callback);

% ,'Text','Channels''Text','Timepoints','Focal Planes'

lbl_6 = uilabel(main,'Text','View','FontSize',14,'FontWeight','bold');
lbl_6.Layout.Row = 3;
lbl_6.Layout.Column = 2;

% scalebar 
% scaleBarLabel = uilabel(fig,'Position',[320 80 120 20],'Text','Scale Bar');
scaleBarInit = uibutton(fig,'Position', [320*(windowSize(3)/1600) 110*(windowSize(4)/900) 80*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','Scale Bar',...
      'ButtonPushedFcn', @setScaleBar);
% scaleBarInit = uibutton(fig,'Position', [320 110 80 20],'Text','Scale Bar',...
%       'ButtonPushedFcn', @setScaleBar);
scaleBarInit = uilabel(fig,'Position', [320*(windowSize(3)/1600) 80*(windowSize(4)/900) 80*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','Pixel size(um)');
pixelInput = uieditfield(fig,'text','Position', [405*(windowSize(3)/1600) 80*(windowSize(4)/900) 80*(windowSize(3)/1600) 20*(windowSize(4)/900)],...
            'Value', '');

% pixelInput = uieditfield(fig,'text','Position', [405 80 80 20],...
%             'Value', '');
 
% color map options
color_lbl = uilabel(fig,'Position',[320*(windowSize(3)/1600) 50*(windowSize(4)/900) 80*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','Colormap');
% color_lbl = uilabel(fig,'Position',[320 50 80 20],'Text','Colormap');
color = uidropdown(fig,'Position',[375*(windowSize(3)/1600) 50*(windowSize(4)/900) 120*(windowSize(3)/1600) 20*(windowSize(4)/900)],'ValueChangedFcn',@setColor); 
% color = uidropdown(fig,'Position',[375 50 120 20],'ValueChangedFcn',@setColor); 
color.Items = ["Default Colormap" "MATLAB Color: JET" "MATLAB Color: Gray" "MATLAB Color: hsv"...
    "MATLAB Color: Hot" "MATLAB Color: Cool"];

% reset button
btnReset = uibutton(fig,'push','Position',[290*(windowSize(3)/1600) 10*(windowSize(4)/900) 60*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','Reset',...
    'ButtonPushedFcn',@resetImg_Callback);
% ok button [horizonal vertical element_length element_height]
btnOK = uibutton(fig,'Position',[360*(windowSize(3)/1600) 10*(windowSize(4)/900) 60*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','OK','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@return_Callback);
% btnOK = uibutton(fig,'Position',[360 10 60 20],'Text','OK','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@return_Callback);
% cancel button 
btnCancel = uibutton(fig,'Position',[430*(windowSize(3)/1600) 10*(windowSize(4)/900) 60*(windowSize(3)/1600) 20*(windowSize(4)/900)],'Text','Cancel','ButtonPushedFcn',@exit_Callback);
% btnCancel = uibutton(fig,'Position',[430 10 60 20],'Text','Cancel','ButtonPushedFcn',@exit_Callback);
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
        BFvisualziation(BFcontrol,axVisualization);
        
    end

%% Create the function for the import callback
    function  import_Callback(hObject,Img,eventdata,handles)
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
        Img = imread(ff);
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
        cellArrayText{1} = sprintf('%s : %s', 'Filename', fileName);
        cellArrayText{2} = sprintf('%s : %d', 'Series', seriesCount);
        cellArrayText{3} = sprintf('%s : %d', 'Channel', nChannels);
        cellArrayText{4} = sprintf('%s : %d', 'TimePoints', nTimepoints);
        cellArrayText{5} = sprintf('%s : %d', 'Focal Planes', nFocalplanes);
        tarea.Value=cellArrayText;
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
          
  
%         omeMeta = Img{1, 4};
%         omeXML = char(omeMeta.dumpXML());
    end

%% import svs 
    function import_svs(fileName, pathName)
        defaultBackground = get(0,'defaultUicontrolBackgroundColor');
        svsfig = figure('Resize','on','Color',defaultBackground,'Units','normalized','Position',[0.3 0.1 0.4 0.8],'Visible','on',...
        'MenuBar','none','name','Bio-formats series options','NumberTitle','off','UserData',0);
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
        seriesCount = 1;
        nChannels = r.getSizeC(); 
        nTimepoints = r.getSizeT(); 
        nFocalplanes = r.getSizeZ(); 
        btn_1.UserData=struct("ff",ff,"r",r,"seriesCount",seriesCount,...
        "nChannels",nChannels,"nTimepoints",nTimepoints,"nFocalplanes",nFocalplanes);
        cellArrayText{1} = sprintf('%s : %s', 'Filename', fileName);
        cellArrayText{2} = sprintf('%s : %d', 'Series', seriesCount);
        cellArrayText{3} = sprintf('%s : %d', 'Channel', nChannels);
        cellArrayText{4} = sprintf('%s : %d', 'TimePoints', nTimepoints);
        cellArrayText{5} = sprintf('%s : %d', 'Focal Planes', nFocalplanes);
        tarea.Value=cellArrayText;
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
%         BFcontrol.colormap = 'gray';
%         switch lower(fExt)
%             case '.svs'
%                 BFcontrol.iSeries = 4; numField_4.Value =   BFcontrol.iSeries;
%                 svsfig = figure('Resize','on','Color','white','Units','normalized','Position',[0.007 0.05 0.260 0.85],'Visible','on',...
%                 'MenuBar','none','name','Bio-formats import options','NumberTitle','off','UserData',0);
%             otherwise
%                 BFcontrol.iSeries = seriesCount; numField_4.Value =   BFcontrol.iSeries;
%         end
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

        ImgData = bfopen(ff);
        if iSeries == 1
            metadata = ImgData{1, 2};
%             newStr = split(metadata,","); 
            subject = metadata.get('Subject');
            title = metadata.get('Title');
            metadataKeys = metadata.keySet().iterator();
            for i=1:metadata.size()
                key = metadataKeys.nextElement();
                value = metadata.get(key);

                if  ~isa(value,'double')
                    
                    fprintf('%s = %s\n', key, value);  
                end
                if  isa(value,'double')
                    
                    fprintf('%s = %d\n', key, value);  
                end
                
            end
                %Data identification function
                %method1: if else, check type before printing 
                %method2: separate by , split() failed
            close(d) 
        else if valList{4}>1
                metadata = ImgData{iSeries, 2}; 
%                 metadata = r.getSeriesMetadata();
                subject = metadata.get('Subject');
                title = metadata.get('Title');
                metadataKeys = metadata.keySet().iterator();
                for i=1:metadata.size()
                    key = metadataKeys.nextElement();
                    value = metadata.get(key);
                    if  ~isa(value,'double')
                        
                        fprintf('%s = %s\n', key, value);
                    end
                    if  isa(value,'double')
                        
                        fprintf('%s = %d\n', key, value);
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
            cellArrayText{1} = sprintf('%s : %d', 'Pixel X', voxelSizeXdouble);
            cellArrayText{2} = sprintf('%s : %d', 'Pixel Y', voxelSizeYdouble);
            cellArrayText{3} = sprintf('%s : %d', 'image width', stackSizeX);
            cellArrayText{4} = sprintf('%s : %d', 'image height', stackSizeY);
%             cellArrayText{5} = sprintf('%s : %d', 'value in default unit', voxelSizeXdefaultValue)
%             cellArrayText{5} = sprintf('%s : %d', 'default unit', voxelSizeXdefaultUnit)
            tarea.Value = cellArrayText;
            fprintf(omeXML)
            close(d)
        else if iSeries>1
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
                cellArrayText{1} = sprintf('%s : %d', 'Pixel X', voxelSizeXdouble);
                cellArrayText{2} = sprintf('%s : %d', 'Pixel Y', voxelSizeYdouble);
                tarea.Value = cellArrayText; 
                fprintf(omeXML)
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
            'normalized','Position',[0.185 0.75 0.14 0.3],'Visible','on','Tag','scaleBarFig',...
            'MenuBar','none','name','Scale Bar Options','NumberTitle','off','UserData',0);
        
        label1 = uicontrol('Parent',scaleBarFig,'Style','text','String','Width in microns','FontSize',12,'Units','normalized','Position',[0.05 0.8 .5 .125]);
        enterLabel1 = uicontrol('Parent',scaleBarFig,'Style','edit','String','10','BackgroundColor','w','UserData',[10],'Units','normalized','Position',[0.6 0.835 .14 .125],'Callback',{@get_textbox_data1});

        label2 = uicontrol('Parent',scaleBarFig,'Style','text','String','Height in pixels','FontSize',12,'Units','normalized','Position',[0.05 0.65 .5 .125]);
        enterLabel2 = uicontrol('Parent',scaleBarFig,'Style','edit','String','2','BackgroundColor','w','UserData',[2],'Units','normalized','Position',[0.6 0.685 .14 .125],'Callback',{@get_textbox_data2});

        label3 = uicontrol('Parent',scaleBarFig,'Style','text','String','Font size','FontSize',12,'Units','normalized','Position',[0.05 0.5 .5 .125]);
        enterLabel3 = uicontrol('Parent',scaleBarFig,'Style','edit','String','8','BackgroundColor','w','UserData',[8],'Units','normalized','Position',[0.6 0.535 .14 .125],'Callback',{@get_textbox_data3});
        8
        label4 = uicontrol('Parent',scaleBarFig,'Style','text','String','Font color','FontSize',12,'Units','normalized','Position',[0.05 0.35 .5 .125]);
        enterDropdown1 = uicontrol('Parent',scaleBarFig,'Style','popupmenu','String',{'white';'black';'cyan'; 'red'},...
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
    function BFvisualziation(BFcontrol,axVisualization,pixelInput)
        r.setSeries(valList{4} - 1);
        iSeries = valList{4};
        iZ = valList{3};
        iT = valList{2};
        iC= valList{1};
%         fig_1 = ancestor(src,"figure","toplevel");
%         data=fig_1.UserData; 
        
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
            stackSizeX,stackSizeY,stackSizeZ,iZ,nFocalplanes,iC,nChannels,iT,nTimepoints,voxelSizeXdouble,iSeries,seriesCount);
        title(figureTitle,'FontSize',10,'Parent',axVisualization);
        imagesc(I,'Parent',axVisualization);
        set(axVisualization,'YTick',[],'XTick',[]);
  
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

        voxelSizeXdouble = str2double(pixelInput.Value); 
        units = '\mum';

  %      if scaleBarCheck == 1
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
    end
%% save button callback to save images using bfsave function
    function save_Callback (src,eventData)
        val = ss.Value; 
%         ss.Items = [,"Regular" "MATLAB readable" "Metadata"];
        switch val 
            case 'Regualar'
                selpath = uigetdir(path);
                [a b] = fileparts(selpath);
                bfsave(I, b);  %strsplit   %strfind

            case 'MATLAB readable' 
               [I pathName] = uiputfile; 
               fprintf(pathName); 
               
            case 'Metadata'
                selpath = uigetdir(path);
                [a b] = fileparts(selpath);                 
                metadata = createMinimalOMEXMLMetadata(I);
                pixelSize = ome.units.quantity.Length(java.lang.Double(.05), ome.units.UNITS.MICROMETER);
                metadata.setPixelsPhysicalSizeX(pixelSize,voxelSizeXdouble);
                metadata.setPixelsPhysicalSizeY(pixelSize, voxelSizeXdouble);
                pixelSizeZ = ome.units.quantity.Length(java.lang.Double(.2), ome.units.UNITS.MICROMETER);
                metadata.setPixelsPhysicalSizeZ(pixelSizeZ,stackSizeZ);         
                bfsave(I, b,'metadata.ome.tiff', 'metadata', metadata); 
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

%% ok button callback to return selected image
    function return_Callback(src,eventData)
        assignin('base','BFoutput',I)
    end
%% cancel button to close the window
    function exit_Callback(src,eventData)
        close(fig)
    end
end

