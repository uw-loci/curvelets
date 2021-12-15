function bioFormatsMatlabGUI
clear,clc, home, close all
addpath(genpath(fullfile('C:/Users/sabri/Documents/GitHub/curvelets/bfmatlab-6.7.0')));

% define the font size used in the GUI
fz1 = 9 ; % font size for the title of a panel
fz2 = 10; % font size for the text in a panel
fz3 = 12; % font size for the button
fz4 = 14; % biggest fontsize size

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
voxelSizeXdouble = 1; % 
voxelSizeYdouble = 1;
I = [];
BFcontrol = struct('imagePath','','imageName','','seriesCount',1,'nChannels',1,...
    'nTimepoints',1,'nFocalplanes',1,'colormap','gray','iseries',1,'ichannel',1,...
    'iTimepoint',1,'iFocalplane',1);
BFobjects = cell(1,4); %{'Series','Channel','Timepoint','Focalplane'};
%initialize the axes for BF visualization
axVisualization = '';
sliderObjects = cell(1,4);

% Create figure window
fig = uifigure('Position',[100 100 500 390]);
fig.Name = "bfGUI";
% fig.UserData = struct("ff",'',"r",'',"Img",'',"ImgData",[]);

% Manage app layout
main = uigridlayout(fig);
main.ColumnWidth = {250,250};
main.RowHeight = {110,110,120};

% Create UI components
lbl_1 = uilabel(main,'Position',[100 450 50 20],'Text','Import','FontSize',14,'FontWeight','bold');
lbl_1.Layout.Row = 1;
lbl_1.Layout.Column = 1;
btn_1 = uibutton(fig,'push','Position',[100 320 50 20],'Text','Load',...
    'ButtonPushedFcn',@import_Callback);

% down sampling option temporarily disable 
% ds = uidropdown(fig,'Position',[100 280 100 20]);
% ds.Items = ["Sampling 1" "Sampling 2" "Sampling 3"];

lbl_2 = uilabel(main,'Text','Export','FontSize',14,'FontWeight','bold');
lbl_2.Layout.Row = 2;
lbl_2.Layout.Column = 1;
ss = uidropdown(fig,'Position',[100 220 120 20], 'ValueChangedFcn',@save_Callback);
ss.Items = [,"Regular" "MATLAB readable" "Metadata"];
btn_2 = uibutton(fig,'Position',[100 170 50 20],'Text','Save','ButtonPushedFcn',@export_Callback);

lbl_3 = uilabel(main);
lbl_3.Text = 'Info';
lbl_3.Layout.Row = 3;
lbl_3.Layout.Column = 1;
tarea = uitextarea(main);
tarea.Layout.Row = 3;
tarea.Layout.Column = 1;
tarea.Value= 'This area displays info';


lbl_5 = uilabel(main,'Text','Split Windows','FontSize',14,'FontWeight','bold');
lbl_5.Layout.Row = 1;
lbl_5.Layout.Column = 2;
lbl_series = uilabel(fig,'Position',[370 360 80 20],'Text','Series');
lbl_Channel  = uilabel(fig,'Position',[370 330 80 20],'Text','Channel');
lbl_Timepoints = uilabel(fig,'Position',[370 300 80 20],'Text','Timepoints');
lbl_Focalplanes = uilabel(fig,'Position',[370 270 80 20],'Text','Focalplanes');
numField_4 = uieditfield(fig,'numeric','Position',[435 360 50 20],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_4,event) getSeries_Callback(numField_4,event));
numField_1 = uieditfield(fig,'numeric','Position',[435 330 50 20],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_1,event) getChannel_Callback(numField_1,event));
numField_2 = uieditfield(fig,'numeric','Position',[435 300 50 20],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_2,event) getTimepoints_Callback(numField_2,event));
numField_3 = uieditfield(fig,'numeric','Position',[435 270 50 20],'Limits',[0 1000],...
    'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event));
BFobjects{1} = numField_4; %series
BFobjects{2} = numField_1; % channel
BFobjects{3} = numField_2; % timepoint
BFobjects{4} = numField_3  % focoalplane;

lbl_4 = uilabel(main,'Text','Metadata','FontSize',14,'FontWeight','bold');
lbl_4.Layout.Row = 2;
lbl_4.Layout.Column = 2;
btn_3 = uibutton(fig,'Position',[350 210 130 20],'Text','Display Metadata',...
    'ButtonPushedFcn',@dispmeta_Callback);
btn_4 = uibutton(fig,'Position',[350 180 150 20],'Text','Display OME-XML Data'...
    ,'ButtonPushedFcn',@disOMEpmeta_Callback);

% ,'Text','Channels''Text','Timepoints','Focal Planes'

lbl_6 = uilabel(main,'Text','View','FontSize',14,'FontWeight','bold');
lbl_6.Layout.Row = 3;
lbl_6.Layout.Column = 2;
scaleBar = uilabel(fig,'Position',[330 80 120 20],'Text','Scale Bar Ratio');
% 'ValueChangedFcn', @(barWidth,event)
barWidth = uieditfield(fig,'numeric','Position', [420 80 50 20],'Limits',[1 30],...
     'Value', 1, 'ValueChangedFcn', @dispSplitImages);
 
% color map options
color = uidropdown(fig,'Position',[330 50 120 20]); 
color.Items = ["Default Colormap" "MATLAB Color: JET" "MATLAB Color: Gray"];

% ok button [horizonal vertical element_length element_height]
btnOK = uibutton(fig,'Position',[360 10 60 20],'Text','OK','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@return_Callback);
% cancel button 
btnCancel = uibutton(fig,'Position',[430 10 60 20],'Text','Cancel','BackgroundColor','[0.4260 0.6590 0.1080]','ButtonPushedFcn',@exit_Callback);
%% Create the function for the import callback
    function  import_Callback(hObject,Img,eventdata,handles)
%         [seriesCount,nChannels,nTimepoints,nFocalplanes]
        [fileName pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg;*.svs';'*.*'},'File Selector','MultiSelect','on');
        if isequal(fileName,0)
            disp('User selected Cancel')
        else
            disp(['User selected ', fullfile(pathName,fileName)])
        end
%         imageList = dir([imageFolder '*.*']);
%         for i = 1:length(imageList)
%             fprintf('image %d: %s \n', i, imageList(i).name);
%         end
%     lastParamsGlobal = load('currentP_CA.mat');
%     pathNameGlobal = lastParamsGlobal.pathNameGlobal;
%     keepValGlobal = lastParamsGlobal.keepValGlobal;
%     distValGlobal = lastParamsGlobal.distValGlobal;
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
        
        cellArrayText{1} = sprintf('%s : %s', 'Filename', fileName)
        cellArrayText{2} = sprintf('%s : %d', 'Series', seriesCount)
        cellArrayText{3} = sprintf('%s : %d', 'Channel', nChannels)
        cellArrayText{4} = sprintf('%s : %d', 'TimePoints', nTimepoints)
        cellArrayText{5} = sprintf('%s : %d', 'Focal Planes', nFocalplanes)
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
        BFcontrol.colormap = 'gray';
        BFcontrol.iSeries = 1; numField_4.Value =   BFcontrol.iSeries;
        BFcontrol.iChannel = 1; numField_1.Value = BFcontrol.iChannel;
        BFcontrol.iTimepont = 1; numField_2.Value = BFcontrol.iTimepoint;
        BFcontrol.iFocalplane = 1; numField_3.Value = BFcontrol.iFocalplane;
        [axVisualization, sliderObjects] = BFinMatlabFigureSlider(BFcontrol,BFobjects);
  
%         omeMeta = Img{1, 4};
%         omeXML = char(omeMeta.dumpXML());
    end

%% get channel
    function getChannel_Callback(numField_1,event)
        valList{1} = event.Value;
        sprintf('%s : %d', 'User entered:', valList{1});
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
    end
%% get series 
    function getSeries_Callback(numField_4,event)      
        valList{4} = event.Value; 
        sprintf('%s : %d', 'User entered:', valList{4});
    end
%% 
    function dispmeta_Callback(src,eventdata)
        iSeries = valList{4};
        d = uiprogressdlg(fig,'Title','Reading Original Metadata',...
        'Indeterminate','on','Cancelable','on');
%     omeMeta = reader.getMetadataStore();
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
%                 fig_2 = uifigure;
%                 uit = uitextarea(fig_2,'Value', cellOMEText);
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
%             omeMeta = ImgData{1, 4}; 
            omeMeta = r.getMetadataStore();
            stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
            stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
            stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
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
            cellArrayText{1} = sprintf('%s : %d', 'Pixel X', voxelSizeXdouble)
            cellArrayText{2} = sprintf('%s : %d', 'Pixel Y', voxelSizeYdouble)
            cellArrayText{3} = sprintf('%s : %d', 'image width', stackSizeX)
            cellArrayText{4} = sprintf('%s : %d', 'image height', stackSizeY)
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
                cellArrayText{1} = sprintf('%s : %d', 'Pixel X', voxelSizeXdouble)
                cellArrayText{2} = sprintf('%s : %d', 'Pixel Y', voxelSizeYdouble)
                tarea.Value = cellArrayText; 
                fprintf(omeXML)
                close(d)
            end

        end
    end
%% function dispSplitImages(hObject,src,eventData,handles)
    function dispSplitImages(barWidth,event)
%     BFcontrol.imageName = imageList{3};
%     BFcontrol.seriesCount = 1;
%     BFcontrol.nChannels = 2;
%     BFcontrol.nTimepoints = 72;
%     BFcontrol.nFocalplanes = 1;
%     BFcontrol.colormap = 'gray'; 
%     BFcontrol.iSeries = 1;
%     BFcontrol.iChannel = 1;
%     BFcontrol.nTimepont = 1;
%     BFcontrol.nFocalplane = 1;
        if ~isempty(event)
            width = event.Value;
        else 
            width = 10;
        end
        r.setSeries(valList{4} - 1);
        iSeries = valList{4}; 
        iZ = valList{3};
        iT = valList{2};
        iC= valList{1};
%         seriesCount,nChannels,nTimepoints,nFocalplanes = @import_Callback; 
%         stackSizeX,stackSizeY,stackSizeZ,voxelSizeXdouble = @disOMEpmeta_Callback; 
        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
        
        I = bfGetPlane(r, iPlane);
        [row, col, ~] = size(I);
%         interpolationwidth = 1;
%          figure, imagesc(I);daspect([1 1 1]);
        BFfigure = findobj(0,'Tag','BF-MAT figure');
%        BFfigureAX = findobj(0,'Tag','BF-MAT figureAX');
       figure(BFfigure); 
       imagesc(I,'Parent',axVisualization);
       axis image equal
       drawnow;
       if 1

       x = [col-width/voxelSizeXdouble, col];
%        stackSizeX/width 10/0.33
%         x = [col-(voxelSizeXdouble*(stackSizeX*width)), col];
        y = round([row*.95, row*.95]);
        hold on;
        line(x,y,'LineWidth',2,'Color','w','Parent',axVisualization);
        text(x(1),round(row*.90),[num2str(round(width)) '\mum'],'FontWeight','bold','FontSize', 8,'Color','w');
        figureTitle = sprintf('%dx%dx%d pixels, Z=%d/%d,  Channel= %d/%d, Timepoint=%d/%d,pixelSize=%3.2f um, Series =%d/%d',...
          stackSizeX,stackSizeY,stackSizeZ,iZ,nFocalplanes,iC,nChannels,iT,nTimepoints,voxelSizeXdouble,iSeries,seriesCount);
        title(figureTitle,'FontSize',10,'Parent',axVisualization);
        axis image equal
        hold off
        drawnow;        
       end
       
    end
%% 
    function execute_Callback(src,event)
        %         dispSplitImages
        fig_1 = uifigure('Position',[500 600 400 200]);
        slider1 = uislider(fig_1,'position',[200 110 110 3]);
        lbl_Focalplanes = uilabel(fig_1,'Position',[30 100 80 20],'Text','Focalplanes');
        numField_Focalplanes = uieditfield(fig_1,'numeric','Position',[115 100 50 20],'Limits',[1 nFocalplanes],...
            'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event,slider1));
        
        slider2 = uislider(fig_1,'position',[200 180 110 3]);
        lbl_Channels = uilabel(fig_1,'Position',[30 120 80 20],'Text','Focalplanes');
        numField_Channels = uieditfield(fig_1,'numeric','Position',[115 100 50 20],'Limits',[1 nChannels],...
            'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event,slider1));
        
        slider3 = uislider(fig_1,'position',[200 250 110 3]);
        lbl_Timepoints = uilabel(fig_1,'Position',[30 100 80 20],'Text','Focalplanes');
        numField_Timepoints = uieditfield(fig_1,'numeric','Position',[115 100 50 20],'Limits',[1 nTimepoints],...
            'Value', 1,'ValueChangedFcn',@(numField_3,event) getFocalPlanes_Callback(numField_3,event,slider1));
        
        %for Focalplanes
        nMajorTickLabels = min(5,nFocalplanes);
        MajorTickLabelsValue = [1:floor(nFocalplanes/nMajorTickLabels):nFocalplanes];
        set(slider1,'Limits',[1 nFocalplanes],'MajorTickLabelsMode','auto',...
            'MajorTicks',MajorTickLabelsValue,'MinorTicksMode','manual',...
            'ValueChangedFcn',@(slider1,event) slideMoving(slider1,numField_3));
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
                %E:\Studying\LOCI\BF-testImages
            case 'MATLAB readabl' 
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

%% visualization function
    function BFvisualziation(BFcontrol,axVisualization)
        r.setSeries(valList{4} - 1);
        iSeries = valList{4};
        iZ = valList{3};
        iT = valList{2};
        iC= valList{1};
        iPlane = r.getIndex(iZ - 1, iC -1, iT - 1) + 1;
        I = bfGetPlane(r, iPlane);
        BFfigure = findobj(0,'Tag','BF-MAT figure');
        figure(BFfigure);
        imagesc(I,'Parent',axVisualization);
        axis image equal
        drawnow;      
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

