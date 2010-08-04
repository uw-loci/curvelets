function curvGUI

% curvGUI.m
% This is the gui that controls the absolute measurement scheme.
% 
% The imgOpen button allows the user to select one or more single images (NOT image stacks), use the shift or command/control key to select
% multiple images. The filenames of the selected images will then appear in the list box as verification that they were properly loaded. 
% 
% Once the image files are selected, the user will be able to choose from a number of output options:
% - a histogram of measured angles
% - a compass plot of measured angles
% - descriptive statistics of the measured angles
% - values of measured angles
% these outputs can either be displayed on the screen or saved as numerical values (NOT as figures) in .csv files. Checking the 'write to file'
% checkbox will prompt the user to select a directory for the output files. 
% 
% The enterKeep textbox allows the user to apply a threshold to the curvelet coefficients (the default is to keep the largest .1% of the coefficients).
% 
% The imgRun button launches the measurement function, and will process all images in the queue, each with individual output. 
% 
% The imgReset button returns the user to the measurement selection window. 
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, August 2010


global imgName
clear all
close all

% main GUI figure
guiFig = figure('Resize','off','Units','inches','position',[2 2 10 6],'Visible','off','MenuBar','none','name','CurvMeasure','NumberTitle','off');
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiFig,'Color',defaultBackground)

% panel containing parameter controls
guiPanel = uipanel('Parent',guiFig,'Title','Set Parameters','Units','normalized','Position',[.5 .1 .4 .8]);

% text box for taking in curvelet threshold "keep"
keepLab1 = uicontrol(guiPanel,'Style','text','String','Enter % of coefs to keep, as decimal:','FontUnits','normalized','FontSize',.395,'Units','normalized','Position',[.1 .85 .6 .1]);
keepLab2 = uicontrol(guiPanel,'Style','text','String','(default is .001)','FontUnits','normalized','FontSize',.3,'Units','normalized','Position',[.1 .75 .58 .1]);
enterKeep = uicontrol(guiPanel,'Style','edit','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.7 .85 .2 .1],'Callback',{@get_textbox_data});

% checkboxes to select outputs
outLab1 = uicontrol(guiPanel,'Style','text','String','Select Output:','Units','normalized','Position',[.03 .7 .45 .075]);
makeHist = uicontrol(guiPanel,'Style','checkbox','String','Histogram','Min',0,'Max',1,'Units','normalized','Position',[.1 .64 .8 .075]);
makeCompass = uicontrol(guiPanel,'Style','checkbox','String','Compass Plot','Min',0,'Max',1,'Units','normalized','Position',[.1 .58 .8 .074]);
makeStat = uicontrol(guiPanel,'Style','checkbox','String','Statistics','Min',0,'Max',1,'Units','normalized','Position',[.1 .52 .8 .075]);
makeVals = uicontrol(guiPanel,'Style','checkbox','String','Values','Min',0,'Max',1,'Units','normalized','Position',[.1 .46 .8 .075]);

outLab2 = uicontrol(guiPanel,'Style','text','String','Output Type:','Units','normalized','Position',[.03 .38 .45 .075]);
makeDisp = uicontrol(guiPanel,'Style','checkbox','String','Display','Min',0,'Max',2,'Value',2,'Units','normalized','Position',[.1 .32 .8 .075]);
makeFile = uicontrol(guiPanel,'Style','checkbox','String','Write to File','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.1 .26 .8 .075]);

outLab3 = uicontrol(guiPanel,'Style','text','String','Images:','Units','normalized','Position',[.03 .18 .45 .075]);
makeImg = uicontrol(guiPanel,'Style','checkbox','String','Show Original Image','Min',0,'Max',1,'Units','normalized','Position',[.1 .12 .8 .075]);
makeRecon = uicontrol(guiPanel,'Style','checkbox','String','Show Reconstructed Image','Min',0,'Max',2,'Units','normalized','Position',[.1 .06 .8 .075]);

% button to select image files
imgOpen = uicontrol(guiFig,'Style','pushbutton','String','Get Images','FontUnits','normalized','FontSize',.3,'Units','normalized','Position',[.1 .75 .3 .125],'callback','ClickedCallback','Callback', {@getFile});

% table to display loaded files
imgList = uicontrol(guiFig,'Style','listbox','BackgroundColor','w','Units','normalized','Position',[.1 .1 .3 .3]);

% label for table
listLabel = uicontrol(guiFig,'Style','text','String','Selected Images:','Units','normalized','Position',[.1 .4 .3 .05]);

% button to run newCurv3
imgRun = uicontrol(guiFig,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.3,'Units','normalized','Position',[.1 .625 .3 .125]);

% button to reset gui
imgReset = uicontrol(guiFig,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.3,'Units','normalized','Position',[.1 .5 .3 .125],'callback','ClickedCallback','Callback',{@resetImg});

% set font
set([guiPanel keepLab1 keepLab2 enterKeep outLab1 makeHist makeCompass makeStat makeVals outLab2 outLab3 makeImg makeRecon makeDisp makeFile imgOpen imgList listLabel imgRun imgReset],'FontName','FixedWidth')
set([guiPanel keepLab1 keepLab2 outLab1 outLab2 outLab3],'ForegroundColor',[.5 .5 .5])
set([guiPanel outLab1 outLab2 outLab3 imgOpen listLabel imgRun imgReset],'FontWeight','bold')
set([keepLab1 keepLab2 outLab1 outLab2 outLab3 listLabel],'HorizontalAlignment','left')

%initialize gui
set([makeHist makeCompass makeStat makeVals makeImg makeRecon makeFile],'Value',0)
set([imgRun makeHist makeCompass makeStat makeVals makeImg makeRecon makeDisp makeFile imgList enterKeep],'Enable','off')
set(guiFig,'Visible','on')

% Callback function definitions

%--------------------------------------------------------------------------
% callback function for imgOpen
    function getFile(imgOpen,eventdata)
        
        [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','on');

        if ~iscell(fileName)
            img = imread(fullfile(pathName,fileName));
            files = {fileName};
            setappdata(imgOpen,'img',img);
            info = imfinfo(fullfile(pathName,fileName));
            imgType = strcat('.',info.Format);
            imgName = getFileName(imgType,fileName);
        else
            getWait = waitbar(0,'Loading Images...','Units','inches','Position',[5 4 4 1]);
            files = fileName;
            numFrames = length(fileName);
            img = imread(fullfile(pathName,fileName{1}));
            stack = cell(1,numFrames);
            for pp = 1:numFrames
                waitbar(pp/numFrames)
                stack{pp} = imread(fullfile(pathName,fileName{pp}));
                info = imfinfo(fullfile(pathName,fileName{pp}));
                imgType{pp} = strcat('.',info.Format);
            end
            imgName = cellfun(@(x,y) getFileName(x,y),imgType,fileName,'UniformOutput',false);
            setappdata(imgOpen,'img',stack)
            close(getWait)
        end
        
        set(imgList,'String',files)
        set([guiPanel keepLab1 keepLab2 outLab1 outLab2 outLab3],'ForegroundColor',[0 0 0])
        set([makeHist makeCompass makeStat makeVals makeDisp makeFile makeImg makeRecon imgRun enterKeep imgList],'Enable','on')
        set(makeFile,'Callback',{@folderOut})
        test = get(enterKeep,'UserData');
        
        if isempty(test)
            set(imgRun,'Callback',{@runMeasure1})
        end

    end

%--------------------------------------------------------------------------
% callback function for enterKeep
    function get_textbox_data(enterKeep,eventdata)
        usr_input = get(enterKeep,'String');
        usr_input = str2double(usr_input);
        set(enterKeep,'UserData',usr_input)
        set(imgRun,'Callback',{@runMeasure2})
    end

%--------------------------------------------------------------------------
% callback function for makeFile
    function folderOut(makeFile,eventdata)
        if (get(makeFile,'Value') == get(makeFile,'Max'))
        tempFolder = uigetdir(' ','Select Output Directory:');
        set(makeFile,'UserData',tempFolder);
        end
    end

%--------------------------------------------------------------------------
% callback function for imgRun with no user input from enterKeep
    function runMeasure1(imgRun,eventdata)
        outInfo = get(makeDisp,'Value') + get(makeFile,'Value');
        IMG = getappdata(imgOpen,'img');
        outputType = [get(makeHist,'Value') get(makeCompass,'Value') get(makeStat,'Value') get(makeVals,'Value')];
        set([imgRun makeHist makeCompass makeStat makeVals makeImg makeRecon makeDisp makeFile imgList enterKeep imgOpen],'Enable','off')
        if iscell(IMG)
            
            runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            
            [object,Ct,inc] = cellfun(@(x) newCurv(x),IMG,'UniformOutput',false);
            angles = cellfun(@(x) vertcat(x.angle),object,'UniformOutput',false);
            angs = cellfun(@(x,y) group5(x,y),angles,inc,'UniformOutput',false);
            outFolder = get(makeFile,'UserData');
            
            waitbar(1)
            close(runWait)
            
            cellfun(@(x,y,z) makeOutput(x,outInfo,outputType,outFolder,y,z),angs,imgName,inc);
            imgWait = waitbar(0,'Preparing Images...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            if (get(makeImg,'Value') == get(makeImg,'Max'))
                cellfun(@(x,y) showImg(x,y),IMG,imgName)
            end
            if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                cellfun(@(x,y) showRecon(x,y),Ct,imgName)
            end
            waitbar(1)
            close(imgWait)
         
        else 
            runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            
            [object, Ct,inc] = newCurv(IMG);
            angles = vertcat(object.angle);
            angs = group5(angles,inc);
            outFolder = get(makeFile,'UserData');
            
            waitbar(1)
            close(runWait)
            
            makeOutput(angs,outInfo,outputType,outFolder,imgName,inc);
            imgWait = waitbar(0,'Preparing Images...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            if (get(makeImg,'Value') == get(makeImg,'Max'))
                showImg(IMG,imgName)
            end
            if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                showRecon(Ct,imgName)
            end
            waitbar(1)
            close(imgWait)

        end

        set(enterKeep,'String',[])
        set(imgList,'String',[])
        set([guiPanel keepLab1 keepLab2 outLab1 outLab2 outLab3],'ForegroundColor',[.5 .5 .5])
        set([makeHist makeCompass makeStat makeVals makeImg makeRecon makeFile],'Value',0)
        set(imgOpen,'Enable','on')
    end

%--------------------------------------------------------------------------
% callback function for imgRun with user data from enterKeep
    function runMeasure2(imgRun,eventdata)
        outInfo = get(makeDisp,'Value') + get(makeFile,'Value');
        IMG = getappdata(imgOpen,'img');
        keep = get(enterKeep,'UserData');
        outputType = [get(makeHist,'Value') get(makeCompass,'Value') get(makeStat,'Value') get(makeVals,'Value')];
        set([imgRun makeHist makeCompass makeStat makeVals makeImg makeRecon makeDisp makeFile imgList enterKeep imgOpen],'Enable','off')
        
        if iscell(IMG)
            runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            [object,Ct,inc] = cellfun(@(x) newCurv(x,keep),IMG,'UniformOutput',false);
            angles = cellfun(@(x) vertcat(x.angle),object,'UniformOutput',false);
            angs = cellfun(@(x,y) group5(x,y),angles,inc,'UniformOutput',false);
            outFolder = get(makeFile,'UserData');
            waitbar(1)
            close(runWait)
            cellfun(@(x,y,z) makeOutput(x,outInfo,outputType,outFolder,y,z),angs,imgName,inc);
            imgWait = waitbar(0,'Preparing Images...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            if (get(makeImg,'Value') == get(makeImg,'Max'))
                cellfun(@(x,y) showImg(x,y),IMG,imgName)
            end
            if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                cellfun(@(x,y) showRecon(x,y),Ct,imgName)
            end
            waitbar(1)
            close(imgWait)
        else
            runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            [object, Ct, inc] = newCurv(IMG,keep);
            angles = vertcat(object.angle);
            angs = group5(angles,inc);
            outFolder = get(makeFile,'UserData');
            waitbar(1)
            close(runWait)
            makeOutput(angs,outInfo,outputType,outFolder,imgName,inc);
            imgWait = waitbar(0,'Preparing Images...','Units','inches','Position',[5 4 4 1]);
            waitbar(0)
            if (get(makeImg,'Value') == get(makeImg,'Max'))
                showImg(IMG,imgName)
            end
            if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                showRecon(Ct,imgName)
            end
            waitbar(1)
            close(imgWait)
        end

        set(enterKeep,'String',[])
        set(imgList,'String',[])
        set([guiPanel keepLab1 keepLab2 outLab1 outLab2 outLab3],'ForegroundColor',[.5 .5 .5])
        set([makeHist makeCompass makeStat makeVals makeImg makeRecon makeFile],'Value',0)
        set(imgOpen,'Enable','on')

    end

%--------------------------------------------------------------------------
% callback function for imgReset
    function resetImg(resetClear,eventdata)
        CurvMeasure
    end

     
        
end

