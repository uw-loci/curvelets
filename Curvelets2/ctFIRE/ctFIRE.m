function ctFIRE

% ctFIRE.m
% This is the GUI associated with an approach of integrating curvelet transform(ct,2004) and a fiber extraction algorithm(FIRE,2008 Stein).
% To deploy this:
% 1. type mcc -m ctFIRE_v1.m -R '-startmsg,"Starting_Curvelet_transform_plus_FIRE"' at
% the matlab command prompt

clc; clear all;close all;
addpath('../CurveLab-2.1.2/fdct_wrapping_matlab');
addpath(genpath(fullfile('../FIRE')));
% global imgName

guiCtrl = figure('Resize','on','Units','pixels','Position',[25 75 300 650],'Visible','off','MenuBar','none','name','CT-FIRE Control','NumberTitle','off','UserData',0);
guiFig = figure('Resize','on','Units','pixels','Position',[340 125 600 600],'Visible','off','MenuBar','none','name','Original Image','NumberTitle','off','UserData',0);
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

imgPanel = uipanel('Parent', guiFig,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('Parent',imgPanel,'Units','normalized','Position',[0 0 1 1]);

reconPanel = uipanel('Parent',guiRecon,'Units','normalized','Position',[0 0 1 1]);
reconAx = axes('Parent',reconPanel,'Units','normalized','Position',[0 0 1 1]);

histPanel = axes('Parent',guiHist);

compassPanel = axes('Parent',guiCompass);

valuePanel = uitable('Parent',guiTable,'ColumnName','Angles','Units','normalized','Position',[0 0 .35 1]);
rowN = {'Mean','Median','Standard Deviation','Coeff of Alignment','Red Pixels','Yellow Pixels','Green Pixels'};
statPanel = uitable('Parent',guiTable,'RowName',rowN,'Units','normalized','Position',[.35 0 .65 1]);

% button to select an image file
imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Images','FontUnits','normalized','FontSize',.185,'Units','normalized','Position',[0 .85 .5 .1],'callback','ClickedCallback','Callback', {@getFile});

% button to process an output mat file of ctFIRE
postprocess = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Post-processing','FontUnits','normalized','FontSize',.185,'UserData',[],'Units','normalized','Position',[.5 .85 .5 .1],'callback','ClickedCallback','Callback', {@postP});

% button to set FIRE parameters
setFIRE = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','FIRE Parameters','FontUnits','normalized','FontSize',.185,'Units','normalized','Position',[0 .75 .5 .1]);


% button to run measurement
% imgRun = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[0 .75 .5 .1]);
imgRun = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.185,'Units','normalized','Position',[0.5 .75 .5 .1]);

% button to reset gui
imgReset = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',1.0,'Units','normalized','Position',[.75 .975 .25 .025],'callback','ClickedCallback','Callback',{@resetImg});

% text box for taking in curvelet threshold "keep"
LL1label = uicontrol('Parent',guiCtrl,'Style','text','String','Minimum Fiber Lengh to Show: ','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .50 .75 .1]);
enterLL1 = uicontrol('Parent',guiCtrl,'Style','edit','String','30','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.70 .57 .25 .04],'Callback',{@get_textbox_data1});

FNLlabel = uicontrol('Parent',guiCtrl,'Style','text','String','Maximum fiber number to show:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .45 .75 .1]);
enterFNL = uicontrol('Parent',guiCtrl,'Style','edit','String','2999','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.70 .52 .25 .04],'Callback',{@get_textbox_data2});

LW1label = uicontrol('Parent',guiCtrl,'Style','text','String','Fiber Line Width:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .40 .75 .1]);
enterLW1 = uicontrol('Parent',guiCtrl,'Style','edit','String','0.5','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.70 .47 .25 .04],'Callback',{@get_textbox_data3});

% panel to contain output checkboxes
guiPanel2 = uipanel('Parent',guiCtrl,'Title','Select Output: ','Units','normalized','Position',[0 .2 1 .225]);

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Overlaid and Reconstructed Image','Min',0,'Max',3,'Units','normalized','Position',[.075 .8 .8 .1]);

% checkbox to display a angle histogram
makeHistA = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Angle Histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .65 .8 .1]);

% checkbox to display a length histogram
makeHistL = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Length Histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .5 .8 .1]);

% checkbox to output list of values
makeValuesA = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Angle Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .35 .8 .1]);

% checkbox to save length value
makeValuesL = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Length Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .2 .8 .1]);

% checkbox to process whole stack
wholeStack = uicontrol('Parent',guiPanel2,'Style','checkbox','Enable','off','String','Whole Stack','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .05 .8 .1]);

% listbox containing names of active files
%listLab = uicontrol('Parent',guiCtrl,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[0 .6 1 .1]);
%imgList = uicontrol('Parent',guiCtrl,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[0 .425 1 .25]);
% slider for scrolling through stacks
slideLab = uicontrol('Parent',guiCtrl,'Style','text','String','Stack Image Selected:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .64 .75 .1]);
stackSlide = uicontrol('Parent',guiCtrl,'Style','slide','Units','normalized','position',[0 .62 1 .1],'min',1,'max',100,'val',1,'SliderStep', [.1 .2],'Enable','off');

infoLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Click Get Images button.','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[0 .05 .75 .1]);

% set font
set([guiPanel2 LL1label LW1label FNLlabel infoLabel enterLL1 enterLW1 enterFNL makeHistL makeValuesA makeRecon  makeHistA makeValuesL wholeStack imgOpen setFIRE imgRun imgReset postprocess slideLab],'FontName','FixedWidth')
set([LL1label LW1label FNLlabel],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset postprocess],'FontWeight','bold')
set([LL1label LW1label FNLlabel slideLab infoLabel],'HorizontalAlignment','left')

%initialize gui
set([postprocess setFIRE imgRun makeHistA makeRecon enterLL1 enterLW1 enterFNL makeValuesA makeHistL makeValuesL],'Enable','off')
set([makeRecon makeHistA makeHistL makeValuesA makeValuesL wholeStack],'Value',3)
%set(guiFig,'Visible','on')

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

        name='Select an image or an image(s) folder to process';
        prompt={'Process an image or a folder (1: image, 0: folder)'};
        numlines=1;
        defaultanswer={'1'};
        filetype = inputdlg(prompt,name,numlines,defaultanswer);
        openimg = str2num(filetype{1});

        setappdata(imgOpen, 'openType',openimg);


         if openimg ==1

            [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','off');
%             filePath = fullfile(pathName,fileName);
            setappdata(imgOpen,'imgPath',pathName);
            setappdata(imgOpen, 'imgName',fileName);


            ff = fullfile(pathName,fileName);
            info = imfinfo(ff);
            numSections = numel(info)%;

            if numSections > 1
                img = imread(ff,1,'Info',info);
                set(stackSlide,'max',numSections);
                set(stackSlide,'Enable','on');
                set(wholeStack,'Enable','on');
                set(stackSlide,'SliderStep',[1/(numSections-1) 3/(numSections-1)]);
                set(stackSlide,'Callback',{@slider_chng_img});
                set(slideLab,'String','Stack Image Selected: 1');

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
    %         imgName = getFileName(imgType,fileName);  % YL
            setappdata(imgOpen,'type',info(1).Format)
            colormap(gray);

            set([LL1label LW1label FNLlabel],'ForegroundColor',[0 0 0])
            set(guiFig,'UserData',0)

            if ~get(guiFig,'UserData')
                set(guiFig,'WindowKeyPressFcn',@startPoint)
                coords = [-1000 -1000];
                aa = 1;
            end

            if numSections > 1
               %initialize gui
                set([postprocess setFIRE imgRun makeHistA makeRecon enterLL1 enterLW1 enterFNL makeValuesA makeHistL makeValuesL],'Enable','off')
                set([makeRecon makeHistA makeHistL makeValuesA makeValuesL wholeStack],'Enable','off')
                set(infoLabel, 'String','Showing a stack. Processing a stack is in development. Please select a single image to process.')
            else
                %set(imgList,'String',files)
                %set(imgList,'Callback',{@showImg})
                set(setFIRE,'callback',{@setpFIRE});
                set(imgRun,'Callback',{@runMeasure});
                set([makeRecon makeHistA makeHistL makeValuesA makeValuesL setFIRE enterLL1 enterLW1 enterFNL postprocess],'Enable','on');
                set([imgOpen postprocess],'Enable','off');
                set(guiFig,'Visible','on');

                set(infoLabel,'String','Select parameters to run.');

            end

         else

              set([postprocess setFIRE imgRun makeHistA makeRecon enterLL1 enterLW1 enterFNL makeValuesA makeHistL makeValuesL],'Enable','off')
              set([makeRecon makeHistA makeHistL makeValuesA makeValuesL wholeStack],'Enable','off')
              set(infoLabel, 'String','Processing a folder is in development. Please select a single image.')

%             pathName = uigetdir([],'choosing image folder');
%             setappdata(imgOpen,'imgPath',pathName);

        end

            %set(t1,'Title','Image')

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

        set(slideLab,'String',['Stack Image Selected: ' num2str(idx)]);
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
% callback function for postprocess button
    function postP(postprocess,eventdata)

        dirout = getappdata(imgRun,'outfolder');
        openimg = getappdata(imgOpen, 'openType');

        ctfP = getappdata(imgRun,'ctfparam');
        cP = getappdata(imgRun,'controlpanel');
        cP.postp = 1;

        LW1 = get(enterLW1,'UserData');
        LL1 = get(enterLL1,'UserData');
        FNL = get(enterFNL,'UserData');

        if isempty(LW1), LW1 = 0.5; end
        if isempty(LL1), LL1 = 30;  end
        if isempty(FNL), FNL = 2999; end

        cP.LW1 = LW1;
        cP.LL1 = LL1;
        cP.FNL = FNL;

        if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; else cP.plotflag =1;end
        if (get(makeHistA,'Value') ~= get(makeHistA,'Max')); cP.angH =0; else cP.angH = 1;end
        if (get(makeHistL,'Value') ~= get(makeHistL,'Max')); cP.lenH =0; else cP.lenH = 1;end
        if (get(makeValuesA,'Value') ~= get(makeValuesA,'Max')); cP.angV =0; else cP.angV =1; end
        if (get(makeValuesL,'Value') ~= get(makeValuesL,'Max')); cP.lenV =0; else cP.lenV =1;end


        if openimg
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
%              disp(sprintf('Parameter # %d [%s], is of type string.',itc, pfnames{itc}));

         end
    end

    name='Update FIRE Parameters';
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
        disp('FIRE parameters were updated.')
        fpupdate = 1;

    else
        disp('FIRE parameters are set to default values.')
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
      set(imgRun,'Enable','on')


end
%--------------------------------------------------------------------------
% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        dirout =[ uigetdir(' ','Select Output Directory:'),'\'];
        setappdata(imgRun,'outfolder',dirout);

%         IMG = getappdata(imgOpen,'img');
        LW1 = get(enterLW1,'UserData');
        LL1 = get(enterLL1,'UserData');
        FNL = get(enterFNL,'UserData');

        if isempty(LW1), LW1 = 0.5; end
        if isempty(LL1), LL1 = 30;  end
        if isempty(FNL), FNL = 2999; end

     % select to Run ctFIRE, FIRE, or Both
        name='Run Options';
        prompt={'1: ctFIRE; 2: FIRE; 3: Both'};
        numlines=1;
        defaultanswer={'1'};
        runoption = inputdlg(prompt,name,numlines,defaultanswer);
        RO = str2num(runoption{1});  % run option

        openimg = getappdata(imgOpen, 'openType');
        fp = getappdata(setFIRE,'FIREp');
    % initilize the input options
        cP = struct('plotflag',[],'RO',[],'LW1',[],'LL1',[],'FNL',[],'Flabel',[],...,
            'angH',[],'lenH',[],'angV','lenV');
        ctfP = struct('value',[],'status',[],'pct',[],'SS',[]);

        cP.postp = 0;
        cP.RO = RO;
        cP.LW1 = LW1;
        cP.LL1 = LL1;
        cP.FNL = FNL;
        cP.Flabel = 0;
        cP.plotflag = 1;
        cP.angH = 1;
        cP.lenH = 1;
        cP.angV = 1;
        cP.lenV = 1;

        if (get(makeRecon,'Value') ~= get(makeRecon,'Max')); cP.plotflag =0; end
        if (get(makeHistA,'Value') ~= get(makeHistA,'Max')); cP.angH =0; end
        if (get(makeHistL,'Value') ~= get(makeHistL,'Max')); cP.lenH =0; end
        if (get(makeValuesA,'Value') ~= get(makeValuesA,'Max')); cP.angV =0; end
        if (get(makeValuesL,'Value') ~= get(makeValuesL,'Max')); cP.lenV =0; end

        setappdata(imgRun,'controlpanel',cP);

        ctfP.value = fp.value;
        ctfP.status = fp.status;

        if openimg

            imgPath = getappdata(imgOpen,'imgPath');
            imgName = getappdata(imgOpen, 'imgName');

            if RO == 1 || RO == 3      % ctFIRE need to set pct and SS

                name='Set CT-FIRE Parameters';
                prompt={'Percentile of the remaining curvelet coeffs',...
                    'Number of selected scales'};
                numlines=1;
                defaultanswer={'0.2','3'};
                ctFIREp = inputdlg(prompt,name,numlines,defaultanswer);
                ctfP.pct = str2num(ctFIREp{1});
                ctfP.SS  = str2num(ctFIREp{2});
            end

             disp(sprintf('Image Path:%s \n Image Name:%s \n Output Folder: %s \n pct = %4.3f \n SS = %d',...
                    imgPath,imgName,dirout,ctfP.pct,ctfP.SS));

            setappdata(imgRun,'ctfparam',ctfP);
             [OUTf OUTctf] = ctFIRE_1(imgPath,imgName,dirout,cP,ctfP);

        else  % open a folder

            disp('In the process of development...')
%             imgPath = getappdata(imgOpen,'imgPath');
%             name='Running CT-FIRE: Parameters Overview';
%             prompt={'Percentile of the remaining curvelet coeffs',...
%                 'Number of selected scales','Threshold to remove background noise'};
%             numlines=1;
%             defaultanswer={'0.2','3','30'};
%             ctFIREp = inputdlg(prompt,name,numlines,defaultanswer);
%             cfp = struct('pct',[],'SS',[],'thi',[]);  % initilize struct cfp
%             cfp.pct = str2num(ctFIREp{1});
%             cfp.SS  = str2num(ctFIREp{2});
%             cfp.thi = str2num(ctFIREp{3});
%             disp(sprintf('Image Path: %s \n Image Name: %s \n Output Path: %s \n pct = %4.3f \n SS = %d \n thi = %d',imgPath,cfp.pct,cfp.SS,cfp.thi));
%             disp('Press any key to continue...')
%             pause

%             OUTctf_gui = ctFIRE_all_GUI(imgPath,cfp);
        end

        set([setFIRE imgRun imgOpen],'Enable','off');
        set(postprocess,'Enable','on');
        set(infoLabel,'String','Confirm or change parameters for post-processing.');

end


%--------------------------------------------------------------------------

% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        ctFIRE
    end

end
