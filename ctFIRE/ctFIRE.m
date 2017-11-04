 function ctFIRE(CAdata)

% ctFIRE.m - is the main program of an open-source collagen fiber quantification tool
% named CT-FIRE(curvelet transform plus FIRE algorithm),allowing users to automatically
% extract collagen fibers in an image, and quantifing fibers with descriptive statistics,
% including fiber angle,fiber length, fiber straightness, and fiber width.

% CT-FIRE combines the advantage of the fast discrete curvelet transform
% (FDCT, curvelet.org,2004) to denoise the image and enhance the fiber edge and
% and the advantage of fiber extraction algorithm(FIRE,A. M. Stein,
% 2008 Journal of Microscopy) to extract individual fibers.

%By Laboratory for Optical and Computational Instrumentation, UW-Madison
%since 2012
% Developers:
% Yuming Liu (primary contact and lead developer, Feb 2012-)
% Guneet Singh Mehta (current graduate student developer, Jun 2014-)
% Adib Keikhosravi (current graduate student developer, Aug 2014-)
% Jeremy Bredfeldt (former LOCI PhD student, Feb 2012- Jul 2014)
% Carolyn Pehlke (former LOCI PhD student, Feb 2012- May 2012)
% Prashant Mittal, former undergraduate student from IITJ (India), had contribution on testing and debugging, Aug 2014-May 2015

% Webpage: http://loci.wisc.edu/software/ctfire
% github: https://github.com/uw-loci/curvelets

% References:
% Bredfeldt, J.S., Liu, Y., Pehlke, C.A., Conklin, M.W., Szulczewski, J.M., Inman,
%   D.R., Keely, P.J., Nowak, R.D., Mackie, T.R., and Eliceiri, K.W. (2014).
%  Computational segmentation of collagen fibers from second-harmonic generation
%  images of breast cancer. Journal of Biomedical Optics 19, 016007�016007.

% Licensed under the 2-Clause BSD license
% Copyright (c) 2012 - 2017, Board of Regents of the University of Wisconsin-Madison
% All rights reserved.

if nargin>0
    home
    CA_flag = 1;
    CTF_gui_name = 'CT-FIRE Module for CurveAlign';
    disp('Switching to CT-FIRE Module')
else
    home; close all; clear all;
    CA_flag =0;
    CTF_gui_name = 'CT-FIRE V2.0 Beta';
    disp('Running CT-FIRE 2.0');
end
%only keep the CurveAlign GUI open
fig_ALL = findobj(0,'type','figure');
fig_keep = findobj(0,'Name','CurveAlign V4.0 Beta');
if ~isempty(fig_ALL)
    if isempty(fig_keep)
        close(fig_ALL)
    else
        for ij = 1:length(fig_ALL)
            if (strcmp (fig_ALL(ij).Name,fig_keep.Name) == 1)
                fig_ALL(ij) = [];
                close(fig_ALL)
                break
            end
        end
    end
    clear ij fig_ALL fig_keep
end
warning('off','all');
%Add path of associated toolboxes
if CA_flag == 0     % CT-FIRE and CurveAlign have different "current working directory"
    if (~isdeployed)
        addpath('../../../CurveLab-2.1.2/fdct_wrapping_matlab');
        addpath(genpath(fullfile('../FIRE')));
        addpath('../20130227_xlwrite');
        addpath('.');
        addpath('../xlscol/');
        display('Please make sure you have downloaded the Curvelets library from http://curvelet.org')
        %Add matlab java path
        javaaddpath('../20130227_xlwrite/poi_library/poi-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
        javaaddpath('../20130227_xlwrite/poi_library/xmlbeans-2.3.0.jar');
        javaaddpath('../20130227_xlwrite/poi_library/dom4j-1.6.1.jar');
        javaaddpath('../20130227_xlwrite/poi_library/stax-api-1.0.1.jar');
    end
end

%% remember the path to the last opened file
if exist('lastPATH_CTF.mat','file')
    lastPATHname = importdata('lastPATH_CTF.mat');
    if isequal(lastPATHname,0)
        lastPATHname = '';
    end
else
    %use current directory
    lastPATHname = '';
end

fz1 = 10; % font size for the text in a panel
fz2 = 9 ; % font size for the title of a panel
fz3 = 12; % font size for the button

ssU = get(0,'screensize');
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
%Figure for GUI
guiCtrl = figure('Resize','on','Color',defaultBackground','Units','normalized','Position',[0.007 0.05 0.260 0.85],'Visible','on',...
    'MenuBar','none','name',CTF_gui_name,'NumberTitle','off','UserData',0);

%Figure for showing Original Image
guiFig = figure('Resize','on','Color',defaultBackground','Units','normalized','Position',...
    [0.269 0.05 0.474*ssU(4)/ssU(3) 0.474],'Visible','off',...
    'MenuBar','figure','name','Original Image','NumberTitle','off','UserData',0, 'Tag','Original Image');

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);

guiFig2 = figure('Resize','on','Color',defaultBackground','Units','normalized',...
    'Position',[0.269 0.05 0.474*ssU(4)/ssU(3)*2 0.474],'Visible','off',...
    'MenuBar','figure','name','CTF Overlaid Image','Tag','CTF Overlaid Image',...
    'NumberTitle','off','UserData',0);

guiFig3 = figure('Resize','on','Color',defaultBackground','Units','pixels',...
    'Position',[0.269*ssU(3)+0.474*ssU(4)+5 0.05*ssU(4) 0.474*ssU(4) 0.474*ssU(4)],'Visible','off',...
    'MenuBar','figure','name','CT-FIRE ROI Output Image','NumberTitle','off');

guiFig4 = figure('Resize','on','Color',defaultBackground','Units','pixels',...
    'Position',[0.269*ssU(3)+0.474*ssU(4)*2+10 0.308*ssU(4) 0.285*ssU(4) 0.32*ssU(4)],'Visible','off',...
    'MenuBar','figure','name','CT-FIRE Fiber Metrics Distribution','NumberTitle','off');

% button to open an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Open File(s)',...
    'FontSize',fz3,'Enable','off','Units','normalized','Position',[0.005 .91 .405 .035],...
    'callback','ClickedCallback','Callback', {@getFile});

% panel to contain buttons for loading and updating parameters
guiPanel0 = uipanel('Parent',guiCtrl,'Title','Parameters: ','Units','normalized','Position',[0.466 .865 0.534 .08],'Fontsize',fz2);
setFIRE_load = uicontrol('Parent',guiPanel0,'Style','pushbutton','String','Load',...
    'FontSize',fz3,'Units','normalized','Position',[0 0 0.5 0.8 ],...
    'Callback', {@setpFIRE_load});
setFIRE_update = uicontrol('Parent',guiPanel0,'Style','pushbutton','String','Update',...
    'FontSize',fz3,'Units','normalized','Position',[0.5 0 0.5 0.8],...
    'Callback', {@setpFIRE_update});

% panel to run measurement
guiPanel01 = uipanel('Parent',guiCtrl,'Title','Run Options','Units','normalized','Position',[0.466 .73 0.534 .125],'Fontsize',fz2);
imgRun = uicontrol('Parent',guiPanel01,'Style','pushbutton','String','RUN',...
    'FontSize',fz3,'Units','normalized','Position',[0 .525 .2 0.405],...
    'Callback',{@kip_run},'TooltipString','Run Analysis');
% select run options
selRO = uicontrol('Parent',guiPanel01,'Style','popupmenu','String',{'CT-FIRE(CTF)';'ROI Manager';'CTF ROI Analyzer'; 'CTF Post-ROI Analyzer';'FIRE (Original 2D Fiber Extraction)'},...
    'FontSize',fz2,'Units','normalized','Position',[0.22 -0.15 0.78 1],...
    'Value',1,'TooltipString','Select Run Mode','Callback',@selRo_fn);

% only enable the CT-FIRE mode for CurveAlign
if CA_flag == 1
    selRO.String(2:5) = [];
end

% button to process an output mat file of ctFIRE
postprocess = uicontrol('Parent',guiPanel01,'Style','pushbutton','String','Post-processing',...
    'FontSize',fz3,'UserData',[],'Units','normalized','Position',[0 0 1 .5],...
    'callback','ClickedCallback','Callback', {@postP});

% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontSize',fz3,'Units','normalized','Position',[.80 .965 .20 .035],'callback','ClickedCallback','Callback',{@resetImg},'TooltipString','Click to start over');

% Checkbox to load .mat file for post-processing
matModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','.mat','Min',0,'Max',3,'Units','normalized','Position',[.175 .975 .17 .025],'TooltipString','Use CT-FIRE Output');

%checkbox for batch mode option
batchModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Batch','Min',0,'Max',3,'Units','normalized','Position',[.0 .975 .17 .025],'TooltipString','Process Multiple Images');

%checkbox for selected output option
selModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','OUT.adv','Min',0,'Max',3,'Units','normalized','Position',[.320 .975 .19 .025],'Callback',{@OUTsel});

%checkbox for selected output option
parModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Parallel','Min',0,'Max',3,'Units','normalized','Position',[.545 .975 .17 .025],'Callback',{@PARflag_callback},'TooltipString','Use parallel computing for multiple images or stack(s).');

% panel to contain output figure control
guiPanel1 = uipanel('Parent',guiCtrl,'Title','Output Figure Control','Units','normalized','FontSize',fz2,'Position',[0 0.345 1 .186]);

% text box for getting output figure control
LL1label = uicontrol('Parent',guiPanel1,'Style','text','String','Minimum Fiber Length [pixels] ','FontSize',fz1,'Units','normalized','Position',[0.05 0.85 .85 .125]);
enterLL1 = uicontrol('Parent',guiPanel1,'Style','edit','String','30','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.85 0.875 .14 .125],'Callback',{@get_textbox_data1});

RESlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Image Res.[dpi]','FontSize',fz1,'Units','normalized','Position',[0.05 .65 .85 .125]);
enterRES = uicontrol('Parent',guiPanel1,'Style','edit','String','300','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.85 .675 .14 .125],'Callback',{@get_textbox_data2});

LW1label = uicontrol('Parent',guiPanel1,'Style','text','String','Fiber Line Width  [0-2]','FontSize',fz1,'Units','normalized','Position',[0.05 .45 .85 .125]);
enterLW1 = uicontrol('Parent',guiPanel1,'Style','edit','String','0.5','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.85 .475 .14 .125],'Callback',{@get_textbox_data3});

WIDlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Max Fiber Width [pixels]','FontSize',fz1,'Units','normalized','Position',[0.05 .25 .65 .125]);
enterWID = uicontrol('Parent',guiPanel1,'Style','edit','String','15','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.85 .275 .14 .125],'Callback',{@get_textbox_dataWID});
WIDadv = uicontrol('Parent',guiPanel1,'Style','pushbutton','String','MORE...',...
    'FontSize',fz1*.8,'Units','normalized','Position',[0.695 .265 .145 .15],...
    'Callback', {@setpWID});

BINlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Histogram Bins Number [#]','FontSize',fz1,'Units','normalized','Position',[0.05 .075 .65 .145]);
enterBIN = uicontrol('Parent',guiPanel1,'Style','edit','String','10','BackgroundColor','w','Min',0,'Max',1,'UserData',10,'Units','normalized','Position',[.85 .075 .14 .125],'Callback',{@get_textbox_data4});
BINauto = uicontrol('Parent',guiPanel1,'Style','pushbutton','String','AUTO...',...
    'FontSize',fz1*.8,'Units','normalized','Position',[0.695 .075 .145 .15],...
    'Callback', {@setpBIN});


% panel to contain output checkboxes
guiPanel2 = uipanel('Parent',guiCtrl,'Title','Output Options ','Units','normalized','FontSize',fz2,'Position',[0 .125 1 .209]);

% checkbox to display the image reconstructed from the thresholded
% overlaid images
makeRecon = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Overlaid Fibers','Min',0,'Max',3,'Units','normalized','Position',[.075 .8 .8 .125],'FontSize',fz1);

% non overlaid images
makeNONRecon = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Non-overlaid Fibers','Min',0,'Max',3,'Units','normalized','Position',[.075 .65 .8 .125],'FontSize',fz1);

% checkbox to display a angle histogram
makeHVang = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Angle Histogram & Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .50 .8 .125],'FontSize',fz1);

% checkbox to display a length histogram
makeHVlen = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Length Histogram & Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .35 .8 .125],'FontSize',fz1);

% checkbox to output list of values
makeHVstr = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Straightness Histogram & Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .20 .8 .125],'FontSize',fz1);

% checkbox to save length value
makeHVwid = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Width Histogram & Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .05 .8 .125],'FontSize',fz1);

%add more output control options
OUTmore_str = struct('unitconversionFLAG',0, 'ppmRatio',5.7,'fiber_midpointEST',1);  % advanced output options, add ROI related options as in CurveAlign later
%unitconversionFLAG: 1:  convert the unit of width and length from pixel to micron and save it. 0:no conversion
%ppmRatio: pixel per micron ratio for the SHG image, default value is 5.7
%fiber_midpointEST: 1: use two fiber end points coordinate to estimate
%fiber middle point, middle point is not necessary on the fiber; 2: find the point that divides the fiber into two segments of equal length

OUTmore_ui = uicontrol('Parent',guiPanel2,'Style','pushbutton','Enable','off','String','MORE...',...
    'Units','normalized','Position',[.855 .05 .125 .15],'FontSize',fz1,'FontName','FixedWidth',...
    'Callback', {@OUTmore_callback});

% slider for scrolling through stacks
slideLab = uicontrol('Parent',guiCtrl,'Style','text','String','Stack Image Preview, Slice:','FontSize',fz2,'Units','normalized','Position',[0 .61 .75 .1]);
stackSlide = uicontrol('Parent',guiCtrl,'Style','slide','Units','normalized','position',[0 .64 1 .05],'min',1,'max',100,'val',1,'SliderStep', [.1 .2],'Enable','off');
% panel to contain stack control
guiPanelsc = uipanel('Parent',guiCtrl,'visible','on','BorderType','none','FontSize',fz2,'Units','normalized','Position',[0 0.54 1 .0864]);
%  = uicontrol('Parent',guiPanel2,'Style','radio','Enable','on','String','Stack Range','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .03 .8 .1]);
hsr = uibuttongroup('parent',guiPanelsc,'title','Slices Range', 'visible','on','Units','normalized','Position',[0 0 1 1]);
% Create three radio buttons in the button group.
sru1 = uicontrol('Style','radiobutton','String','Whole Stack','Units','normalized',...
    'pos',[0 0.6 0.5 0.5 ],'parent',hsr,'HandleVisibility','on','FontSize',fz1);
sru2 = uicontrol('Style','radiobutton','String','Slices','Units','normalized',...
    'pos',[0 0.1 0.5 0.5],'parent',hsr,'HandleVisibility','on','FontSize',fz1);
sru3 = uicontrol('Style','edit','String','','Units','normalized',...
    'pos',[0.25 0.1 0.1 0.5],'parent',hsr,'HandleVisibility','on','BackgroundColor','w',...
    'Userdata',[],'Callback',{@get_textbox_sru3});
sru4 = uicontrol('Style','text','String','To','Units','normalized',...
    'pos',[ 0.40 -0.05 0.1 0.5],'parent',hsr,'HandleVisibility','on','FontSize',fz1);
sru5 = uicontrol('Style','edit','String','','Units','normalized',...
    'pos',[0.55 0.1 0.1 0.5],'parent',hsr,'HandleVisibility','on','BackgroundColor','w',...
    'Userdata',[],'Callback',{@get_textbox_sru5});
set(hsr,'SelectionChangeFcn',@selcbk);

% set font
set([guiPanel2 LL1label LW1label WIDlabel RESlabel enterLL1 enterLW1 enterWID WIDadv enterRES ...
    BINlabel enterBIN BINauto OUTmore_ui makeHVlen makeHVstr makeRecon makeNONRecon makeHVang makeHVwid imgOpen ...
    setFIRE_load, setFIRE_update imgRun imgReset selRO postprocess slideLab],'FontName','FixedWidth')
set([LL1label LW1label WIDlabel RESlabel BINlabel],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset postprocess],'FontWeight','bold')
set([LL1label LW1label WIDlabel RESlabel BINlabel slideLab],'HorizontalAlignment','left')

%initialize gui
set([postprocess setFIRE_load, setFIRE_update imgRun selRO makeHVang makeRecon makeNONRecon enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto ,...
    makeHVstr makeHVlen makeHVwid OUTmore_ui sru1 sru2 sru3 sru4 sru5],'Enable','off')
set([makeRecon,makeHVang,makeHVlen,makeHVstr,makeHVwid],'Value',3)

% initialize variables used in some callback functions
coords = [-1000 -1000];
ff = '';
numSections = 0;
info = [];

% initialize the opensel
opensel = 0;
setappdata(imgOpen, 'opensel',opensel);

% initialize the width calculation parameters
widcon = struct('wid_mm',10,'wid_mp',6,'wid_sigma',1,'wid_max',0,'wid_opt',1);
wid_mm = widcon.wid_mm; % minimum maximum fiber width
wid_mp = widcon.wid_mp; % minimum points to apply fiber points selection
wid_sigma = widcon.wid_sigma; % confidence region, default +- 1 sigma
wid_max = widcon.wid_max;     % calculate the maximum width of each fiber, deault 0, not calculate; 1: caculate
wid_opt = widcon.wid_opt;     % choice for width calculation, default 1 use all

BINa = '';     % automaticallly estimated BINs number
%%-------------------------------------------------------------------------
%% add globle variables
fileName = [];
pathName = [];
imgLabel = uicontrol('Parent',guiCtrl,'Style','listbox','String','None Selected','HorizontalAlignment','left','FontSize',fz2,'Units','normalized','Position',[0  .725  .442 .175],'Callback', {@imgLabel_Callback});
index_selected = 1;   % default file index
%Define  parameters to be passed to CTFroi
ROIctfp = struct('filename',[],'pathname',[],'ctfp',[],'CTF_data_current',[],'roiopenflag',[],'fiber_midpointEST',1);  % arguments for ROI manager call
idx = 1; % index to the current slice of a stack

ROI_flag = 0; %
%%parallel computing flag to close or open parpool
prlflag = 0 ; %YL: parallel loop flag, 0: regular for loop; 1: parallel loop
if exist('parpool','file')
    poolobj = gcp('nocreate');  % get current pool
    if ~isempty(poolobj)
        delete(poolobj);
    end
    disp('Parallel pool is closed.')
end
%%
%YL: ROI-related directories here - values used in program
ROImanDir = '';         %fullfile(pathName,'ROI_management');
ROIanaBatDir = '';      % fullfile(pathName,'CTF_ROI','Batch','ROI_analysis')
ROIanaBatOutDir = '';   %fullfile(ROIanaBatDir,'ctFIREout');
ROIanaDir = '';         %fullfile(pathName,'CTF_ROI','Batch');
ROIDir = '';            %fullfile(pathName,'CTF_ROI');
ROIpostBatDir = '';     %fullfile(pathName,'CTF_ROI','Batch','ROI_post_analysis');

%% YL create CT-FIRE output table for ROI analysis and batch mode analysis
img = [];  % current image data
roiMATnamefull = ''; % directory for the fullpath of ROI .mat files
fileEXT = '.tif';   % defaut image extention
ROIshapes = {'Rectangle','Freehand','Ellipse','Polygon'};

% Column names and column format
columnname = {'No.','Image Label','ROI Label','Width','Length','Straightness','Angle','FeatNum',...
    'Method','CROP','POST','Shape','Xc','Yc','Z'};
columnformat = {'numeric','char','char','char','char' ,'char','char','char',...
    'char','char','char','char','numeric','numeric','numeric'};
columnwidth = {30 100 60 60 60 60 60 60,...
    60 40 40 60 30 30 30};   %
CTF_data_current = [];
selectedROWs = [];
stackflag = [];

figPOS = [0.269 0.05+0.474+0.095 0.474*ssU(4)/ssU(3)*2 0.85-0.474-0.095];
CTF_table_fig = figure('Units','normalized','Position',figPOS,'Visible','off',...
    'NumberTitle','off','Name','CT-FIRE Analysis Output Table','Tag', 'CT-FIRE Analysis Output Table in Main GUI','Menu','None');
CTF_output_table = uitable('Parent',CTF_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],...
    'Data', CTF_data_current,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnWidth',columnwidth,...
    'ColumnEditable', [false false false false false false false false false false false false false false false],...
    'RowName',[],...
    'CellSelectionCallback',{@CTFot_CellSelectionCallback});
%%
set(imgOpen,'Enable','on')
infoLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Initialization is complete. Import image or data to start.','FontSize',fz1,'Units','normalized','Position',[0 .005 1 .11]);
set(infoLabel,'FontName','FixedWidth','HorizontalAlignment','left','BackgroundColor','g');
figure(guiCtrl);%textSizeChange(guiCtrl);
% set(findall(guiCtrl,'-property','Fontname'),'Fontname','Fixedwidth');

% disable the advanced output module of CT-FIRE
if CA_flag == 1
    set(selModeChk,'Enable','off')
end
% callback functoins
%-------------------------------------------------------------------------
%% output table callback functions

    function CTFot_CellSelectionCallback(hobject, eventdata,handles)
    %CT-FIRE ROI analysis output table callback function - shows selected ROIs on the image
        handles.currentCell=eventdata.Indices;              %currently selected fields
        selectedROWs = unique(handles.currentCell(:,1));
        if isempty(selectedROWs)
            disp('No image is selected in the output table.')
            return
        end
        selectedZ = CTF_data_current(selectedROWs,15);
        if length(selectedROWs) > 1
            IMGnameV = CTF_data_current(selectedROWs,2);
            uniqueName = strncmpi(IMGnameV{1},IMGnameV,length(IMGnameV{1}));
            if length(find(uniqueName == 0)) >=1
                error('Only a single image OR single section of a stack should be selected.');
            else
                IMGname = IMGnameV{1};
            end
        elseif length(selectedROWs)== 1
            IMGname = CTF_data_current{selectedROWs,2};
        end

        guiFig4 = findobj(0,'Name','CT-FIRE Fiber Metrics Distribution');
        if isempty(guiFig4)
            guiFig4 = figure('Resize','on','Color',defaultBackground','Units','pixels',...
                'Position',[0.269*ssU(3)+0.474*ssU(4)*2+10 0.308*ssU(4) 0.285*ssU(4) 0.32*ssU(4)],'Visible','off',...
                'MenuBar','figure','name','CT-FIRE Fiber Metrics Distribution','NumberTitle','off');
        end
        csvdata_ROI = [];  % raw data for histogram
        bins = get(enterBIN,'UserData');

        if ~isempty(CTF_data_current{selectedROWs(1),3})   % ROI analysis, ROI label is not empty
            roiMATnamefull = [IMGname,'_ROIs.mat'];
            load(fullfile(ROImanDir,roiMATnamefull),'separate_rois')
            ROInames = fieldnames(separate_rois);
            IMGnamefull = fullfile(pathName,[IMGname,fileEXT]);
            IMGinfo = imfinfo(IMGnamefull);
            numSections = numel(IMGinfo); % number of sections
            if numSections > 1
                for j = 1:length(selectedZ)
                    Zv(j) = selectedZ{j};
                end
                if size(unique(Zv)) == 1
                    zc = unique(Zv);
                else
                    error('Only display ROIs in the same section of a stack.')
                end

            else
                zc = 1;
            end
            if numSections == 1
                img2 = imread(IMGnamefull);
            elseif numSections > 1
                img2 = imread(IMGnamefull,zc);
            end
            if size(img2,3) > 1
                img2 = rgb2gray(img2);
            end
            IMGO(:,:,1) = uint8(img2);
            IMGO(:,:,2) = uint8(img2);
            IMGO(:,:,3) = uint8(img2);

            cropFLAG_selected = unique(CTF_data_current(selectedROWs,10));
            if size(cropFLAG_selected,1)~=1
                disp('Please select ROIs processed with the same method.')
                return
            elseif size(cropFLAG_selected,1)==1
                cropFLAG = cropFLAG_selected;
            end
            postFLAG_selected = unique(CTF_data_current(selectedROWs,11));
            if size(postFLAG_selected,1)~=1
                disp('Please select ROIs processed with the same method.')
                return
            elseif size(postFLAG_selected,1)==1
                postFLAG = postFLAG_selected;
            end

            if strcmp(cropFLAG,'YES')
                for i= 1:length(selectedROWs)
                    CTFroi_name_selected =  CTF_data_current(selectedROWs(i),3);
                    if numSections > 1
                        roiNamefullNE = [IMGname,sprintf('_s%d_',zc),CTFroi_name_selected{1}];
                    elseif numSections == 1
                        roiNamefullNE = [IMGname,'_', CTFroi_name_selected{1}];
                    end
                    %load all the results
                    if strcmp(postFLAG,'NO')
                        csvdata_readTMP = check_csvfile_fn(ROIanaBatDir,roiNamefullNE);
                    elseif strcmp(postFLAG,'YES')
                        csvdata_readTMP = check_csvfile_fn(ROIpostBatDir,roiNamefullNE);
                    end
                    csvdata_ROI{i,1} = csvdata_readTMP{1};  % width
                    csvdata_ROI{i,2} = csvdata_readTMP{2};  % length
                    csvdata_ROI{i,3} = csvdata_readTMP{3};  % straightness
                    csvdata_ROI{i,4} = csvdata_readTMP{4};  % angle
                    ROInumV{i} = cell2mat(CTF_data_current(selectedROWs(i),1));

                    IMGol = [];
                    olName = fullfile(ROIanaBatDir,'ctFIREout',sprintf('OL_ctFIRE_%s.tif',roiNamefullNE));
                    if exist(olName,'file')
                        IMGol = imread(olName);
                    else
                        data2=separate_rois.(CTFroi_name_selected{1}).roi;
                        a=round(data2(1));b=round(data2(2));c=round(data2(3));d=round(data2(4));
                        ROIrecWidth = c; ROIrecHeight = d;
                        IMGol = zeros(ROIrecHeight,ROIrecWidth,3);
                    end
                    if separate_rois.(CTFroi_name_selected{1}).shape == 1
                        data2=separate_rois.(CTFroi_name_selected{1}).roi;
                        a=round(data2(1));b=round(data2(2));c=round(data2(3));d=round(data2(4));
                        IMGO(b:b+d-1,a:a+c-1,1) = IMGol(:,:,1);
                        IMGO(b:b+d-1,a:a+c-1,2) = IMGol(:,:,2);
                        IMGO(b:b+d-1,a:a+c-1,3) = IMGol(:,:,3);
                        xx(i) = a+c/2;  yy(i)= b+d/2; ROIind(i) = selectedROWs(i);
                        aa2(i) = a; bb(i) = b;cc(i) = c; dd(i) = d;
                    else
                        error('Cropped image ROI analysis for shapes other than rectangles is not available so far.');
                    end
                end
                 if isempty(findobj(0,'Name', 'CT-FIRE ROI Output Image'))
                    guiFig3 = figure('Resize','on','Color',defaultBackground','Units','pixels',...
                        'Position',[0.269*ssU(3)+0.474*ssU(4)+5 0.05*ssU(4) 0.474*ssU(4) 0.474*ssU(4)],'Visible','off',...
                        'MenuBar','figure','Name','CT-FIRE ROI Output Image','NumberTitle','off');      % enable the Menu bar for additional operations
                 end
                figure(guiFig3);
                imshow(IMGO);set(guiFig,'Name',IMGname); hold on;
                for i= 1:length(selectedROWs)
                    CTFroi_name_selected =  CTF_data_current(selectedROWs(i),3);
                    if separate_rois.(CTFroi_name_selected{1}).shape == 1
                        rectangle('Position',[aa2(i) bb(i) cc(i) dd(i)],'EdgeColor','y','linewidth',3)
                    end
                    text(xx(i),yy(i),sprintf('%d',ROIind(i)),'fontsize', 10,'color','m')
                end
                hold off
                set(guiFig3,'Units','pixels','Position',[0.269*ssU(3)+0.474*ssU(4)+5 0.05*ssU(4) 0.474*ssU(4) 0.474*ssU(4)])

            end

            if strcmp(cropFLAG,'NO')
                ii = 0; boundaryV = {};yy = []; xx = []; RV = [];
                for i= 1:length(selectedROWs)
                    CTFroi_name_selected =  CTF_data_current(selectedROWs(i),3);
                    if ~iscell(separate_rois.(CTFroi_name_selected{1}).shape)
                        ii = ii + 1;
                        if numSections > 1
                            roiNamefullNE = [IMGname,sprintf('_s%d_',zc),CTFroi_name_selected{1}];
                        elseif numSections == 1
                            roiNamefullNE = [IMGname,'_', CTFroi_name_selected{1}];
                        end
                        %load all the results
                        if strcmp(postFLAG,'NO')
                            csvdata_readTMP = check_csvfile_fn(ROIanaBatDir,roiNamefullNE);
                        elseif strcmp(postFLAG,'YES')
                            csvdata_readTMP = check_csvfile_fn(ROIpostBatDir,roiNamefullNE);
                        end
                        csvdata_ROI{i,1} = csvdata_readTMP{1};  % width
                        csvdata_ROI{i,2} = csvdata_readTMP{2};  % length
                        csvdata_ROI{i,3} = csvdata_readTMP{3};  % straightness
                        csvdata_ROI{i,4} = csvdata_readTMP{4};  % angle
                        ROInumV{i} = cell2mat(CTF_data_current(selectedROWs(i),1));

                        IMGol = [];
                        if strcmp(postFLAG,'NO')
                            olName = fullfile(ROIanaBatDir,'ctFIREout',sprintf('OL_ctFIRE_%s.tif',roiNamefullNE));
                            if exist(olName,'file')
                                IMGol = imread(olName);
                            end
                        elseif strcmp(postFLAG,'YES')
                            olName = fullfile(ROIpostBatDir,'ctFIREout',sprintf('OL_ctFIRE_%s.tif',roiNamefullNE));
                            if exist(olName,'file')
                               IMGol = imread(olName);
                            end
                        end
                        if isempty(IMGol)
                            IMGol = zeros(size(IMGO));
                        end
                        IMG_height = size(IMGO,1);
                        IMG_width = size(IMGO,2);
                        boundary = separate_rois.(CTFroi_name_selected{1}).boundary{1};
                        [x_min,y_min,x_max,y_max] = enclosing_rect_fn(fliplr(boundary),IMG_height,IMG_width);
                        a = x_min;  % x of upper left corner of the enclosing rectangle
                        b = y_min;   % y of upper left corner of the enclosing rectangle
                        c = x_max-x_min;  % width of the enclosing rectangle
                        d = y_max - y_min;  % height of the enclosing rectangle
                        % replace the region of interest with the data in the
                        % ROI analysis output
                        IMGO(b:b+d-1,a:a+c-1,1) = IMGol(b:b+d-1,a:a+c-1,1);
                        IMGO(b:b+d-1,a:a+c-1,2) = IMGol(b:b+d-1,a:a+c-1,2);
                        IMGO(b:b+d-1,a:a+c-1,3) = IMGol(b:b+d-1,a:a+c-1,3);
                        boundaryV{ii} = boundary;
                        yy(ii) = separate_rois.(CTFroi_name_selected{1}).xm;
                        xx(ii) = separate_rois.(CTFroi_name_selected{1}).ym;
                        RV(ii) = i;
                        ROIind(ii) = selectedROWs(i);
                    else
                        disp('Selected ROI is a combined one, and was not displayed.')
                        return
                    end
                end

                if isempty(findobj(0,'Name', 'CT-FIRE ROI Output Image'))
                    guiFig3 = figure('Resize','on','Color',defaultBackground','Units','pixels',...
                        'Position',[0.269*ssU(3)+0.474*ssU(4)+5 0.05*ssU(4) 0.474*ssU(4) 0.474*ssU(4)],'Visible','off',...
                        'MenuBar','figure','Name','CT-FIRE ROI Output Image','NumberTitle','off');      % enable the Menu bar for additional operations
                end
                figure(guiFig3);
                imshow(IMGO); hold on;
                if ii > 0
                    for ii = 1:length(selectedROWs)
                        text(xx(ii),yy(ii),sprintf('%d',ROIind(ii)),'fontsize', 10,'color','m')
                        boundary = boundaryV{ii};
                        plot(boundary(:,2), boundary(:,1), 'm', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                        text(xx(ii),yy(ii),sprintf('%d',selectedROWs(RV(ii))),'fontsize', 10,'color','m')
                    end
                    set(guiFig3,'Units','pixels','Position',[0.269*ssU(3)+0.474*ssU(4)+5 0.05*ssU(4) 0.474*ssU(4) 0.474*ssU(4)])
                else
                    disp('NO CT-FIRE ROI analysis output was visualized.')
                end
                hold off
            end
            % histogram
            figure(guiFig4);
            tab_names = {'Width','Length','Straightness','Angle'};
            xlab_names = {'Width[pixels]','Length[Pixels]','Straightness[-]','Angle[Degrees]'};
            htabgroup = uitabgroup(guiFig4);
            for i = 1: length(selectedROWs)
                for j = 1: 4
                    tabfig_name1 = uitab(htabgroup, 'Title',...
                        sprintf('%d-%s',ROInumV{i},tab_names{j}));
                    hax_hist = axes('Parent', tabfig_name1);
                    set(hax_hist,'Position',[0.15 0.15 0.80 0.80]);
                    output_values = csvdata_ROI{i,j};
                    hist(output_values,bins);
                    xlabel(xlab_names{j})
                    ylabel('Frequency [#]')
                    axis square
                end
            end

        else    % full image, ROI label is empty
            % check the availability of guiFig2
            guiFig2_find = findobj(0,'Tag','CTF Overlaid Image');
            if isempty(guiFig2_find)
                guiFig2 = figure('Resize','on','Color',defaultBackground','Units','normalized',...
                    'Position',[0.269 0.05 0.474*ssU(4)/ssU(3)*2 0.474],'Visible','off',...
                    'MenuBar','figure','name','CTF Overlaid Image','Tag','CTF Overlaid Image',...
                    'NumberTitle','off','UserData',0);      % enable the Menu bar for additional operations
            end
            % end of guiFig2 check
            IMGnamefull = fullfile(pathName,[IMGname,fileEXT]);
            IMGinfo = imfinfo(IMGnamefull);
            SZ = selectedZ{1};
            if numel(IMGinfo) == 1
                imagename_mod = IMGname;
                OLnamefull = fullfile(pathName, 'ctFIREout',['OL_ctFIRE_',IMGname,'.tif']);
                OLinfo = imfinfo(OLnamefull);
                figure(guiFig2);
                set(guiFig2,'Name',['CT-FIRE Overlaid Image of ',IMGname,fileEXT]);
                % link the axes of the original and OL images to simply a visual inspection of the fiber extraction
                axLINK1(1)= subplot(1,2,1); set(axLINK1(1),'Position', [0.01 0.01 0.485 0.94]);
                imshow(IMGnamefull,'border','tight');
                title(sprintf('Original, %dx%d, %d-bit ,%3.2fM',IMGinfo.Width,...
                    IMGinfo.Height,IMGinfo.BitDepth,IMGinfo.FileSize/10^6),'fontweight','normal','FontSize',10)
                axis image
                axLINK1(2)= subplot(1,2,2); set(axLINK1(2),'Position', [0.505 0.01 0.485 0.94]);
                imshow(OLnamefull,'border','tight');
                title(sprintf('Overlaid, %dx%d, RGB, %3.2fM',OLinfo.Width,...
                    OLinfo.Height,OLinfo.FileSize/10^6),'fontweight','normal','FontSize',10)
                axis image
                linkaxes(axLINK1,'xy')
            elseif numel(IMGinfo) > 1
                imagename_mod = [IMGname,'_s',num2str(SZ)];
                OLnamefull = fullfile(pathName, 'ctFIREout',['OL_ctFIRE_',IMGname,'_s',num2str(SZ),'.tif']);
                OLinfo = imfinfo(OLnamefull);
                figure(guiFig2);
                set(guiFig2,'Name',['CT-FIRE Overlaid Image of ',IMGname,fileEXT,', ',num2str(SZ),'/',num2str(numel(IMGinfo))]);
                % link the axes of the original and OL images to simply a visual inspection of the fiber extraction
                axLINK1(1)= subplot(1,2,1); set(axLINK1(1),'Position', [0.01 0.01 0.485 0.94]);
                imgdata = imread(IMGnamefull,SZ);
                imshow(imgdata,'border','tight');
                title(sprintf('Original, %dx%d, %d-bit ,%3.2fM,',IMGinfo(SZ).Width,...
                    IMGinfo(SZ).Height,IMGinfo(SZ).BitDepth,IMGinfo(SZ).FileSize/10^6),'fontweight','normal','FontSize',10)
                axis image
                axLINK1(2)= subplot(1,2,2); ; set(axLINK1(2),'Position', [0.505 0.01 0.485 0.94]);
                imshow(OLnamefull,'border','tight');
                title(sprintf('Overlaid, %dx%d, RGB, %3.2fM',OLinfo.Width,...
                    OLinfo.Height,OLinfo.FileSize/10^6),'fontweight','normal','FontSize',10)
                axis image
                linkaxes(axLINK1,'xy')
            end

            %load all the results

            csvdata_readTMP = check_csvfile_fn(pathName,imagename_mod);
            csvdata_ROI{1,1} = csvdata_readTMP{1};  % width
            csvdata_ROI{1,2} = csvdata_readTMP{2};  % length
            csvdata_ROI{1,3} = csvdata_readTMP{3};  % straightness
            csvdata_ROI{1,4} = csvdata_readTMP{4};  % angle
            ROInumV{1} = cell2mat(CTF_data_current(selectedROWs(1),1));
            % histogram
            figure(guiFig4);
            tab_names = {'Width','Length','Straightness','Angle'};
            xlab_names = {'Width[pixels]','Length[Pixels]','Straightness[-]','Angle[Degrees]'};
            htabgroup = uitabgroup(guiFig4);
            for j = 1: 4
                tabfig_name1 = uitab(htabgroup, 'Title',...
                    sprintf('%d-%s',ROInumV{1},tab_names{j}));
                hax_hist = axes('Parent', tabfig_name1);
                set(hax_hist,'Position',[0.15 0.15 0.80 0.80]);
                output_values = csvdata_ROI{1,j};
                hist(output_values,bins);
                xlabel(xlab_names{j})
                ylabel('Frequency[#]')
                axis square
            end
        end

         function[xmid,ymid]=midpoint_fn(BW)
           s1_BW=size(BW,1); s2_BW=size(BW,2);
           xmid=0;ymid=0;count=0;
           for i2=1:s1_BW
               for j2=1:s2_BW
                   if(BW(i2,j2)==logical(1))
                      xmid=xmid+i2;ymid=ymid+j2;count=count+1;
                   end
               end
           end
           xmid=floor(xmid/count);ymid=floor(ymid/count);
        end

    end
%%

     function[]=kip_run(object,handles)
        runMeasure(object,handles);
     end
% callback function for imgOpen
     function getFile(imgOpen,eventdata)
         %checking for invalid combinations - if present then return
         % 1st invalid - out.adv+batch
         % 2nd Paral +batch
         %         if (get(batchModeChk,'Value')==get(batchModeChk,'Max')&&get(matModeChk,'Value')==get(matModeChk,'Max'))
         %             set(infoLabel,'String','Batchmode Processing cannot be done on .mat files.');
         %             return;
         %         end
         if(get(selModeChk,'Value')==get(selModeChk,'Max')&&get(parModeChk,'Value')==get(parModeChk,'Max'))
             set(infoLabel,'String','Parallel Processing cannot be done for Post-processing.');
             return;
         end

         if (get(batchModeChk,'Value') ~= get(batchModeChk,'Max')); openimg =1; else openimg =0;end
         if (get(matModeChk,'Value') ~= get(matModeChk,'Max')); openmat =0; else openmat =1;end
         if (get(selModeChk,'Value') ~= get(selModeChk,'Max')); opensel =0; else opensel =1;end


         if openimg==1 %openimg is 1 if one image is selected and 0 if multiple images
             % single image
             if openmat==0 % normal image
                 [imgName,imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select an Image',lastPATHname,'MultiSelect','on');
                 if(iscell(imgName))
                     openimg=0;%setting to multiple images mode
                     set(batchModeChk,'Value',get(batchModeChk,'Max'));%setting the batchmodechk box when multiple images are selected
                 end
             elseif openmat==1
                 [matName,matPath] = uigetfile({'*FIREout*.mat'},'Select .mat file(s)',lastPATHname,'MultiSelect','on');
                 if(iscell(matName))
                     openimg=0;%setting to multiple images mode
                     set(batchModeChk,'Value',get(batchModeChk,'Max'));%setting the batchmodechk box when multiple images are selected
                 end
             end
         elseif openimg==0
             %multiple images
             if openmat==0
                 [imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)',lastPATHname,'MultiSelect','on');
             elseif openmat==1
                 [matName matPath] = uigetfile({'*FIREout*.mat';'*.*'},'Select multi .mat files',lastPATHname,'MultiSelect','on');
             end
         end

         setappdata(imgOpen, 'openImg',openimg);
         setappdata(imgOpen, 'openMat',openmat);
         setappdata(imgOpen, 'opensel',opensel);

         if openimg ==1
             if openmat ~= 1
                 if ~isequal(imgPath,0)
                     lastPATHname = imgPath;
                     save('lastPATH_CTF.mat','lastPATHname');
                 end
                 if imgName == 0
                     disp('Please choose the correct image/data to start an analysis.');
                 else
                     set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update selRO enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto OUTmore_ui],'Enable','on');
                     set([imgOpen matModeChk batchModeChk postprocess],'Enable','off');
                     set(guiFig,'Visible','on');
                     set(infoLabel,'String','Load or Update Parameters');

                     ff = fullfile(imgPath, imgName);
                     info = imfinfo(ff);
                     numSections = numel(info);
                     if numSections > 1
                         openstack = 1;
                         setappdata(imgOpen, 'openstack',openstack);
                         setappdata(imgOpen,'totslice',numSections);
                         disp('Default slice range is the whole stack.')
                         setappdata(hsr,'wholestack',1);
                         img = imread(ff,1,'Info',info);
                         set(stackSlide,'max',numSections);
                         set(stackSlide,'Enable','on');
                         set(stackSlide,'SliderStep',[1/(numSections-1) 3/(numSections-1)]);
                         set(stackSlide,'Callback',{@slider_chng_img});
                         set(slideLab,'String','Stack Image Preview, Slice: 1');
                         set([sru1 sru2],'Enable','on')
                     else
                         openstack = 0;
                         setappdata(imgOpen, 'openstack',openstack);
                         img = imread(ff);
                     end
                     setappdata(imgOpen, 'openstack',openstack);
                     if size(img,3) > 1
                         img = rgb2gray(img);
                         disp('Color image was loaded but converted to grayscale image.')
                     end
                     figure(guiFig);imshow(img,'Parent',imgAx);
                     setappdata(imgOpen,'img',img);
                     setappdata(imgOpen,'type',info(1).Format)
                     colormap(gray);
                     if numSections > 1
                         set(guiFig,'name',sprintf('%s, stack, %d slices, %dx%d, %d-bit',imgName,numel(info),info(1).Width,info(1).Height,info(1).BitDepth));
                     else
                         set(guiFig,'name',sprintf('%s, %dx%d, %d-bit',imgName,info.Width,info.Height,info.BitDepth));
                     end
                     set([LL1label LW1label WIDlabel RESlabel BINlabel],'ForegroundColor',[0 0 0])
                     set(guiFig,'UserData',0)

                     if numSections > 1
                         %initialize gui
                         set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto OUTmore_ui],'Enable','on');
                         set([imgOpen matModeChk batchModeChk postprocess],'Enable','off');
                         set(guiFig,'Visible','on');
                         set(infoLabel,'String','Load and/or Update Parameters');
                     end
                     setappdata(imgOpen,'imgPath',imgPath);
                     setappdata(imgOpen, 'imgName',imgName);
                 end
             else
                 if ~isequal(matPath,0)
                     imgPath = strrep(matPath,'ctFIREout','');
                 end
                 if ~isequal(matPath,0)
                     lastPATHname = matPath;
                     save('lastPATH_CTF.mat','lastPATHname');

                 end

                 if matName == 0
                     disp('Please choose the correct image/data to start an analysis.');
                 else
                     matfile = [matPath,matName];
                     savePath = matPath;
                     %% 7-18-14: don't load imgPath,savePath, use relative image path
                     load(matfile,'imgName','cP','ctfP'); %
                     ff = fullfile(imgPath, imgName);
                     info = imfinfo(ff);
                     if cP.stack == 1
                         img = imread(ff,cP.slice);
                     else
                         img = imread(ff);
                     end
                     if size(img,3) > 1 %if rgb, pick one color
                         img = rgb2gray(img);
                         disp('Color image was loaded but converted to grayscale image.')
                     end
                     figure(guiFig);
                     %                     img = imadjust(img);  % YL: only display original image
                     imshow(img,'Parent',imgAx);

                     if cP.stack == 1
                         set(guiFig,'name',sprintf('%s, stack, %d slices, %dx%d, %d-bit',imgName,numel(info),info(1).Width,info(1).Height,info(1).BitDepth));
                     else
                         set(guiFig,'name',sprintf('%s, %dx%d, %d-bit',imgName,info.Width,info.Height,info.BitDepth));
                     end

                     setappdata(imgRun,'outfolder',savePath);
                     setappdata(imgRun,'ctfparam',ctfP);
                     setappdata(imgRun,'controlpanel',cP);
                     setappdata(imgOpen,'matPath',matPath);
                     setappdata(imgOpen,'matName',matName);  % YL

                     set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid enterLL1 enterLW1 enterWID WIDadv ...
                         enterRES enterBIN BINauto postprocess OUTmore_ui],'Enable','on');
                     set([imgOpen matModeChk batchModeChk imgRun setFIRE_load, setFIRE_update],'Enable','off');
                     set(infoLabel,'String','Load and/or Update Parameters');
                 end
             end
             setappdata(imgOpen,'imgPath',imgPath);
             setappdata(imgOpen, 'imgName',imgName);

         else   % open multi-files
             if openmat ~= 1
                 if ~isequal(imgPath,0)
                     lastPATHname = imgPath;
                     save('lastPATH_CTF.mat','lastPATHname');
                 end
                 if ~iscell(imgName)
                     error('Please select at least 2 files to do batch processing.')

                 else
                     setappdata(imgOpen,'imgPath',imgPath);
                     setappdata(imgOpen,'imgName',imgName);
                     set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update selRO enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto OUTmore_ui],'Enable','on');
                     set([imgOpen matModeChk batchModeChk postprocess],'Enable','off');
                     set(infoLabel,'String','Load and/or Update Parameters');
                 end
             else
                 if ~isequal(matPath,0)
                     imgPath = strrep(matPath,'ctFIREout','');
                 end
                 if ~isequal(matPath,0)
                     lastPATHname = matPath;
                     save('lastPATH_CTF.mat','lastPATHname');
                 end
                 if ~iscell(matName)
                     error('Please select at least 2 mat files to do batch processing.')
                 else
                     %build filename list
                     for i = 1:length(matName)
                         imgNametemp = load(fullfile(matPath,matName{i}),'imgName');
                         imgName{i} = imgNametemp.imgName;%
                     end
                     clear imgNametemp

                     setappdata(imgOpen,'matName',matName);
                     setappdata(imgOpen,'matPath',matPath);
                     set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto OUTmore_ui],'Enable','on');
                     set([postprocess],'Enable','on');
                     set([imgOpen matModeChk batchModeChk],'Enable','off');
                     set(infoLabel,'String','Select Parameters');
                 end
             end
         end

         % load default fiber extraction parameters for image(s) or stack
         if openmat ~= 1
             if imgPath ~= 0
                 %   load default fiber extraction parameters
                 [pathstr,pfname]=fileparts(which('FIREpdefault.mat'));
                 pdf = load(fullfile(pathstr,[pfname,'.mat']));
                 pdesc = pdf.pdesc;
                 pnum = pdf.pnum;
                 pvalue = pdf.pvalue;
                 tcnum = pdf.tcnum;
                 % Table description
                 %   Name        Size            Bytes  Class     Attributes
                 %   pdesc       1x1              7372  struct    description
                 %   pnum        1x1              4968  struct    number
                 %   pvalue      1x1              5062  struct    value
                 %   tcnum       1x5                40  double    rows need for a type change
                 pfnames = fieldnames(pvalue);    % parameter field names
                 pori = pvalue;

                 % change the type of the 'pvalue' fields into string,so that they can
                 % be used in ' inputdlg'
                 for itc = 1:27
                     if length(find([tcnum,3] == itc))==0   % itc= 3 is dtype: 'cityblock',not need to change to string type
                         fieldtc =pfnames{itc};
                         tcvalue = extractfield(pvalue,fieldtc);  % try replacing "extractfield" with "getfield" if the former does not work.
                         pvalue = setfield(pvalue,fieldtc,num2str(tcvalue));
                     else
                         %              disp(sprintf('Parameter # %d [%s], is of type string.',itc, pfnames{itc}));
                     end
                 end
                 currentP = struct2cell(pvalue)';
                 fpdesc = struct2cell(pdesc);
                 setappdata(imgOpen, 'FIREpvalue',pvalue);
                 setappdata(imgOpen, 'FIREparam',currentP);
                 setappdata(imgOpen,'FIREpname',pfnames);
                 setappdata(imgOpen,'FIREpdes',fpdesc);

                 %set default curvelet transform parameters
                 ctp = {'0.2','3'};
                 setappdata(imgOpen,'ctparam',ctp);
                 %set default parameters for imgRun

                 % change string type to numerical type and calculate sin or cos
                 for ifp = 1:27                 % number of fire parameters
                     if ifp ~= 3        % field 3 dtype: 'cityblock', should be kept string type,
                         if ifp ==4 | ifp == 22
                             pdf.pvalue.(pfnames{ifp}) = str2num(pdf.pvalue.(pfnames{ifp}));
                         elseif ifp == 10 | ifp == 14 | ifp == 19
                             pdf.pvalue.(pfnames{ifp}) = cos(pdf.pvalue.(pfnames{ifp})*pi/180);
                         end
                     end
                 end
                 ctfP.pct = str2num(ctp{1});
                 ctfP.SS  = str2num(ctp{2});
                 ctfP.value = pdf.pvalue;
                 ctfP.status = 0;               % not updated
                 setappdata(imgRun,'ctfparam',ctfP);
             end
         end
         set([selModeChk batchModeChk],'Enable','off');
         % not enable imgRUN when doing postprocessing of the .mat file(s)
         if openmat ~= 1
             set(imgRun,'Enable','on');
         end

         %% add global file name and path name
         if ~iscell(imgName)
             pathName = imgPath;
             fileName = {imgName};
         else
             fileName = imgName;
             pathName = imgPath;
         end
         try
             [~,~,fileEXT] = fileparts(fileName{1}) ; % all the images should have the same extention
             IMGnamefull = fullfile(pathName,fileName{1});
             IMGinfo = imfinfo(IMGnamefull);
             if numel(IMGinfo) > 1% number of sections
                 stackflag = 1;    %
             else
                 stackflag = 0;
             end
             set(imgLabel,'String',fileName);
         catch
             set(infoLabel,'String','Error in loading Image(s).');

         end

         %YL: define all the output files, directory here
         ROImanDir = fullfile(pathName,'ROI_management');
         ROIanaBatDir = fullfile(pathName,'CTF_ROI','Batch','ROI_analysis');
         ROIanaBatOutDir = fullfile(ROIanaBatDir,'ctFIREout');
         ROIanaDir = fullfile(pathName,'CTF_ROI','Batch');
         ROIDir = fullfile(pathName,'CTF_ROI');
         ROIpostBatDir = fullfile(pathName,'CTF_ROI','Batch','ROI_post_analysis');

         % add an option to show the previous analysis results
         % in "ctFIREout" folder
         CTFout_found = checkCTFoutput(pathName,fileName);
         existing_ind = find(cellfun(@isempty, CTFout_found) == 0); % index of images with existing output
         if isempty(existing_ind)
             set(infoLabel,'String',sprintf('No previous analysis was found. Please select an option from "Run Options", and if fiber extraction needs to be run, parameters can be updated/loaded.'))
         else
           disp(sprintf('Previous CT-FIRE analysis was found for %d out of %d opened image(s).',...
                 length(existing_ind),length(fileName)))
%              set(infoLabel,'String',sprintf('Previous CT-FIRE analysis was found for %d out of %d opened image(s).',...
%                  length(fileName),length(CTFout_found)))
             % user choose to check the previous analysis
             choice=questdlg('Check previoius CT-FIRE results?','Previous CT-FIRE analysis exists','Yes','No','Yes');
             if(isempty(choice))
                 return;
             else
                 switch choice
                     case 'Yes'
                         set(infoLabel, 'String',sprintf('Existing fiber extraction results listed: %d out of %d opened image(s). \n Running "CT-FIRE" now will overwrite them.',...
                       length(existing_ind),length(fileName)))
                         checkCTFout_display_fn(pathName,fileName,existing_ind);
                     case 'No'
                         set(infoLabel,'String','Choose "Run Options" and if necesssary, set/confirm parameters to run fiber extraction.')
                         return;
                 end
             end
         end

     end

%--------------------------------------------------------------------------
% callback function for listbox 'imgLabel'
    function imgLabel_Callback(imgLabel, eventdata, handles)
        % Function to set the filenames being displayed in ctFIRE GUI
        % hObject    handle to imgLabel
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        % Hints: contents = cellstr(get(hObject,'String')) returns contents
        % contents{get(hObject,'Value')} returns selected item from listbox1

        if isempty(findobj(0,'Tag','Original Image'))   % if guiFig is closed, reset it again
            guiFig = figure('Resize','on','Units','normalized','Position',...
                [0.269 0.05 0.474*ssU(4)/ssU(3) 0.474],'Visible','off',...
                'MenuBar','figure','name','Original Image','NumberTitle','off',...
                'UserData',0,'Tag','Original Image');      % enable the Menu bar so that to explore the intensity value
            set(guiFig,'Color',defaultBackground);
            imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
            imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);
        end

        items = get(imgLabel,'String');
        if ~iscell(items)
            items = {items};%putting items in a cell if not in cell already
        end
        index_selected = get(imgLabel,'Value');
        item_selected = items{index_selected};
        item_fullpath = fullfile(pathName,item_selected);
        iteminfo = imfinfo(item_fullpath);
        item_numSections = numel(iteminfo);

        ff = item_fullpath; info = iteminfo; numSections = item_numSections;%Global variables to find which file is selected.
        if numSections > 1
            openstack = 1;
            setappdata(imgOpen, 'openstack',openstack);
            setappdata(imgOpen,'totslice',numSections);
            disp('Default slice range is the whole stack.')
            setappdata(hsr,'wholestack',1);
            img = imread(ff,1,'Info',info);
            set(stackSlide,'max',numSections);
            set(stackSlide,'Enable','on');
            set(stackSlide,'SliderStep',[1/(numSections-1) 3/(numSections-1)]);%minor step=1/(numSections-1) major step=3/(numSections-1)
            set(stackSlide,'Callback',{@slider_chng_img});
            set(slideLab,'String','Stack Image Preview, Slice: 1');
            set([sru1 sru2],'Enable','on'); %Enabling wholestack button and slices button
            set(guiFig,'name',sprintf('(%d slices)%s, %dx%d, %d-bit stack',item_numSections,item_selected,info(1).Height,info(1).Width,info(1).BitDepth)); %setting image data
        else
            openstack = 0;
            setappdata(imgOpen, 'openstack',openstack);
            img = imread(ff);
            set(guiFig,'name',sprintf('%s, %dx%d, %d-bit',item_selected,info.Height,info.Width,info.BitDepth));
        end

        if size(img,3) > 1
            img = rgb2gray(img);
            disp('Color image was loaded but converted to grayscale image.')
        end

        figure(guiFig);imshow(img,'Parent',imgAx);
        setappdata(imgOpen,'img',img);
        setappdata(imgOpen,'type',info(1).Format);
        colormap(gray);
        set(guiFig,'UserData',0)
        set(guiFig,'Visible','on');

    end

%--------------------------------------------------------------------------
    function setpFIRE_load(setFIRE_load,eventdata)
        % callback function for FIRE params button
        % load ctFIRE parameters
        % ---------for windows----------
        %         [ctfpName ctfpPath] = uigetfile({'*.xlsx';'*.*'},'Load parameters via XLSX file','MultiSelect','off');
        %         xlsfullpath = [ctfpPath ctfpName];
        %         [~,~,ctfPxls]=xlsread(xlsfullpath,1,'C1:C29');  % the xlsfile has 27 rows and 4 column:
        %         currentP = ctfPxls(1:27)';
        %         ctp = ctfPxls(28:29)';
        %         ctp{1} = num2str(ctp{1}); ctp{2} = num2str(ctp{2}); % change to string to be used in ' inputdlg'
        % --------------------------------------------------cs-------------------
        %---------for MAC and Windows, MAC doesn't support xlswrite and xlsread----

        [ctfpName,ctfpPath] = uigetfile({'*.csv';'*.*'},'Load parameters via CSV file',lastPATHname,'MultiSelect','off');
        xlsfullpath = [ctfpPath ctfpName];
        try
            fid1 = fopen(xlsfullpath,'r');
        catch
            set(infoLabel,'String','Error Loading File');return;
        end
        tline = fgetl(fid1);  % fgets
        k = 0;
        while ischar(tline)
            k = k+1;
            currentPload{k} = deblank(tline);
            tline = fgetl(fid1);
        end
        fclose(fid1);
        currentP = currentPload(1:27);
        ctp{1} = deblank(currentPload{28});  ctp{2} = deblank(currentPload{29});
        % ------------------------------------------------------------------------

        ctpfnames = {'ct threshold', 'ct selected scales'};
        pfnames = getappdata(imgOpen,'FIREpname');
        pvalue = struct;  %initialize pvalue as a structure;
       %YL: load the parameters into pvalue

        for ifp = 1:27 % number of fire parameters
            pvalue = setfield(pvalue,pfnames{ifp},currentP{ifp});
        end
       setappdata(imgOpen, 'FIREpvalue',pvalue);  %YL: update fiber extraction pvalue, in format of "string"

        %% change string type to numerical type
        for ifp = 1:27   % YL090814
            if ifp ~= 3%YL08272014:find([4 22] == ifp)
                pvalue.(pfnames{ifp}) = str2num(pvalue.(pfnames{ifp}));
                if ifp == 10 | ifp == 14 | ifp == 19
                    pvalue.(pfnames{ifp}) = cos(pvalue.(pfnames{ifp})*pi/180);
                end
            end
        end
        fp.value = pvalue;   % update pvalue int the format of numerical
        fp.status = 0;%fpupdate;
        %

        % change the type of the currentP into string,so that they can
        % be used in ' inputdlg'
        for itc = 1:27
            if length(find([3 4 22] == itc))==0   % itc= 3 is dtype: 'cityblock',not need to change to string type
                currentP{itc} = num2str(currentP{itc});
            else
                %              disp(sprintf('Parameter # %d [%s], is of type string.',itc, pfnames{itc}));
            end
        end
        setappdata(imgOpen,'FIREparam',currentP);
        ROtemp = get(selRO,'Value');
        %YL map to the original RO: 1: CTF, 2: FIRE, 3: CTF&FIRE(deleted),
        %4: ROI manager, 5: CTF ROI batch, 6: CTF post-ROI batch
        if ROtemp > 1 & ROtemp < 5
            RO = ROtemp + 2;
        elseif ROtemp == 5
            RO = 2;
        elseif ROtemp == 1
            RO = ROtemp;
        end
        clear ROItemp

        %Writing the default values to the setappdata
        if RO == 1 | RO == 3 | RO == 4 |RO == 5      % ctFIRE need to set pct and SS
            ctfP.pct = str2num(ctp{1});
            ctfP.SS  = str2num(ctp{2});
            ctfP.value = fp.value;
            ctfP.status = fp.status;
            setappdata(imgRun,'ctfparam',ctfP);
            setappdata(imgOpen,'ctparam',ctp);  % update ct param
        else
            ctfP.pct = [];
            ctfP.SS  = [];
            ctfP.value = fp.value;
            ctfP.status = 0;
            setappdata(imgRun,'ctfparam',ctfP);
        end
        disp('Parameters for running CT-FIRE are loaded.')
        set(imgRun,'Enable','on')
        set(infoLabel,'String','To run CT-FIRE, select the corresponding run option and click on the "Run" button');
    end

% update ctFIRE parameters

    function setpFIRE_update(setFIRE_update,eventdata)
        pvalue =  getappdata(imgOpen, 'FIREpvalue');
        currentP = getappdata(imgOpen, 'FIREparam');
        pfnames = getappdata(imgOpen,'FIREpname');
        name='Update FIRE Parameters';
        prompt= pfnames';
        numlines=1;
        defaultanswer= currentP;
        updatepnum = [5 7 10 15:20];
        promptud = prompt(updatepnum);
        defaultud=defaultanswer(updatepnum);
        FIREpud = inputdlg(promptud,name,numlines,defaultud);

        if length(FIREpud)>0
            for iud = updatepnum
                pvalue = setfield(pvalue,pfnames{iud},FIREpud{find(updatepnum ==iud)});
            end
            setappdata(imgOpen, 'FIREpvalue',pvalue);  % update fiber extraction pvalue
            set(infoLabel,'String','Fiber extraction parameters are updated or confirmed.');
            fpupdate = 1;
            currentP = struct2cell(pvalue)';
            setappdata(imgOpen, 'FIREparam',currentP);  % update fiber extraction parameters
        else
           set(infoLabel,'String','Please update or confirm the fiber extraction parameters.');
            fpupdate = 0;
        end

        % change string type to numerical type
        for ifp = 1:27                 % number of fire parameters
            if ifp ~= 3        % field 3 dtype: 'cityblock', should be kept string type,
                pvalue.(pfnames{ifp}) = str2num(pvalue.(pfnames{ifp}));
                if ifp == 10 | ifp == 14 | ifp == 19
                    pvalue.(pfnames{ifp}) = cos(pvalue.(pfnames{ifp})*pi/180);
                end
            end
        end
        fp.value = pvalue;
        fp.status = fpupdate;

        ROtemp = get(selRO,'Value');
        %YL map to the original RO: 1: CTF, 2: FIRE, 3: CTF&FIRE(deleted),
        %4: ROI manager, 5: CTF ROI batch, 6: CTF post-ROI batch
        if ROtemp > 1 & ROtemp < 5
            RO = ROtemp + 2;
        elseif ROtemp == 5
            RO = 2;
        elseif ROtemp == 1
            RO = ROtemp;
        end
        clear ROItemp

        if RO == 1 || RO == 3 || RO == 4 || RO == 5     % ctFIRE need to set pct and SS
            name='Set CT-FIRE Parameters';
            prompt={'Percentile of the remaining curvelet coeffs',...
                'Number of selected scales'};
            numlines=1;

            ctp = getappdata(imgOpen,'ctparam');
            defaultanswer= ctp;
            ctpup = inputdlg(prompt,name,numlines,defaultanswer); %update ct param
            if length(ctpup)> 0
                ctfP.pct = str2num(ctpup{1});
                ctfP.SS  = str2num(ctpup{2});
                ctfP.value = fp.value;
                ctfP.status = fp.status;
                setappdata(imgRun,'ctfparam',ctfP);  %
                setappdata(imgOpen,'ctparam',ctpup');  % update ct param
                set(infoLabel,'String',['Curvelet transform parameters are updated or confirmed.' char(10) 'Select a Run mode and click the "Run" button.']);
            else
                set(infoLabel,'String','Please confirm or update the curvelet transform parameters.');
            end
        else
            ctfP.pct = [];
            ctfP.SS  = [];
            ctfP.value = fp.value;
            ctfP.status = fp.status;
            setappdata(imgRun,'ctfparam',ctfP);
        end
        set(imgRun,'Enable','on');
        set(infoLabel,'String','To run CT-FIRE, select the corresponding run option and click on the "Run" button.');
    end

%--------------------------------------------------------------------------
% callback function for stack slider
    function slider_chng_img(hObject,eventdata)
        idx = round(get(hObject,'Value'));
        img = imread(ff,idx,'Info',info);
        set(imgAx,'NextPlot','new');
%         img = imadjust(img);  % YL: only display original image
        imshow(img,'Parent',imgAx);
        set(imgAx,'NextPlot','add');
        if ~isempty(coords) %if there is a boundary, draw it now
            plot(imgAx,coords(:,1),coords(:,2),'r');
            plot(imgAx,coords(:,1),coords(:,2),'*y');
        end
        setappdata(imgOpen,'img',img);
        set(slideLab,'String',['Stack Image Preview, Slice: ' num2str(idx)]);

    end

%callback functoins for stack control
    function get_textbox_sru3(sru3,eventdata)
        usr_input = get(sru3,'String');
        usr_input = str2double(usr_input);
        set(sru3,'UserData',usr_input)
        setappdata(hsr,'srstart',usr_input);
    end


    function get_textbox_sru5(sru5,eventdata)
        usr_input = get(sru5,'String');
        usr_input = str2double(usr_input);
        set(sru5,'UserData',usr_input)
        setappdata(hsr,'srend',usr_input);
    end

    function selcbk(hsr,eventdata)

        if strcmp(get(get(hsr,'SelectedObject'),'String'),'Slices')
            set([sru3 sru4 sru5],'Enable','on')
            disp('Need to enter the slice range.');
            setappdata(hsr,'wholestack',0);
            srstart = get(sru3,'UserData');
            srend = get(sru5,'UserData');
            if length(srstart) == 0 || length(srend) == 0

                disp('Please enter the correct slice range.')
            else
                setappdata(hsr,'srstart',srstart);
                setappdata(hsr,'srend',srend);
                disp(sprintf('Updated, start slice is %d, end slice is %d',srstart,srend));
            end
        else
            disp('Slice range is the whole stack.')
            setappdata(hsr,'wholestack',1);
            set([sru3 sru4 sru5],'Enable','off')
        end
    end
%--------------------------------------------------------------------------
% callback function for selModeChk
    function OUTsel(selModeChk,eventdata)

        if (get(selModeChk,'Value') ~= get(selModeChk,'Max')); opensel =0; else opensel =1;end
        setappdata(imgOpen, 'opensel',opensel);
        if opensel == 1
            set(imgOpen,'Enable','off')
            set(postprocess,'Enable','on')
            set([makeRecon makeHVang makeHVlen makeHVstr makeHVwid enterBIN BINauto],'Enable','on');
            set([makeNONRecon enterLL1 enterLW1 enterWID WIDadv enterRES OUTmore_ui],'Enable','off');
            set(infoLabel,'String','Advanced Selective Output.');
            set([batchModeChk matModeChk parModeChk],'Enable','off');
        else
            set(imgOpen,'Enable','on')
            set(postprocess,'Enable','off')
            set([makeHVang makeHVlen makeHVstr makeHVwid enterBIN BINauto OUTmore_ui],'Enable','off');
            set(infoLabel,'String','Import Image or Data');
            set([batchModeChk matModeChk parModeChk],'Enable','on');
        end

    end

%% callback function for selModeChk
     function PARflag_callback(hobject,handles)

         if exist('parpool','file')
             disp('Matlab parallel computing toolbox exists.')
         else
             error('Matlab parallel computing toolbox does NOT exist.')
         end

         if (get(parModeChk,'Value') ~= get(parModeChk,'Max'))
             poolobj = gcp('nocreate');  % get current pool
             if ~isempty(poolobj)
                 delete(poolobj);
             end
             disp('Parallel pool is closed.')
             prlflag =0;
         else
              poolobj = gcp('nocreate');  % get current pool
             if  isempty(poolobj)
                 % matlabpool open;  % % YL, tested in Matlab 2012a and 2014a, Start a worker pool using the default profile (usually local) with
                 % to customize the number of core, please refer the following
                 mycluster=parcluster('local');
                 numCores = feature('numCores');
                 % the option to choose the number of cores
                 name = 'Parallel Computing Settings';
                 numlines=1;
                 defaultanswer= numCores -1;
                 promptud = sprintf('Number of cores for parallel computing (%d avaiable)',numCores);
                 defaultud = {sprintf('%d',defaultanswer)};
                 NumCoresUP = inputdlg(promptud,name,numlines,defaultud);
                 if ~isempty(NumCoresUP)
                     if str2num(NumCoresUP{1}) > numCores || str2num(NumCoresUP{1}) < 2
                         set(parModeChk,'Value',0)
                         error( sprintf('Number of cores should be set between 2 and %d',numCores))
                     end
                     mycluster.NumWorkers = str2num(NumCoresUP{1});% finds the number of multiple cores for the host machine
                     saveProfile(mycluster);% myCluster has the same properties as the local profile but the number of cores is changed
                 else
                    set(parModeChk,'Value',0)
                    error( sprintf('Number of cores shoud be set between 2 and %d',numCores))

                 end
                 set(infoLabel,'String','Starting multiple workers. Please Wait...');
                 poolobj = parpool(mycluster);
                 set(infoLabel,'String','Multiple Workers Set Up');
                 prlflag = 1;
             end
             disp('Parallel computing can be used for extracting fibers from multiple images or stack(s).')
             disp(sprintf('%d out of %d cores will be used for parallel computing.', mycluster.NumWorkers,numCores))
         end
     end

%--------------------------------------------------------------------------
% callback function for enterLL1 text box
    function get_textbox_data1(enterLL1,eventdata)
        usr_input = get(enterLL1,'String');
        usr_input = str2double(usr_input);
        set(enterLL1,'UserData',usr_input)
    end

%--------------------------------------------------------------------------

% callback function for enterLW1 text box
    function get_textbox_data3(enterLW1,eventdata)
        usr_input = get(enterLW1,'String');
        usr_input = str2double(usr_input);
        set(enterLW1,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% callback function for enterWID text box
    function get_textbox_dataWID(enterWID,eventdata)
        usr_input = get(enterWID,'String');
        usr_input = str2double(usr_input);
        set(enterWID,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% callback function to specify the parameters for width calculation

    function setpWID(WIDadv,eventdata)

        WIDopt = questdlg('Use ALL found fiber points?','Fiber Width Calculation Options','YES to use all','NO to select','YES to use all');
        setappdata(WIDadv,'value',WIDopt)

        switch WIDopt
            case 'YES to use all'
                disp('Use all the extracted points to calculate width, except for the artifact points.')
                setappdata(WIDadv,'WIDall',1)
                widcon.wid_opt = 1;
                return
            case 'NO to select'
                disp('Determine the criteria to select points for width calculation.')
                widcon.wid_opt = 0;
            case ''
                disp('Customized fiber point selections may help improve accuracy of the width calculation.')
                return
        end
        WIDsel =  struct2cell(widcon);
        promptud = {'Minimum/Maximum fiber width','Minimum points to apply fiber points selection',...
            'Confidence Region, times of sigma','Output Maximum Fiber Width (default 0)'};
        WIDname = 'Enter the parameters for width calculation';
        numlines  = 1;
        defaultanswer= cellfun(@num2str,WIDsel,'UniformOutput',false);
        defaultanswerud = defaultanswer(1:4);
        %     FIREp = inputdlg(prompt,name,numlines,defaultanswer);
        WIDpud1 = inputdlg(promptud,WIDname,numlines,defaultanswerud);
        WIDpud = cellfun(@str2num,WIDpud1,'UniformOutput',false);

        for i = 1:length(WIDpud)
            if ~isempty(WIDpud(i))
                if i == 1
                    widcon.wid_mm = WIDpud{i};
                elseif i == 2
                    widcon.wid_mp = WIDpud{i};

                elseif i == 3
                    widcon.wid_sigma = WIDpud{i};

                elseif i == 4
                    widcon.wid_max = WIDpud{i};
                end
            end
        end
    end

%--------------------------------------------------------------------------
% callback function for automatically calculation histogram bins number
     function setpBIN(BINauto,eventdata)

        if (get(batchModeChk,'Value') ~= get(batchModeChk,'Max')); openimg =1; else openimg =0;end
        if (get(matModeChk,'Value') ~= get(matModeChk,'Max')); openmat =0; else openmat =1;end
        if (get(selModeChk,'Value') ~= get(selModeChk,'Max')); opensel =0; else opensel =1;end
        if openmat == 1 && openimg  == 1 && opensel == 0
            matName = getappdata(imgOpen,'matName');
            matPath = getappdata(imgOpen,'matPath');
            matfull = fullfile(matPath,matName);
            if isempty(matfull)
                disp('Auto bins number calculation is off. Please ensure .mat/.csv file exists.')
                return
            else
                imgNameNE = matName(11:end-4);  % image name with no extension
                csvfile = dir('*imgNameNE.csv');
                if isempty(csvfile)
                    load(matfull,'data')
                    LL1 = get(enterLL1,'UserData');
                    if isempty(LL1), LL1 = 30;  end
                    N= length((find(data.M.L > LL1)));
                    clear data
                else
                    N = size( csvread(csvfile(1).name),1);
                end
            end
        elseif openmat == 0 && openimg  == 1 && opensel == 0
            imgName = getappdata(imgOpen,'imgName');
            imgPath = getappdata(imgOpen,'imgPath');
            [~, imgNameNE,~] = fileparts(imgName);
            matName = sprintf('ctFIREout_%s.mat', imgNameNE);
            matfull = fullfile(imgPath,'ctFIREout',matName);  % CT-FIRE .mat output

            if isempty(matfull)
                disp('Auto bins number calculation is off. Please ensure .mat/.csv file exists.')
                return
            else
                csvfile = dir('* imgNameNE.csv');
                if isempty(csvfile)
                    load(matfull,'data');
                    LL1 = get(enterLL1,'UserData');
                    if isempty(LL1), LL1 = 30;  end
                    N= length((find(data.M.L > LL1)));
                    clear data
                else
                    N = size( csvread(csvfile(1).name),1);
                end
            end
        elseif openmat == 1 && openimg  == 1 && opensel == 1  % single image
            selName = getappdata(imgOpen,'selName');
            selPath = getappdata(imgOpen,'selPath');
            selfull = fullfile(selPath,selName);
            if isempty(selfull)
                disp('Auto bins number calculation is off. Please ensure selected output .xlsx file exists.')
                return
            else

                [~,~,selSTA]= xlsread(selfull,'statistics');
                N= selSTA{10,2};
                clear selSTA
            end

            elseif openmat == 1 && openimg  == 0 && opensel == 1  % single image
            selName = getappdata(imgOpen,'selName');
            selPath = getappdata(imgOpen,'selPath');
            selfull = fullfile(selPath,['ALL_',selName]);
            if isempty(selfull)
                disp('Auto bins number calculation is off. Please ensure the combined selected output *.xlsx file exists.')
                return
            else

                [~,~,selSTA]= xlsread(selfull,'Combined ALL');
                N= length(selSTA)-1;
                clear selSTA
            end
        elseif openimg  == 0 && opensel == 0
            disp('Auto bins number calculation does not work for batch-mode fiber extraction.')
            return
        end


         BINopt = questdlg('Which method should be used?', 'Estimate Optimal BINs number based on all extracted fibers (N)',...
             'Square-root','Sturges Formula','Rice Rule','Square-root');
        setappdata(BINauto,'value',BINopt);

        switch  BINopt,
             case 'Square-root',
                  BINa = round(sqrt(N));
                  set(enterBIN,'UserData',BINa);
                  disp(sprintf(' use %s [sqrt(N)] for bins number calculation, BINs = %d', BINopt, BINa));

             case 'Sturges Formula',
                 BINa = round(log2(N));
                 set(enterBIN,'UserData',BINa)
                 disp(sprintf(' use %s [log2(N)] for bins number calculation,, BINs = %d', BINopt, BINa));
             case 'Rice Rule',
                 BINa = round(2*N^(1/3));
                 set(enterBIN,'UserData',BINa)
                 disp(sprintf(' use %s [2*N^(1/3)]for bins number calculation, BINs = %d', BINopt,BINa));
             case '',
                 disp('Auto bins number calculation is off. You can choose it later.')
         end % switch

          set(enterBIN,'string',num2str(BINa));

     end

%--------------------------------------------------------------------------
% callback function for enterRES text box
    function get_textbox_data2(enterRES,eventdata)
        usr_input = get(enterRES,'String');
        usr_input = str2double(usr_input);
        set(enterRES,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% callback function for enter text box
     function get_textbox_data4(enterBIN,eventdata)
         usr_input = get(enterBIN,'String');
         usr_input = str2double(usr_input);
         set(enterBIN,'UserData',usr_input)
     end

%--------------------------------------------------------------------------
%callback function for advanced options
    function OUTmore_callback(handles, eventdata)

        name = 'More Output/Setting Parameters';
        numlines = 1;
        optadv{1} = OUTmore_str.unitconversionFLAG;
        optadv{2} = OUTmore_str.ppmRatio;
        optadv{3} = OUTmore_str.fiber_midpointEST;

        optDefault= {num2str(optadv{1}), num2str(optadv{2}),num2str(optadv{3})};
        promptname = {'Add the unit converted file(s) for width and length, 1: ADD; 0: DO NOT ADD',...
            'Pixel per Micron Ratio for the Image',...
            'Options for fiber middle point estimation based on: 1-end points coordinates(default);2-fiber length'};
        % FIREp = inputdlg(prompt,name,numlines,defaultanswer);
        optUpdate = inputdlg(promptname,name,numlines,optDefault);
        OUTmore_str.unitconversionFLAG = str2num(optUpdate{1});
        OUTmore_str.ppmRatio = str2num(optUpdate{2});
        OUTmore_str.fiber_midpointEST = str2num(optUpdate{3});

        if  OUTmore_str.unitconversionFLAG == 1
            % check the csv file for width data
            WIDfilelist = dir(fullfile(pathName,'ctFIREout','HistWID_*.csv'));
            if length(fileName)> length(WIDfilelist) || length(dir(fullfile(pathName,'ctFIREout','ctFIREout*.mat')))> length(WIDfilelist)
                disp('One or more width files are missing.')
            end

            % check the csv file for length data
            LENfilelist = dir(fullfile(pathName,'ctFIREout','HistLEN_*.csv'));
            if length(fileName)> length(LENfilelist) || length(dir(fullfile(pathName,'ctFIREout','ctFIREout*.mat')))> length(LENfilelist)
                disp('One or more length files are missing.')
            end
            %convert width and save into a new csv file
            if ~isempty(WIDfilelist)
                for i = 1:length(WIDfilelist)
                    WIDname = WIDfilelist(i).name;
                    WIDname_uc = strrep(WIDname,'HistWID','HistWIDum');
                    tempdata = csvread(fullfile(pathName,'ctFIREout',WIDname));
                    tempdata = tempdata/OUTmore_str.ppmRatio;
                    csvwrite(fullfile(pathName,'ctFIREout',WIDname_uc),tempdata)
                end
                disp(sprintf('Added %d width-in-micron file(s) in %s.',length(WIDfilelist),fullfile(pathName,'ctFIREout')))
                clear WIDname WIDname_uc tempdata
            else
                disp('No width-in-micron file is added.')
            end

            %convert width and save into a new csv file
            if ~isempty(LENfilelist)
                for i = 1:length(LENfilelist)
                    LENname = LENfilelist(i).name;
                    LENname_uc = strrep(LENname,'HistLEN','HistLENum');
                    tempdata = csvread(fullfile(pathName,'ctFIREout',LENname));
                    tempdata = tempdata/OUTmore_str.ppmRatio;
                    csvwrite(fullfile(pathName,'ctFIREout',LENname_uc),tempdata)
                end
                disp(sprintf('Added %d length-in-micron file(s) in %s.',length(LENfilelist),fullfile(pathName,'ctFIREout')))
                clear LENname LENname_uc tempdata
            end

        else
            disp('No unit conversion for width or length was done.')

        end

        if OUTmore_str.fiber_midpointEST == 1
            disp('Fiber middle point estimation is based on fiber end point coordinates by default.')
        elseif OUTmore_str.fiber_midpointEST == 2
            disp('Fiber middle point estimation is based on fiber length now.')
            disp('Click "MORE..." button in the "Output Options" panel to switch back to default.')
        end

    end

%--------------------------------------------------------------------------
% callback function for postprocess button
     function postP(postprocess,eventdata)
         if (get(batchModeChk,'Value') ~= get(batchModeChk,'Max')); openimg =1; else openimg =0;end
         if (get(matModeChk,'Value') ~= get(matModeChk,'Max')); openmat =0; else openmat =1;end
         if (get(selModeChk,'Value') ~= get(selModeChk,'Max')); opensel =0; else opensel =1;end
         if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); OLplotflag =0; else OLplotflag =1;end
         OLchoice = '';  %
         setappdata(imgOpen, 'openImg',openimg);
         setappdata(imgOpen, 'openMat',openmat);
         setappdata(imgOpen, 'opensel',opensel);

         if  opensel == 1 && openmat == 0
             selectedOUT;
         elseif opensel == 1 && openmat == 1 && openimg ==1
             set(infoLabel,'String','Open a post-processed data file of selected fibers.');

             [selName selPath] = uigetfile({'*statistics.xlsx';'*statistics.xls';'*statistics.csv';'*.*'},'Choose a processed data file',lastPATHname,'MultiSelect','off');
             if isequal(selPath,0)
                 disp('Please select a post-processed data file to start the analysis.')
                 return
             end
             if OLplotflag == 1
                 OLchoice = questdlg('Does the overlaid image exist?','Create Overlaid Image?', ...
                     'Yes to display','No to create','Yes to display');
             end
             set(infoLabel,'String','Select parameters for advanced fiber selection');

             if ~isequal(selPath,0)
                 imgPath = strrep(selPath,'\CTF_selectedOUT','');
                 lastPATHname = selPath;
                 save('lastPATH_CTF.mat','lastPATHname');
             end

             cP = struct('stack',0);
             % YL: use cP.OLexist to control whether to create OL from
             % .mat file or not in look_SEL_fibers.m function,
             cP.OLexist = '';
             if strcmp(OLchoice, 'Yes to display')
                 cP.OLexist = 1;
             elseif strcmp(OLchoice, 'No to create')
                 cP.OLexist = 0;

             end

             cP.postp = 1;
             LW1 = get(enterLW1,'UserData');
             LL1 = get(enterLL1,'UserData');
             FNL = 9999; % get(enterFNL,'UserData'); set default value
             RES = get(enterRES,'UserData');
             widMAX = get(enterWID,'UserData');
             BINs = get(enterBIN,'UserData');

             if isempty(LW1), LW1 = 0.5; end
             if isempty(LL1), LL1 = 30;  end
             if isempty(FNL), FNL = 9999; end
             if isempty(BINs),BINs = 10; end
             if isempty(RES),RES = 300; end
             if isempty(widMAX),widMAX = 15; end

             cP.LW1 = LW1;
             cP.LL1 = LL1;
             cP.FNL = FNL;
             cP.BINs = BINs;
             cP.RES = RES;
             cP.widMAX = widMAX;

             if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
             if (get(makeNONRecon,'Value') ~= get(makeNONRecon,'Max')); cP.plotflagnof =0; else cP.plotflagnof =1;end  % plog flag for non overlaid figure
             if (get(makeHVang,'Value') ~= get(makeHVang,'Max')); cP.angHV =0; else cP.angHV = 1;end
             if (get(makeHVlen,'Value') ~= get(makeHVlen,'Max')); cP.lenHV =0; else cP.lenHV = 1;end
             if (get(makeHVstr,'Value') ~= get(makeHVstr,'Max')); cP.strHV =0; else cP.strHV =1; end
             if (get(makeHVwid,'Value') ~= get(makeHVwid,'Max')); cP.widHV =0; else cP.widHV =1;end

             savePath = selPath;
             tic
             cP.widcon = widcon;
             setappdata(imgOpen,'selName',selName);
             setappdata(imgOpen,'selPath',selPath);
             look_SEL_fibers(selPath,selName,savePath,cP);
             toc

         elseif opensel == 1 && openmat == 1 && openimg ==0  % batch-mode on selected fibers
             set(infoLabel,'String','Open a batch-processed data file of selected fibers');
             [selName selPath] = uigetfile({'batch*statistics*.xlsx';'batch*statistics*.xls';'batch*statistics*.csv';'*.*'},'Choose a batch-processed data file',lastPATHname,'MultiSelect','off');
             if isequal(selPath,0)
                 disp('Please select a post-processed data file to start the batch analysis.')
                 return
             end
             if OLplotflag == 1
                 OLchoice = questdlg('Does the overlaid image exist?','Create Overlaid Image?', ...
                     'Yes to display','No to create','Yes to display');
                 set(infoLabel,'String','Select parameters for advanced fiber selection');
             end
             if ~isequal(selPath,0)
                 imgPath = strrep(selPath,'\CTF_selectedOUT','');
                 lastPATHname = selPath;
                 save('lastPATH_CTF.mat','lastPATHname');
             end

             cP = struct('stack',1);
             % YL: use cP.OLexist to control whether to create OL from
             % .mat file or not in look_SEL_fibers.m function,
             cP.OLexist = '';
             if strcmp(OLchoice, 'Yes to display')
                 cP.OLexist = 1;
             elseif strcmp(OLchoice, 'No to create')
                 cP.OLexist = 0;
             end

             cP.postp = 1;
             LW1 = get(enterLW1,'UserData');
             LL1 = get(enterLL1,'UserData');
             FNL = 9999; % get(enterFNL,'UserData'); set default value
             RES = get(enterRES,'UserData');
             widMAX = get(enterWID,'UserData');
             BINs = get(enterBIN,'UserData');

             if isempty(LW1), LW1 = 0.5; end
             if isempty(LL1), LL1 = 30;  end
             if isempty(FNL), FNL = 9999; end
             if isempty(BINs),BINs = 10; end
             if isempty(RES),RES = 300; end
             if isempty(widMAX),widMAX = 15; end

             cP.LW1 = LW1;
             cP.LL1 = LL1;
             cP.FNL = FNL;
             cP.BINs = BINs;
             cP.RES = RES;
             cP.widMAX = 15;

             if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
             if (get(makeNONRecon,'Value') ~= get(makeNONRecon,'Max')); cP.plotflagnof =0; else cP.plotflagnof =1;end  % plog flag for non overlaid figure
             if (get(makeHVang,'Value') ~= get(makeHVang,'Max')); cP.angHV =0; else cP.angHV = 1;end
             if (get(makeHVlen,'Value') ~= get(makeHVlen,'Max')); cP.lenHV =0; else cP.lenHV = 1;end
             if (get(makeHVstr,'Value') ~= get(makeHVstr,'Max')); cP.strHV =0; else cP.strHV =1; end
             if (get(makeHVwid,'Value') ~= get(makeHVwid,'Max')); cP.widHV =0; else cP.widHV =1;end

             savePath = selPath;
             setappdata(imgOpen,'selName',selName);
             setappdata(imgOpen,'selPath',selPath);
             tic
             look_SEL_fibers(selPath,selName,savePath,cP);
             toc
         else

             openimg = getappdata(imgOpen, 'openImg');
             openmat = getappdata(imgOpen, 'openMat');

             if openimg == 0 && openmat == 1
                 matPath = getappdata(imgOpen,'matPath');
                 mmat = getappdata(imgOpen,'matName');
                 filelist = cell2struct(mmat,'name',1);
                 fnum = length(filelist);
                 if prlflag == 0
                     for fn = 1:fnum
                         matLName = filelist(fn).name;
                         matfile = [matPath,matLName];
                         imgPath = strrep(matPath,'ctFIREout','');
                         savePath = matPath;
                         %% 7-18-14: don't load imgPath,savePath, use relative image path
                         %                 load(matfile,'imgName','imgPath','savePath','cP','ctfP'); %
                         load(matfile,'imgName','cP','ctfP'); %
                         %                 load(matfile,'matdata');
                         %                 imgName = matdata.imgName;
                         %                 cP = matdata.cP;
                         %                 ctfP = matdata.ctfP;

                         dirout = savePath;

                         ff = [imgPath, imgName];
                         info = imfinfo(ff);
                         if cP.stack == 1
                             img = imread(ff,cP.slice);
                         else
                             img = imread(ff);
                         end

                         if size(img,3) > 1 %if rgb, pick one color
                             img = rgb2gray(img);
                             disp('Color image was loaded but converted to grayscale image.')
                         end
                         figure(guiFig);
                         %                 img = imadjust(img); % YL: only display original image
                         imshow(img);
                         %                 imshow(img,'Parent',imgAx); % YL0726

                         cP.postp = 1;
                         LW1 = get(enterLW1,'UserData');
                         LL1 = get(enterLL1,'UserData');
                         FNL = 9999; % get(enterFNL,'UserData'); set default value
                         RES = get(enterRES,'UserData');
                         widMAX = get(enterWID,'UserData');
                         BINs = get(enterBIN,'UserData');

                         if isempty(LW1), LW1 = 0.5; end
                         if isempty(LL1), LL1 = 30;  end
                         if isempty(FNL), FNL = 9999; end
                         if isempty(BINs),BINs = 10; end
                         if isempty(RES),RES = 300; end
                         if isempty(widMAX),widMAX = 15; end

                         cP.LW1 = LW1;
                         cP.LL1 = LL1;
                         cP.FNL = FNL;
                         cP.BINs = BINs;
                         cP.RES = RES;
                         cP.widMAX = widMAX;

                         if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
                         if (get(makeNONRecon,'Value') ~= get(makeNONRecon,'Max')); cP.plotflagnof =0; else cP.plotflagnof =1;end  % plog flag for non overlaid figure
                         if (get(makeHVang,'Value') ~= get(makeHVang,'Max')); cP.angHV =0; else cP.angHV = 1;end
                         if (get(makeHVlen,'Value') ~= get(makeHVlen,'Max')); cP.lenHV =0; else cP.lenHV = 1;end
                         if (get(makeHVstr,'Value') ~= get(makeHVstr,'Max')); cP.strHV =0; else cP.strHV =1; end
                         if (get(makeHVwid,'Value') ~= get(makeHVwid,'Max')); cP.widHV =0; else cP.widHV =1;end

                         disp(sprintf('Image Path:%s \n Image Name:%s \n Output Folder: %s \n pct = %4.3f \n SS = %d',...
                             imgPath,imgName,dirout,ctfP.pct,ctfP.SS));

                         set(infoLabel,'String',['Analysis is ongoing...' sprintf('%d/%d',fn,fnum) ]);
                         cP.widcon = widcon;
                         ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);


                     end
                     set(infoLabel,'String','Analysis is done.');
                 elseif prlflag == 1
                     imgNameALL = {};
                     cPALL      = {};
                     ctfPALL    = {};
                     for fn = 1:fnum
                         matLName = filelist(fn).name;
                         matfile = [matPath,matLName];
                         imgPath = strrep(matPath,'ctFIREout','');
                         savePath = matPath;
                         load(matfile,'imgName','cP','ctfP'); %
                         dirout = savePath;
                         ff = [imgPath, imgName];
                         info = imfinfo(ff);
                         if cP.stack == 1
                             img = imread(ff,cP.slice);
                         else
                             img = imread(ff);
                         end

                         if size(img,3) > 1 %if rgb, pick one color
                             img = rgb2gray(img);
                             disp('Color image was loaded but converted to grayscale image.')
                         end
                         figure(guiFig);
                         %                 img = imadjust(img); % YL: only display original image
                         imshow(img);
                         %                 imshow(img,'Parent',imgAx); % YL0726

                         cP.postp = 1;
                         LW1 = get(enterLW1,'UserData');
                         LL1 = get(enterLL1,'UserData');
                         FNL = 9999; % get(enterFNL,'UserData'); set default value
                         RES = get(enterRES,'UserData');
                         widMAX = get(enterWID,'UserData');
                         BINs = get(enterBIN,'UserData');

                         if isempty(LW1), LW1 = 0.5; end
                         if isempty(LL1), LL1 = 30;  end
                         if isempty(FNL), FNL = 9999; end
                         if isempty(BINs),BINs = 10; end
                         if isempty(RES),RES = 300; end
                         if isempty(widMAX),widMAX = 15; end

                         cP.LW1 = LW1;
                         cP.LL1 = LL1;
                         cP.FNL = FNL;
                         cP.BINs = BINs;
                         cP.RES = RES;
                         cP.widMAX = widMAX;

                         if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
                         if (get(makeNONRecon,'Value') ~= get(makeNONRecon,'Max')); cP.plotflagnof =0; else cP.plotflagnof =1;end  % plog flag for non overlaid figure
                         if (get(makeHVang,'Value') ~= get(makeHVang,'Max')); cP.angHV =0; else cP.angHV = 1;end
                         if (get(makeHVlen,'Value') ~= get(makeHVlen,'Max')); cP.lenHV =0; else cP.lenHV = 1;end
                         if (get(makeHVstr,'Value') ~= get(makeHVstr,'Max')); cP.strHV =0; else cP.strHV =1; end
                         if (get(makeHVwid,'Value') ~= get(makeHVwid,'Max')); cP.widHV =0; else cP.widHV =1;end

                         disp(sprintf('Image Path:%s \n Image Name:%s \n Output Folder: %s \n pct = %4.3f \n SS = %d',...
                             imgPath,imgName,dirout,ctfP.pct,ctfP.SS));

                         set(infoLabel,'String',['Loading mat file...' sprintf('%d/%d',fn,fnum) ]); drawnow;
                         cP.widcon = widcon;

                         imgNameALL{fn} = imgName;
                         cPALL{fn} = cP;
                         ctfPALL{fn} = ctfP;

                     end
                     set(infoLabel,'String',sprintf('%d mat files are loaded, parallel post-processing is on-going...',fnum));drawnow
                     parstar = tic;
                     try
                         parfor fn = 1:fnum   % loop through all the slices of all the stacks

                             ctFIRE_1p(imgPath,imgNameALL{fn},dirout,cPALL{fn},ctfPALL{fn});

                         end
                     catch

                         set(infoLabel,'String',[ sprintf('Parallel post-processing stopped, check %s for processed results.',dirout) ]);drawnow


                     end
                     parend = toc(parstar);
                     disp(sprintf('%d images were processed using parallel computing, taking %3.2f minutes.',fnum,parend/60));
                 end %parallel flag
             else
                 dirout = getappdata(imgRun,'outfolder');
                 ctfP = getappdata(imgRun,'ctfparam');
                 cP = getappdata(imgRun,'controlpanel');
                 cP.postp = 1;
                 cP.RO = get(selRO,'Value');
                 % YL
                 if getappdata(imgOpen,'openstack')== 1
                     cP.stack = getappdata(imgOpen,'openstack');
                     cP.RO = 1;
                     cP.slice = idx;
                 end

                 LW1 = get(enterLW1,'UserData');
                 LL1 = get(enterLL1,'UserData');
                 FNL = 9999;%get(enterFNL,'UserData');
                 RES = get(enterRES,'UserData');
                 widMAX = get(enterWID,'UserData');
                 BINs = get(enterBIN,'UserData');


                 if isempty(LW1), LW1 = 0.5; end
                 if isempty(LL1), LL1 = 30;  end
                 if isempty(FNL), FNL = 9999; end
                 if isempty(BINs),BINs = 10; end
                 if isempty(RES),RES = 300; end
                 if isempty(widMAX),widMAX = 15; end

                 cP.LW1 = LW1;
                 cP.LL1 = LL1;
                 cP.FNL = FNL;
                 cP.BINs = BINs;
                 cP.RES = RES;
                 cP.widMAX = widMAX;

                 if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
                 if (get(makeNONRecon,'Value') ~= get(makeNONRecon,'Max')); cP.plotflagnof =0; else cP.plotflagnof =1;end
                 if (get(makeHVang,'Value') ~= get(makeHVang,'Max')); cP.angHV =0; else cP.angHV = 1;end
                 if (get(makeHVlen,'Value') ~= get(makeHVlen,'Max')); cP.lenHV =0; else cP.lenHV = 1;end
                 if (get(makeHVstr,'Value') ~= get(makeHVstr,'Max')); cP.strHV =0; else cP.strHV =1; end
                 if (get(makeHVwid,'Value') ~= get(makeHVwid,'Max')); cP.widHV =0; else cP.widHV =1;end

                 imgPath = getappdata(imgOpen,'imgPath');
                 imgName = getappdata(imgOpen, 'imgName');

                 set(infoLabel,'String','Analysis is ongoing...');
                 cP.widcon = widcon;
                 [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);

             end
             set(infoLabel,'String','Analysis is done.');

         end

         set([batchModeChk matModeChk selModeChk],'Enable','on');
         home;
         if opensel == 1 && openmat == 0 && openimg ==1
             disp('Switch to advanced output control module.')
         else
             % check the output files in "ctFIREout" folder
             CTFout_found = checkCTFoutput(pathName,fileName);
             existing_ind = find(cellfun(@isempty, CTFout_found) == 0); % index of images with existing output
             if isempty(existing_ind)
                 set(infoLabel,'String',sprintf('No result was found in "ctFIREout" folder, check/reset the parameters to start over.'))
             else
                 disp(sprintf('Post-processing is done. CT-FIRE results found in "ctFIREout" folder for %d out of %d opened image(s).',...
                     length(existing_ind),length(fileName)))
                 checkCTFout_display_fn(pathName,fileName,existing_ind)
                 set(infoLabel,'String',sprintf('Analysis is done. CT-FIRE results found at "ctFIREout" folder for %d out of %d opened image(s).',...
                     length(existing_ind),length(fileName)))

             end
             % close unnecessary figures
             POSTana_fig1H = findobj(0,'-regexp','Name','ctFIRE output:*');
             if ~isempty(POSTana_fig1H)
                 close(POSTana_fig1H)
                 disp('CT-FIRE post-processing output figures are closed.')
             end
         end
     end
%--------------------------------------------------------------------------
% callback function for imgRun
    function runMeasure(imgRun,eventdata)

         ROtemp = get(selRO,'Value');
        %YL map to the original RO: 1: CTF, 2: FIRE, 3: CTF&FIRE(deleted),
        %4: ROI manager, 5: CTF ROI batch, 6: CTF post-ROI batch
        if ROtemp > 1 & ROtemp < 5
            RO = ROtemp + 2;
        elseif ROtemp == 5
            RO = 2;
        elseif ROtemp == 1
            RO = ROtemp;
        end
        clear ROItemp

 %% batch-mode ROI analysis with previous fiber extraction on the whole image
    if RO == 6
        set(infoLabel,'String','Running Post-ROI Analysis');
        cP.stack = 0;  % during the analysis, convert stack into into individual ROI images
        cP.RO = 1;     % change to CTFIEE fiber extraction mode
        set(makeRecon,'Value',3,'Enable','off');
        set(makeNONRecon,'Value',0,'Enable','off');
        set(makeHVang,'Value',3,'Enable','off');
        set(makeHVlen,'Value',3,'Enable','off');
        set(makeHVstr,'Value',3,'Enable','off');
        set(makeHVwid,'Value',3,'Enable','off');
        set([postprocess setFIRE_load, setFIRE_update makeHVang makeRecon makeNONRecon enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto ,...
        makeHVstr makeHVlen makeHVwid],'Enable','off')
        CTF_data_current = [];
        matDir = fullfile(pathName,'ctFIREout');
        roioutDir = fullfile(ROIpostBatDir,'ctFIREout');
        roiIMGDir = fullfile(ROIpostBatDir,'ctFIREout');

        % CT-FIRE output files must be present)
        ctfFnd = checkCTFireFiles(matDir, fileName);  % if stack, check the mat file of the first slice
        if (~isempty(ctfFnd))
            set(infoLabel,'String','');
        else
            set(infoLabel,'String','One or more CT-FIRE files are missing.');
            return;
        end
        k = 0;
        ROIflag = zeros(length(fileName));  % add ROI flag: 0: ROI file not exist; 1: ROI file exist
        for i = 1:length(fileName)
            [~,fileNameNE] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            if exist(fullfile(ROImanDir,roiMATnamefull),'file')
                load(fullfile(ROImanDir,roiMATnamefull),'separate_rois');
                if exist('separate_rois') && ~isempty(separate_rois)
                    k = k + 1; disp(sprintf('Found ROI for %s',fileName{i}))
                    ROIflag(i) = 1;  % set ROI flag to 1 when ROI file exist;
                end
            else
                disp(sprintf('ROI for %s does not exist.',fileName{i}));
            end

        end

        if k == 0
            disp('No ROI file exists, ROI analysis was aborted.');
            return
        end

        if k ~= length(fileName)
            disp(sprintf('Missing %d ROI files.',length(fileName) - k))
            disp(sprintf('ROI analysis on %d files out of %d files.',k,length(fileName)))
        else
            disp(sprintf('All files have associated ROI files. ROI analysis on %d files. ',length(fileName)))
        end

        if(exist(roioutDir,'dir')==0)%check for ROI folder
            mkdir(roioutDir);
        end

        % check the availability of output table
        if  isempty(findobj(0,'Tag','CT-FIRE Analysis Output Table in Main GUI'))
            CTF_table_fig = figure('Units','normalized','Position',figPOS,'Visible','off',...
                'NumberTitle','off','Name','CT-FIRE Analysis Output Table','Tag', 'CT-FIRE Analysis Output Table in Main GUI','Menu','None');
            CTF_output_table = uitable('Parent',CTF_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],...
                'Data', CTF_data_current,...
                'ColumnName', columnname,...
                'ColumnFormat', columnformat,...
                'ColumnWidth',columnwidth,...
                'ColumnEditable', [false false false false false false false false false false false false false false false],...
                'RowName',[],...
                'CellSelectionCallback',{@CTFot_CellSelectionCallback});
        end

        items_number_current = 0; ki= 0;
        for i = 1:length(fileName)
            if ROIflag(i) == 1
                ki = ki+1;
                set(infoLabel,'String',sprintf('ROI Post-analysis %d/%d of %s',ki,length(find(ROIflag == 1)),fileName{i}));
                drawnow;
                [~,fileNameNE] = fileparts(fileName{i}) ;
                roiMATnamefull = [fileNameNE,'_ROIs.mat'];
                load(fullfile(ROImanDir,roiMATnamefull),'separate_rois')
                ROInames = fieldnames(separate_rois);
                s_roi_num = length(ROInames);

                IMGname = fullfile(pathName,fileName{i});
                IMGinfo = imfinfo(IMGname);
                numSections = numel(IMGinfo); % number of sections, default: 1;
                if numSections > 1
                    stackflag =1;
                elseif numSections == 1
                    stackflag = 0;
                end
                for j = 1:numSections
                    if numSections == 1
                        IMG = imread(IMGname);
                        ctfmatname = fullfile(pathName,'ctFIREout',['ctFIREout_' fileNameNE '.mat']);
                    else
                        IMG = imread(IMGname,j);
                        ctfmatname = fullfile(pathName,'ctFIREout',sprintf('ctFIREout_%s_s%d.mat',fileNameNE,j));
                    end

                    if size(IMG,3) > 1
                        IMG = rgb2gray(IMG);
                        disp('Color image was loaded but converted to grayscale image.')
                    end

                    for k=1:s_roi_num
                        if numSections == 1
                            set(infoLabel,'String',sprintf('ROI analysis on image-%s %d/%d, ROI-%s %d/%d.',...
                                fileName{i},i,length(fileName),ROInames{k},k,s_roi_num))
                        elseif numSections > 1
                            set(infoLabel,'String',sprintf('ROI analysis on stack-%s %d/%d, slice-%d/%d,ROI-%s %d/%d.',...
                                fileName{i},i,length(fileName),j,numSections,ROInames{k},k,s_roi_num))
                        end
                        ROIshape_ind = separate_rois.(ROInames{k}).shape;
                        combined_rois_present=iscell(ROIshape_ind);
                        if(combined_rois_present==0)
                            % when combination of ROIs is not present
                            %finding the mask -starts
                            Boundary = separate_rois.(ROInames{k}).boundary{1};
                            vertices = fliplr(Boundary);
                            BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                        else
                            display('Combined ROIs can not be processed for now.')
                            continue;
                        end

                        image_copy2 = IMG.*uint8(BW);%figure;imshow(image_temp);
                        if stackflag == 1
                            filename_temp = fullfile(ROIpostBatDir,[fileNameNE,sprintf('_s%d_',j),ROInames{k},'.tif']);
                        elseif stackflag == 0
                            filename_temp= fullfile(ROIpostBatDir, [fileNameNE '_' ROInames{k} '.tif']);
                        end

                        imwrite(image_copy2,filename_temp);
                        imgpath = ROIpostBatDir;
                        if stackflag == 1
                            imgname=[fileNameNE sprintf('_s%d_',j) ROInames{k} '.tif'];
                        elseif stackflag == 0
                            imgname=[fileNameNE '_' ROInames{k} '.tif'];
                        end
                        savepath = fullfile(ROIpostBatDir,'ctFIREout');

                        %% find the fibers in each ROIs and output fiber properties csv file of each ROI
                        %                        ctFIRE_1p(imgpath,imgname,savepath,cP,ctfP,1);%error here - error resolved - making cP.plotflagof=0 nad cP.plotflagnof=0
                        roiP.BW = BW;
                        roiP.fibersource = 1;  % 1: use original fiber extraction output; 2: use selectedOUT out put
                        roiP.fibermode = 1;    % 1: fibermode, check the fiber middle point 2: check the hold fiber
                        roiP.ROIname = ROInames{k};
                        roiP.fiber_midpointEST = OUTmore_str.fiber_midpointEST;
                        ctFIRE_1_ROIpost(pathName,fileName{i},ctfmatname,imgpath,imgname,savepath,roiP);

                        %%
                        [~,imagenameNE] = fileparts(imgname);
                        histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls angle histogram values
                        histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls length histogram values
                        histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls straightness histogram values
                        histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls width histogram values
                        ROIangle = nan; ROIlength = nan; ROIstraight = nan; ROIwidth = nan;
                        if exist(histA2,'file')
                            ROIangle = mean(importdata(histA2));
                            ROIlength = mean(importdata(histL2));
                            ROIstraight = mean(importdata(histSTR2));
                            ROIwidth = mean(importdata(histWID2));
                            fibNUM = length(importdata(histA2));
                        else
                            disp(sprintf('%s does not exist. Fiber metrics reading was skipped.',histA2))
                            ROIangle = nan;
                            ROIlength = nan;
                            ROIstraight = nan;
                            ROIwidth = nan;
                            fibNUM = nan;
                        end
                        xc = separate_rois.(ROInames{k}).ym; yc = separate_rois.(ROInames{k}).xm; zc = j;
                        postFLAG = 'YES';
                        cropFLAG = 'NO';
                        modeID = 'CTF';  % options: 'CTF' or 'CTF+Threshold' or 'FIRE'
                        items_number_current = items_number_current+1;
                        CTF_data_add = {items_number_current,sprintf('%s',fileNameNE),sprintf('%s',ROInames{k}),...
                            sprintf('%.1f',ROIwidth),sprintf('%.1f',ROIlength), sprintf('%.2f',ROIstraight),sprintf('%.1f',ROIangle)...
                            sprintf('%d',fibNUM),modeID,cropFLAG,postFLAG,ROIshapes{ROIshape_ind},round(xc),round(yc),zc,};
                        CTF_data_current = [CTF_data_current;CTF_data_add];
                        set(CTF_output_table,'Data',CTF_data_current)
                        set(CTF_table_fig,'Visible','on')

                    end % ROIs
                end  % slices  if stack
            end % only work on files with associated ROI file
        end  % files

        % save CTFroi results:
        if ~isempty(CTF_data_current)
            save(fullfile(ROIDir,'Batch','last_ROIsCTF.mat'),'CTF_data_current','separate_rois') ;
            existFILE = length(dir(fullfile(ROIDir,'Batch','Batch_ROIsCTF*.xlsx')));
            try
                xlswrite(fullfile(ROIDir,'Batch',sprintf('Batch_ROIsCTF%d.xlsx',existFILE+1)),[columnname;CTF_data_current],'CTF ROI Analysis') ;
            catch
                xlwrite(fullfile(ROIDir,'Batch',sprintf('Batch_ROIsCTF%d.xlsx',existFILE+1)),[columnname;CTF_data_current],'CTF ROI Analysis') ;
            end
            set(infoLabel,'String',sprintf('Done with the CT-FIRE ROI post-analysis, results were saved into %s.',...
                fullfile(ROIDir,'Batch',sprintf('Batch_ROIsCA%d.xlsx',existFILE+1))))
        else
            set(infoLabel,'String','Done with the CT-FIRE ROI post analysis but no output exists.')
        end

        % close unnecessary figures
        ROIpost_figH = findobj(0,'-regexp','Name','ctFIRE ROI output:*');
        if ~isempty(ROIpost_figH)
            disp('Closing CT-FIRE Output Figures')
            close(ROIpost_figH)
        end
        disp('Done!')
        figure(CTF_table_fig)
        return

    end

%--------------------------------------------------------------------------
        %% YL use fullfile to avoid this difference, do corresponding change in ctFIRE_1
         dirout = fullfile(pathName,'ctFIREout');
        if ~exist(dirout,'dir')
            mkdir(dirout);

        end

        setappdata(imgRun,'outfolder',dirout);

        openimg = getappdata(imgOpen, 'openImg');
        openmat = getappdata(imgOpen, 'openMat');
        openstack = getappdata(imgOpen,'openstack');
        %% get/save bothe the fiber extraction parameters (ctfP) and the output control parameters(cP)


        %ctfP
        ctfP = getappdata(imgRun,'ctfparam');
        %cP
        LW1 = get(enterLW1,'UserData');
        LL1 = get(enterLL1,'UserData');
        FNL = 9999;%get(enterFNL,'UserData');
        RES = get(enterRES,'UserData');
        widMAX = get(enterWID,'UserData');
        BINs = get(enterBIN,'UserData');

        if isempty(LW1), LW1 = 0.5; end
        if isempty(LL1), LL1 = 30;  end
        if isempty(FNL), FNL = 9999; end
        if isempty(BINs), BINs = 10; end
        if isempty(RES), RES = 300; end
        if isempty(widMAX), widMAX = 15; end

        % initilize the input options

        cP.postp = 0;
        cP.RO = RO;
        cP.LW1 = LW1;
        cP.LL1 = LL1;
        cP.FNL = FNL;
        cP.BINs = BINs;
        cP.RES = RES;
        cP.widMAX = widMAX;
        cP.Flabel = 0;
        cP.plotflag = 1;
        cP.plotflagnof = 1;
        %         cP.plotctf = 1;
        %         cP.plotrec = 0;
        cP.angHV = 1;
        cP.lenHV = 1;
        cP.strHV = 1;
        cP.widHV = 1;

        if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; end
        if (get(makeNONRecon,'Value') ~= get(makeNONRecon,'Max')); cP.plotflagnof =0; end
        if (get(makeHVang,'Value') ~= get(makeHVang,'Max')); cP.angHV =0; end
        if (get(makeHVlen,'Value') ~= get(makeHVlen,'Max')); cP.lenHV =0; end
        if (get(makeHVstr,'Value') ~= get(makeHVstr,'Max')); cP.strHV =0; end
        if (get(makeHVwid,'Value') ~= get(makeHVwid,'Max')); cP.widHV =0; end

         cP.slice = [];  cP.stack = [];  % initialize stack option

         if openstack == 1
                set([sru1 sru2 sru3 sru4 sru5],'Enable','off');
                set(stackSlide,'Enable','off');
                cP.stack = openstack;
                sslice = getappdata(imgOpen,'totslice'); % selected slices
                disp(sprintf('process an image stack with %d slices',sslice));
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                    pathName,fileName{index_selected},dirout,ctfP.pct,ctfP.SS));
                cP.ws = getappdata(hsr,'wholestack');
                disp(sprintf('cp.ws = %d',cP.ws));
                cP.sselected = sslice;      % slices selected
                cP.slice = idx;             % current slice
         end
         cP.widcon = widcon;

        save(fullfile(pathName,'currentP_CTF.mat'),'cP', 'ctfP')
    %% ROI analysis

        if RO == 4
            imgPath = getappdata(imgOpen,'imgPath');
            imgName = getappdata(imgOpen, 'imgName');
            IMG = getappdata(imgOpen,'img');
            ROIctfp.filename = fileName{index_selected};
            ROIctfp.pathname = pathName;
            ROIctfp.CTF_data_current = [];
            ROIctfp.roiopenflag = 0;    % to enable open button
            ROIctfp.fiber_midpointEST = OUTmore_str.fiber_midpointEST;
            disp('Switch to ROI analysis module.')
            CTFroi(ROIctfp);    %
            return
        end
    %% batch-mode ROI analysis without previous fiber extraction on the whole image
    if RO == 5
        ROIanaChoice = questdlg('Run CT-FIRE on the cropped rectangular ROI OR the ROI mask of any shape?', ...
            'CT-FIRE on ROI','Cropped Rectangular ROI','ROI Mask of Any Shape','Cropped Rectangular ROI');
        if isempty(ROIanaChoice)
            error('Please choose the shape of the ROI to be analyzed.')
        end
        switch ROIanaChoice
            case 'Cropped Rectangular ROI'
                cropIMGon = 1;
                disp('Run CT-FIRE on the the cropped rectangular ROIs, not applicable to the combined ROI.')
                disp('Loading ROI...')
            case 'ROI Mask of Any Shape'
                cropIMGon = 0;
                disp('Run CT-FIRE on the the ROI mask of any shape, not applicable to the combined ROI.');
                disp('Loading ROI...')
        end

        cP.stack = 0;  % during the analysis, convert stack into into individual ROI images
        cP.RO = 1;     % change to CTFIEE fiber extraction mode
        CTF_data_current = [];

        k = 0;
        for i = 1:length(fileName)
            [~,fileNameNE,fileEXT] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            if exist(fullfile(ROImanDir,roiMATnamefull),'file')
                k = k + 1; disp(sprintf('Found ROI for %s',fileName{i}))
            else
                disp(sprintf('ROI for %s does not exist.',fileName{i}));
            end
        end

        if k ~= length(fileName)
            error(sprintf('Missing %d ROI files.',length(fileName) - k))
        end

        roiIMGDir = ROIanaBatDir;
        roioutDir = fullfile(ROIanaBatDir,'ctFIREout');

        if(exist(roioutDir,'dir')==0)%check for ROI folder
            mkdir(roioutDir);
        end

        % check the availability of output table
        if  isempty(findobj(0,'Tag','CT-FIRE Analysis Output Table in Main GUI'))
            CTF_table_fig = figure('Units','normalized','Position',figPOS,'Visible','off',...
                'NumberTitle','off','Name','CT-FIRE Analysis Output Table','Tag', 'CT-FIRE Analysis Output Table in Main GUI','Menu','None');
            CTF_output_table = uitable('Parent',CTF_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],...
                'Data', CTF_data_current,...
                'ColumnName', columnname,...
                'ColumnFormat', columnformat,...
                'ColumnWidth',columnwidth,...
                'ColumnEditable', [false false false false false false false false false false false false false false false],...
                'RowName',[],...
                'CellSelectionCallback',{@CTFot_CellSelectionCallback});
        end

        items_number_current = 0;
        for i = 1:length(fileName)
            [~,fileNameNE,fileEXT] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            try
                load(fullfile(ROImanDir,roiMATnamefull),'separate_rois')
                if isempty(separate_rois)
                   disp(sprintf('%s is empty, \n %s was skipped.',fullfile(ROImanDir,roiMATnamefull),fileName{i}))
                   continue
                end
            catch
                display(sprintf('ROI file does NOT exist, %s was skipped.', fileName{i}))
                continue
            end
            ROInames = fieldnames(separate_rois);
            s_roi_num = length(ROInames);

            IMGname = fullfile(pathName,fileName{i});
            IMGinfo = imfinfo(IMGname);
            numSections = numel(IMGinfo); % number of sections, default: 1;
            if numSections > 1
                stackflag =1;
            elseif numSections == 1
                stackflag = 0;
            end;
            for j = 1:numSections
                if numSections == 1
                    IMG = imread(IMGname);
                elseif numSections > 1
                    IMG = imread(IMGname,j);
                end
                if size(IMG,3) > 1
                    IMG = rgb2gray(IMG);
                    disp('Color image was loaded but converted to grayscale image.')
                end
                    for k=1:s_roi_num
                       if numSections == 1
                           set(infoLabel,'String',sprintf('ROI analysis on image-%s %d/%d, ROI-%s %d/%d.',...
                               fileName{i},i,length(fileName),ROInames{k},k,s_roi_num))
                       elseif numSections > 1
                           set(infoLabel,'String',sprintf('ROI analysis on stack-%s %d/%d, slice-%d/%d,ROI-%s %d/%d.',...
                               fileName{i},i,length(fileName),j,numSections,ROInames{k},k,s_roi_num))
                       end
                        if iscell(separate_rois.(ROInames{k}).shape)
                            combined_rois_present = 1;
                            set(infoLabel,'String','Cropped image ROI analysis for shapes other than rectangles is not available so far.');
                                   continue;
                                   pause(1.5)
                        else
                            combined_rois_present= 0;
                        end
                        ROIshape_ind = separate_rois.(ROInames{k}).shape;
                        if(combined_rois_present==0)
                            % when combination of ROIs is not present
                            %finding the mask -starts
                            % add the option of rectangular ROI
                            if cropIMGon == 0     % use ROI mask
                                boundary = separate_rois.(ROInames{k}).boundary{1};
                                BW=roipoly(IMG,boundary(:,2),boundary(:,1));
                            elseif cropIMGon == 1
                                if ROIshape_ind == 1   % use cropped ROI image
                                    data2 = round(separate_rois.(ROInames{k}).roi);
                                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                    ROIimg = IMG(b:b+d-1,a:a+c-1); % cropped image
                                    xc = round(a+c/2); yc = round(b+d/2); z = j;
                                else
                                    set(infoLabel,'String','Cropped image ROI analysis for shapes other than rectangles is not available so far.');
                                   continue;
                                end
                            end
                        end

                        if cropIMGon == 0
                            image_copy2 = IMG.*uint8(BW);%figure;imshow(image_temp)
                        elseif cropIMGon == 1
                            image_copy2 = ROIimg;
                        end

                       if stackflag == 1
                          filename_temp = fullfile(roiIMGDir,[fileNameNE,sprintf('_s%d_',j),ROInames{k},'.tif']);
                       elseif stackflag == 0
                         filename_temp = fullfile(roiIMGDir,[fileNameNE '_' ROInames{k} '.tif']);
                       end

                       imwrite(image_copy2,filename_temp);
                       imgpath = roiIMGDir;
                       if stackflag == 1
                           imgname=[fileNameNE sprintf('_s%d_',j) ROInames{k} '.tif'];
                       elseif stackflag == 0
                           imgname=[fileNameNE '_' ROInames{k} '.tif'];
                       end
                       savepath = roioutDir;
                       ctFIRE_1(imgpath,imgname,savepath,cP,ctfP); % us ctFIRE_1 instead of ctFIRE_1p so far
                       [~,imagenameNE] = fileparts(imgname);
                       histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls angle histogram values
                       histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls length histogram values
                       histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls straightness histogram values
                       histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls width histogram values
                       ROIangle = nan; ROIlength = nan; ROIstraight = nan; ROIwidth = nan;
                       if exist(histA2,'file')
                           ROIangle = mean(importdata(histA2));
                           ROIlength = mean(importdata(histL2));
                           ROIstraight = mean(importdata(histSTR2));
                           ROIwidth = mean(importdata(histWID2));
                           fibNUM = length(importdata(histA2));
                       else
                           disp(sprintf('%s does not exist. Fiber metrics reading was skipped.',histA2))
                           ROIangle = nan;
                           ROIlength = nan;
                           ROIstraight = nan;
                           ROIwidth = nan;
                           fibNUM = nan;
                       end
                       xc = separate_rois.(ROInames{k}).ym; yc = separate_rois.(ROInames{k}).xm; zc = j;
                        postFLAG = 'NO';
                        if cropIMGon == 1
                            cropFLAG = 'YES';
                        elseif cropIMGon == 0
                            cropFLAG = 'NO';
                        end
                        modeID = 'CTF';  % options: 'CTF' or 'CTF+Threshold' or 'FIRE'
                        items_number_current = items_number_current+1;
                        CTF_data_add = {items_number_current,sprintf('%s',fileNameNE),sprintf('%s',ROInames{k}),...
                            sprintf('%.1f',ROIwidth),sprintf('%.1f',ROIlength), sprintf('%.2f',ROIstraight),sprintf('%.1f',ROIangle)...
                            sprintf('%d',fibNUM),modeID,cropFLAG,postFLAG,ROIshapes{ROIshape_ind},round(xc),round(yc),zc,};
                       CTF_data_current = [CTF_data_current;CTF_data_add];
                       set(CTF_output_table,'Data',CTF_data_current)
                       set(CTF_table_fig,'Visible','on')
                end %k: ROIs
            end  %j: slices  if stack
        end  %i: files
        if ~isempty(CTF_data_current)
            save(fullfile(ROIDir,'Batch','last_ROIsCTF.mat'),'CTF_data_current','separate_rois') ;
            existFILE = length(dir(fullfile(ROIDir,'Batch','Batch_ROIsCTF*.xlsx')));
            try
                xlswrite(fullfile(ROIDir,'Batch',sprintf('Batch_ROIsCTF%d.xlsx',existFILE+1)),[columnname;CTF_data_current],'CTF ROI Analysis') ;
            catch
                xlwrite(fullfile(ROIDir,'Batch',sprintf('Batch_ROIsCTF%d.xlsx',existFILE+1)),[columnname;CTF_data_current],'CTF ROI Analysis') ;
            end
            set(infoLabel,'String',sprintf('Done with the CT-FIRE ROI analysis, results were saved into %s.',...
                fullfile(ROIDir,'Batch',sprintf('Batch_ROIsCA%d.xlsx',existFILE+1))))
        else
           set(infoLabel,'String','Done with the CT-FIRE ROI analysis but no output exists.')
        end
         % close unnecessary figures
        ROIana_fig1H = findobj(0,'-regexp','Name','ctFIRE output:*');
        ROIana_fig2H = findobj(0, 'Name','CT reconstructed image ');
        if ~isempty(ROIana_fig1H)
            close(ROIana_fig1H)
            disp('CT-FIRE ROI analysis output figures are closed.')

        end
         if ~isempty(ROIana_fig2H)
            close(ROIana_fig2H)
            disp('CT-FIRE ROI analysis output CT-recontructed image is closed.')
        end

        disp('Done!')
        figure(CTF_table_fig)
        return
    end
        imgPath = getappdata(imgOpen,'imgPath');

        if openimg
            imgPath = getappdata(imgOpen,'imgPath');
            imgName = getappdata(imgOpen, 'imgName');
            if openstack == 1
                set([sru1 sru2 sru3 sru4 sru5],'Enable','off');
                set(stackSlide,'Enable','off');
                cP.stack = openstack;
                sslice = getappdata(imgOpen,'totslice'); % selected slices
                disp(sprintf('Process an image stack with %d slices',sslice));
                disp(sprintf('Image Path:%s \n Image Name:%s \n Output Folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                cP.ws = getappdata(hsr,'wholestack');
                disp(sprintf('cp.ws = %d',cP.ws));


                if prlflag == 0
                    if cP.ws == 1 % process whole stack
                        cP.sselected = sslice;      % slices selected

                        for iss = 1:sslice
                            img = imread([imgPath imgName],iss);
                            figure(guiFig);
%                             img = imadjust(img);  % YL: only display original image
                            imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                            %                     imshow(img,'Parent',imgAx);

                            cP.slice = iss;
                            set(infoLabel,'String','Analysis is ongoing...');
                            cP.widcon = widcon;
                            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                            soutf(:,:,iss) = OUTf;
                            OUTctf(:,:,iss) = OUTctf;
                        end

                        set(infoLabel,'String','Analysis is done.');
                    else
                        srstart = getappdata(hsr,'srstart');
                        srend = getappdata(hsr,'srend');
                        cP.sselected = srend - srstart + 1;      % slices selected

                        for iss = srstart:srend
                            img = imread([imgPath imgName],iss);
                            figure(guiFig);
%                             img = imadjust(img);  % YL: only display original image
                            imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                            %                     imshow(img,'Parent',imgAx);
                            cP.slice = iss;

                            set(infoLabel,'String','Analysis is ongoing...');
                            cP.widcon = widcon;
                            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                            soutf(:,:,iss) = OUTf;
                            OUTctf(:,:,iss) = OUTctf;
                        end
                    end

                else %parallel computing for a single stack
                    cP.widcon = widcon;
                    if cP.ws == 1 % process whole stack
                        cP.sselected = sslice;      % slices selected
                        set(infoLabel,'String',sprintf('%d slices of a single stack are being processed in parallel. Check the command window for details.',sslice)); drawnow;
                        parstar = tic;
                        parfor iss = 1:sslice

                            ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP,iss);

                        end
                        parend = toc(parstar);
                        disp(sprintf('%d slices of a single stack were processed, taking %3.2f minutes',sslice,parend/60));
                        set(infoLabel,'String','Analysis is done.');
                    else
                        srstart = getappdata(hsr,'srstart');
                        srend = getappdata(hsr,'srend');
                        cP.sselected = srend - srstart + 1;      % slices selected
                        set(infoLabel,'String',sprintf('%d slices of a single stack are being processed in parallel. Check the command window for details.',srend-srstart+1));drawnow;
                        parstar = tic;
                        parfor iss = srstart:srend

                            ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP,iss);

                        end
                        parend = toc(parstar);
                        disp(sprintf('%d slices of a single stack were processed, taking %3.2f minutes',srend-srstart+1,parend/60));
                        set(infoLabel,'String','Analysis is done');
                    end

                end

            else
                disp('Process an Image')

                setappdata(imgRun,'controlpanel',cP);
                disp(sprintf('Image Path:%s \n Image Name:%s \n Output Folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                set(infoLabel,'String','Analysis is ongoing...');
                cP.widcon = widcon;
                figure(guiFig);%open some figure
                [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                set(postprocess,'Enable','on');
                set([batchModeChk matModeChk selModeChk],'Enable','on');
            end
            set(infoLabel,'String','Analysis is done.');

        else  % process multiple files
            if openmat ~= 1
                set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update enterLL1 enterLW1 enterWID enterRES enterBIN BINauto],'Enable','off');
                set(infoLabel,'String','Load and/or Update Parameters');
                imgPath = getappdata(imgOpen,'imgPath');
                multiimg = getappdata(imgOpen,'imgName');
                filelist = cell2struct(multiimg,'name',1);
                fnum = length(filelist);

               % YL 2014-01-16: add image stack analysis, only consider
                % multiple files are all images or all stacks
                ff = [imgPath, filelist(1).name];
                info = imfinfo(ff);
                numSections = numel(info);

                if numSections == 1   % process multiple images
                  if prlflag == 0
                        cP.widcon = widcon;
                     tstart = tic;
                    for fn = 1:fnum
                        set (infoLabel,'String',['processing ' num2str(fn)  ' out of ' num2str(fnum) '  images. Analysis is ongoing...']);
                        ctFIRE_1(imgPath,filelist(fn).name,dirout,cP,ctfP);
                    end
                    seqfortime = toc(tstart);  % sequestial processing time
                    disp(sprintf('Sequential processing for %d images took %4.2f seconds',fnum,seqfortime))
                    set(infoLabel,'String','Analysis is done.');

                  elseif prlflag == 1
                        set(infoLabel,'String',sprintf('Parallel processing on %d images is on-going. \n Check command window for details.',fnum));drawnow
                        cP.widcon = widcon;
                        tstart = tic;
                        cnt=0;
                        parfor fn = 1:fnum
                            ctFIRE_1p(imgPath,filelist(fn).name,dirout,cP,ctfP);
                        end
                        parfortime = toc(tstart); % parallel processing time
                        disp(sprintf('Parallel processing for %d images took %4.2f seconds',fnum,parfortime))
                        set(infoLabel,'String','Analysis is done.');
                  end
                elseif  numSections > 1% process multiple stacks
                if prlflag == 0
                    %cP.ws == 1; % process whole stack
                    cP.stack = 1;
                    for ms = 1:fnum   % loop through all the stacks
                        imgName = filelist(ms).name;
                        ff = [imgPath, imgName];
                        info = imfinfo(ff);
                        numSections = numel(info);
                        sslice = numSections;
                        cP.sselected = sslice;      % slices selected
                        set (infoLabel,'String',['Processing ' num2str(ms)  ' out of ' num2str(fnum) ' stacks. Analysis is ongoing....']);
                        for iss = 1:sslice
                            img = imread([imgPath imgName],iss);
                            figure(guiFig);
%                             img = imadjust(img);  % YL: only display original image
                            imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                            cP.slice = iss;
                            cP.widcon = widcon;
                            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                            soutf(:,:,iss) = OUTf;
                            OUTctf(:,:,iss) = OUTctf;
                        end
                        set (infoLabel,'String',['Processed' num2str(ms)  'out of' num2str(fnum) 'stacks']);
                    end
                elseif prlflag == 1  % parallel computing for multiple stacks
                        cP.stack = 1;
                        ks = 0;
                        for ms = 1:fnum   % loop through all the stacks
                            imgNametemp = filelist(ms).name;
                            ff = [imgPath, imgNametemp];
                            info = imfinfo(ff);
                            numSections = numel(info);
                            sslice = numSections;
                            cP.sselected = sslice;      % slices selected
                            for iss = 1:sslice
                                ks = ks + 1;
                                imgNameALL{ks} = imgNametemp;
                                slicenumber(ks) = iss;
                                slickstack(ks) = ms;
                            end
                        end
                        set(infoLabel,'String',sprintf('Parallel processing on %d slices from %d stack(s) is on-going. \n Check command window for details.',ks,fnum));drawnow
                        cP.widcon = widcon;
                        parstar = tic;
                        parfor iks = 1:ks   % loop through all the slices of all the stacks
                            ctFIRE_1p(imgPath,imgNameALL{iks},dirout,cP,ctfP,slicenumber(iks));
                        end
                        parend = toc(parstar);
                        disp(sprintf('%d slices from %d stacks were processed, taking %3.2f minutes.',ks, fnum,parend/60));
                end

                end
                set(infoLabel,'String','Analysis is done.');
            else
            end
        end
        if openmat ~= 1
            if imgPath ~= 0
                imgPath = getappdata(imgOpen,'imgPath');

                if openimg ~= 1;  % batch mode
                    multiimg = getappdata(imgOpen,'imgName');
                    imgNameP = multiimg{1};
                else
                    imgNameP = imgName;
                end

                pfnames = getappdata(imgOpen,'FIREpname');
                currentP = getappdata(imgOpen,'FIREparam');
                fpdesc = getappdata(imgOpen,'FIREpdes');

                ctpnames = {'pct', 'ss'};
                ctp = getappdata(imgOpen,'ctparam');
                ctpdes = {'Percentile of the remaining curvelet coeffs',...
                    'Number of selected scales'};
%----- for Mac and Windows ---------
                ctfPname = fullfile(dirout,['ctfParam_',imgNameP,'.csv']);
                disp('Saving Parameters...');
                fid2 = fopen(ctfPname,'w');
                for ii = 1:29
                    if ii <= 27
                        fprintf(fid2,'%s\n',currentP{ii});
                    elseif ii== 28 || ii == 29
                        fprintf(fid2,'%s\n',ctp{ii-27});
                    end %
                end

                fclose(fid2);
%--------------------------------------------------------------------
                disp(sprintf('Parameters were saved at %s',dirout));
            end
        end
        set([imgOpen],'Enable','on')
        set([imgRun],'Enable','off')
        % add output table here if RO = 1
        if RO == 1
            % close unnecessary figures
            ROIana_fig1H = findobj(0,'-regexp','Name','ctFIRE output:*');
            ROIana_fig2H = findobj(0, 'Name','CT reconstructed image ');
            if ~isempty(ROIana_fig1H)
                disp('Closing CT-FIRE full image analysis output figures.')
                close(ROIana_fig1H)
            end
            if ~isempty(ROIana_fig2H)
                disp('Closing CT-FIRE full image analysis output CT-reconstructed image.')
                close(ROIana_fig2H)
            end

            % check the output files in "ctFIREout" folder
            CTFout_found = checkCTFoutput(pathName,fileName);
            existing_ind = find(cellfun(@isempty, CTFout_found) == 0); % index of images with existing output
            if isempty(existing_ind)
                set(infoLabel,'String',sprintf('No result was found in "ctFIREout" folder, check/reset the parameters to start over.'))
            else
                checkCTFout_display_fn(pathName,fileName,existing_ind)
                disp(sprintf('Analysis is done. CT-FIRE results found in "ctFIREout" folder for %d out of %d opened image(s).',...
                    length(existing_ind),length(fileName)))
                note_temp = 'Click the item in the output table to display the extracted fibers';
                set(infoLabel,'String',sprintf('Analysis is done. CT-FIRE results found in "ctFIREout" folder for %d out of %d opened image(s).\n %s',...
                    length(existing_ind),length(fileName),note_temp))

            end
        end
    end
%--------------------------------------------------------------------------

     function change_state(state)
         % this function changes the state of current figure
         % input - state . If=='off' then any operation cannot be done on
         % this figure
         % if state=='on' - this reenables operations on the current figure
        FigH=gcf;drawnow;
         jFrame  = get(handle(FigH), 'JavaFrame');
        jWindow = jFrame.fHG1Client.getWindow;
        if(strcmp(state,'off'))
            jWindow.setEnabled(false);
        elseif(strcmp(state,'on'))
            jWindow.setEnabled(true);
        end
     end
 %------------------------------------------------------------------------------
 %display previous CT-FIRE extracted fibers
     function checkCTFout_display_fn(pathName,fileName,existing_ind)
         ii = 0;
         items_number_current = 0;
         CTF_data_current = [];
         selectedROWs = [];
         savepath = fullfile(pathName,'ctFIREout');
         % check the availability of output table
         if  isempty(findobj(0,'Tag','CT-FIRE Analysis Output Table in Main GUI'))
             CTF_table_fig = figure('Units','normalized','Position',figPOS,'Visible','off',...
                 'NumberTitle','off','Name','CT-FIRE Analysis Output Table','Tag', 'CT-FIRE Analysis Output Table in Main GUI','Menu','None');
             CTF_output_table = uitable('Parent',CTF_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],...
                 'Data', CTF_data_current,...
                 'ColumnName', columnname,...
                 'ColumnFormat', columnformat,...
                 'ColumnWidth',columnwidth,...
                 'ColumnEditable', [false false false false false false false false false false false false false false false],...
                 'RowName',[],...
                 'CellSelectionCallback',{@CTFot_CellSelectionCallback});
         end

         figure(CTF_table_fig)
         for jj = 1: length(existing_ind)
             [~,imagenameNE] = fileparts(fileName{existing_ind(jj)});
             numSEC = numel(imfinfo(fullfile(pathName,fileName{existing_ind(jj)}))); % 1:single stack; > 1: stack
             if numSEC == 1 % single image
                 OLname = fullfile(savepath,'OL_ctFIRE_',imagenameNE,'.tif');
                 histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:csv angle histogram values
                 histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:csv length histogram values
                 histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:csv straightness histogram values
                 histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:csv width histogram values
                 ROIangle = nan; ROIlength = nan; ROIstraight = nan; ROIwidth = nan;
                 if exist(histA2,'file')
                     ROIangle = mean(importdata(histA2));
                     ROIlength = mean(importdata(histL2));
                     ROIstraight = mean(importdata(histSTR2));
                     ROIwidth = mean(importdata(histWID2));
                     fibNUM = length(importdata(histA2));
                 else
                     disp(sprintf('%s does not exist. Fiber metrics reading was skipped.',histA2))
                     ROIangle = nan;
                     ROIlength = nan;
                     ROIstraight = nan;
                     ROIwidth = nan;
                     fibNUM = nan;
                 end
                 xc = nan; yc = nan; zc = 1;
                 roiNameT = '';
                 postFLAG = '';
                 cropFLAG = '';
                 roiShapeT = '';
                 modeID = 'CTF';  % options: 'CTF' or 'CTF+Threshold' or 'FIRE'
                 items_number_current = items_number_current+1;
                 CTF_data_add = {items_number_current,sprintf('%s',imagenameNE),roiNameT,...
                     sprintf('%.1f',ROIwidth),sprintf('%.1f',ROIlength), sprintf('%.2f',ROIstraight),sprintf('%.1f',ROIangle)...
                     sprintf('%d',fibNUM),modeID,cropFLAG,postFLAG,roiShapeT,round(xc),round(yc),zc,};
                 CTF_data_current = [CTF_data_current;CTF_data_add];
                 set(CTF_output_table,'Data',CTF_data_current)
             elseif numSEC > 1   % stack
                 for kk = 1:numSEC
                     OLname = fullfile(savepath,['OL_ctFIRE_',imagenameNE,'_s',num2str(kk),'.tif']);
                     histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s_s%d.csv',imagenameNE,kk));      % ctFIRE output:csv angle histogram values
                     histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s_s%d.csv',imagenameNE,kk));      % ctFIRE output:csv length histogram values
                     histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s_s%d.csv',imagenameNE,kk));      % ctFIRE output:csv straightness histogram values
                     histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s_s%d.csv',imagenameNE,kk));      % ctFIRE output:csv width histogram values
                     ROIangle = nan; ROIlength = nan; ROIstraight = nan; ROIwidth = nan;
                     if exist(histA2,'file')
                         ROIangle = mean(importdata(histA2));
                         ROIlength = mean(importdata(histL2));
                         ROIstraight = mean(importdata(histSTR2));
                         ROIwidth = mean(importdata(histWID2));
                         fibNUM = length(importdata(histA2));
                     else
                         disp(sprintf('%s does not exist. Fiber metrics reading was skipped.',histA2))
                         ROIangle = nan;
                         ROIlength = nan;
                         ROIstraight = nan;
                         ROIwidth = nan;
                         fibNUM = nan;
                     end
                     xc = nan; yc = nan; zc = kk;
                     roiNameT = '';
                     postFLAG = '';
                     cropFLAG = '';
                     roiShapeT = '';
                     modeID = 'CTF';  % options: 'CTF' or 'CTF+Threshold' or 'FIRE'
                     items_number_current = items_number_current+1;
                     CTF_data_add = {items_number_current,sprintf('%s',imagenameNE),roiNameT,...
                         sprintf('%.1f',ROIwidth),sprintf('%.1f',ROIlength), sprintf('%.2f',ROIstraight),sprintf('%.1f',ROIangle)...
                     sprintf('%d',fibNUM),modeID,cropFLAG,postFLAG,roiShapeT,round(xc),round(yc),zc,};
                     CTF_data_current = [CTF_data_current;CTF_data_add];
                     set(CTF_output_table,'Data',CTF_data_current)
                 end % slices loop
             end  % single image or stack
         end

     end
 %-------------------------------------------------------------------------
% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        if exist('CAdata')
            ctFIRE(CAdata)
        else
            ctFIRE
        end
    end

     function selRo_fn(object,handles)
         set([imgRun imgOpen],'Enable','on');
         if get(selRO,'value') == 4
             set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid ...
                 setFIRE_load, setFIRE_update enterLL1 enterLW1 enterWID WIDadv ...
                 enterRES enterBIN BINauto],'Enable','off');
             set([matModeChk batchModeChk postprocess],'Enable','off');
         else
             set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid ...
                 setFIRE_load, setFIRE_update enterLL1 enterLW1 enterWID WIDadv ...
                 enterRES enterBIN BINauto],'Enable','on');
         end
     end

     function[x_min,y_min,x_max,y_max]=enclosing_rect_fn(coordinates,y_limit,x_limit)
         x_min=round(min(coordinates(:,1)));
         x_max=round(max(coordinates(:,1)));
         y_min=round(min(coordinates(:,2)));
         y_max=round(max(coordinates(:,2)));
         if x_min < 1
             x_min = 1;
         end
         if y_min < 1;
             y_min = 1;
         end
         if x_max > x_limit;
             x_max = x_limit;
         end
         if y_max > y_limit
             y_max = y_limit;
         end

     end

     function  csvdata_read = check_csvfile_fn(filepath_input, filename_input)
         csvdata_read = {nan nan nan nan};
         % check the output values
         csvName_ROI_width = fullfile(filepath_input,'ctFIREout',...
             sprintf('HistWID_ctFIRE_%s.csv',filename_input));
         csvName_ROI_length = fullfile(filepath_input,'ctFIREout',...
             sprintf('HistLEN_ctFIRE_%s.csv',filename_input));
         csvName_ROI_straightness = fullfile(filepath_input,'ctFIREout',...
             sprintf('HistSTR_ctFIRE_%s.csv',filename_input));
         csvName_ROI_angle = fullfile(filepath_input,'ctFIREout',...
             sprintf('HistANG_ctFIRE_%s.csv',filename_input));

         if exist(csvName_ROI_width,'file')
             csvdata_read{1} = importdata(csvName_ROI_width);
         else
             fprintf('%s does NOT exist \n',csvName_ROI_width)
         end
         if exist(csvName_ROI_length,'file')
             csvdata_read{2} = importdata(csvName_ROI_length);
         else
             fprintf('%s does NOT exist \n',csvName_ROI_length)
         end
         if exist(csvName_ROI_straightness,'file')
             csvdata_read{3} = importdata(csvName_ROI_straightness);
         else
             fprintf('%s does NOT exist \n',csvName_ROI_straightness)
         end
         if exist(csvName_ROI_angle,'file')
             csvdata_read{4} = importdata(csvName_ROI_angle);
         else
             fprintf('%s does NOT exist \n',csvName_ROI_angle)
         end
     end

 end
