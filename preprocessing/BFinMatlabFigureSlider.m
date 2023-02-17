%%
function [imgAx, sliderObjects]= BFinMatlabFigureSlider(BFcontrol,BFobjects)
%visualize the image read by Bio-Formats(BF) with or without slider(s)
%input argument BFcontrol
if nargin == 0 % hard wired parameters which should be passed from the BF GUI
    BFcontrol.imagePath = '../../BF-testImages/';  %path to image folder
    imageList = {'SHG.tif','stackforBF2.tif','Cell_2.tif','2B_D9_ROI1.tif','Aperio.svs'};
    %test images can be downloaded from here: https://drive.google.com/drive/folders/1bH_cTVHNk3bONCoYEXT_sRHNmoV3hZZj?usp=sharing
    BFcontrol.imageName = imageList{3};
    BFcontrol.seriesCount = 1;
    BFcontrol.nChannels = 2;
    BFcontrol.nTimepoints = 72;
    BFcontrol.nFocalplanes = 1;
    BFcontrol.colormap = 'gray'; 
    BFcontrol.iSeries = 1;
    BFcontrol.iChannel = 1;
    BFcontrol.iTimepoint = 1;
    BFcontrol.iFocalplane = 1;
else % from BF MATLAB interface
    %use a structure variable "BFcontrol" to include all the parameters
    %needed to create the matlab BF figure window.
    BFobjects{5}.Value = 0;  % if slider is used,do not merge channels
end


%delete the exist BF-MAT figure 
BFfigure = findobj(0,'Tag','BF-MAT figure');
if ~isempty(BFfigure)
   delete(BFfigure); 
end
%initialize the slider current value
iSeries = BFcontrol.iSeries;
iChannel = BFcontrol.iChannel;
iTimepoint = BFcontrol.iTimepoint;
iFocalplane = BFcontrol.iFocalplane;

fullPath2image = fullfile(BFcontrol.imagePath,BFcontrol.imageName);
sliderName = {'Series','Channel','Timepoint','Focalplane'};
sliderObjects = cell(1,4);
maxSlider = [BFcontrol.seriesCount BFcontrol.nChannels BFcontrol.nTimepoints BFcontrol.nFocalplanes]; % maximum value of each slider
flagSlider = [0 0 0 0]; % flags for 4 sliders for [series, channel, timepoints,
if BFcontrol.seriesCount> 1; flagSlider(1) = 1;  end% series
if BFcontrol.nChannels > 1; flagSlider(2) = 1; end % channels
if BFcontrol.nTimepoints > 1;flagSlider(3) = 1; end % time points
if BFcontrol. nFocalplanes > 1; flagSlider(4) = 1; end % focal planes

indexSlider = find(flagSlider>0);
if isempty(indexSlider)
    nSlider = 0;
    disp('No slider is needed for the dataset')
else
    nSlider = length(indexSlider);
    fprintf('Number of slider(s) to be displayed is %d \n', nSlider)
    for i = 1:nSlider
        fprintf('slider "%s" will stand for %s \n',sliderName{indexSlider(i)}(1),sliderName{indexSlider(i)});
    end
end
titleHeight = 0.025;  % normalized title height
sliderHeight = 0.025; % Normalized slider height;
imageAreaHeight = 1-titleHeight-(nSlider+1)*sliderHeight; %normalized image area size
imageAreaWidth = imageAreaHeight;
titleWidth = imageAreaWidth;
sliderWidth = imageAreaWidth;     % Normalized slider length
imageAreaX = (1-imageAreaWidth)/2;
imageAreaY = (nSlider+1)*sliderHeight;
titleX = imageAreaX+0.040;
titleY = imageAreaHeight+(nSlider+1)*sliderHeight; 

guiCtrl = figure('Position', [200 200 800 800], 'NumberTitle','off','Tag','BF-MAT figure',...
    'Name',sprintf('Bio-Formats MATLAB figure for %s:', BFcontrol.imageName));   % should be set with respect to the BF GUI position
imgPanel = uipanel('Parent', guiCtrl,'Units','normalized','Position',[0 0  1 1]);
fz1 = 10; % slider label size
fz2 = 11; % image title size

imgAx = axes('Parent',imgPanel,'YTick',[],'XTick',[],'Units','normalized',...
    'Position',[imageAreaX imageAreaY imageAreaWidth imageAreaHeight],'Tag','BF-MAT figureAX');
labelTitle = uicontrol('Parent',imgPanel,'Style','text','String',...
    BFcontrol.imageName,'Enable','on','HorizontalAlignment','left',...
    'FontSize',fz2,'Units','normalized','Position',[titleX titleY titleWidth titleHeight]);

if nSlider == 0  
    bfRederinfo = bfGetReader(fullPath2image);
    bfRederinfo.setSeries(iSeries - 1);
    iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
    I = bfGetPlane( bfRederinfo, iPlane); 
    imagesc(I,'Parent',imgAx);
    set(imgAx,'YTick',[],'XTick',[]);
    colormap(imgAx,BFcontrol.colormap);
elseif nSlider > 0
    bfRederinfo = bfGetReader(fullPath2image);
    bfRederinfo.setSeries(iSeries - 1);
    iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
    I = bfGetPlane( bfRederinfo, iPlane); 
    imagesc(I,'Parent',imgAx);
    set(imgAx,'YTick',[],'XTick',[]);
    colormap(imgAx,BFcontrol.colormap);

% create slider(s)
    sliderWidth = imageAreaWidth;
    sliderX = imageAreaX;   
    sliderLabelSize = [0.0275 0.0275];
    sliderLabelX = sliderX-sliderLabelSize(1);
    for i = 1:nSlider   % 1. Series; 2 Channel; 3 Timepoint; 4 Focalplane.
        sliderY = (nSlider-i+1)*sliderHeight;   % Y coordinate of the slider starting point;
        sliderCreated = sliderName{indexSlider(i)};
        sliderMax = maxSlider(indexSlider(i));
        sliderMin = 1;
        sliderLabelY = sliderY;                  % Y coordinate of the slider label starting point;
        if strcmp (sliderCreated, 'Series')
            sliderSeries = uicontrol('Parent',imgPanel,'Style','slide','Units',...
                'normalized','position',[sliderX sliderY sliderWidth sliderHeight],'min',1,'max',sliderMax,...
                'val',iSeries,'SliderStep', [1 1]/sliderMax,'Enable','on','Callback',{@slider_chng_img});
            sliderLabelSeries = uicontrol('Parent',imgPanel,'Style','text','String',...
                sliderCreated(1),'Enable','off',...
                'FontSize',fz1,'Units','normalized','Position',[sliderLabelX sliderLabelY/2  sliderLaberlSize]);
            sliderObjects{1} = sliderSeries;
        end
        if strcmp (sliderCreated, 'Channel')
            sliderChannel = uicontrol('Parent',imgPanel,'Style','slide','Units',...
                'normalized','position',[sliderX sliderY sliderWidth sliderHeight],'min',sliderMin,'max',sliderMax,...
                'val',iChannel,'SliderStep', [1 1]/(sliderMax-sliderMin),'Enable','on','Callback',{@slider_chng_img});
            sliderLabelFocalplane = uicontrol('Parent',imgPanel,'Style','text','String',...
                sliderCreated(1),'Enable','on',...
                'FontSize',fz1,'Units','normalized','Position',[sliderLabelX sliderLabelY sliderLabelSize]);
            sliderObjects{2} = sliderChannel;
        end
        if strcmp (sliderCreated, 'Timepoint')
            sliderTimepoint = uicontrol('Parent',imgPanel,'Style','slide','Units',...
                'normalized','position',[sliderX sliderY sliderWidth sliderHeight],'min',sliderMin,'max',sliderMax,...
                'val',iTimepoint,'SliderStep', [1 1]/(sliderMax-sliderMin),'Enable','on','Callback',{@slider_chng_img});
            sliderLabelFocalplane = uicontrol('Parent',imgPanel,'Style','text','String',...
                sliderCreated(1),'Enable','on',...
                'FontSize',fz1,'Units','normalized','Position',[sliderLabelX sliderLabelY sliderLabelSize]);
            sliderObjects{3} = sliderTimepoint; 
        end

        if strcmp (sliderCreated, 'Focalplane')
            sliderFocalplane = uicontrol('Parent',imgPanel,'Style','slide','Units',...
                'normalized','position',[sliderX sliderY sliderWidth sliderHeight],'min',sliderMin,'max',sliderMax,...
                'val',iFocalplane,'SliderStep', [1 1]/(sliderMax-sliderMin),'Enable','on','Callback',{@slider_chng_img});
            sliderLabelFocalplane = uicontrol('Parent',imgPanel,'Style','text','String',...
                sliderCreated(1),'Enable','on',...
                'FontSize',fz1,'Units','normalized','Position',[sliderLabelX sliderLabelY sliderLabelSize]);
            sliderObjects{4} = sliderFocalplane; 
        end
    end
    return
    
end


%% plot the image
% callback function for stack slider
    function slider_chng_img(hObject,eventdata)
        titleText = ''; seriesText = '';channelText = '';timepointText = '';focalplaneText = '';
        if exist('sliderSeries','var'); 
            iSeries = round(sliderSeries.Value);
            titleText = sprintf('%s S:%d/%d ',titleText,iSeries,BFcontrol.seriesCount);
            sliderObjects{1} = sliderSeries;
        end
        if exist('sliderChannel','var'); 
            iChannel = round(sliderChannel.Value);
            titleText = sprintf('%s C:%d/%d ',titleText,iChannel,BFcontrol.nChannels);
            sliderObjects{2} = sliderChannel;

        end
        if exist('sliderTimepoint','var'); 
            iTimepoint = round(sliderTimepoint.Value); 
            titleText = sprintf('%s T:%d/%d ',titleText,iTimepoint,BFcontrol.nTimepoints);
            sliderObjects{3} = sliderTimepoint;
        end
        if exist('sliderFocalplane','var'); 
            iFocalplane = round(sliderFocalplane.Value); 
            titleText = sprintf('%s F:%d/%d ',titleText,iFocalplane,BFcontrol.nFocalplanes);
            sliderObjects{4} = sliderFocalplane;
        end
        bfRederinfo = bfGetReader(fullPath2image);
        bfRederinfo.setSeries(iSeries - 1);
        iPlane =  bfRederinfo.getIndex(iFocalplane- 1, iChannel-1, iTimepoint-1) + 1;
        I = bfGetPlane( bfRederinfo, iPlane); 
        
        imagesc(I,'Parent',imgAx);
        set(labelTitle,'String',titleText);
        set(imgAx,'YTick',[],'XTick',[]);
        colormap(imgAx,BFcontrol.colormap);
        axis image
        drawnow
        %update the uieditfield in main GUI
        BFobjects{1}.Value = iSeries;
        BFobjects{2}.Value = iChannel;
        BFobjects{3}.Value = iTimepoint;
        BFobjects{4}.Value = iFocalplane;
        BFobjects{5}.Value = 0;
        return
        
    end
end