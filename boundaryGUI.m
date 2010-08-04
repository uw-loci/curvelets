function boundaryGUI

% boundaryGUI.m
% This is the GUI associated with the boundary measurement scheme. 
% 
% The imgOpen button opens a file selection window allowing the user to select the desired image file.
% 
% A reference line or boundary is required. To create the boundary, hold down the 'alt' key and use the mouse to select the endpoints
% of the line segments that will make up the boundary. 
% 
% Once the boundary has been created, the user can choose whether or not to write the angle histogram information to a file, to apply
% a threshold to the curvelet coefficents (default is to keep the largest .1% of the coefficients), or to see a reconstructed image from the 
% thresholded curvelet coefficients. Checking the 'write to file' checkbox will prompt the user to select a directory for the output files. 
% 
% After the boundary has been created, the imgRun button will launch the measurement function.
% 
% The imgReset button will return the user to the measurement selection window. 
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, August 2010

clear all
close all
global imgName

% main GUI figure
guiFig = figure('Resize','off','Units','pixels','Position',[100 200 900 650],'Visible','off','MenuBar','none','name','CurvMeasure','NumberTitle','off','UserData',0);
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiFig,'Color',defaultBackground)

% the axis where the selected image will be displayed
imgAx = axes('Parent',guiFig,'Units','pixels','Position',[100 100 575 500]);

% button to select an image file
imgOpen = uicontrol(guiFig,'Style','pushbutton','String','Get Image','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.775 .825 .2 .1],'callback','ClickedCallback','Callback', {@getFile});

% button to run measurement
imgRun = uicontrol(guiFig,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.775 .725 .2 .1]);

% button to reset gui
imgReset = uicontrol(guiFig,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.775 .625 .2 .1],'callback','ClickedCallback','Callback',{@resetImg});

% text box for taking in curvelet threshold "keep"
keepLab1 = uicontrol(guiFig,'Style','text','String','Enter % of coefs to keep, as decimal:','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[.775 .5 .2 .1]);
keepLab2 = uicontrol(guiFig,'Style','text','String','(default is .001)','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[.775 .45 .2 .1]);
enterKeep = uicontrol(guiFig,'Style','edit','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.875 .425 .1 .075],'Callback',{@get_textbox_data});

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol(guiFig,'Style','checkbox','Enable','off','String','Show Curvelets','Min',0,'Max',2,'Units','normalized','Position',[.775 .275 .2 .1]);

% checkbox to write the angle histogram data to a .csv file
makeFile = uicontrol(guiFig,'Style','checkbox','Enable','off','String','Save Histogram Data','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.775 .22 .2 .1],'Callback',{@folderOut});

% set font
set([keepLab1 keepLab2 enterKeep makeRecon  makeFile imgOpen imgRun imgReset],'FontName','FixedWidth')
set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset],'FontWeight','bold')
set([keepLab1 keepLab2],'HorizontalAlignment','left')

%initialize gui
set([imgRun makeFile makeRecon enterKeep],'Enable','off')
set([makeRecon makeFile],'Value',0)
set(guiFig,'Visible','on')

% initialize variables used in some callback functions
coords = [-1000 -1000];
aa = 1;
extent = get(imgAx,'Position');
bottom = extent(2) + extent(4);
left = extent(1);
width = extent(3);
height = extent(4);

%--------------------------------------------------------------------------
% callback function for imgOpen
    function getFile(imgOpen,eventdata)

        [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image');
        
        if fileName ~= 0
        img = imread(fullfile(pathName,fileName));
        imagesc(img)
        colormap(gray)

        setappdata(imgOpen,'img',img);
        info = imfinfo(fullfile(pathName,fileName));
        imgType = strcat('.',info.Format);
        imgName = getFileName(imgType,fileName);
        
        set([keepLab1 keepLab2],'ForegroundColor',[0 0 0])
        set(guiFig,'UserData',0)
        set(guiFig,'WindowKeyPressFcn',@startPoint)
        coords = [-1000 -1000];
        aa = 1;
        test = get(enterKeep,'UserData');
        
        if isempty(test)
            set(imgRun,'Callback',{@runMeasure1})
        end
        end

    end

%--------------------------------------------------------------------------
% callback function for enterKeep text box
    function get_textbox_data(enterKeep,eventdata)
        usr_input = get(enterKeep,'String');
        usr_input = str2double(usr_input);
        set(enterKeep,'UserData',usr_input)
        set(imgRun,'Callback',{@runMeasure2})
    end

%--------------------------------------------------------------------------
% callback function for makeFile checkbox
    function folderOut(makeFile,eventdata)
        if (get(makeFile,'Value') == get(makeFile,'Max'))
        tempFolder = uigetdir(' ','Select Output Directory:');
        set(makeFile,'UserData',tempFolder);
        end
    end

%--------------------------------------------------------------------------
% callback function for imgRun, in the case that there is no user input
% from enterKeep
    function runMeasure1(imgRun,eventdata)
        IMG = getappdata(imgOpen,'img');
        extent = get(imgAx,'Position'); 
        set([imgRun makeFile makeRecon enterKeep imgOpen],'Enable','off')
        runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
        waitbar(0)
            
        [object, Ct] = newCurv(IMG);
        
        histData = getBoundary(coords,IMG,extent,object);
        waitbar(1)
        close(runWait)
        
        imgWait = waitbar(0,'Preparing Images...','Units','inches','Position',[5 4 4 1]);
        waitbar(0)
        if (get(makeRecon,'Value') == get(makeRecon,'Max'))
            showRecon(Ct,imgName)
        end
        if (get(makeFile,'Value') == get(makeFile,'Max'))
            saveFile = fullfile(get(makeFile,'UserData'),strcat(imgName,'_hist.csv'));
            csvwrite(saveFile,histData)
        end
        waitbar(1)
        close(imgWait)
        set(enterKeep,'String',[])
        set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
        set(imgOpen,'Enable','on')
        set([makeRecon makeFile],'Value',0)    
    end

%--------------------------------------------------------------------------
% callback function for imgRun, in the case that there is user input from
% enterKeep
    function runMeasure2(imgRun,eventdata)
        IMG = getappdata(imgOpen,'img');
        keep = get(enterKeep,'UserData');        
        extent = get(imgAx,'Position');
        set([imgRun makeFile makeRecon enterKeep imgOpen],'Enable','off')
        runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
        waitbar(0)
        
        [object, Ct] = newCurv(IMG,keep);
        
        histData = getBoundary(coords,IMG,extent,object);
        waitbar(1)
        close(runWait)
        
        imgWait = waitbar(0,'Preparing Images...','Units','inches','Position',[5 4 4 1]);
        waitbar(0)
        if (get(makeRecon,'Value') == get(makeRecon,'Max'))
            showRecon(Ct,imgName)
        end
        if (get(makeFile,'Value') == get(makeFile,'Max'))
            saveFile = fullfile(get(makeFile,'UserData'),strcat(imgName,'_hist.csv'));
            csvwrite(saveFile,histData)
        end
        
        waitbar(1)
        close(imgWait)
        set(enterKeep,'String',[])
        set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
        set([makeRecon makeFile],'Value',0)
        set(imgOpen,'Enable','on')
    end

%--------------------------------------------------------------------------
% keypress function for the main gui window
    function startPoint(guiFig,evnt)
        
        if strcmp(evnt.Modifier{:},'alt')
        
            set(guiFig,'WindowKeyReleaseFcn',@stopPoint)
            set(guiFig,'WindowButtonDownFcn',@getPoint)
                      
        end
    end

%--------------------------------------------------------------------------
% boundary creation function that records the user's mouse clicks while the
% alt key is being held down
    function getPoint(guiFig,evnt2)

       if ~get(guiFig,'UserData') 
           coords(aa,:) = get(guiFig,'CurrentPoint');
           rows = round((bottom - coords(:,2)) * size(getappdata(imgOpen,'img'),2)/height);
           cols = round((coords(:,1) - left) * size(getappdata(imgOpen,'img'),1)/width);
           
           aa = aa + 1;

           hold on
           plot(cols,rows,'r')
           plot(cols,rows,'*y')
       end

    end

%--------------------------------------------------------------------------
% terminates boundary creation when the alt key is released
    function stopPoint(guiFig,evnt4)

            set(guiFig,'UserData',1)
            set(guiFig,'WindowButtonUpFcn',[]) 
            set(guiFig,'WindowKeyPressFcn',[])
            set([enterKeep imgRun makeFile makeRecon],'Enable','on')
    
    end

%--------------------------------------------------------------------------
% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        CurvMeasure
    end

end










