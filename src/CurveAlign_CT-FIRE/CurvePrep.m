function CurvePrep

% CurvePrep.m
% This program is a pre-processing step for use with the CurveAlign
% measurement program. 
% Read in either a single image or a stack.
% Commands:
% Creat ROI - interactive tool for selecting a region to exclude from
% CurveAlign measurement (will be blurred). Click points to create a closed
% region, then double click inside the region to blur
% Save Image - saves the current image
% Save All - saves all of the images (each slice of a stack will be saved
% as a separate image
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation
% February, 2012

clear all
close all

% main GUI figure
guiFig = figure('Resize','off','Units','pixels','Position',[25 75 1000 650],'Visible','on','MenuBar','none','name','CurvePrep','NumberTitle','off','UserData',0);
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiFig,'Color',defaultBackground)

% image dispay region and dimensions
imgPanel = uipanel(guiFig,'Units','normalized','Position',[.035 .05 .75 .9]);
imgAx = axes('parent',imgPanel,'Units','pixels','Position',[0 0 1 1]);
boundingbox = get(imgPanel,'Position');
figBox = get(guiFig,'Position');
width = boundingbox(3)*figBox(3);
height = boundingbox(4)*figBox(4);

% button to select an image file
imgOpen = uicontrol(guiFig,'Style','pushbutton','String','Get Images','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.825 .825 .14 .1],'callback','ClickedCallback','Callback', {@getFile});

% button to blur a region (exclude from curvelets analysis)
makeROI = uicontrol(guiFig,'Style','pushbutton','String','Create ROI','FontUnits','normalized','FontSize',.25,'UserData',[],'Units','normalized','Position',[.825 .725 .14 .1],'callback','ClickedCallback');

% button to save a single file
saveImg = uicontrol(guiFig,'Style','pushbutton','String','Save Image','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.825 .625 .14 .1]);

% button to save all of the files
saveAll = uicontrol(guiFig,'Style','pushbutton','String','Save All','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.825 .525 .14 .1]);

% button to reset gui
imgReset = uicontrol(guiFig,'Style','pushbutton','String','Reset','FontUnits','normalized','FontSize',.25,'Units','normalized','Position',[.825 .425 .14 .1],'callback','ClickedCallback','Callback',{@resetImg});

% listbox containing names of active files
listLab = uicontrol(guiFig,'Style','text','String','Selected Images: ','FontUnits','normalized','FontSize',.2,'HorizontalAlignment','left','Units','normalized','Position',[.8 .3 .15 .1]);
imgList = uicontrol(guiFig,'Style','listbox','BackgroundColor','w','Max',1,'Min',0,'Units','normalized','Position',[.8 .1 .19 .25]);

    
% callback function for imgOpen button (loads images)
    function getFile(imgOpen,eventdata)

        [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','off');

        filePath = fullfile(pathName,fileName);
        img = imread(filePath);
        info = dir(filePath);
        sliceSize = size(img,1)*size(img,2);
        stackSize = info.bytes;
        slices = round(stackSize/sliceSize);
        names = cell(1,slices);
        imgStack = cell(length(slices),1);
        for bb = 1:slices
            tempi = imread(filePath,bb);
            names{bb} = strcat(num2str(bb),'_',fileName);
            imgStack{bb}(:,:,:,:) = tempi; 
        end
        setappdata(imgOpen,'img',imgStack)
        set(imgList,'String',names)
        set(imgList,'Callback',{@showImg})
        displayImg(imgStack{1},imgPanel)
        set(saveImg,'Callback',{@saveOne})
        set(saveAll,'Callback',{@savemAll})
        set(makeROI,'Callback',{@fillROI})
    end

% callback function for the imgList listbox
    function showImg(imgList,eventdata)
        img = getappdata(imgOpen,'img');
        index = get(imgList,'Value');
        imgPanel = uipanel(guiFig,'Units','normalized','Position',[.035 .05 .75 .9]);
        displayImg(img{index},imgPanel)
    end

% function for displaying images in output panel
    function displayImg(img,panel)
            left = (width - round(size(img,2)/2))/2;
            bottom = (height -  round(size(img,1)/2))/2;
            imgAx = axes('parent',imgPanel,'Units','pixels','Position',[left bottom-10 (width-2*left) (height-2*bottom)]);
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

% callback function for saving a single image
    function saveOne(saveImg,eventdata)
        [fileName pathName] = uiputfile;
        idx = get(imgList,'Value');
        img = getappdata(imgOpen,'img');
        names = get(imgList,'String');
        imwrite(img{idx},fullfile(pathName,fileName));
    end

% callback function for saving all of the images
    function savemAll(saveAll,eventdata)
        pathName = uigetdir;
        imgs = getappdata(imgOpen,'img');
        names = get(imgList,'String');
        for aa = 1:length(imgs)
            imwrite(imgs{aa},fullfile(pathName,names{aa}));
        end
    end

% callback function for ROI creation
    function fillROI(makeROI,eventdata)
        J = roifill;
        displayImg(J,imgPanel)
        img = getappdata(imgOpen,'img');
        ind = get(imgList,'Value');
        img{ind} = J;
        setappdata(imgOpen,'img',img)
    end
        
    function resetImg(imgReset,eventdata)
        CurvePrep
    end
        
end