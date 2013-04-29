function ctFIRE

% ctFIRE.m
% This is the GUI associated with an approach of integrating curvelet transform(curvelet.org,2004) and a fiber extraction algorithm(FIRE,A. M. Stein, 2008 Journal of Microscopy).
% To deploy this:
% (1)copy matlab file(.m and .mat) in folder ctFIRE to the folder../FIRE/
% (2)change directory to where the ctFIRE.m is.
% (3) type mcc -m ctFIRE.m -a ../CurveLab-2.1.2/fdct_wrapping_matlab -a ../FIRE -R '-startmsg,"Starting_Curvelet_transform_plus_FIRE"' at
% at the matlab command prompt

% Main developers: Yuming Liu, Jeremy Bredfeldt
%Laboratory for Optical and Computational Instrumentation
%University of Wisconsin-Madison
%Since January, 2013

home; clear all;close all;
if (~isdeployed)
    addpath('../CurveLab-2.1.2/fdct_wrapping_matlab');
    addpath(genpath(fullfile('../FIRE')));
end

% global imgName
guiCtrl = figure('Resize','on','Units','pixels','Position',[25 75 300 650],'Visible','off',...
    'MenuBar','none','name','ctFIRE Control','NumberTitle','off','UserData',0);
guiFig = figure('Resize','on','Units','pixels','Position',[340 125 600 600],'Visible','off',...
    'MenuBar','none','name','Original Image','NumberTitle','off','UserData',0);
guiRecon = figure('Resize','on','Units','pixels','Position',[340 415 300 300],'Visible','off',...
    'MenuBar','none','name','CurveAlign Reconstruction','NumberTitle','off','UserData',0);

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiFig,'Color',defaultBackground);
set(guiRecon,'Color',defaultBackground);

set(guiCtrl,'Visible','on');

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);


% button to select an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Import image/data',...
    'FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[0 .88 .50 .08],...
    'callback','ClickedCallback','Callback', {@getFile});

% button to process an output mat file of ctFIRE
postprocess = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Post-processing',...
    'FontUnits','normalized','FontSize',.25,'UserData',[],'Units','normalized','Position',[.5 .88 .50 .08],...
    'callback','ClickedCallback','Callback', {@postP});

% button to set (fiber extraction)FIRE parameters
setFIRE = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Set parameters',...
    'FontUnits','normalized','FontSize',.285,'Units','normalized','Position',[0 .80 .50 .08],...
    'Callback', {@setpFIRE});


% button to run measurement
imgRun = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run',...
    'FontUnits','normalized','FontSize',.285,'Units','normalized','Position',[0.5 .80 .20 .08],...
    'Callback',{@runMeasure});
% select run options
selRO = uicontrol('Parent',guiCtrl,'Style','popupmenu','String',{'ctFIRE'; 'FIRE';'CTF&FIRE'},...
    'FontUnits','normalized','FontSize',.0725,'Units','normalized','Position',[0.70 .515 .30 .35],...
    'Value',1);

% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',1.0,'Units','normalized','Position',[.75 .975 .25 .025],'callback','ClickedCallback','Callback',{@resetImg});

% Checkbox to load .mat file for post-processing
matModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','.Mat','Min',0,'Max',3,'Units','normalized','Position',[.35 .975 .30 .025]);

%checkbox for batch mode option
batchModeChk = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Batch-mode','Min',0,'Max',3,'Units','normalized','Position',[.0 .975 .30 .025]);

% panel to contain output figure control
guiPanel1 = uipanel('Parent',guiCtrl,'Title','Output Figure Control: ','Units','normalized','FontSize',9,'Position',[0 0.40 1 .215]);

% text box for taking in figure control

LL1label = uicontrol('Parent',guiPanel1,'Style','text','String','Minimum fiber lengh: ','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.1 0.7 .75 .15]);
enterLL1 = uicontrol('Parent',guiPanel1,'Style','edit','String','30','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.80 0.75 .15 .15],'Callback',{@get_textbox_data1});

FNLlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Maximum fiber number:','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.1 .55 .75 .15]);
enterFNL = uicontrol('Parent',guiPanel1,'Style','edit','String','2999','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[0.80 .55 .15 .15],'Callback',{@get_textbox_data2});

LW1label = uicontrol('Parent',guiPanel1,'Style','text','String','Fiber line width:','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.1 .35 .75 .15]);
enterLW1 = uicontrol('Parent',guiPanel1,'Style','edit','String','0.5','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.80 .35 .15 .15],'Callback',{@get_textbox_data3});

BINlabel = uicontrol('Parent',guiPanel1,'Style','text','String','Histogram bins number:','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[0.1 .15 .75 .15]);
enterBIN = uicontrol('Parent',guiPanel1,'Style','edit','String','10','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.80 .15 .15 .15],'Callback',{@get_textbox_data4});

% panel to contain output checkboxes
guiPanel2 = uipanel('Parent',guiCtrl,'Title','Select Output: ','Units','normalized','Position',[0 .2 1 .225]);

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Overlaying and Reconstructed Image','Min',0,'Max',3,'Units','normalized','Position',[.075 .8 .8 .1]);

% checkbox to display a angle histogram
makeHistA = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Angle histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .65 .8 .1]);

% checkbox to display a length histogram
makeHistL = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Length histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .5 .8 .1]);

% checkbox to output list of values
makeValuesA = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Angle values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .35 .8 .1]);

% checkbox to save length value
makeValuesL = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Length values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .2 .8 .1]);

% Create the button group.

% Initialize some button group properties.
% set(h,'SelectionChangeFcn',@selcbk);
% set(h,'SelectedObject',[]);  % No selection
% set(h,'Visible','on');

% listbox containing names of active files
%listLab = uicontrol('Parent',guiCtrl,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[0 .6 1 .1]);
%imgList = uicontrol('Parent',guiCtrl,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[0 .425 1 .25]);
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
        % disp(hsr);
        % disp([eventdata.EventName,'  ',...
        %      get(eventdata.OldValue,'String'),'  ', ...
        %      get(eventdata.NewValue,'String')]);
        % disp(get(get(hsr,'SelectedObject'),'String'));
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
        
        % if eventdata.ld
    end


infoLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Import Image or data.','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .05 .75 .1]);

% set font
set([guiPanel2 LL1label LW1label FNLlabel infoLabel enterLL1 enterLW1 enterFNL ...
    makeHistL makeValuesA makeRecon  makeHistA makeValuesL imgOpen ...
    setFIRE imgRun imgReset selRO postprocess slideLab],'FontName','FixedWidth')
set([LL1label LW1label FNLlabel BINlabel],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset postprocess],'FontWeight','bold')
set([LL1label LW1label FNLlabel BINlabel slideLab infoLabel],'HorizontalAlignment','left')

%initialize gui
set([postprocess setFIRE imgRun selRO makeHistA makeRecon enterLL1 enterLW1 enterFNL enterBIN ,...
    makeValuesA makeHistL makeValuesL],'Enable','off')
set([sru1 sru2 sru3 sru4 sru5],'Enable','off')
set([makeRecon],'Value',3)
set([makeHistA makeHistL makeValuesA makeValuesL],'Value',0)

% % initialize variables used in some callback functions
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
        
        
        if (get(batchModeChk,'Value') ~= get(batchModeChk,'Max')); openimg =1; else openimg =0;end
        if (get(matModeChk,'Value') ~= get(matModeChk,'Max')); openmat =0; else openmat =1;end
        
        setappdata(imgOpen, 'openImg',openimg);
        setappdata(imgOpen, 'openMat',openmat);
        
        if openimg ==1
            
            if openmat ~= 1
                
                [imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select an Image','MultiSelect','off');
                if imgName == 0
                    disp('Please choose the correct image/data to start an analysis.');
                else
                    
                    %             filePath = fullfile(pathName,fileName);
                    %set(imgList,'Callback',{@showImg})
                    set([makeRecon makeHistA makeHistL makeValuesA makeValuesL setFIRE selRO enterLL1 enterLW1 enterFNL enterBIN],'Enable','on');
                    set([imgOpen postprocess],'Enable','off');
                    set(guiFig,'Visible','on');
                    set(infoLabel,'String','Select parameters to run');
                    
                    ff = [imgPath, imgName];
                    info = imfinfo(ff);
                    numSections = numel(info)%;
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
                    img = imadjust(img);
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
                    
                    set([LL1label LW1label FNLlabel BINlabel],'ForegroundColor',[0 0 0])
                    set(guiFig,'UserData',0)
                    
                    if ~get(guiFig,'UserData')
                        set(guiFig,'WindowKeyPressFcn',@startPoint)
                        coords = [-1000 -1000];
                        aa = 1;
                    end
                    
                    if numSections > 1
                        %initialize gui
                        
                        set([makeRecon makeHistA makeHistL makeValuesA makeValuesL setFIRE enterLL1 enterLW1 enterFNL enterBIN],'Enable','on');
                        set([imgOpen postprocess],'Enable','off');
                        set(guiFig,'Visible','on');
                        set(infoLabel,'String','Select parameters to do fiber extraction');
                        
                    end
                    
                end
                
            else
                [matName matPath] = uigetfile({'*FIREout*.mat'},'Select .Mat file(s)','MultiSelect','off');
                if matName == 0
                    disp('Please choose the correct image/data to start an analysis.');
                else
                    matfile = [matPath, '\',matName];
                    load(matfile,'imgName','imgPath','savePath','cP','ctfP')
                    
                    ff = [imgPath, imgName];
                    if cP.stack == 1
                        img = imread(ff,cP.slice);
                    else
                        img = imread(ff);
                    end
                    if size(img,3) > 1 %if rgb, pick one color
                        img = img(:,:,1);
                    end
                    figure(guiFig);
                    img = imadjust(img);
                    imshow(img,'Parent',imgAx);
                    
                    setappdata(imgRun,'outfolder',savePath);
                    setappdata(imgRun,'ctfparam',ctfP);
                    setappdata(imgRun,'controlpanel',cP);
                    setappdata(imgOpen,'matPath',matPath);
                    
                    
                    set([makeRecon makeHistA makeHistL makeValuesA makeValuesL enterLL1 enterLW1 ...
                        enterFNL enterBIN postprocess],'Enable','on');
                    set([imgOpen imgRun setFIRE],'Enable','off');
                    set(infoLabel,'String','Select parameters to do post-processing');
                    
                    
                    setappdata(imgOpen,'imgPath',imgPath);
                    setappdata(imgOpen, 'imgName',imgName);
                end
                %
            end
            %             set(guiFig,'Visible','on');
            
        else   % open multi-files
            if openmat ~= 1
                [imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','on');
                           
                if ~iscell(imgName)
                    error('Please select at least two files to do batch process')
                    
                else
                    setappdata(imgOpen,'imgPath',imgPath);
                    setappdata(imgOpen,'imgName',imgName);
                    set([makeRecon makeHistA makeHistL makeValuesA makeValuesL setFIRE selRO enterLL1 enterLW1 enterFNL enterBIN],'Enable','on');
                    set([imgOpen postprocess],'Enable','off');
                    %                 set(guiFig,'Visible','on');
                    set(infoLabel,'String','Select parameters to run');
                end
                
            else
                %                 matPath = [uigetdir([],'choosing mat file folder'),'\'];
               
                [matName matPath] = uigetfile({'*FIREout*.mat';'*.*'},'Select multi .mat files','MultiSelect','on');
                if ~iscell(matName)
                    error('Please select at least two mat files to do batch process')
                 else
                    
                    setappdata(imgOpen,'matName',matName);
                    setappdata(imgOpen,'matPath',matPath);
                    set([makeRecon makeHistA makeHistL makeValuesA makeValuesL enterLL1 enterLW1 enterFNL enterBIN],'Enable','on');
                    
                    set([postprocess],'Enable','on');
                    set([imgOpen],'Enable','off');
                    
                    set(infoLabel,'String','Select parameters to do post-processing ');
                    
                end
            end
            
            
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
        set(slideLab,'String',['Stack image preview, slice: ' num2str(idx)]);
        
    end

%--------------------------------------------------------------------------
% callback function for enterLL1 text box
    function get_textbox_data1(enterLL1,eventdata)
        usr_input = get(enterLL1,'String');
        usr_input = str2double(usr_input);
        set(enterLL1,'UserData',usr_input)
    end


% callback function for enterLW1 text box
    function get_textbox_data3(enterLW1,eventdata)
        usr_input = get(enterLW1,'String');
        usr_input = str2double(usr_input);
        set(enterLW1,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% callback function for enterFNL text box
    function get_textbox_data2(enterFNL,eventdata)
        usr_input = get(enterFNL,'String');
        usr_input = str2double(usr_input);
        set(enterFNL,'UserData',usr_input)
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
                
                load(matfile,'imgName','imgPath','savePath','cP','ctfP')
                dirout = savePath;
                
                ff = [imgPath, imgName];
                if cP.stack == 1
                    img = imread(ff,cP.slice);
                else
                    img = imread(ff);
                end
                
                if size(img,3) > 1 %if rgb, pick one color
                    img = img(:,:,1);
                end
                figure(guiFig);
                img = imadjust(img);
                imshow(img,'Parent',imgAx);
                
                
                cP.postp = 1;
                LW1 = get(enterLW1,'UserData');
                LL1 = get(enterLL1,'UserData');
                FNL = get(enterFNL,'UserData');
                BINs = get(enterBIN,'UserData');
                
                
                if isempty(LW1), LW1 = 0.5; end
                if isempty(LL1), LL1 = 30;  end
                if isempty(FNL), FNL = 2999; end
                if isempty(BINs),BINs = 10; end
                
                cP.LW1 = LW1;
                cP.LL1 = LL1;
                cP.FNL = FNL;
                cP.BINs = BINs;
                
                if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
                if (get(makeHistA,'Value') ~= get(makeHistA,'Max')); cP.angH =0; else cP.angH = 1;end
                if (get(makeHistL,'Value') ~= get(makeHistL,'Max')); cP.lenH =0; else cP.lenH = 1;end
                if (get(makeValuesA,'Value') ~= get(makeValuesA,'Max')); cP.angV =0; else cP.angV =1; end
                if (get(makeValuesL,'Value') ~= get(makeValuesL,'Max')); cP.lenV =0; else cP.lenV =1;end
                
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                
                ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                
            end
            
        else
            
            dirout = getappdata(imgRun,'outfolder');
            
            ctfP = getappdata(imgRun,'ctfparam');
            cP = getappdata(imgRun,'controlpanel');
            cP.postp = 1;
            
            LW1 = get(enterLW1,'UserData');
            LL1 = get(enterLL1,'UserData');
            FNL = get(enterFNL,'UserData');
            BINs = get(enterBIN,'UserData');
            
            
            if isempty(LW1), LW1 = 0.5; end
            if isempty(LL1), LL1 = 30;  end
            if isempty(FNL), FNL = 2999; end
            if isempty(BINs),BINs = 10; end
            
            cP.LW1 = LW1;
            cP.LL1 = LL1;
            cP.FNL = FNL;
            cP.BINs = BINs;
            
            if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
            if (get(makeHistA,'Value') ~= get(makeHistA,'Max')); cP.angH =0; else cP.angH = 1;end
            if (get(makeHistL,'Value') ~= get(makeHistL,'Max')); cP.lenH =0; else cP.lenH = 1;end
            if (get(makeValuesA,'Value') ~= get(makeValuesA,'Max')); cP.angV =0; else cP.angV =1; end
            if (get(makeValuesL,'Value') ~= get(makeValuesL,'Max')); cP.lenV =0; else cP.lenV =1;end
            
            
            imgPath = getappdata(imgOpen,'imgPath');
            imgName = getappdata(imgOpen, 'imgName');
            [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
            
            
        end
        
    end
%--------------------------------------------------------------------------
% callback function for FIRE params button
    function setpFIRE(setFIRE,eventdata)
        
        %    setFIREp
        
        pdf = load('FIREpdefault.mat'); %'pvalue' 'pdesc' 'pnum' 'tcnum'
        
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
                tcvalue = extractfield(pvalue,fieldtc);
                pvalue = setfield(pvalue,fieldtc,num2str(tcvalue));
            else
                %              disp(sprintf('parameter # %d [%s],is string type',itc, pfnames{itc}));
                
            end
        end
        
        name='Update FIRE parameters';
        prompt= pfnames';
        numlines=1;
        datemp = struct2cell(pvalue)';
        defaultanswer= datemp;
        updatepnum = [5 7 10 14 15 18];
        promptud = prompt(updatepnum);
        defaultud=defaultanswer(updatepnum);
        %     FIREp = inputdlg(prompt,name,numlines,defaultanswer);
        
        FIREpud = inputdlg(promptud,name,numlines,defaultud);
        
        if length(FIREpud)>0
            
            for iud = updatepnum
                
                pvalue = setfield(pvalue,pfnames{iud},FIREpud{find(updatepnum ==iud)});
                
            end
            disp('FIRE parameters are updated')
            fpupdate = 1;
            
        else
            disp('FIRE parameters are default values')
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
        setappdata(setFIRE,'FIREp',fp);
        
        RO = get(selRO,'Value')
        if RO == 1 || RO == 3      % ctFIRE need to set pct and SS
            
            name='set ctFIRE parameters';
            prompt={'Percentile of the remaining curvelet coeffs',...
                'Number of selected scales'};
            numlines=1;
            defaultanswer={'0.2','3'};
            ctFIREp = inputdlg(prompt,name,numlines,defaultanswer);
            ctfP.pct = str2num(ctFIREp{1});
            ctfP.SS  = str2num(ctFIREp{2});
            ctfP.value = fp.value;
            ctfP.status = fp.status;
            setappdata(imgRun,'ctfparam',ctfP);
            
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
% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        
        imgPath = getappdata(imgOpen,'imgPath');
        dirout = [imgPath,'ctFIREout\'];
        if ~exist(dirout,'dir')
            mkdir(dirout);
            
        end
        disp(sprintf('dirout= %s',dirout))
        
        %         dirout =[ uigetdir(' ','Select Output Directory:'),'\'];
        setappdata(imgRun,'outfolder',dirout);
        
        
        %         IMG = getappdata(imgOpen,'img');
        LW1 = get(enterLW1,'UserData');
        LL1 = get(enterLL1,'UserData');
        FNL = get(enterFNL,'UserData');
        BINs = get(enterFNL,'UserData');
        
        if isempty(LW1), LW1 = 0.5; end
        if isempty(LL1), LL1 = 30;  end
        if isempty(FNL), FNL = 2999; end
        if isempty(BINs), BINs = 10; end
        
        % select to Run ctFIRE, FIRE, or both
        RO =  get(selRO,'Value')
        
        fp = getappdata(setFIRE,'FIREp');
        % initilize the input options
        cP = struct('plotflag',[],'RO',[],'LW1',[],'LL1',[],'FNL',[],'Flabel',[],...,
            'angH',[],'lenH',[],'angV',[],'lenV',[],'stack',[]);
        ctfP = struct('value',[],'status',[],'pct',[],'SS',[]);
        
        cP.postp = 0;
        cP.RO = RO;
        cP.LW1 = LW1;
        cP.LL1 = LL1;
        cP.FNL = FNL;
        cP.BINs = BINs;
        cP.Flabel = 0;
        cP.plotflag = 1;
        %         cP.plotctf = 1;
        %         cP.plotrec = 0;
        cP.angH = 1;
        cP.lenH = 1;
        cP.angV = 1;
        cP.lenV = 1;
        
        if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; end
        if (get(makeHistA,'Value') ~= get(makeHistA,'Max')); cP.angH =0; end
        if (get(makeHistL,'Value') ~= get(makeHistL,'Max')); cP.lenH =0; end
        if (get(makeValuesA,'Value') ~= get(makeValuesA,'Max')); cP.angV =0; end
        if (get(makeValuesL,'Value') ~= get(makeValuesL,'Max')); cP.lenV =0; end
        
        ctfP = getappdata(imgRun,'ctfparam');
        openimg = getappdata(imgOpen, 'openImg');
        openmat = getappdata(imgOpen, 'openMat');
        openstack = getappdata(imgOpen,'openstack');
        
        set([setFIRE imgRun selRO imgOpen],'Enable','off');
        
        cP.slice = [];  cP.stack = [];  % initialize stack option
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
                cP.ws = getappdata(hsr,'wholestack')
                disp(sprintf('cp.ws = %d',cP.ws));
                
                if cP.ws == 1 % process whole stack
                    for iss = 1:sslice
                        img = imread([imgPath imgName],iss);
                        figure(guiFig);
                        img = imadjust(img);
                        imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                        %                     imshow(img,'Parent',imgAx);
                        
                        cP.slice = iss;
                        [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                        soutf(:,:,iss) = OUTf;
                        OUTctf(:,:,iss) = OUTctf;
                    end
                else
                    srstart = getappdata(hsr,'srstart');
                    srend = getappdata(hsr,'srend');
                    
                    for iss = srstart:srend
                        img = imread([imgPath imgName],iss);
                        figure(guiFig);
                        img = imadjust(img);
                        imshow(img);set(guiFig,'name',sprintf('Processing slice %d of the stack',iss));
                        %                     imshow(img,'Parent',imgAx);
                        cP.slice = iss;
                        [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                        soutf(:,:,iss) = OUTf;
                        OUTctf(:,:,iss) = OUTctf;
                    end
                end
                disp('Stack analysis is done, ctFIRE will reset')
                %                 reset ctFIRE
                ctFIRE
                
            else
                disp('process an image')
                setappdata(imgRun,'controlpanel',cP);
                disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                
                [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                set(postprocess,'Enable','on');
                set(infoLabel,'String','After fiber extration is done, confirm or change parameters for post-processing ');
                
            end
            
        else  % open multi-files
            
            if openmat ~= 1
                set([makeRecon makeHistA makeHistL makeValuesA makeValuesL setFIRE enterLL1 enterLW1 enterFNL enterBIN],'Enable','off');
                %                 set([imgOpen postprocess],'Enable','off');
                %                 set(guiFig,'Visible','on');
                set(infoLabel,'String','Select parameters to run');
                imgPath = getappdata(imgOpen,'imgPath');
                multiimg = getappdata(imgOpen,'imgName');
                filelist = cell2struct(multiimg,'name',1);
                
                %                 filelist = dir(imgPath);
                %                 filelist(1:2) = [];% get rid of the first two files named '.','..'
                fnum = length(filelist);
                
                for fn = 1:fnum
                    imgName = filelist(fn).name;
                    
                    disp(sprintf(' image path:%s \n image name:%s \n output folder: %s \n pct = %4.3f \n SS = %d',...
                        imgPath,imgName,dirout,ctfP.pct,ctfP.SS));
                    ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);
                    
                end
                
                disp(sprintf('%d images have been prcoessed, ctFIRE will reset',fnum));
                %                 reset ctFIRE
                ctFIRE
               
                
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
        
        
        %         set(postprocess,'Enable','on');
        
    end


%--------------------------------------------------------------------------

% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        ctFIRE
    end

end