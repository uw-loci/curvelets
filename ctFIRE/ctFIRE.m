 function ctFIRE

% ctFIRE.m
% This is the GUI associated with an approach of integrating curvelet transform(curvelet.org,2004) and a fiber extraction algorithm(FIRE,A. M. Stein, 2008 Journal of Microscopy).
% To deploy this:
% (1)copy matlab file(.m and .mat) in folder ctFIRE to the folder../FIRE/
% (2)change directory to where the ctFIRE.m is.
% (3) type:
%mcc -m ctFIRE.m -a ../CurveLab-2.1.2/fdct_wrapping_matlab -a ../FIRE -a ../20130227_xlwrite 
%-a FIREpdefault.mat -a ../xlscol/xlscol.m -R '-startmsg,
%"Starting CT-FIRE Version 1.3 Beta2, the license of the third-party code if exists can be found in the open source code at 
% http:// loci.wisc.edu/software/ctfire"'
% at the matlab command prompt 

%Main developers: Yuming Liu, Jeremy Bredfeldt, Guneet Singh Mehta
%Laboratory for Optical and Computational Instrumentation
%University of Wisconsin-Madison
%Since January, 2013
%YL reserved figures: 51,52,55,101, 102, 103, 104,151, 152,  201, 202, 203, 204, 240, 241, 242, 243

home; clear all;close all;
if (~isdeployed)
    addpath('../CurveLab-2.1.2/fdct_wrapping_matlab');
    addpath(genpath(fullfile('../FIRE')));
    addpath('../20130227_xlwrite');
    addpath('.');
    addpath('../xlscol/');
    display('Please make sure you have downloaded the Curvelets library from http://curvelet.org')

end

%% remember the path to the last opened file
if exist('lastPATH.mat','file')
    %use parameters from the last run
    lastPATHname = importdata('lastPATH.mat');
    
    if isequal(lastPATHname,0)
        lastPATHname = '';
    end
else
    %use default parameters
    lastPATHname = '';
end

% global imgName
% guiCtrl = figure('Resize','on','Units','pixels','Position',[25 55 300 650],'Visible','off',...
%     'MenuBar','none','name','ctFIRE V1.3 Beta2','NumberTitle','off','UserData',0);
% guiFig = figure('Resize','on','Units','pixels','Position',[340 55 600 600],'Visible','off',...
%     'MenuBar','figure','name','Original Image','NumberTitle','off','UserData',0);      % enable the Menu bar so that to explore the intensity value
ssU = get(0,'screensize');

guiCtrl = figure('Resize','on','Units','normalized','Position',[0.01 0.1 0.20 0.85],'Visible','on',...
    'MenuBar','none','name','ctFIRE V2.0 Beta','NumberTitle','off','UserData',0);
guiFig = figure(241);clf; %ctFIRE and CTFroi figure
set(guiFig,'Resize','on','Units','normalized','Position',[0.225 0.1 0.65*ssU(4)/ssU(3) 0.85],'Visible','off',...
    'MenuBar','figure','name','Original Image','NumberTitle','off','UserData',0);      % enable the Menu bar so that to explore the intensity value

% guiRecon = figure('Resize','on','Units','pixels','Position',[340 415 300 300],'Visible','off',...
%     'MenuBar','none','name','CurveAlign Reconstruction','NumberTitle','off','UserData',0);

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiFig,'Color',defaultBackground);
% set(guiRecon,'Color',defaultBackground);

set(guiCtrl,'Visible','on');

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);

% button to select an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Open',...
    'FontUnits','normalized','FontSize',.25,'Enable','off','Units','normalized','Position',[0 .88 .12 .08],...
    'callback','ClickedCallback','Callback', {@getFile});

% button to process an output mat file of ctFIRE
postprocess = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Post-processing',...
    'FontUnits','normalized','FontSize',.25,'UserData',[],'Units','normalized','Position',[.525 .88 .475 .08],...
    'callback','ClickedCallback','Callback', {@postP});

% button to set (fiber extraction)FIRE parameters
% setFIRE = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Set parameters',...
%     'FontUnits','normalized','FontSize',.285,'Units','normalized','Position',[0 .80 .50 .08],...
%     'Callback', {@setpFIRE});

% panel to contain buttons for loading and updating parameters
guiPanel0 = uipanel('Parent',guiCtrl,'Title','Parameters: ','Units','normalized','Position',[0 .8 0.520 .08]);
setFIRE_load = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Load',...
    'FontUnits','normalized','FontSize',.285,'Units','normalized','Position',[0.01 .805 .24 .055],...
    'Callback', {@setpFIRE_load});
setFIRE_update = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Update',...
    'FontUnits','normalized','FontSize',.285,'Units','normalized','Position',[0.25 .805 .24 .055],...
    'Callback', {@setpFIRE_update});

% panel to run measurement
guiPanel01 = uipanel('Parent',guiCtrl,'Title','Run Options: ','Units','normalized','Position',[0.520 .8 0.480 .08]);

imgRun = uicontrol('Parent',guiPanel01,'Style','pushbutton','String','RUN',...
    'FontUnits','normalized','FontSize',.325,'Units','normalized','Position',[0 .1 .2 0.9],...
    'Callback',{@kip_run},'TooltipString','Run Analysis');
% select run options
selRO = uicontrol('Parent',guiPanel01,'Style','popupmenu','String',{'ctFIRE'; 'FIRE';'CTF&FIRE';'ROI for individual image';'ROI batch processing'; 'ROI for CTF postprocessing'},...
    'FontUnits','normalized','FontSize',.475,'Units','normalized','Position',[0.2 0 0.8 1],...
    'Value',1,'TooltipString','Select RUn type','Callback',@selRo_fn);

% imgRunPanel = uipanel('Parent',guiCtrl,'Title','Run options',...
%     'FontUnits','normalized','FontSize',.285,'Units','normalized','Position',[0.5 .80 .50 .08])
% select run options


% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',1.0,'Units','normalized','Position',[.75 .975 .25 .025],'callback','ClickedCallback','Callback',{@resetImg},'TooltipString','Reset Image');

% Checkbox to load .mat file for post-processing
matModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','.mat','Min',0,'Max',3,'Units','normalized','Position',[.175 .975 .17 .025]);

%checkbox for batch mode option
batchModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Batch','Min',0,'Max',3,'Units','normalized','Position',[.0 .975 .17 .025]);

%checkbox for selected output option
selModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','OUT.adv','Min',0,'Max',3,'Units','normalized','Position',[.320 .975 .17 .025],'Callback',{@OUTsel});

%checkbox for selected output option
parModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Paral','Min',0,'Max',3,'Units','normalized','Position',[.545 .975 .17 .025],'Callback',{@PARflag_callback},'TooltipString','use parallel computing for multiple images or stacks');


% panel to contain output figure control
guiPanel1 = uipanel('Parent',guiCtrl,'Title','Output Figure Control: ','Units','normalized','FontSize',8,'Position',[0 0.38 1 .225]);

% text box for taking in figure control

LL1label = uicontrol('Parent',guiPanel1,'Style','text','String','Minimum fiber length[pixels] ','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.05 0.85 .85 .15]);
enterLL1 = uicontrol('Parent',guiPanel1,'Style','edit','String','30','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.85 0.875 .14 .15],'Callback',{@get_textbox_data1});

% remove the control for the maximum fiber number 
% FNLlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Maximum fiber number:','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.1 .55 .75 .15]);
% enterFNL = uicontrol('Parent',guiPanel1,'Style','edit','String','9999','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.80 .55 .15 .15],'Callback',{@get_textbox_data2});
% add the image resolution control
RESlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Image Res.[dpi]','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.05 .65 .85 .15]);
enterRES = uicontrol('Parent',guiPanel1,'Style','edit','String','300','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.85 .675 .14 .15],'Callback',{@get_textbox_data2});

LW1label = uicontrol('Parent',guiPanel1,'Style','text','String','Fiber line width [0-2]','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.05 .45 .85 .15]);
enterLW1 = uicontrol('Parent',guiPanel1,'Style','edit','String','0.5','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.85 .475 .14 .15],'Callback',{@get_textbox_data3});

WIDlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Max fiber width[pixels]','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.05 .25 .65 .15]);
enterWID = uicontrol('Parent',guiPanel1,'Style','edit','String','15','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.85 .275 .14 .15],'Callback',{@get_textbox_dataWID});
WIDadv = uicontrol('Parent',guiPanel1,'Style','pushbutton','String','More...',...
    'FontUnits','normalized','FontSize',.45,'Units','normalized','Position',[0.675 .275 .145 .15],...
    'Callback', {@setpWID});

BINlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Histogram bins number[#]','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.05 .05 .65 .15]);
enterBIN = uicontrol('Parent',guiPanel1,'Style','edit','String','10','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.85 .075 .14 .15],'Callback',{@get_textbox_data4});
BINauto = uicontrol('Parent',guiPanel1,'Style','pushbutton','String','AUTO...',...
    'FontUnits','normalized','FontSize',.45,'Units','normalized','Position',[0.675 .075 .145 .15],...
    'Callback', {@setpBIN});


% panel to contain output checkboxes
guiPanel2 = uipanel('Parent',guiCtrl,'Title','Select Output: ','Units','normalized','FontSize',9,'Position',[0 .125 1 .25]);

% checkbox to display the image reconstructed from the thresholded
% overlaid images
makeRecon = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Overlaid fibers','Min',0,'Max',3,'Units','normalized','Position',[.075 .8 .8 .1]);

% non overlaid images
makeNONRecon = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Non-overlaid fibers','Min',0,'Max',3,'Units','normalized','Position',[.075 .65 .8 .1]);

% checkbox to display a angle histogram
makeHVang = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Angle histogram & values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .50 .8 .1]);

% checkbox to display a length histogram
makeHVlen = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Length histogram & values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .35 .8 .1]);

% checkbox to output list of values
makeHVstr = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Straightness histogram & values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .20 .8 .1]);

% checkbox to save length value
makeHVwid = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Width histogram & values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .05 .8 .1]);

% slider for scrolling through stacks
slideLab = uicontrol('Parent',guiCtrl,'Style','text','String','Stack image preview, slice:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .70 .75 .1]);
stackSlide = uicontrol('Parent',guiCtrl,'Style','slide','Units','normalized','position',[0 .72 1 .05],'min',1,'max',100,'val',1,'SliderStep', [.1 .2],'Enable','off');
% panel to contain stack control
guiPanelsc = uipanel('Parent',guiCtrl,'visible','on','BorderType','none','FontUnits','normalized','FontSize',.20,'Units','normalized','Position',[0 0.62 1 .10]);
%  = uicontrol('Parent',guiPanel2,'Style','radio','Enable','on','String','stack range','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .03 .8 .1]);
hsr = uibuttongroup('parent',guiPanelsc,'title','Slices range:', 'visible','on','Units','normalized','Position',[0 0 1 1]);
% Create three radio buttons in the button group.
sru1 = uicontrol('Style','radiobutton','String','whole stack','Units','normalized',...
    'pos',[0 0.6 0.5 0.3 ],'parent',hsr,'HandleVisibility','on');
sru2 = uicontrol('Style','radiobutton','String','Slices','Units','normalized',...
    'pos',[0 0.1 0.5 0.3],'parent',hsr,'HandleVisibility','on');
sru3 = uicontrol('Style','edit','String','','Units','normalized',...
    'pos',[0.2 0.1 0.1 0.4],'parent',hsr,'HandleVisibility','on','BackgroundColor','w',...
    'Userdata',[],'Callback',{@get_textbox_sru3});
sru4 = uicontrol('Style','text','String','To','Units','normalized',...
    'pos',[ 0.35 0.1 0.1 0.4],'parent',hsr,'HandleVisibility','on');
sru5 = uicontrol('Style','edit','String','','Units','normalized',...
    'pos',[0.50 0.1 0.1 0.4],'parent',hsr,'HandleVisibility','on','BackgroundColor','w',...
    'Userdata',[],'Callback',{@get_textbox_sru5});
set(hsr,'SelectionChangeFcn',@selcbk);

% set font
set([guiPanel2 LL1label LW1label WIDlabel RESlabel enterLL1 enterLW1 enterWID WIDadv enterRES ...
    makeHVlen makeHVstr makeRecon makeNONRecon makeHVang makeHVwid imgOpen ...
    setFIRE_load, setFIRE_update imgRun imgReset selRO postprocess slideLab],'FontName','FixedWidth')
set([LL1label LW1label WIDlabel RESlabel BINlabel],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset postprocess],'FontWeight','bold')
set([LL1label LW1label WIDlabel RESlabel BINlabel slideLab],'HorizontalAlignment','left')

%initialize gui
set([postprocess setFIRE_load, setFIRE_update imgRun selRO makeHVang makeRecon makeNONRecon enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto ,...
    makeHVstr makeHVlen makeHVwid],'Enable','off')
set([sru1 sru2 sru3 sru4 sru5],'Enable','off')
set([makeRecon,makeHVang,makeHVlen,makeHVstr,makeHVwid],'Value',3)
%set([makeHVang makeHVlen makeHVstr makeHVwid],'Value',0)

% % initialize variables used in some callback functions
coords = [-1000 -1000];
aa = 1;
imgSize = [0 0];
rows = [];
cols = [];
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
imgLabel = uicontrol('Parent',guiCtrl,'Style','listbox','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.20,'Units','normalized','Position',[0.125  .88  .40 .08],'Callback', {@imgLabel_Callback});
global index_selected %  file index in the file list
global ROIctfp %  parameters to be passed to CTFroi
global idx;    % index to the current slice of a stack
index_selected = 1;   % default file index
ROIctfp = struct('filename',[],'pathname',[],'ctfp',[],'CTF_data_current',[],'roiopenflag',[]);  % initialize the ROI
idx = 1; 

%%parallel computing flag to close or open matlabpool
     prlflag = 0 ; %YL: parallel loop flag, 0: regular for loop; 1: parallel loop , will add this as a control on the interface later
     if exist('matlabpool','file')
         if (matlabpool('size') ~= 0);
             matlabpool close;
         end
         
     end
     
%% YL create CT-FIRE output table for ROI analysis and batch mode analysis 
     img = [];  % current image data
     roimatDir = '';  % directory for roi .mat files
     roiMATnamefull = ''; % directory for the fullpath of ROI .mat files
     fileEXT = '.tif';   % defaut image extention

      ROIshapes = {'Rectangle','Freehand','Ellipse','Polygon'};

    % Column names and column format
    columnname = {'No.','IMG Label','ROI label','Shape','Xc','Yc','z','Width','Length','Straightness','Angle'};
    columnformat = {'numeric','char','char','char','numeric','numeric','numeric','numeric' ,'numeric','numeric' ,'numeric'};
    CTF_data_current = [];
    selectedROWs = [];
    stackflag = [];
 
    CTF_table_fig = figure(242); clf
%      figPOS = get(caIMG_fig,'Position');
%      figPOS = [figPOS(1)+0.5*figPOS(3) figPOS(2)+0.75*figPOS(4) figPOS(3)*1.25 figPOS(4)*0.275]
     figPOS = [0.55 0.45 0.425 0.425];
     set(CTF_table_fig,'Units','normalized','Position',figPOS,'Visible','off','NumberTitle','off')
     set(CTF_table_fig,'name','CT-FIRE ROI analysis output table')
     CTF_output_table = uitable('Parent',CTF_table_fig,'Units','normalized','Position',[0.05 0.05 0.9 0.9],...
    'Data', CTF_data_current,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false false false false false false false false false false false],...
    'RowName',[],...
    'CellSelectionCallback',{@CTFot_CellSelectionCallback});
%%

set(imgOpen,'Enable','on')
infoLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Initialization is done. Import image or data to start','FontUnits','normalized','FontSize',.35,'Units','normalized','Position',[0 .05 .95 .05]);
set(infoLabel,'FontName','FixedWidth','HorizontalAlignment','left');

disp('Initialization is done. Import image or data to start.')

% callback functoins
%-------------------------------------------------------------------------
%% output table callback functions

    function CTFot_CellSelectionCallback(hobject, eventdata,handles)
        handles.currentCell=eventdata.Indices;
        selectedROWs = unique(handles.currentCell(:,1));
        selectedZ = CTF_data_current(selectedROWs,7);
  
        if length(selectedROWs) > 1
            IMGnameV = CTF_data_current(selectedROWs,2);
            uniqueName = strncmpi(IMGnameV{1},IMGnameV,length(IMGnameV{1}));
            if length(find(uniqueName == 0)) >=1
                error('only display ROIs in the same section of a stack or in the same image');
            else
                IMGname = IMGnameV{1};
            end
            
        else
            IMGname = CTF_data_current{selectedROWs,2};
        end
        
         roiMATnamefull = [IMGname,'_ROIs.mat'];
        load(fullfile(roimatDir,roiMATnamefull),'separate_rois')
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
                error('only display ROIs in the same section of a stack')
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
            %                 IMG = rgb2gray(IMGtemp);
            img2 = img2(:,:,1);
        end
        
        
%         if numSections == 1
%                 
%             IMGO(:,:,1) = uint8(image(:,:,1));
%             IMGO(:,:,2) = uint8(image(:,:,2));
%             IMGO(:,:,3) = uint8(image(:,:,3));
%         elseif numSections > 1
%             
%             IMGtemp = imread(fullfile(CApathname,CAfilename),zc);
%             if size(IMGtemp,3) > 1
% %                 IMGtemp = rgb2gray(IMGtemp);
%                  IMGtemp = IMGtemp(:,:,1);
%             end
%                 IMGO(:,:,1) = uint8(IMGtemp);
%                 IMGO(:,:,2) = uint8(IMGtemp);
%                 IMGO(:,:,3) = uint8(IMGtemp);
%         
%         end
        
        for i= 1:length(selectedROWs)
           CTF_name_selected =  CTF_data_current(selectedROWs(i),3);
          
           if numSections > 1
               roiNamefull = [IMGname,sprintf('_s%d_',zc),CTF_name_selected{1},'.tif'];
           elseif numSections == 1
               roiNamefull = [IMGname,'_', CTF_name_selected{1},'.tif'];
           end

           
        end
          figure(guiFig);  imshow(img2); hold on;
                    
              for i=1:length(selectedROWs)
                  
                  CTF_name_selected =  CTF_data_current(selectedROWs(i),3);
                  data2=[];vertices=[];
           %%YL: adapted from cell_selection_fn     
                  if(separate_rois.(CTF_name_selected{1}).shape==1)
                    %display('rectangle');
                    % vertices is not actual vertices but data as [ a b c d] and
                    % vertices as [(a,b),(a+c,b),(a,b+d),(a+c,b+d)] 
                    data2=separate_rois.(CTF_name_selected{1}).roi;
                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                    vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
                    BW=roipoly(img2,vertices(:,1),vertices(:,2));
                    
                  elseif(separate_rois.(CTF_name_selected{1}).shape==2)
                      %display('freehand');
                      vertices=separate_rois.(CTF_name_selected{1}).roi;
                      BW=roipoly(img2,vertices(:,1),vertices(:,2));
                      
                  elseif(separate_rois.(CTF_name_selected{1}).shape==3)
                      %display('ellipse');
                      data2=separate_rois.(CTF_name_selected{1}).roi;
                      a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                      %here a,b are the coordinates of uppermost vertex(having minimum value of x and y)
                      %the rect enclosing the ellipse. 
                      % equation of ellipse region->
                      % (x-(a+c/2))^2/(c/2)^2+(y-(b+d/2)^2/(d/2)^2<=1
                      s1=size(img2,1);s2=size(image,2);
                      for m=1:s1
                          for n=1:s2
                                dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                %%display(dist);pause(1);
                                if(dist<=1.00)
                                    BW(m,n)=logical(1);
                                else
                                    BW(m,n)=logical(0);
                                end
                          end
                      end
                      %figure;imshow(255*uint8(BW));
                  elseif(separate_rois.(CTF_name_selected{1}).shape==4)
                      %display('polygon');
                      vertices=separate_rois.(CTF_name_selected{1}).roi;
                      BW=roipoly(img2,vertices(:,1),vertices(:,2));
                      
                  end
    
              
                  B=bwboundaries(BW);
%                   figure(image_fig);
                  for k2 = 1:length(B)
                     boundary = B{k2};
                     plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);%boundary need not be dilated now because we are using plot function now
                  end
                  [yc xc]=midpoint_fn(BW);%finds the midpoint of points where BW=logical(1)
                       
              
             text(xc,yc,sprintf('%d',selectedROWs(i)),'fontsize', 10,'color','m')
           
          end
        hold off 
        
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
       % openimg is 1 if one image is selected and 0 if multiple images
       % would be selected
       
        %checking for invalid combinations - if present then return
        % 1st invalid - out.adv+batch
        % 2nd Paral +batch
        if (get(batchModeChk,'Value')==get(batchModeChk,'Max')&&get(matModeChk,'Value')==get(matModeChk,'Max'))
            set(infoLabel,'String','Batchmode Processing cannot be done on .mat files');
            return;
        end
        if(get(selModeChk,'Value')==get(selModeChk,'Max')&&get(parModeChk,'Value')==get(parModeChk,'Max'))
             set(infoLabel,'String','Parallel Processing cannot be done for Post Processing');
            return;
        end
       
        if (get(batchModeChk,'Value') ~= get(batchModeChk,'Max')); openimg =1; else openimg =0;end
        if (get(matModeChk,'Value') ~= get(matModeChk,'Max')); openmat =0; else openmat =1;end
        if (get(selModeChk,'Value') ~= get(selModeChk,'Max')); opensel =0; else opensel =1;end

        
        if openimg==1
           % single image 
           if openmat==0 % normal image
               [imgName,imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select an Image',lastPATHname,'MultiSelect','on'); 
               if(iscell(imgName))
                   openimg=0;%setting to multiple images mode
                   set(batchModeChk,'Value',get(batchModeChk,'Max'));%setting the batchmodechk box when multiple images are selected
               end
           elseif openmat==1
               [matName,matPath] = uigetfile({'*FIREout*.mat'},'Select .mat file(s)',lastPATHname,'MultiSelect','on');
               if(iscell(imgName))
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
               % [imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select an Image',lastPATHname,'MultiSelect','off');
                if ~isequal(imgPath,0)
                    lastPATHname = imgPath;
                    save('lastPATH.mat','lastPATHname');
                end
                
                
                if imgName == 0
                    disp('Please choose the correct image/data to start an analysis.');
                else
                    
                    %filePath = fullfile(pathName,fileName);
                    %set(imgList,'Callback',{@showImg})
                    set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update selRO enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto],'Enable','on');
                    set([imgOpen matModeChk batchModeChk postprocess],'Enable','off');
                    set(guiFig,'Visible','on');
                    set(infoLabel,'String','Load and/or update parameters');
                    
                    ff = [imgPath, imgName];
                    info = imfinfo(ff);
                    numSections = numel(info);
                    if numSections > 1
                        openstack = 1;
                        setappdata(imgOpen, 'openstack',openstack);
                        setappdata(imgOpen,'totslice',numSections);
                        disp('Default slcices range is  whole stack')
                        setappdata(hsr,'wholestack',1);
                        img = imread(ff,1,'Info',info);
                        set(stackSlide,'max',numSections);
                        set(stackSlide,'Enable','on');
                        set(stackSlide,'SliderStep',[1/(numSections-1) 3/(numSections-1)]);
                        set(stackSlide,'Callback',{@slider_chng_img});
                        set(slideLab,'String','Stack image preview, slice: 1');
                        set([sru1 sru2],'Enable','on')
                        
                    else
                        openstack = 0;
                        setappdata(imgOpen, 'openstack',openstack);
                        img = imread(ff);
                    end
                    
                    setappdata(imgOpen, 'openstack',openstack);
                    
                    if size(img,3) > 1 %if rgb, pick one color
                        img = img(:,:,1);
                    end
                    figure(guiFig);
%                     img = imadjust(img);  % YL: only display original image
                    imshow(img,'Parent',imgAx);
                    imgSize = size(img);
                    %displayImg(img,imgPanel)
                    
                    %files = {fileName};
                    setappdata(imgOpen,'img',img);
                    %info = imfinfo(ff);
                    imgType = strcat('.',info(1).Format);
                    %         imgName = getFileName(imgType,fileName);  % YL
                    setappdata(imgOpen,'type',info(1).Format)
                    colormap(gray);
                    if numSections > 1
                        set(guiFig,'name',sprintf('%s, stack, %d slices, %d x %d pixels, %d-bit',imgName,numel(info),info(1).Width,info(1).Height,info(1).BitDepth));
                    else
                        set(guiFig,'name',sprintf('%s, %d x %d pixels, %d-bit',imgName,info.Width,info.Height,info.BitDepth));
                    end
                    set([LL1label LW1label WIDlabel RESlabel BINlabel],'ForegroundColor',[0 0 0])
                    set(guiFig,'UserData',0)
                    
%                     if ~get(guiFig,'UserData')
%                         set(guiFig,'WindowKeyPressFcn',@startPoint)
%                         coords = [-1000 -1000];
%                         aa = 1;
%                     end
                    
                    if numSections > 1
                        %initialize gui
                        
                        set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto],'Enable','on');
                        set([imgOpen matModeChk batchModeChk postprocess],'Enable','off');
                        set(guiFig,'Visible','on');
                        set(infoLabel,'String','Load and/or update parameters');
                        
                    end
                    
                    setappdata(imgOpen,'imgPath',imgPath);
                    setappdata(imgOpen, 'imgName',imgName);
                    
                end
                
           
                
            else
                %[matName matPath] = uigetfile({'*FIREout*.mat'},'Select .mat file(s)',lastPATHname,'MultiSelect','off');
                if ~isequal(matPath,0)
                   
                    imgPath = strrep(matPath,'ctFIREout','');
                end
                if ~isequal(matPath,0)
                    lastPATHname = matPath;
                    save('lastPATH.mat','lastPATHname');
                    
                end
                
                if matName == 0
                    disp('Please choose the correct image/data to start an analysis.');
                else
                    matfile = [matPath,matName];
                    savePath = matPath;
                     %% 7-18-14: don't load imgPath,savePath, use relative image path
%                 load(matfile,'imgName','imgPath','savePath','cP','ctfP'); % 
                  load(matfile,'imgName','cP','ctfP'); % 
%                     load(matfile,'matdata');
%                     imgName = matdata.imgName;
%                     cP = matdata.cP;
%                     ctfP = matdata.ctfP;

                    ff = [imgPath, imgName];
                    info = imfinfo(ff);
                    if cP.stack == 1
                        img = imread(ff,cP.slice);
                    else
                        img = imread(ff);
                    end
                    if size(img,3) > 1 %if rgb, pick one color
                        img = img(:,:,1);
                    end
                    figure(guiFig);
%                     img = imadjust(img);  % YL: only display original image
                    imshow(img,'Parent',imgAx);
                   
                    if cP.stack == 1
                        set(guiFig,'name',sprintf('%s, stack, %d slices, %d x %d pixels, %d-bit',imgName,numel(info),info(1).Width,info(1).Height,info(1).BitDepth));
                    else
                        set(guiFig,'name',sprintf('%s, %d x %d pixels, %d-bit',imgName,info.Width,info.Height,info.BitDepth));
                    end
                    
                    setappdata(imgRun,'outfolder',savePath);
                    setappdata(imgRun,'ctfparam',ctfP);
                    setappdata(imgRun,'controlpanel',cP);
                    setappdata(imgOpen,'matPath',matPath);
                    setappdata(imgOpen,'matName',matName);  % YL
                    
                    set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid enterLL1 enterLW1 enterWID WIDadv ...
                        enterRES enterBIN BINauto postprocess],'Enable','on');
                    set([imgOpen matModeChk batchModeChk imgRun setFIRE_load, setFIRE_update],'Enable','off');
                    set(infoLabel,'String','Load and/or update parameters');
                    
                end
                
            end
            setappdata(imgOpen,'imgPath',imgPath);
            setappdata(imgOpen, 'imgName',imgName);
            %             set(guiFig,'Visible','on');
            
        else   % open multi-files
            if openmat ~= 1
%                 [imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)',lastPATHname,'MultiSelect','on');
                 if ~isequal(imgPath,0)
                    lastPATHname = imgPath;
                    save('lastPATH.mat','lastPATHname');

                end
                
                if ~iscell(imgName)
                    error('Please select at least two files to do batch process')
                    
                else
                    setappdata(imgOpen,'imgPath',imgPath);
                    setappdata(imgOpen,'imgName',imgName);
                    set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update selRO enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto],'Enable','on');
                    set([imgOpen matModeChk batchModeChk postprocess],'Enable','off');
                    %                 set(guiFig,'Visible','on');
                    set(infoLabel,'String','Load and/or update parameters');
                end
                
            else
                %                 matPath = [uigetdir([],'choosing mat file folder'),'\'];

%                 [matName matPath] = uigetfile({'*FIREout*.mat';'*.*'},'Select multi .mat files',lastPATHname,'MultiSelect','on');
                 if ~isequal(matPath,0)
                    imgPath = strrep(matPath,'ctFIREout','');
                 end
                 if ~isequal(matPath,0)
                    lastPATHname = matPath;
                    save('lastPATH.mat','lastPATHname');
                end
                if ~iscell(matName)
                    error('Please select at least two mat files to do batch process')
                else
                    
                    setappdata(imgOpen,'matName',matName);
                    setappdata(imgOpen,'matPath',matPath);
                    set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid enterLL1 enterLW1 enterWID WIDadv enterRES enterBIN BINauto],'Enable','on');
                    
                    set([postprocess],'Enable','on');
                    set([imgOpen matModeChk batchModeChk],'Enable','off');
                    
                    
                    set(infoLabel,'String','Select parameters');
                    
                end
            end
            
            
        end
        % load default fiber extraction parameters for image(s) or stack
        
        if openmat ~= 1
            if imgPath ~= 0
                
                %   load default fiber extraction parameters
                                
%                 pdf = load(fullfile(pwd,'FIREpdefault.mat')); %'pvalue' 'pdesc' 'pnum' 'tcnum'%YL07-19-14: add full path of the .mat file
%                pdf = load('FIREpdefault.mat'); %'pvalue' 'pdesc' 'pnum' 'tcnum'%YL07-19-14: add full path of the .mat file
                [pathstr,pfname]=fileparts(which('FIREpdefault.mat'));
                pdf = load(fullfile(pathstr,[pfname,'.mat']));
                
              
                pdesc = pdf.pdesc;
                pnum = pdf.pnum;
                pvalue = pdf.pvalue;
                tcnum = pdf.tcnum;
                
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
                        %              disp(sprintf('parameter # %d [%s],is string type',itc, pfnames{itc}));
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
                
                % change string type to numerical type and calculate sin or
                % cos
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
    set(imgRun,'Enable','on');
    
    %% add global file name and path name
    
    if ~iscell(imgName)
        pathName = imgPath;
        fileName = {imgName};
    else
        fileName = imgName;
        pathName = imgPath;
    end
    
    [~,~,fileEXT] = fileparts(fileName{1}) ; % all the images should have the same extention
    
    IMGnamefull = fullfile(pathName,fileName{1});
    IMGinfo = imfinfo(IMGnamefull);
    if numel(IMGinfo) > 1% number of sections
        stackflag = 1;    % 
    end
    
    set(imgLabel,'String',fileName);
   
    end


%--------------------------------------------------------------------------
% callback function for listbox 'imgLabel'
    function imgLabel_Callback(imgLabel, eventdata, handles)
        % hObject    handle to imgLabel
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        % Hints: contents = cellstr(get(hObject,'String')) returns contents
        % contents{get(hObject,'Value')} returns selected item from listbox1
        if isempty(find(findobj('Type','figure')== 241))   % if guiFig is closed, reset it again
            
            guiFig = figure(241); %ctFIRE and CTFroi figure
            set(guiFig,'Resize','on','Units','normalized','Position',[0.225 0.25 0.65*ssU(4)/ssU(3) 0.65],'Visible','off',...
                'MenuBar','figure','name','Original Image','NumberTitle','off','UserData',0);      % enable the Menu bar so that to explore the intensity value
            set(guiFig,'Color',defaultBackground);
            imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
            imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);
      
        end
        
        items = get(imgLabel,'String');
        if ~iscell(items)
            items = {items};
        end
        index_selected = get(imgLabel,'Value');
        item_selected = items{index_selected};
        display(item_selected);
        
        item_fullpath = fullfile(pathName,item_selected);
        iteminfo = imfinfo(item_fullpath);
        item_numSections = numel(iteminfo);
        ff = item_fullpath; info = iteminfo; numSections = item_numSections;
        
        if numSections > 1
            openstack = 1;
            setappdata(imgOpen, 'openstack',openstack);
            setappdata(imgOpen,'totslice',numSections);
            disp('Default slcices range is  whole stack')
            setappdata(hsr,'wholestack',1);
            img = imread(ff,1,'Info',info);
            set(stackSlide,'max',numSections);
            set(stackSlide,'Enable','on');
            set(stackSlide,'SliderStep',[1/(numSections-1) 3/(numSections-1)]);
            set(stackSlide,'Callback',{@slider_chng_img});
            set(slideLab,'String','Stack image preview, slice: 1');
            set([sru1 sru2],'Enable','on')
            
        else
            openstack = 0;
            setappdata(imgOpen, 'openstack',openstack);
            img = imread(ff);
        end
        
            
%             if item_numSections > 1
%                 img = imread(item_fullpath,1,'Info',info);
%                 set(stackSlide,'max',item_numSections);
%                 set(stackSlide,'Enable','on');
%                 set(stackSlide,'SliderStep',[1/(item_numSections-1) 3/(item_numSections-1)]);
%                 set(slideLab,'String','Stack image selected: 1');
%             else
%                 img = imread(item_fullpath);
%                 set(stackSlide,'Enable','off');
%             end
            
            if size(img,3) > 1
                img = img(:,:,1); %if rgb, pick one color
            end
            
            figure(guiFig);
%             img = imadjust(img);
            imshow(img,'Parent',imgAx);
            imgSize = size(img);
           if item_numSections == 1
               
               set(guiFig,'name',sprintf('%s, %dx%d pixels, %d-bit',item_selected,info.Height,info.Width,info.BitDepth))
               
           elseif item_numSections > 1   % stack
               
               set(guiFig,'name',sprintf('(1/%d)%s, %dx%d pixels, %d-bit stack',item_numSections,item_selected,info(1).Height,info(1).Width,info(1).BitDepth))
          
           end
            setappdata(imgOpen,'img',img);
            setappdata(imgOpen,'type',info(1).Format)
            colormap(gray);
            
            set(guiFig,'UserData',0)
      
            set(guiFig,'Visible','on');
            
         
    end

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% callback function for FIRE params button
% load ctFIRE parameters
    function setpFIRE_load(setFIRE_load,eventdata)

% ---------for windows----------
%         [ctfpName ctfpPath] = uigetfile({'*.xlsx';'*.*'},'Load parameters via xlsx file','MultiSelect','off');
%         xlsfullpath = [ctfpPath ctfpName];
%         [~,~,ctfPxls]=xlsread(xlsfullpath,1,'C1:C29');  % the xlsfile has 27 rows and 4 column:
%         currentP = ctfPxls(1:27)';
%         ctp = ctfPxls(28:29)';
%         ctp{1} = num2str(ctp{1}); ctp{2} = num2str(ctp{2}); % change to string to be used in ' inputdlg'
% --------------------------------------------------cs-------------------
 %---------for MAC and Windows, MAC doesn't support xlswrite and xlsread----
         
        [ctfpName ctfpPath] = uigetfile({'*.csv';'*.*'},'Load parameters via csv file',lastPATHname,'MultiSelect','off');
         
        xlsfullpath = [ctfpPath ctfpName];
            
        fid1 = fopen(xlsfullpath,'r');
        tline = fgetl(fid1);  % fgets
        k = 0;
        while ischar(tline)
            k = k+1;
            currentPload{k} = deblank(tline);
            tline = fgetl(fid1);
        end
        fclose(fid1)
       currentP = currentPload(1:27); 
       ctp{1} = deblank(currentPload{28});  ctp{2} = deblank(currentPload{29});  
  % ------------------------------------------------------------------------     
    
        ctpfnames = {'ct threshold', 'ct selected scales'};
        pfnames = getappdata(imgOpen,'FIREpname');
        %              pvalue = currentP;
        pvalue = struct;  %initialize pvalue as a structure;
       %YL: load the parameters into pvalue
        for ifp = 1:27                 % number of fire parameters
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
                %              disp(sprintf('parameter # %d [%s],is string type',itc, pfnames{itc}));
            end
        end
        setappdata(imgOpen,'FIREparam',currentP);
        
        RO = get(selRO,'Value');
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
        
        disp('Parameters for running ctFIRE are loaded.')
        
        set(imgRun,'Enable','on')
        
    end

% update ctFIRE parameters

    function setpFIRE_update(setFIRE_update,eventdata)
        
        pvalue =  getappdata(imgOpen, 'FIREpvalue');
        currentP = getappdata(imgOpen, 'FIREparam');
        pfnames = getappdata(imgOpen,'FIREpname');
        %             pvalue.load = 0; % pvalue is not from loading
        name='Update FIRE parameters';
        prompt= pfnames';
        numlines=1;
               
        defaultanswer= currentP;
        updatepnum = [5 7 10 15:20];
        promptud = prompt(updatepnum);
        defaultud=defaultanswer(updatepnum);
        %     FIREp = inputdlg(prompt,name,numlines,defaultanswer);
        
        FIREpud = inputdlg(promptud,name,numlines,defaultud);
        
        if length(FIREpud)>0
            
            for iud = updatepnum
                
                pvalue = setfield(pvalue,pfnames{iud},FIREpud{find(updatepnum ==iud)});
                
            end
            
            setappdata(imgOpen, 'FIREpvalue',pvalue);  % update fiber extraction pvalue
            disp('Fiber extraction parameters are updated or confirmed')
            fpupdate = 1;
            currentP = struct2cell(pvalue)';
            setappdata(imgOpen, 'FIREparam',currentP);  % update fiber extraction parameters
            
        else
           disp('Please confirm or update the fiber extraction parameters.')
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
        %             setappdata(setFIRE,'FIREp',fp);
        
        RO = get(selRO,'Value');
        if RO == 1 || RO == 3 || RO == 4 || RO == 5     % ctFIRE need to set pct and SS
            name='set ctFIRE parameters';
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
             disp('Curvelet transform parameters are updated or confirmed.')

            else
                disp('Please confirm or update the curvelet transform parameters. ')
                
            end
            
        else
            ctfP.pct = [];
            ctfP.SS  = [];
            ctfP.value = fp.value;
            ctfP.status = fp.status;
            setappdata(imgRun,'ctfparam',ctfP);
            
        end
        
        set(imgRun,'Enable','on')
        
    end

%--------------------------------------------------------------------------
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
        set(slideLab,'String',['Stack image preview, slice: ' num2str(idx)]);
        
    end

%callback functoins for stack control
    function get_textbox_sru3(sru3,eventdata)
        
        usr_input = get(sru3,'String');
        usr_input = str2double(usr_input);
        set(sru3,'UserData',usr_input)
        setappdata(hsr,'srstart',usr_input);
        %
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
            disp(' Needs to enter the slices range');
            setappdata(hsr,'wholestack',0);
            srstart = get(sru3,'UserData');
            srend = get(sru5,'UserData');
            if length(srstart) == 0 || length(srend) == 0
                
                disp('Please enter the correct slice range')
            else
                setappdata(hsr,'srstart',srstart);
                setappdata(hsr,'srend',srend);
                disp(sprintf('updated,start slice is %d, end slice is %d',srstart,srend));
            end
            
        else
            disp('Slcices range is  whole stack')
            setappdata(hsr,'wholestack',1);
            set([sru3 sru4 sru5],'Enable','off')
            
        end
        
    end
%--------------------------------------------------------------------------
% callback function for selModeChk
    function OUTsel(selModeChk,eventdata)
        
        if (get(selModeChk,'Value') ~= get(selModeChk,'Max')); opensel =0; else opensel =1;end
        setappdata(imgOpen, 'opensel',opensel);
        %          getappdata(imgOpen, 'opensel',opensel);
        %switch to advanced selective output
        if opensel == 1
            set(imgOpen,'Enable','off')
            set(postprocess,'Enable','on')
            set([makeRecon makeHVang makeHVlen makeHVstr makeHVwid enterBIN BINauto],'Enable','on');
            set([makeNONRecon enterLL1 enterLW1 enterWID WIDadv enterRES],'Enable','off');
            set(infoLabel,'String','Advanced selective output.');
            set([batchModeChk matModeChk parModeChk],'Enable','off');
        else
            set(imgOpen,'Enable','on')
            set(postprocess,'Enable','off')
            set([makeHVang makeHVlen makeHVstr makeHVwid enterBIN BINauto],'Enable','off');
            set(infoLabel,'String','Import image or data');
            set([batchModeChk matModeChk parModeChk],'Enable','on');
        end
       
    end

%% callback function for selModeChk
     function PARflag_callback(hobject,handles)
         
         if exist('matlabpool','file')
             disp('matlab parallel computing toolbox exists')
         else
             error('Matlab parallel computing toolbox do not exist')
             
         end
         
         if (get(parModeChk,'Value') ~= get(parModeChk,'Max'))
             prlflag =0;
             if (matlabpool('size') ~= 0);
                 matlabpool close;
             end
         else
             prlflag = 1;
             if (matlabpool('size') == 0)  ;
                 %                      matlabpool open;  % % YL, tested in Matlab 2012a and 2014a, Start a worker pool using the default profile (usually local) with
                 % to customize the number of core, please refer the following
                 %GSM- optimization of number of cores -starts
                 mycluster=parcluster('local');
                 numCores = feature('numCores');
                 if  numCores > 2
                     mycluster.NumWorkers = numCores - 1;% finds the number of multiple cores for the host machine
                     saveProfile(mycluster);% myCluster has the same properties as the local profile but the number of cores is changed
                 end
                 matlabpool(mycluster);
                 
             end
             
             disp('Parallel computing can be used for extracting fibers from multiple images or stack(s)')
             disp(sprintf('%d out of %d labs will be used for parallel computing ', mycluster.NumWorkers,numCores))
             
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
        
        WIDopt = questdlg('Use all the found fiber points?','Fiber Width Calculation Options','YES to use all','NO to select','YES to use all');
        setappdata(WIDadv,'value',WIDopt)
        
        switch WIDopt
            case 'YES to use all'
                disp('Use all the extracted points to calculate width except for the artifact points.')
                setappdata(WIDadv,'WIDall',1)
                widcon.wid_opt = 1; 
                return
            case 'NO to select'
                disp('Determine the criteria to select points for width calcultion.') 
                widcon.wid_opt = 0; 
            case ''
                disp('Customized fiber points selection may help improve the accuracy of the width calculation.')
                return
        end
        
        
       
       WIDsel =  struct2cell(widcon);
      
       promptud = {'Minimum maximum fiber width','Minimum points to apply fiber points selection',...
            'Confidence region, times of sigma','Output Maximum fiber width (default 0)'};
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
        
        return
        
        
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
                disp('Auto bins number calculation is off. Auto Please ensure .mat/.csv file exists')
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
                disp('Auto bins number calculation is off. Auto Please ensure .mat/.csv file exists')
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
                disp('Auto bins number calculation is off. Auto Please ensure selected output .xlsx file exists')
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
                disp('Auto bins number calculation is off. Auto Please ensure the combined selected output ALL*.xlsx file exists')
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
                
                
         BINopt = questdlg('Which method to be used?', 'Estimate optimal BINs number based on all extracted fibers (N)',...
             'Square-root','Sturges formula','Rice Rule','Square-root');
        setappdata(BINauto,'value',BINopt);
       
        switch  BINopt,
             case 'Square-root',
                  BINa = round(sqrt(N));
                  set(enterBIN,'UserData',BINa);
                  disp(sprintf(' use %s [sqrt(N)] for bins number calculation, BINs = %d', BINopt, BINa));
         
             case 'Sturges formula',
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

%
% callback function for enterFNL text box
%     function get_textbox_data2(enterFNL,eventdata)
%         usr_input = get(enterFNL,'String');
%         usr_input = str2double(usr_input);
%         set(enterFNL,'UserData',usr_input)
%     end

%--------------------------------------------------------------------------
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
%             set([makeHVang makeHVlen makeHVstr makeHVwid enterLL1 enterLW1 enterWID enterRES enterBIN],'Enable','on');
            
%             set([makeRecon makeNONRecon imgOpen matModeChk batchModeChk],'Enable','off');
               set(infoLabel,'String','Open a post-processed data file of selected fibers  ');
                              
              [selName selPath] = uigetfile({'*statistics.xlsx';'*statistics.xls';'*statistics.csv';'*.*'},'Choose a processed data file',lastPATHname,'MultiSelect','off');
              if isequal(selPath,0)
                  disp('Please a post-processed data file to start the  analysis')
                  return
              end
              if OLplotflag == 1 
                  OLchoice = questdlg('Does the overlaid image exist?','Create Overlaid Image?', ...
                      'Yes to display','No to create','Yes to display');
              end
              
              set(infoLabel,'String','Select parameters for advanced fiber selection');
    
              if ~isequal(selPath,0)
                  imgPath = strrep(selPath,'\selectout','');
                  lastPATHname = selPath;
                  save('lastPATH.mat','lastPATHname');
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
              set(infoLabel,'String','Open a batch-processed data file of selected fibers  ');
             [selName selPath] = uigetfile({'batch*statistics*.xlsx';'batch*statistics*.xls';'batch*statistics*.csv';'*.*'},'Choose a batch-processed data file',lastPATHname,'MultiSelect','off');
             if isequal(selPath,0)
                  disp('Please a post-processed data file to start the batch analysis')
                  return
              end
             if OLplotflag == 1
                 OLchoice = questdlg('Does the overlaid image exist?','Create Overlaid Image?', ...
                     'Yes to display','No to create','Yes to display');
                 set(infoLabel,'String','Select parameters for advanced fiber selection');
             end
               %                if ~isequal(selPath,0)
%                    imgPath = strrep(selPath,'\selectout','');
%                end
%                if ~isequal(imgPath,0)
%                     lastPATHname = imgPath;
%                     save('lastPATH.mat','imgPath');
%                 end 

                if ~isequal(selPath,0)
                    imgPath = strrep(selPath,'\selectout','');
                    lastPATHname = selPath;
                    save('lastPATH.mat','lastPATHname');
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
                    img = img(:,:,1);
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
                
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
       
              set(infoLabel,'String','Analysis is ongoing ...');
              cP.widcon = widcon;
              ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
              
                
            end
            
            set(infoLabel,'String','Analysis is done'); 
            
        else
            
            dirout = getappdata(imgRun,'outfolder');
            ctfP = getappdata(imgRun,'ctfparam');
            cP = getappdata(imgRun,'controlpanel');
            cP.postp = 1;
            
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
            
            set(infoLabel,'String','Analysis is ongoing ...');
            cP.widcon = widcon;
            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
            
        end
        set(infoLabel,'String','Analysis is done');    
            
        end
        
     set([batchModeChk matModeChk selModeChk],'Enable','on');
     home;
     if opensel == 1 && openmat == 0 && openimg ==1
         disp('Switch to advanced output control module')
     else
         disp('Post-processing is done!');
     end
    end

% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        
         RO =  get(selRO,'Value');
    
 %% batch-mode ROI analysis with previous fiber extraction on the whole image    
    if RO == 6
        
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
        roimatDir = fullfile(pathName,'ROI\ROI_management\');
        
        % CT-FIRE output files must be present)

        ctfFnd = checkCTFireFiles(matDir, fileName);  % if stack, check the mat file of the first slice
        
        if (~isempty(ctfFnd))
            set(infoLabel,'String','');
        else
            set(infoLabel,'String','One or more CT-FIRE files are missing.');
            return;
        end
             
        k = 0
        for i = 1:length(fileName)
            [~,fileNameNE] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            if exist(fullfile(roimatDir,roiMATnamefull),'file')
                k = k + 1; disp(sprintf('Found ROI for %s',fileName{i}))
            else
                disp(sprintf('ROI for %s not exist',fileName{i}));
            end
                
        end
        
        if k ~= length(fileName)
            error(sprintf('Missing %d ROI files',length(fileName) - k))
        end
        
        roioutDir = fullfile(pathName,'ROI\ROI_management\ctFIRE_on_ROIbatch_post\ctFIREout');
        roiIMGDir = fullfile(pathName,'ROI\ROI_management\ctFIRE_on_ROIbatch_post\ctFIREout');
        
             
        if(exist(horzcat(pathName,'ROI\ROI_management\ctFIRE_on_ROIbatch_post\ctFIREout'),'dir')==0)%check for ROI folder
            mkdir(pathName,'ROI\ROI_management\ctFIRE_on_ROIbatch_post\ctFIREout');
        end
        
        items_number_current = 0;
        for i = 1:length(fileName)
            [~,fileNameNE] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            load(fullfile(roimatDir,roiMATnamefull),'separate_rois')
            ROInames = fieldnames(separate_rois);
            s_roi_num = length(ROInames);
          
            IMGname = fullfile(pathName,fileName{i});
            IMGinfo = imfinfo(IMGname);
            numSections = numel(IMGinfo); % number of sections, default: 1;
            if numSections > 1, stackflag =1; end;
            for j = 1:numSections
                
                if numSections == 1
                    IMG = imread(IMGname);
                    ctfmatname = fullfile(pathName,'ctFIREout',['ctFIREout_' fileNameNE '.mat'])
           
                else
                    IMG = imread(IMGname,j);
                    ctfmatname = fullfile(pathName,'ctFIREout',sprintf('ctFIREout_%s_s%d.mat',fileNameNE,j));
                   
                end
                
                if size(IMG,3) > 1
                    %if rgb, pick one color
                    IMG = IMG(:,:,1);
                end
                
                for k=1:s_roi_num
                    combined_rois_present=0;
                    ROIshape_ind = separate_rois.(ROInames{k}).shape;
                    if(combined_rois_present==0)
                       % when combination of ROIs is not present
                       %finding the mask -starts
                       if(ROIshape_ind==1)
                        data2 = separate_rois.(ROInames{k}).roi;
                        a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                        vertices =[a,b;a+c,b;a+c,b+d;a,b+d;];
                        BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                      elseif(ROIshape_ind==2)
                          vertices = separate_rois.(ROInames{k}).roi;
                          BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                      elseif(ROIshape_ind==3)
                          data2 = separate_rois.(ROInames{k}).roi;
                          a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                          s1=size(image,1);s2=size(image,2);
                          for m=1:s1
                              for n=1:s2
                                    dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                    if(dist<=1.00)
                                        BW(m,n)=logical(1);
                                    else
                                        BW(m,n)=logical(0);
                                    end
                              end
                          end
                      elseif(ROIshape_ind==4)
                          vertices = separate_rois.(ROInames{k}).roi;
                          BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                       end
                    else
                        
                        error('Combined ROIs can not be processed for now') 
                    end
                       
                       image_copy2 = IMG.*uint8(BW);%figure;imshow(image_temp);
                       if stackflag == 1
                          filename_temp = fullfile(pathName,'ROI\ROI_management\ctFIRE_on_ROIbatch_post\',[fileNameNE,sprintf('_s%d_',j),ROInames{k},'.tif']);
                        else
                         filename_temp=[pathName 'ROI\ROI_management\ctFIRE_on_ROIbatch_post\' fileNameNE '_' ROInames{k} '.tif'];
                       end
   
                       imwrite(image_copy2,filename_temp);
                       imgpath=[pathName 'ROI\ROI_management\ctFIRE_on_ROIbatch_post\'];
                       if stackflag == 1
                           imgname=[fileNameNE sprintf('_s%d_',j) ROInames{k} '.tif'];
                       else
                           imgname=[fileNameNE '_' ROInames{k} '.tif'];
                       end
                       savepath=[pathName 'ROI\ROI_management\ctFIRE_on_ROIbatch_post\ctFIREout\'];
                       display(savepath);%pause(5);
                       
                %% find the fibers in each ROIs and output fiber properties csv file of each ROI
  
%                        ctFIRE_1p(imgpath,imgname,savepath,cP,ctfP,1);%error here - error resolved - making cP.plotflagof=0 nad cP.plotflagnof=0
                      roiP.BW = BW; 
                      roiP.fibersource = 1;  % 1: use original fiber extraction output; 2: use selectedOUT out put 
                      roiP.fibermode = 1;    % 1: fibermode, check the fiber middle point 2: check the hold fiber  
                      roiP.ROIname = ROInames{k};
                      
                      ctFIRE_1_ROIpost(pathName,fileName{i},ctfmatname,imgpath,imgname,savepath,roiP);                      
                
 %%         
                       [~,imagenameNE] = fileparts(imgname);
                       histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls angle histogram values
                       histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls length histgram values
                       histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls straightness histogram values
                       histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls width histgram values
                       ROIangle = nan; ROIlength = nan; ROIstraight = nan; ROIwidth = nan;
                       if exist(histA2,'file')
                           ROIangle = mean(importdata(histA2));
                           ROIlength = mean(importdata(histL2));
                           ROIstraight = mean(importdata(histSTR2));
                           ROIwidth = mean(importdata(histWID2));
                       end
                       xc = separate_rois.(ROInames{k}).ym; yc = separate_rois.(ROInames{k}).xm; zc = j;
                       
                       items_number_current = items_number_current+1;
                       CTF_data_add = {items_number_current,sprintf('%s',fileNameNE),sprintf('%s',ROInames{k}),ROIshapes{ROIshape_ind},xc,yc,zc,ROIwidth,ROIlength, ROIstraight,ROIangle};
                       CTF_data_current = [CTF_data_current;CTF_data_add];
                       set(CTF_output_table,'Data',CTF_data_current)
                       set(CTF_table_fig,'Visible','on')
                       
                       
                end % ROIs
            end  % slices  if stack 
        end  % files
     
        
        % save CTFroi results:
        
        if ~isempty(CTF_data_current)
            %YL: may need to delete the existing files
            save(fullfile(pathName,'ROI','ROI_management','lastPOST_ROIsCTF.mat'),'CTF_data_current','separate_rois') ;
            if exist(fullfile(pathName,'ROI','ROI_management','lastPOST_ROIsCTF.xlsx'),'file')
                delete(fullfile(pathName,'ROI','ROI_management','lastPOST_ROIsCTF.xlsx'));
            end
            xlswrite(fullfile(pathName,'ROI','ROI_management','lastPOST_ROIsCTF.xlsx'),[columnname;CTF_data_current],'CT-FIRE ROI analysis') ;
        end
        
        disp('Done!')
        set(infoLabel,'String','Done with the CT-FIRE ROI analysis.')
        
        
        return
    end
%--------------------------------------------------------------------------    
        %% YL use fullfile to avoid this difference, do corresponding change in ctFIRE_1 
         dirout = fullfile(pathName,'ctFIREout');
        if ~exist(dirout,'dir')
            mkdir(dirout);
    
        end
        disp(sprintf('dirout= %s',dirout))
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
            disp('Switch to ROI analysis module')
            CTFroi(ROIctfp);    %
            
            return
            
        end
    %% batch-mode ROI analysis without previous fiber extraction on the whole image    
    if RO == 5
        
        
        ROIanaChoice = questdlg('Run CT-FIRE on the cropped ROI of rectgular shape or the ROI mask of any shape?', ...
            'CT-FIRE on ROI','Cropped rectangular ROI','ROI mask of any shape','Cropped rectangular ROI');
        if isempty(ROIanaChoice)
            
            error('please choose the shape of the ROI to be analyzed')
            
        end
        switch ROIanaChoice
            case 'Cropped rectangular ROI'
                cropIMGon = 1;
                disp('Run CT-FIRE on the the cropped rectangular ROIs, not applicable to the combined ROI')
                disp('loading ROI')
                
            case 'ROI mask of any shape'
                cropIMGon = 0;
                disp('Run CT-FIRE on the the ROI mask of any shape,not applicable to the combined ROI');
                disp('loading ROI')
                                
        end
        
        cP.stack = 0;  % during the analysis, convert stack into into individual ROI images
        cP.RO = 1;     % change to CTFIEE fiber extraction mode  
        CTF_data_current = [];
        
        roimatDir = fullfile(pathName,'ROI\ROI_management\');
        
        k = 0;
        for i = 1:length(fileName)
            [~,fileNameNE,fileEXT] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            if exist(fullfile(roimatDir,roiMATnamefull),'file')
                k = k + 1; disp(sprintf('Found ROI for %s',fileName{i}))
            else
                disp(sprintf('ROI for %s not exist',fileName{i}));
            end
            
            
        end
        
        if k ~= length(fileName)
            error(sprintf('Missing %d ROI files',length(fileName) - k))
        end
        
        roiIMGDir = fullfile(pathName,'ROI','ROI_management','ctFIRE_on_ROIbatch');
        roioutDir = fullfile(pathName,'ROI','ROI_management','ctFIRE_on_ROIbatch','ctFIREout');
   
        if(exist(roioutDir,'dir')==0)%check for ROI folder
            mkdir(roioutDir);
        end
        
        items_number_current = 0;
        for i = 1:length(fileName)
            [~,fileNameNE,fileEXT] = fileparts(fileName{i}) ;
            roiMATnamefull = [fileNameNE,'_ROIs.mat'];
            try
                load(fullfile(roimatDir,roiMATnamefull),'separate_rois')
            catch
                display('ROIs not present for one of the images');return;
            end
            ROInames = fieldnames(separate_rois);
            s_roi_num = length(ROInames);
          
            IMGname = fullfile(pathName,fileName{i});
            IMGinfo = imfinfo(IMGname);
            numSections = numel(IMGinfo); % number of sections, default: 1;
            if numSections > 1, stackflag =1; end;
            for j = 1:numSections
                
                if numSections == 1
                    IMG = imread(IMGname);
                    
                else
                    IMG = imread(IMGname,j);
                    
                end
                
                if size(IMG,3) > 1
                    %if rgb, pick one color
                    IMG = IMG(:,:,1);
                end
                
                    for k=1:s_roi_num
                        combined_rois_present=0;
                        ROIshape_ind = separate_rois.(ROInames{k}).shape;

                        if(combined_rois_present==0)
                            % when combination of ROIs is not present
                            %finding the mask -starts
                            % add the option of rectangular ROI
                            if cropIMGon == 0     % use ROI mask
                                if(ROIshape_ind==1)
                                    data2 = separate_rois.(ROInames{k}).roi;
                                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                    vertices =[a,b;a+c,b;a+c,b+d;a,b+d;];
                                    BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                                elseif(ROIshape_ind==2)
                                    vertices = separate_rois.(ROInames{k}).roi;
                                    BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                                elseif(ROIshape_ind==3)
                                    data2 = separate_rois.(ROInames{k}).roi;
                                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                    s1=size(image,1);s2=size(image,2);
                                    for m=1:s1
                                        for n=1:s2
                                            dist=(n-(a+c/2))^2/(c/2)^2+(m-(b+d/2))^2/(d/2)^2;
                                            if(dist<=1.00)
                                                BW(m,n)=logical(1);
                                            else
                                                BW(m,n)=logical(0);
                                            end
                                        end
                                    end
                                elseif(ROIshape_ind==4)
                                    vertices = separate_rois.(ROInames{k}).roi;
                                    BW=roipoly(IMG,vertices(:,1),vertices(:,2));
                                end

                            elseif cropIMGon == 1

                                if ROIshape_ind == 1   % use cropped ROI image
                                    data2 = separate_rois.(ROInames{k}).roi;
                                    a=data2(1);b=data2(2);c=data2(3);d=data2(4);
                                    ROIimg = IMG(b:b+d-1,a:a+c-1); % YL to be confirmed
                                    xc = round(a+c-1/2); yc = round(b+d-1/2); z = j;
                                else
                                    error('cropped image ROI analysis for shapes other than rectangle is not availabe so far')

                                end
                            end

                        else

                            error('Combined ROIs can not be processed for now')
                        end


                        if cropIMGon == 0
                            image_copy2 = IMG.*uint8(BW);%figure;imshow(image_temp)
                        elseif cropIMGon == 1
                            image_copy2 = ROIimg;
                        end
                        
                       if stackflag == 1
                          filename_temp = fullfile(roiIMGDir,[fileNameNE,sprintf('_s%d_',j),ROInames{k},'.tif']);
                        else
                         filename_temp = fullfile(roiIMGDir,[fileNameNE '_' ROInames{k} '.tif']);
                       end
   
                       imwrite(image_copy2,filename_temp);
                       imgpath = roiIMGDir;
                       if stackflag == 1
                           imgname=[fileNameNE sprintf('_s%d_',j) ROInames{k} '.tif'];
                       else
                           imgname=[fileNameNE '_' ROInames{k} '.tif'];
                       end
                       savepath = roioutDir;
                       ctFIRE_1(imgpath,imgname,savepath,cP,ctfP); % us ctFIRE_1 instead of ctFIRE_1p so far
                       [~,imagenameNE] = fileparts(imgname);
                       histA2 = fullfile(savepath,sprintf('HistANG_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls angle histogram values
                       histL2 = fullfile(savepath,sprintf('HistLEN_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls length histgram values
                       histSTR2 = fullfile(savepath,sprintf('HistSTR_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls straightness histogram values
                       histWID2 = fullfile(savepath,sprintf('HistWID_ctFIRE_%s.csv',imagenameNE));      % ctFIRE output:xls width histgram values
                       ROIangle = nan; ROIlength = nan; ROIstraight = nan; ROIwidth = nan;
                       if exist(histA2,'file')
                           ROIangle = mean(importdata(histA2));
                           ROIlength = mean(importdata(histL2));
                           ROIstraight = mean(importdata(histSTR2));
                           ROIwidth = mean(importdata(histWID2));
                       end
                       xc = separate_rois.(ROInames{k}).ym; yc = separate_rois.(ROInames{k}).xm; zc = j;
                       
                       items_number_current = items_number_current+1;
                       CTF_data_add = {items_number_current,sprintf('%s',fileNameNE),sprintf('%s',ROInames{k}),ROIshapes{ROIshape_ind},xc,yc,zc,ROIwidth,ROIlength, ROIstraight,ROIangle};
                       CTF_data_current = [CTF_data_current;CTF_data_add];
                       set(CTF_output_table,'Data',CTF_data_current)
                       set(CTF_table_fig,'Visible','on')
                       
                       
                end %k: ROIs
            end  %j: slices  if stack 
        end  %i: files
                    
                    
%                     items_number_current = items_number_current+1;
%                     ROIshape_ind = separate_rois.(ROInames{k}).shape;
%                     if(ROIshape_ind==1)
%                         ROIcoords=separate_rois.(ROInames{k}).roi;
%                         a=ROIcoords(1);b=ROIcoords(2);c=ROIcoords(3);d=ROIcoords(4);
%                         %                         vertices(:,:)=[a,b;a+c,b;a+c,b+d;a,b+d;];
%                         %                         BW=roipoly(image_copy,vertices(:,1),vertices(:,2));
%                         %                         ROIimg = image_copy(a:a+c-1,b:b+d-1);
%                         ROIimg = IMG(b:b+d-1,a:a+c-1); % YL to be confirmed
%                         roiNamelist = ROInames{k};  % roi name on the list
%                         if numSections > 1
%                             roiNamefull = [fileName{i},sprintf('_s%d_',i),roiNamelist,'.tif'];
%                         elseif numSections == 1
%                             roiNamefull = [fileName{i},'_',roiNamelist,'.tif'];
%                         end
%                         imwrite(ROIimg,fullfile(roiIMGDir,roiNamefull));
%                         %                    CA_P.makeMapFlag =1; CA_P.makeOverFlag = 1;
%                         [~,stats] = processROI(ROIimg, roiNamefull, roioutDir, keep, coords, distThresh, makeAssocFlag, makeMapFlag, makeOverFlag, makeFeatFlag, 1,infoLabel, bndryMode, bdryImg, roiIMGDir, fibMode, 0,1);
%                         xc = round(a+c-1/2); yc = round(b+d-1/2);
%                         if numSections > 1
%                             z = j;
%                         else
%                             z = 1;
%                         end
%                         
%                         CAroi_data_add = {items_number_current,sprintf('%s',fileNameNE),sprintf('%s',roiNamelist),ROIshapes{ROIshape_ind},xc,yc,z,stats(1),stats(5)};
%                         CAroi_data_current = [CAroi_data_current;CAroi_data_add];
%                         
%                         set(CAroi_output_table,'Data',CAroi_data_current)
%                         set(CAroi_table_fig,'Visible', 'on'); figure(CAroi_table_fig)
   
        
        
        % save CTFroi results:
        
        if ~isempty(CTF_data_current)
            %YL: may need to delete the existing files
            save(fullfile(pathName,'ROI','ROI_management','last_ROIsCTF.mat'),'CTF_data_current','separate_rois') ;
            if exist(fullfile(pathName,'ROI','ROI_management','last_ROIsCTF.xlsx'),'file')
                delete(fullfile(pathName,'ROI','ROI_management','last_ROIsCTF.xlsx'));
            end
            xlswrite(fullfile(pathName,'ROI','ROI_management','last_ROIsCTF.xlsx'),[columnname;CTF_data_current],'CT-FIRE ROI analysis') ;
        end
        
        disp('Done!')
        set(infoLabel,'String','Done with the CT-FIRE ROI analysis.')
        
        
        return
    end
        
       % profile on
%         macos = 0;    % 0: for Windows operating system; others: for Mac OS
        imgPath = getappdata(imgOpen,'imgPath');
 
        if openimg
            imgPath = getappdata(imgOpen,'imgPath');
            imgName = getappdata(imgOpen, 'imgName');
            if openstack == 1
                set([sru1 sru2 sru3 sru4 sru5],'Enable','off');
                set(stackSlide,'Enable','off');
                cP.stack = openstack;
                sslice = getappdata(imgOpen,'totslice'); % selected slices
                disp(sprintf('process an image stack with %d slices',sslice));
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
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
                            set(infoLabel,'String','Analysis is ongoing ...');
                            cP.widcon = widcon;
                            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                            soutf(:,:,iss) = OUTf;
                            OUTctf(:,:,iss) = OUTctf;
                        end
                        
                        set(infoLabel,'String','Analysis is done');
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
                            
                            set(infoLabel,'String','Analysis is ongoing ...');
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
     
                        parstar = tic;
                        parfor iss = 1:sslice
                            
                            ctFIRE_1p(imgPath,imgName,dirout,cP,ctfP,iss)
                            
                        end
                        parend = toc(parstar);
                        disp(sprintf('%d slices of a single stack were processed, taking %3.2f minutes',sslice,parend/60));
                        set(infoLabel,'String','Analysis is done');
                    else
                        srstart = getappdata(hsr,'srstart');
                        srend = getappdata(hsr,'srend');
                        cP.sselected = srend - srstart + 1;      % slices selected
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
                disp('process an image')
                
                setappdata(imgRun,'controlpanel',cP);
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                set(infoLabel,'String','Analysis is ongoing ...');
                cP.widcon = widcon;
% YL:why need this?  bug also              
                % preventing drawing on guiFig
%                 figure(guiCtrl);
%                 change_state('off');
                figure(guiFig);%open some figure
                [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
%                 figure(guiCtrl);
%                 change_state('on');
                
                set(postprocess,'Enable','on');
                set([batchModeChk matModeChk selModeChk],'Enable','on');
%                 set(infoLabel,'String','Fiber extration is done, confirm or change parameters for post-processing ');
                
            end
            
            set(infoLabel,'String','Analysis is done'); 
    
            
        else  % process multiple files
            
            if openmat ~= 1
                set([makeRecon makeNONRecon makeHVang makeHVlen makeHVstr makeHVwid setFIRE_load, setFIRE_update enterLL1 enterLW1 enterWID enterRES enterBIN BINauto],'Enable','off');
                %                 set([imgOpen postprocess],'Enable','off');
                %                 set(guiFig,'Visible','on');
                set(infoLabel,'String','Load and/or update parameters');
                imgPath = getappdata(imgOpen,'imgPath');
                multiimg = getappdata(imgOpen,'imgName');
                filelist = cell2struct(multiimg,'name',1);
                %                 filelist = dir(imgPath);
                %                 filelist(1:2) = [];% get rid of the first two files named '.','..'
                fnum = length(filelist);
                
               % YL 2014-01-16: add image stack analysis, only consider
                % multiple files are all images or all stacks
                ff = [imgPath, filelist(1).name];
                info = imfinfo(ff);
                numSections = numel(info);
                
                if numSections == 1   % process multiple images
                  if prlflag == 0 
%                         imgName = filelist(fn).name;
%                         
%                         disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
%                             imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
%                         set(infoLabel,'String','Analysis is ongoing ...');
                        cP.widcon = widcon;
                     tstart = tic; 
                    for fn = 1:fnum
                      
                        ctFIRE_1(imgPath,filelist(fn).name,dirout,cP,ctfP);
                        
                    end
                    seqfortime = toc(tstart);  % sequestial processing time
                    disp(sprintf('Sequential processing for %d images takes %4.2f seconds',fnum,seqfortime)) 
                    
                    set(infoLabel,'String','Analysis is done');
                    
                  elseif prlflag == 1
                        
                        cP.widcon = widcon;
                        tstart = tic;
                        parfor fn = 1:fnum
                      
                        ctFIRE_1p(imgPath,filelist(fn).name,dirout,cP,ctfP);
                        
                        end
                        parfortime = toc(tstart); % parallel processing time
                        disp(sprintf('Parallel processing for %d images takes %4.2f seconds',fnum,parfortime)) 
                        set(infoLabel,'String','Analysis is done');
                         
                        
                  end
                elseif  numSections > 1% process multiple stacks

                if prlflag == 0
%                       cP.ws == 1; % process whole stack
                    cP.stack = 1;
                    for ms = 1:fnum   % loop through all the stacks
                        imgName = filelist(ms).name;
                        ff = [imgPath, imgName];
                        info = imfinfo(ff);
                        numSections = numel(info);
                        sslice = numSections;
                        cP.sselected = sslice;      % slices selected
                        
                        for iss = 1:sslice
                            img = imread([imgPath imgName],iss);
                            figure(guiFig);
%                             img = imadjust(img);  % YL: only display original image
                            imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                            %                     imshow(img,'Parent',imgAx);
                            
                            cP.slice = iss;
                            set(infoLabel,'String','Analysis is ongoing ...');
                            cP.widcon = widcon;
                            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                            soutf(:,:,iss) = OUTf;
                            OUTctf(:,:,iss) = OUTctf;
                        end
                    end
                    
                    
                elseif prlflag == 1  % parallel computing for multiple stacks
                      cP.stack = 1;
                                         
                    ks = 0
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
                        set(infoLabel,'String','Parallel fiber extraction for multiple stacks is ongoing ...');
                         cP.widcon = widcon;
                         parstar = tic;
                        parfor iks = 1:ks   % loop through all the slices of all the stacks
                                 
                            ctFIRE_1p(imgPath,imgNameALL{iks},dirout,cP,ctfP,slicenumber(iks));
                           
                        end
                        parend = toc(parstar);
                        disp(sprintf('%d slices from %d stacks were processed, taking %3.2f minutes',ks, fnum,parend/60));
                    
                end

                end
                set(infoLabel,'String','Analysis is done');
                
                
            else
                
                
                %% shouldn't re-process the image
                %                 matPath = getappdata(imgOpen,'matPath');
                %                 filelist = dir(matPath);
                %                 filelist(1:2) = [];% get rid of the first two files named '.','..'
                %                 fnum = length(filelist);
                %                 for fn = 1:fnum
                %                     matName = filelist(fn).name;
                %                     load([matpath,matname],'imgName','imgPath','ctfP','cP','savePath']
                %                     disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                %                         imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                %                     ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                
            end
            
            
        end
        
        %         set(infoLabel,'String','Analysis is done');
        set(postprocess,'Enable','on');
        
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
                disp('Saving parameters ...');
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
               
                disp(sprintf('Parameters are saved at %s',dirout));
            end
        end
        
%         %         %% reset ctFIRE after process multple images or image stack
%         if openstack == 1
%             
%             disp('Stack analysis is done, ctFIRE is reset')
%             ctFIRE
%         elseif openimg ~= 1 && openmat ~=1
%             disp(' batch-mode image analysis is done, ctFIRE is reset');
%             
%             ctFIRE
%             
%         end
    
      % profile off
%         profile resume
%         profile clear
%         profile viewer
%         S = profile('status')
%         stats = profile('info')
%         save('profile_ctfire.mat','S', 'stats');
        set([imgOpen],'Enable','on')
        set([imgRun],'Enable','off')
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

% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
%         fig = findall(0,'type','figure)
        ctFIRE
    end
    
     function selRo_fn(object,handles)
         set(imgRun,'Enable','on');
     end




end
