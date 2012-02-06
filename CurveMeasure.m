function CurveMeasure

% CurveMeasure.m
% This is the GUI associated with the boundary measurement scheme. 
% 
% The imgOpen button opens a file selection window allowing the user to select the desired image file.
% 
% A reference line or boundary is optional. To create the boundary, hold down the 'alt' key and use the mouse to select the endpoints
% of the line segments that will make up the boundary. Otherwise, use
% loadBoundary button to load coordinates from .csv file
% 
% EnterKeep text box will apply a threshold to the curvelet coefficents
% (default is to keep the largest .1% of the coefficients).
%
% Optional outputs include: histogram, values/statistics, compass plot or
% reconstructed curvelet image
%
% After the boundary has been created, the imgRun button will launch the measurement function.
% 
% The imgReset button will reset gui 
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, December 2011

clear all
close all
global imgName

% main GUI figure
guiFig = figure('Resize','off','Units','pixels','Position',[25 75 1000 650],'Visible','off','MenuBar','none','name','CurveAlign','NumberTitle','off','UserData',0);
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiFig,'Color',defaultBackground)

% the tabgroup, tabs and panels where the selected image and results will be displayed
tabGroup = uitabgroup('v0',guiFig,'Units','pixels','Position',[50 30 650 585]);
boundingbox = get(tabGroup,'Position');
width = boundingbox(3);
height = boundingbox(4);

t1 = uitab('v0',tabGroup);

t2 = uitab('v0',tabGroup);

t3 = uitab('v0',tabGroup);

t4 = uitab('v0',tabGroup);

t5 = uitab('v0',tabGroup);

histPanel = axes('Parent',t2);
compassPanel = axes('Parent',t4);
valuePanel = uitable('Parent',t5,'ColumnName','Angles','Units','normalized','Position',[.15 .2 .25 .6]);
rowN = {'Mean','Median','Standard Deviation','Coef of Alignment'};
statPanel = uitable('Parent',t5,'RowName',rowN,'Units','normalized','Position',[.45 .4 .45 .2]);
imgPanel = uipanel(t1,'Units','normalized','Position',[0 0 1 1]);
imgAx = axes('parent',imgPanel,'Units','pixels','Position',[0 0 1 1]);
reconPanel = uipanel(t3,'Units','normalized','Position',[0 0 1 1]);


% button to select an image file
imgOpen = uicontrol(guiFig,'Style','pushbutton','String','Get Images','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.705 .825 .14 .1],'callback','ClickedCallback','Callback', {@getFile});

% button to select a boundary in a .csv file
loadBoundary = uicontrol(guiFig,'Style','pushbutton','String','Get Boundary','FontUnits','normalized','FontSize',.25,'UserData',[],'Units','normalized','Position',[.845 .825 .14 .1],'callback','ClickedCallback','Callback', {@boundIn});

% button to run measurement
imgRun = uicontrol(guiFig,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.705 .725 .14 .1]);

% button to reset gui
imgReset = uicontrol(guiFig,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.845 .725 .14 .1],'callback','ClickedCallback','Callback',{@resetImg});

% text box for taking in curvelet threshold "keep"
keepLab1 = uicontrol(guiFig,'Style','text','String','Enter % of coefs to keep, as decimal:','FontUnits','normalized','FontSize',.18,'Units','normalized','Position',[.705 .3 .3 .1]);
keepLab2 = uicontrol(guiFig,'Style','text','String','(default is .001)','FontUnits','normalized','FontSize',.15,'Units','normalized','Position',[.705 .275 .2 .1]);
enterKeep = uicontrol(guiFig,'Style','edit','String','.001','BackgroundColor','w','Min',0,'Max',1,'UserData',[],'Units','normalized','Position',[.875 .32 .1 .05],'Callback',{@get_textbox_data});

% panel to contain output checkboxes
guiPanel = uipanel('Parent',guiFig,'Title','Select Output: ','Units','normalized','Position',[.705 .07 .27 .225]);

% checkbox to display the image reconstructed from the thresholded
% curvelets
makeRecon = uicontrol(guiPanel,'Style','checkbox','Enable','off','String','Reconstructed Image','Min',0,'Max',2,'Units','normalized','Position',[.075 .75 .8 .1]);

% checkbox to display a histogram
makeHist = uicontrol(guiPanel,'Style','checkbox','Enable','off','String','Histogram','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .57 .8 .1]);

% checkbox to display a compass plot
makeCompass = uicontrol(guiPanel,'Style','checkbox','Enable','off','String','Compass Plot','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .39 .8 .1]);

% checkbox to output list of values
makeValues = uicontrol(guiPanel,'Style','checkbox','Enable','off','String','Values','UserData','0','Min',0,'Max',3,'Units','normalized','Position',[.075 .188 .8 .1]);

% listbox containing names of active files
listLab = uicontrol(guiFig,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[.705 .6 .15 .1]);
imgList = uicontrol(guiFig,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[.705 .425 .27 .25]);

% set font
set([guiPanel keepLab1 keepLab2 enterKeep listLab makeCompass makeValues makeRecon  makeHist imgOpen imgRun imgReset loadBoundary],'FontName','FixedWidth')
set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
set([imgOpen imgRun imgReset loadBoundary],'FontWeight','bold')
set([keepLab1 keepLab2],'HorizontalAlignment','left')

%initialize gui
set([imgRun makeHist makeRecon enterKeep makeValues makeCompass loadBoundary],'Enable','off')
set([makeRecon makeHist makeCompass makeValues],'Value',0)
set(guiFig,'Visible','on')

% initialize variables used in some callback functions
coords = [-1000 -1000];
aa = 1;


%--------------------------------------------------------------------------
% callback function for imgOpen
    function getFile(imgOpen,eventdata)
        
        [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','on');

        if ~iscell(fileName)
            img = imread(fullfile(pathName,fileName));
            if size(img,3) > 1
                img = img(:,:,1);
            end
            displayImg(img,imgPanel)
            files = {fileName};
            setappdata(imgOpen,'img',img);
            info = imfinfo(fullfile(pathName,fileName));
            imgType = strcat('.',info.Format);
            imgName = getFileName(imgType,fileName);
            setappdata(imgOpen,'type',info.Format)
            colormap(gray);
        else
            files = fileName;
            numFrames = length(fileName);
            fil = fileName{1};
            img = imread(fullfile(pathName,fil));
            if size(img,3) > 1
                img = img(:,:,1);
            end
            displayImg(img,imgPanel)
            getWait = waitbar(0,'Loading Images...','Units','inches','Position',[5 4 4 1]);
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
        set([keepLab1 keepLab2],'ForegroundColor',[0 0 0])
        set(guiFig,'UserData',0)
        
        if ~get(guiFig,'UserData')
            set(guiFig,'WindowKeyPressFcn',@startPoint)
            coords = [-1000 -1000];
            aa = 1;
        end
        
        setappdata(imgOpen,'type',info.Format)        
        set(imgList,'String',files)
        set(imgList,'Callback',{@showImg})
        set(imgRun,'Callback',{@runMeasure})
        set([makeRecon makeHist makeCompass makeValues imgRun loadBoundary enterKeep],'Enable','on')
        set(imgOpen,'Enable','off')
        set(t1,'Title','Image')  

    end

%--------------------------------------------------------------------------
% callback function for listbox, displays currently selected output
    function showImg(imgList,eventdata)
        img = getappdata(imgOpen,'img');
        index = get(imgList,'Value');
        imgPanel = uipanel(t1,'Units','normalized','Position',[0 0 1 1]);
        reconPanel = uipanel(t3,'Units','normalized','Position',[0 0 1 1]);

        if ~iscell(img)
          displayImg(img,imgPanel)
          
          if get(makeRecon,'UserData') == 1
              recImg = getappdata(makeRecon,'data');
              m = max(max(recImg));
              recImg = recImg/m;              
              displayImg(recImg,reconPanel);
          end

          if get(makeHist,'UserData') == 1
              get(makeHist)
              nx = getappdata(makeHist,'data');
              n = nx(1,:);
              x = nx(2,:);
              bar(x,n,'Parent',histPanel)
          end
          
          if get(makeCompass,'UserData') == 1
              UV = getappdata(makeCompass,'data');
              U = UV(1,:);
              V = UV(2,:);
              compass(compassPanel,U,V)
          end
          
          if get(makeValues,'UserData') == 1
              dat = getappdata(makeValues,'data');
              set(valuePanel,'Data',dat)
              stats = getappdata(makeValues,'stats');
              set(statPanel,'Data',stats)
          end
              
        else
          displayImg(img{index},imgPanel)
          
          if get(makeRecon,'UserData') == 1
              recImg = getappdata(makeRecon,'data');
              displayImg(recImg{index},reconPanel);
          end

          if get(makeHist,'UserData') == 1
              nx = getappdata(makeHist,'data');
              n = nx{index}(1,:);
              x = nx{index}(2,:);
              bar(x,n,'Parent',histPanel)
          end
          
          if get(makeCompass,'UserData') == 1
              UV = getappdata(makeCompass,'data');
              U = UV{index}(1,:);
              V = UV{index}(2,:);
              compass(compassPanel,U,V)
          end
          
          if get(makeValues,'UserData') == 1
              dat = getappdata(makeValues,'data');
              set(valuePanel,'Data',dat{index})
              stats = getappdata(makeValues,'stats');
              set(statPanel,'Data',stats{index})
          end
        end
    end
%--------------------------------------------------------------------------
%function for displaying images in output tabs
    function displayImg(img,panel)
            left = (width - round(size(img,2)/2))/2;
            bottom = (height -  round(size(img,1)/2))/2;
            imgAx = axes('parent',panel,'Units','pixels','Position',[left bottom-10 (width-2*left) (height-2*bottom)]);
            imagesc(img,'Parent',imgAx); colormap(gray);
            if getappdata(guiFig,'boundary') == 1
                hold(imgAx);
                plot(imgAx,coords(:,1),coords(:,2),'r')
                plot(imgAx,coords(:,1),coords(:,2),'*y')
                hold off
            end
            setappdata(imgList,'img',img)
            setappdata(imgList,'axis',imgAx)
    end
%--------------------------------------------------------------------------
% callback function for enterKeep text box
    function get_textbox_data(enterKeep,eventdata)
        usr_input = get(enterKeep,'String');
        usr_input = str2double(usr_input);
        set(enterKeep,'UserData',usr_input)
    end

%--------------------------------------------------------------------------
% function for calculating statistics
    function stats = makeStats(vals,tempFolder,imgName)
         aveAngle = mean(vals);
         medAngle = median(vals);
         stdAngle = std(vals); 
         if getappdata(guiFig,'boundary') == 1
             refStd = 48.107;
         else
             refStd = 52.3943;
         end
        
         alignMent = 1-(stdAngle/refStd); 
       
         stats = vertcat(aveAngle,medAngle,stdAngle,alignMent);
         saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
         csvwrite(saveStats,stats)
    end

%--------------------------------------------------------------------------
% callback function for loadBoundary button
    function boundIn(loadBoundary,eventdata)
        [fileName,pathName] = uigetfile('*.csv','Select file containing boundary points: ');
        inName = fullfile(pathName,fileName);
        set(loadBoundary,'UserData',1);
        setappdata(guiFig,'boundary',1)
        set([enterKeep imgRun makeHist makeRecon makeValues makeCompass],'Enable','On')
        coords = csvread(inName);
        hold(imgAx); 
        plot(imgAx,coords(:,1),coords(:,2),'r')
        plot(imgAx,coords(:,1),coords(:,2),'*y')
        hold off
        set(loadBoundary,'Enable','Off');
    end

%--------------------------------------------------------------------------
% callback function for imgRun
    function runMeasure(imgRun,eventdata)
        tempFolder = uigetdir(' ','Select Output Directory:');
        IMG = getappdata(imgOpen,'img');
        keep = get(enterKeep,'UserData');   
        reconPanel = uipanel(t3,'Units','normalized','Position',[0 0 1 1]);
        boundingbox = get(tabGroup,'Position');
        width = boundingbox(3);
        height = boundingbox(4);
                    
        set([imgRun makeHist makeRecon enterKeep imgOpen loadBoundary makeCompass makeValues],'Enable','off')
        
        if isempty(keep)
            keep = .001;
        end
        
        if get(loadBoundary,'UserData')
                setappdata(guiFig,'boundary',1)
        elseif ~get(guiFig,'UserData')
            coords = [0,0];
        else
            [fileName,pathName] = uiputfile('*.csv','Specify output file for boundary coordinates:');
            fName = fullfile(pathName,fileName);
            csvwrite(fName,coords);
        end
        
        runWait = waitbar(0,'Calculating...','Units','inches','Position',[5 4 4 1]);
        waitbar(0.1)
        
        if iscell(IMG)
           [histData,recon,comps,values,stats] = cellfun(@(x,y) processImage(x,y,tempFolder,keep,coords),IMG,imgName,'UniformOutput',false);
           h = histData{1}; r = recon{1}; c = comps{1}; v = values{1}; s = stats{1};          
        else
           [histData,recon,comps,values,stats] = processImage(IMG,imgName,tempFolder,keep,coords);
           h = histData; r = recon; c = comps; v = values; s = stats;
        end
        waitbar(0.2)
        if (get(makeHist,'Value') == get(makeHist,'Max'))
            set(t2,'Title','Histogram')
            set(makeHist,'UserData',1)
            setappdata(makeHist,'data',histData) 
            n = h(1,:);
            x = h(2,:);
            bar(x,n,'Parent',histPanel)
            
        end
        waitbar(0.4)
        if (get(makeRecon,'Value') == get(makeRecon,'Max'))
            set(t3,'Title','Reconstruction')
            set(makeRecon,'UserData',1)
            setappdata(makeRecon,'data',recon)
            displayImg(r,reconPanel)
        end
        waitbar(0.5)
        if (get(makeCompass,'Value') == get(makeCompass,'Max'))
            set(t4,'Title','Compass Plot')
            set(makeCompass,'Userdata',1)
            setappdata(makeCompass,'data',comps)
            U = c(1,:);
            V = c(2,:);
            compass(compassPanel,U,V)
        end
        waitbar(0.7)
        if(get(makeValues,'Value') == get(makeValues,'Max'))
            set(t5,'Title','Values')
            set(makeValues,'Userdata',1)
            setappdata(makeValues,'data',values)
            setappdata(makeValues,'stats',stats)
            set(valuePanel,'Data',v)
            set(statPanel,'Data',s)
            
        end
        
        
        
        set(enterKeep,'String',[])
        set([keepLab1 keepLab2],'ForegroundColor',[.5 .5 .5])
        set([makeRecon makeHist,makeValues makeCompass],'Value',0)
 
        waitbar(1)
        close(runWait)
    end

%--------------------------------------------------------------------------
% function for processing an image
    function [histData,recon,comps,values,stats] = processImage(IMG, imgName, tempFolder, keep, coords)
         
        [object, Ct, inc] = newCurv(IMG,keep);
            
            if getappdata(guiFig,'boundary') == 1
                angles = getBoundary(coords,IMG,object,imgName)';  
                bins = 0:5:90;
            else
                angs = vertcat(object.angle);
                angles = group5(angs,inc);
                bins = min(angles):inc:max(angles);                
            end
            [n xout] = hist(angles,bins);imHist = vertcat(n,xout);
            
             if (get(makeHist,'Value') == get(makeHist,'Max'))
                    histData = imHist;
                    saveHist = fullfile(tempFolder,strcat(imgName,'_hist.csv'));
                    csvwrite(saveHist,histData);
             else
                 histData = 0;
             end
             
             if (get(makeRecon,'Value') == get(makeRecon,'Max'))
                temp = ifdct_wrapping(Ct,0);
                recon = real(temp);
                saveRecon = fullfile(tempFolder,strcat(imgName,'_reconstructed'));
                fmt = getappdata(imgOpen,'type');
                imwrite(recon,saveRecon,fmt)
             else
                 recon = 0;
             end
             
             if (get(makeCompass,'Value') == get(makeCompass,'Max'))
                U = cosd(xout).*n;
                V = sind(xout).*n;
                comps = vertcat(U,V);
                saveComp = fullfile(tempFolder,strcat(imgName,'_compass_plot.csv'));
                csvwrite(saveComp,comps);
             else
                 comps = 0;
             end
             
             if(get(makeValues,'Value') == get(makeValues,'Max'))
                 values = angles;
                 stats = makeStats(values,tempFolder,imgName);
                 saveValues = fullfile(tempFolder,strcat(imgName,'_values.csv'));
                 csvwrite(saveValues,values);
             else
                 values = 0;
                 stats = makeStats(values,tempFolder,imgName);
             end            

    end
%--------------------------------------------------------------------------
% keypress function for the main gui window
    function startPoint(guiFig,evnt)
        if strcmp(evnt.Key,'alt')
        
            set(guiFig,'WindowKeyReleaseFcn',@stopPoint)
            set(guiFig,'WindowButtonDownFcn',@getPoint)
                      
        end
    end

%--------------------------------------------------------------------------
% boundary creation function that records the user's mouse clicks while the
% alt key is being held down
    function getPoint(guiFig,evnt2)
       imgAxis = getappdata(imgList,'axis');
       img = getappdata(imgList,'img');
       extent = get(imgAxis,'Position');
       outExtent = get(tabGroup,'Position');
       bottom =  outExtent(2) + extent(2) + extent(4);
       left = extent(1) + outExtent(1); 
       width = extent(3); 
       height = extent(4);
       if ~get(guiFig,'UserData') 
           coords(aa,:) = get(guiFig,'CurrentPoint');
           rows = round((bottom - coords(:,2)) * size(img,1)/height);
           cols = round((coords(:,1) - left) * size(img,2)/width);
           
           aa = aa + 1;

           hold on
           plot(cols,rows,'r')
           plot(cols,rows,'*y')
           
           setappdata(guiFig,'rows',rows)
           setappdata(guiFig,'cols',cols)
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
            set([enterKeep makeValues makeHist makeRecon makeCompass],'Enable','on')
    
    end

%--------------------------------------------------------------------------
% returns the user to the measurement selection window
    function resetImg(resetClear,eventdata)
        CurveMeasure
    end

end










