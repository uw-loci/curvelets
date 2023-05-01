classdef autoThreshGUI < handle
    % GUI class for the auto-threshold module
    
    properties
        thefig
        operationsPanel
        ImageInfoPanel
        ImageInfoTable
        methodListPanel
        outputTabGroup
        tab_original
        tab_autothreshold
        UIAxes_original
        UIAxes_autothreshold
        msgWindowPanel
        msgWindow
        runButton
        loadButton
        resetButton
        closeButton
        darkObjectCheck
        convTo8BitCheck
        methodList
        resultTable
        resultImg
        img
        autoThreshController
        model
        handles
        controllerGUI
        UIAxes
        lastPATHname
    end
    
    
    methods
        %% Constructor
        function obj = autoThreshGUI(varargin)
            if isempty(varargin)
                obj.controllerGUI = '';
            else
                obj.controllerGUI= varargin{2};
            end
%             if isa(varargin{1}, 'autoThreshController');    obj.autoThreshController = varargin{1}; end
%             obj.model = obj.autoThreshController.autoThreshModel;
            %Get the actual screen size in pixels
            set(0,'units','pixels');
            ssU = get(0,'screensize'); % screen size of the user's display
            fig_width = 900;
            fig_height = 600;

%% import data from lastPATH_AT if it exists
            if exist('lastPATH_AT.mat','file')
                obj.lastPATHname = importdata('lastPATH_AT.mat');
                if isequal(obj.lastPATHname,0)
                    obj.lastPATHname = '';
                end
            else
            %use current directory
                obj.lastPATHname = '';
            end
           
            obj.thefig = uifigure('Position',[ssU(3)/20 ssU(4)-fig_height-100 fig_width fig_height],...
                'MenuBar','none',...
                'NumberTitle','off',...
                'Name','Auto Threshold Module for CurveAlign','Tag','autothreshold_gui');

            set(obj.thefig,'CloseRequestFcn',@(src,event) onclose(obj,src,event))

            gap2Top = 20;  % gap between top panel and the figure top edge 
            gap2Bottom = gap2Top; 
            gap2Side = 20;
            spaceBetweenPanels = 15;

            leftPanelWidth = 200;
            upperleftPanelHeight = 160;
            xStart_upperleftpanel = 20;
            yStart_upperleftpanel = fig_height-gap2Top-upperleftPanelHeight;
            buttonHeight = upperleftPanelHeight/4;
            buttonWidth = leftPanelWidth/3;
            
            obj.operationsPanel = uipanel(obj.thefig,...
                'Position',[ xStart_upperleftpanel  yStart_upperleftpanel leftPanelWidth  upperleftPanelHeight],...
                'Title','Operations');
            obj.loadButton = uibutton(obj.operationsPanel,...
                'Position',[0.1*leftPanelWidth 0.5*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Open','Enable','on',...
                'Tag','loadButton',...
                'Tooltip','Open an image from your files',...
                'ButtonPushedFcn',{@(src,event) loadImage(obj,src,event)});
            %                 'Callback',@(handle,event) loadImage(obj,handle,event),...
            
            obj.runButton = uibutton(obj.operationsPanel,...
                'Position',[0.6*leftPanelWidth 0.5*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Run','Enable','off',...
                'Tooltip','Run the selected thresholding method on the original image',...
                'ButtonPushedFcn',{@(src,event) runThresholding_Callback(obj,src,event)});
            
            obj.resetButton = uibutton(obj.operationsPanel,...
                'Position',[0.10*leftPanelWidth 0.1*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Reset','Enable','off',...
                'Tooltip','Restart the Auto Threshold Module',...
                'ButtonPushedFcn',{@(src,event) resetImage(obj,src,event)});

           obj.closeButton = uibutton(obj.operationsPanel,...
                'Position',[0.60*leftPanelWidth 0.1*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Close',...
                'Tooltip','Close the Auto Threshold Module',...
                'ButtonPushedFcn',{@(src,event) closeApp_Callback(obj,src,event)});
%             'Value','ImgPath' from Model
            leftPanelWidth = 200;
            lowerleftPanelHeight = 300;
            xStart_lowerleftpanel = 20;
            yStart_lowerleftpanel = 75;
            obj.ImageInfoPanel = uipanel(obj.thefig,...
                'Position',[ xStart_lowerleftpanel  yStart_lowerleftpanel leftPanelWidth  lowerleftPanelHeight],...
                'Title','Image Information');
            
            obj.ImageInfoTable = uitable(obj.ImageInfoPanel,...
                'Position',[0 0 leftPanelWidth  lowerleftPanelHeight-20],'ColumnName',{'Property','Value'}, 'RowName','',...
                'ColumnWidth',{80 leftPanelWidth-80},...
                'Data',{'Name','';'Path','';'Width','';'Height','';'BitDepth','';'ColorType','';'No.Slices',[];'CurrentSlice',[]},...
                'Multiselect', 'off','DisplayDataChangedFcn',{@(src,event) tableChanged_Callback(obj,src,event)});
                %'SelectionType', 'row','Enable','off',...
      %          'CellSelectionCallback', @UITableCellSelection_Callback);

            %two checkboxes below the lower left panel
            checkBoxWidth = 120;
            checkBoxHeight = 20;
            obj.darkObjectCheck = uicheckbox(obj.thefig,...
                'Position',[gap2Side gap2Bottom+checkBoxHeight checkBoxWidth checkBoxHeight],...
                'Enable','off',...
                'Tooltip','Invert the whites and blacks of the image',...
                'Text','Dark Object','ValueChangedFcn',{@(src,event) darkObjectCheck_Callback(obj,src,event)});
            
            obj.convTo8BitCheck = uicheckbox(obj.thefig,...
                'Position',[gap2Side gap2Bottom checkBoxWidth checkBoxHeight],...
                'Enable','off',...
                'Text','Convert to 8-bit','ValueChangedFcn',{@(src,event) convTo8BitCheck_Callback(obj,src,event)});
            

     % two middle panels  

            middlePanelWidth = 200;
            lowermiddlePanelHeight = 300;
            xStart_lowermiddle =  xStart_lowerleftpanel + leftPanelWidth+spaceBetweenPanels; 
            yStart_lowermiddle = gap2Bottom;
            %lower middle panel
            obj.msgWindowPanel = uipanel(obj.thefig,...
                'Position',[xStart_lowermiddle yStart_lowermiddle middlePanelWidth lowermiddlePanelHeight],...
                'Title','Message Window');
            obj.msgWindow = uitextarea(obj.msgWindowPanel,...
                'Position',[0 0 middlePanelWidth lowermiddlePanelHeight-20],'Value','');
           %upper middle panel
           yStart_uppermiddle = yStart_lowermiddle+lowermiddlePanelHeight+spaceBetweenPanels;
           obj.methodListPanel = uipanel(obj.thefig,...
                'Position',[xStart_lowermiddle yStart_uppermiddle, middlePanelWidth fig_height-yStart_uppermiddle-gap2Top],...
                'Title','Thresholding Methods'); 

            %autoThreshModel.thresholdOptions_List = {'1 Global Otsu Method','2 Ridler-Calvard (ISO-data) Cluster Method',...
%             '3 Kittler-Illingworth Cluster Method','4 Kapur Entropy Method',...
%             '5 Local Otsu Method','6 Local Sauvola Method','7 Local Adaptive Method','8 all'};
            if isempty (varargin)
                thresholdOptions_List = {'Global Otsu Method','Ridler-Calvard (ISO-data) Cluster Method',...
                    'Kittler-Illingworth Cluster Method','Kapur Entropy Method',...
                    'Local Otsu Method','Local Sauvola Method','Local Adaptive Method'};
            else
                thresholdOptions_List = obj.controllerGUI.autoThreshModel.thresholdOptions_List;
            end
            obj.methodList = uilistbox(obj.methodListPanel,...
                'Position',[0 0 middlePanelWidth fig_height-yStart_uppermiddle-gap2Top*2],...
                'Items',thresholdOptions_List,...
                'ValueChangedFcn', @(src,evnt)methodList_Callback(obj,src,evnt));

%          'ValueChangedFcn', @updateLocalFlag ->pass the flag to
%          controller->controller pass to function->pass back the image and
%          diaplay on uiimage/uitable
           resultTableWidth = fig_width - leftPanelWidth - middlePanelWidth - gap2Side*2-spaceBetweenPanels*2;
           resultTableHeight = fig_height/3;
           xStart_resultTable = xStart_lowermiddle+ middlePanelWidth+spaceBetweenPanels;
           yStart_resultTable = fig_height-gap2Top-resultTableHeight;
           obj.resultTable = uitable(obj.thefig,...
                'Position',[xStart_resultTable yStart_resultTable resultTableWidth resultTableHeight],...
            'ColumnName',{'Method','Threshold'},'ColumnWidth',{resultTableWidth*0.75 resultTableWidth*0.25},'RowName','');

           %image tabs
           outputTabWidth = resultTableWidth;
           outputTabHeight = fig_height-gap2Top-gap2Bottom-spaceBetweenPanels-resultTableHeight;
           xStart_outputTab = xStart_resultTable;
           yStart_resultTable = gap2Bottom;
           obj.outputTabGroup = uitabgroup(obj.thefig,'Position',[xStart_outputTab yStart_resultTable outputTabWidth outputTabHeight]);
           obj.tab_original = uitab(obj.outputTabGroup,'Title','Original');
           %UIAxes_Original
           UIAxesWidth = 0.9*outputTabHeight;
           UIAxesHeight = UIAxesWidth;
           xStart_UIAxes = (outputTabWidth-UIAxesWidth)/2;
           yStart_UIAxes = (outputTabHeight-UIAxesHeight-20)/2;
           obj.UIAxes_original = uiaxes(obj.tab_original,'Position',[xStart_UIAxes yStart_UIAxes UIAxesWidth UIAxesHeight]);
           axis(obj.UIAxes_original,'equal');
           if isempty(obj.ImageInfoTable.Data{1,2}) % no image is opened
               imageHeight = round(0.8*outputTabHeight);
               imageWidth = imageHeight;
               imagesc(zeros(imageHeight,imageWidth),'Parent', obj.UIAxes_original);
               axis(obj.UIAxes_original,'equal');
               colormap(obj.UIAxes_original,"gray")
               text(0.2*imageWidth,0.5*imageHeight,'Raw image displays here','Color','r','FontSize',15,'Parent',obj.UIAxes_original)
           end
        
             %UIAxes_autothreshold
           obj.tab_autothreshold = uitab(obj.outputTabGroup,'Title','Thresholded');
           obj.UIAxes_autothreshold = uiaxes(obj.tab_autothreshold,'Position',[xStart_UIAxes yStart_UIAxes UIAxesWidth UIAxesHeight]);
           if isempty(obj.resultTable.Data)
               imageHeight = round(0.8*outputTabHeight);
               imageWidth = imageHeight;
               imagesc(zeros(imageHeight,imageWidth),'Parent', obj.UIAxes_autothreshold);
               axis(obj.UIAxes_autothreshold,'equal');
               colormap(obj.UIAxes_autothreshold,"gray")
               text(0.05*imageWidth,0.5*imageHeight,'Thresholded image displays here','Color','r','FontSize',15,'Parent',obj.UIAxes_autothreshold)
           end
            
            obj.handles = guihandles(obj.thefig);
        end % constructor
        
        % --- Loads the image from Model.
%         function loadImage(obj,handle,event)
%             obj.Img = obj.model.Img; 
%         end
% callback function for Run button
function runThresholding_Callback(obj,~,~)
    obj.controllerGUI.autoThreshModel.myPath = fullfile(obj.ImageInfoTable.Data{2,2},obj.ImageInfoTable.Data{1,2});
    stackValue = obj.ImageInfoTable.Data{8,2};
    [thresh, I] = obj.controllerGUI.autoThreshModel.AthreshInternal(stackValue);
    obj.resultTable.Data = {obj.methodList.Value,thresh};
    imagesc(I,'Parent',obj.UIAxes_autothreshold);
    xlim(obj.UIAxes_autothreshold,[0  obj.ImageInfoTable.Data{3,2}]); % width
    ylim(obj.UIAxes_autothreshold,[0  obj.ImageInfoTable.Data{4,2}]); % height
    colormap(obj.UIAxes_autothreshold,"gray")
end
        
% reset the parameters from Model.
function resetImage(obj,~,~)
    %initializes the function again
    h = findall(0,'Type','figure','Tag','autothreshold_gui');
    if ~isempty(h)
        delete(h)
    end
    ATmodel = autoThreshModel();     % initialize the model
    ATcontroller = autoThreshController(ATmodel);  % initialize controller
end

%% callback function for Close button
function closeApp_Callback(obj,~,~)
    delete(obj.thefig)
end

        
        %% If someone closes the figure than everything will be deleted !
        function onclose(obj,src,~)
            disp('Closing Auto Threshold module');
            delete(obj) % instance of autoThreshGUI 
            delete(src) %figure (autoThresh_gui) with properties
        end
        
        %% Call back function for loading images
        function loadImage(obj,~,~)
%             imgPath_current = obj.ImageInfoTable.Data{2,2};
%             if imgPath_current == 0
%                 imgPath_current = './';
%             end
            [fileName, pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg';'*.*'},'Select Image',obj.lastPATHname,'MultiSelect','off');
            
            if isequal(fileName, 0)
                obj.msgWindow.Value = [obj.msgWindow.Value;{'NO image is opened'}];
                obj.runButton.Enable = 'off';
                obj.resetButton.Enable = 'off';
            else
                obj.lastPATHname = pathName;
                lstPATHname = obj.lastPATHname;
                save('lastPATH_AT.mat','lstPATHname');
                obj.ImageInfoTable.Data{1,2} = fileName;
                obj.ImageInfoTable.Data{2,2} = pathName;
                imageinfoStruc = imfinfo(fullfile(pathName,fileName));
                numberSlices = size(imageinfoStruc,1);
                if numberSlices> 1 % if user selected image is a stack image
                    %Allow only column 2 of the image info table to be editable, thereby allowing the
                    %user to change the stack number
                    obj.ImageInfoTable.Enable = 'on';
                    set(obj.ImageInfoTable, 'ColumnEditable', true(1,2))
                    obj.ImageInfoTable.ColumnEditable(1) = false; 
                    imageinfoStruc = imageinfoStruc(1);
                    % Set the 'Stack No' cell to be green, so the user
                    % knows they can edit it.
                    s = uistyle("BackgroundColor",[0 1 0]);
                    addStyle(obj.ImageInfoTable,s,"cell",[8,1]);
                    %Load the first stack of the image
                    Idata = imread(fullfile(pathName,fileName),1);
                    obj.msgWindow.Value = [obj.msgWindow.Value;{sprintf('Image %s is not a single image, only the first slice is opened.',fileName)}];
                    obj.msgWindow.Value = [obj.msgWindow.Value;{sprintf('You can edit the slice number (green cell) in the image info table to change between %d slices.',numberSlices)}];
                elseif numberSlices == 1 % if user selected image is not a stack image
                    %Don't allow the image info table. i.e. the user can't
                    %change the stack no.
                    obj.ImageInfoTable.Enable = 'off';
                    Idata = imread(fullfile(pathName,fileName));
                else
                    error('Number of slices must be an integer larger than 0')
                end
                obj.ImageInfoTable.Data{3,2} = imageinfoStruc.Width;
                obj.ImageInfoTable.Data{4,2} = imageinfoStruc.Height;
                obj.ImageInfoTable.Data{5,2} = imageinfoStruc.BitDepth;
                obj.ImageInfoTable.Data{6,2} = imageinfoStruc.ColorType;
                obj.ImageInfoTable.Data{7,2} = numberSlices;
                obj.ImageInfoTable.Data{8,2} = 1;
                fprintf('Opening %s \n', fullfile(pathName,fileName));
%                 I3 (:,:,1)=Idata;
%                 I3 (:,:,2)=Idata;
%                 I3 (:,:,3)=Idata;
%                 obj.resultImg.ImageSource = I3;
                obj.UIAxes_original.NextPlot = 'replace'; 
                imagesc(Idata,'Parent',obj.UIAxes_original);
                xlim(obj.UIAxes_original,[0 imageinfoStruc.Width]);
                ylim(obj.UIAxes_original,[0 imageinfoStruc.Height]);
                axis(obj.UIAxes_original,'equal');
                colormap(obj.UIAxes_original,"gray")
%                  obj.resultImg.ImageSource = fullfile(obj.imgPath.Value{1},obj.ImageInfoTable.Value{1});
%                  imwrite(Idata,'tempPNG.png');
%                  obj.resultImg.ImageSource = 'tempPNG.png';
                obj.msgWindow.Value = [obj.msgWindow.Value;{sprintf('Image %s is opened',fileName)}];
                if imageinfoStruc.BitDepth == 1
                    obj.msgWindow.Value = [obj.msgWindow.Value;{'This image can not be thresholded as the bit depth of this image is 1.'}];
                    obj.runButton.Enable = 'off';
                    return
                  elseif imageinfoStruc.BitDepth == 8
                    obj.msgWindow.Value = [obj.msgWindow.Value;{'No image type converison is needed for this 8-bit image.'}];
                    obj.convTo8BitCheck.Enable = 'off';
                elseif imageinfoStruc.BitDepth > 8
                     obj.msgWindow.Value = [obj.msgWindow.Value;{'Bit depth is larger than 8. 8-bit conversion is preferred.'}];
                     obj.convTo8BitCheck.Enable = 'on';
                end
                % when a new image is opened, initialize the autothreshold
                % tab;
               imageWidth = obj.ImageInfoTable.Data{3,2};
               imageHeight = obj.ImageInfoTable.Data{4,2};
               imagesc(zeros(imageHeight,imageWidth),'Parent', obj.UIAxes_autothreshold);
               xlim(obj.UIAxes_autothreshold,[0  imageWidth]); % width
               ylim(obj.UIAxes_autothreshold,[0  imageHeight]); % height
               axis(obj.UIAxes_autothreshold,'equal');
               colormap(obj.UIAxes_autothreshold,"gray")
               text(0.05*imageWidth,0.5*imageHeight,'Thresholded image displays here','Color','r','FontSize',15,'Parent',obj.UIAxes_autothreshold)

               obj.runButton.Enable = 'on';
               obj.resetButton.Enable = 'on';
            end
            obj.darkObjectCheck.Enable = 'on';
            obj.darkObjectCheck.Value = 0;
        end
        
        %% When the user changes the selected slice number in the image info table for stack images
        function tableChanged_Callback(obj,src,event)
            % get the total number of slices of the image, and set the
            % stack limits of the image to be and the total # of slices
            numberofSlices = src.DisplayData(7,2); 
            sliceLimits = [1,numberofSlices{1}];
            currentSliceNo = src.DisplayData(8,2);
            % get the values in the image info table
            tableData = get(src,'data');
            if currentSliceNo{1} > sliceLimits(2) % if user entered a slice number greater than the total # slices of the image
                currentSliceNo{1} = sliceLimits(2);
                tableData(8,2) = currentSliceNo;
                obj.msgWindow.Value = [obj.msgWindow.Value;{sprintf('There are only %.0f slices.', sliceLimits(2))}];
            elseif currentSliceNo{1} < sliceLimits(1) % if user entered a slice number less than 1
                currentSliceNo{1} = sliceLimits(1);
                tableData(8,2) = currentSliceNo;
                obj.msgWindow.Value = [obj.msgWindow.Value;{'The slice number must be an integer greater than 1'}];
            else % user entered a valid slice number
                obj.msgWindow.Value = [obj.msgWindow.Value;{'You have changed the slice number of the image.'}];
            end
            % set the slice number value in the image info table to the valid
            % value the user entered or one of the limits if the user
            % entered an invalid value
            set(src,'data',tableData)
            % read image slice
            Idata = imread(fullfile(char(src.DisplayData(2,2)),char(src.DisplayData(1,2))),currentSliceNo{1});
            obj.UIAxes_original.NextPlot = 'replace'; 
            % display slice number on GUI
            imagesc(Idata,'Parent',obj.UIAxes_original);
            width = src.DisplayData(3,2);
            height = src.DisplayData(4,2);
            xlim(obj.UIAxes_original,[0 width{1}]);
            ylim(obj.UIAxes_original,[0 height{1}]);
            axis(obj.UIAxes_original,'equal');
            colormap(obj.UIAxes_original,"gray")
            % enable dark object functionality on the new slice
            obj.darkObjectCheck.Enable = 'on';
            obj.darkObjectCheck.Value = 0;
        end
        
        %% Checkbox to invert the whites and blacks of a selected image
        function darkObjectCheck_Callback(obj,~,evnt)
           % fprintf('%d: \n', evnt.Value)
           % check checkbox value
            darkObjectCheckFlag = evnt.Value;
            if darkObjectCheckFlag == 1 %if checkbox is checked
               % get stack value
               sliceValue = obj.ImageInfoTable.Data{8,2};
               % read image from file path and slice number
               I = imread(fullfile(obj.ImageInfoTable.Data{2,2},obj.ImageInfoTable.Data{1,2}),sliceValue);
               % display image
               imagesc(I,'Parent',obj.UIAxes_original);
               %invert colormap
               colormap(obj.UIAxes_original,flipud(gray))
               disp('Image has dark objects.')
            else
               % get stack value
               sliceValue = obj.ImageInfoTable.Data{8,2};
               I = imread(fullfile(obj.ImageInfoTable.Data{2,2},obj.ImageInfoTable.Data{1,2}),sliceValue);
               % display original image
               imagesc(I,'Parent',obj.UIAxes_original);
               colormap(obj.UIAxes_original,"gray")
               disp('Image has dark background.')
            end
            obj.controllerGUI.autoThreshModel.darkObjectCheck = darkObjectCheckFlag;
        end
        
        %% Checkbox to convert to 8-bit image
        function convTo8BitCheck_Callback(obj,~,evnt)
           % fprintf('%d: \n', evnt.Value)
           convTo8BitCheckFlag = evnt.Value; 
           if convTo8BitCheckFlag == 1
               disp('Convert to 8-bit image.')
           else
               disp('NO image format conversion.')
           end
           obj.controllerGUI.autoThreshModel.conv8bit = convTo8BitCheckFlag;

        end
        
        %% When user selects a threshold method
        function methodList_Callback(obj,~,evnt)
            fprintf('%s: \n', evnt.Value)
            numberofMethods = length(obj.controllerGUI.autoThreshModel.thresholdOptions_List);
            selectedMethod = evnt.Value;
            for i = 1:numberofMethods
                if strcmp(selectedMethod,obj.controllerGUI.autoThreshModel.thresholdOptions_List{i})
                    obj.controllerGUI.autoThreshModel.flag = i;
                    break
                end
            end
            fprintf('Selected thresholding method is: %s \n',selectedMethod);
%             if isempty(obj.imgPath.Value)
%                 obj.imgPath.Value = './';
%                 obj.ImageInfoTable.Value = 'atuoTimg.tif';
%             end
%             obj.controllerGUI.autoThreshModel.myPath = fullfile(obj.imgPath.Value{1},obj.ImageInfoTable.Value{1});
%            [thresh, I] = obj.controllerGUI.autoThreshModel.AthreshInternal;
%             imwrite(I,'autoTimg.png');
%             obj.resultTable.Data = {evnt.Value,thresh};
%             obj.resultImg.ImageSource = 'autoTimg.png';
        end
      
        
    end
    
  
end

