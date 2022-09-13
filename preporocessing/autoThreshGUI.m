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
        UIAxes_autothrehold
        msgWindow
        runButton
        loadButton
        resetButton
        closeButton
        blackBackgroundCheck
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
           

            obj.thefig = uifigure('Position',[ssU(3)/20 ssU(4)-fig_height-100 fig_width fig_height],...
                'MenuBar','none',...
                'NumberTitle','off',...
                'Name','Auto Threshold App','Tag','autothreshold_gui');

            set(obj.thefig,'CloseRequestFcn',@(src,event) onclose(obj,src,event))

            gap2Top = 20;  % gap between top panel and the figure top edge 
            gap2Bottom = gap2Top; 
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
                'Text','Open',...
                'Tag','loadButton','ButtonPushedFcn',{@(src,event) loadImage(obj,src,event)});
            %                 'Callback',@(handle,event) loadImage(obj,handle,event),...
            
            obj.runButton = uibutton(obj.operationsPanel,...
                'Position',[0.6*leftPanelWidth 0.5*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Run','ButtonPushedFcn',{@(src,event) runThresholding_Callback(obj,src,event)});
            
            obj.resetButton = uibutton(obj.operationsPanel,...
                'Position',[0.10*leftPanelWidth 0.1*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Reset', 'ButtonPushedFcn',{@(src,event) resetImage(obj,src,event)});

           obj.closeButton = uibutton(obj.operationsPanel,...
                'Position',[0.60*leftPanelWidth 0.1*upperleftPanelHeight  buttonWidth buttonHeight],...
                'Text','Close', 'ButtonPushedFcn',{@(src,event) closeApp_Callback(obj,src,event)});
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
                'ColumnWidth',{70 leftPanelWidth-70},...
                'Data',{'Name','';'Path','';'Witdth','';'Height','';'Format', ''});

            %two checkboxes below the lower left panel
            obj.blackBackgroundCheck = uicheckbox(obj.thefig,...
                'Position',[14 51 119 22],...
                'Text','Black Background','ValueChangedFcn',{@(src,event) blackBackgroundcheck_Callback(obj,src,event)});
            
            obj.convTo8BitCheck = uicheckbox(obj.thefig,...
                'Position',[14 21 104 22],...
                'Text','Convert to 8-bit','ValueChangedFcn',{@(src,event) convTo8BitCheck_Callback(obj,src,event)});
            

     % two middle panels  
            gap2Top = 20;  % gap between top panel and the figure top edge 
            gap2Bottom = gap2Top; 
            gap2Side = 20;
            spaceBetweenPanels = 15;
            middlePanelWidth = 200;
            lowermiddlePanelHeight = 300;
            xStart_lowermiddle =  xStart_lowerleftpanel + leftPanelWidth+spaceBetweenPanels; 
            yStart_lowermiddle = gap2Bottom;
            %lower middle panel
            app.msgWindowPanel = uipanel(obj.thefig,...
                'Position',[xStart_lowermiddle yStart_lowermiddle middlePanelWidth lowermiddlePanelHeight],...
                'Title','Message Window');
            obj.msgWindow = uitextarea(app.msgWindowPanel,...
                'Position',[0 0 middlePanelWidth lowermiddlePanelHeight-20],'Value','');
           %upper middle panel
           yStart_uppermiddle = yStart_lowermiddle+lowermiddlePanelHeight+spaceBetweenPanels;
           app.methodListPanel = uipanel(obj.thefig,...
                'Position',[xStart_lowermiddle yStart_uppermiddle, middlePanelWidth fig_height-yStart_uppermiddle-gap2Top],...
                'Title','Thresholding Methods'); 

            %autoThreshModel.thresholdOptions_List = {'1 Global Otsu Method','2 Ridler-Calvard (ISO-data) Cluster Method',...
%             '3 Kittler-Illingworth Cluster Method','4 Kapur Entropy Method',...
%             '5 Local Otsu Method','6 Local Sauvola Method','7 Local Adaptive Method','8 all'};
            if isempty (varargin)
                thresholdOptions_List = {'1 Global Otsu Method','2 Ridler-Calvard (ISO-data) Cluster Method',...
                    '3 Kittler-Illingworth Cluster Method','4 Kapur Entropy Method',...
                    '5 Local Otsu Method','6 Local Sauvola Method','7 Local Adaptive Method','8 all'};
                obj.methodList = uilistbox(app.methodListPanel,...
                    'Position',[0 0 middlePanelWidth fig_height-yStart_uppermiddle-gap2Top*2],...
                    'Items',thresholdOptions_List,...
                    'ValueChangedFcn', @(src,evnt)methodList_Callback(obj,src,evnt));
                
            else
            
                obj.methodList = uilistbox(obj.thefig,...
                    'Position',[258 258 163 186],...
                    'Items',obj.controllerGUI.autoThreshModel.thresholdOptions_List,...
                    'ValueChangedFcn', @(src,evnt)methodList_Callback(obj,src,evnt));
            end
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
           app.outputTabGroup = uitabgroup(obj.thefig,'Position',[xStart_outputTab yStart_resultTable outputTabWidth outputTabHeight]);
           app.tab_original = uitab(app.outputTabGroup,'Title','Original')
           %UIAxes_Original
           UIAxesWidth = 0.9*outputTabHeight;
           UIAxesHeight = UIAxesWidth;
           xStart_UIAxes = (outputTabWidth-UIAxesWidth)/2;
           yStart_UIAxes = (outputTabHeight-UIAxesHeight-20)/2;
           app.UIAxes_original = uiaxes(app.tab_original,'Position',[xStart_UIAxes yStart_UIAxes UIAxesWidth UIAxesHeight]);
           if isempty(varargin)
               imageHeight = round(0.8*outputTabHeight);
               imageWidth = imageHeight;
               imshow(zeros(imageHeight,imageWidth),'Parent', app.UIAxes_original);
               text(0.2*imageWidth,0.5*imageHeight,'Raw image displays here','Color','r','FontSize',15,'Parent',app.UIAxes_original)
           end
        
             %UIAxes_autothreshold
           app.tab_autothreshold = uitab(app.outputTabGroup,'Title','Autothreshold')
           app.UIAxes_autothreshold = uiaxes(app.tab_autothreshold,'Position',[xStart_UIAxes yStart_UIAxes UIAxesWidth UIAxesHeight]);
           if isempty(varargin)
               imageHeight = round(0.8*outputTabHeight);
               imageWidth = imageHeight;
               imshow(zeros(imageHeight,imageWidth),'Parent', app.UIAxes_autothreshold);
               text(0.05*imageWidth,0.5*imageHeight,'Thresholded image displays here','Color','r','FontSize',15,'Parent',app.UIAxes_autothreshold)
           end
% %             obj.resultImg = uiimage(obj.thefig,...
% %                 'Position',[425 21 423 352]);
%             obj.UIAxes = uiaxes(obj.thefig,...
%                 'Position',[425 21 423 352]);
            
            obj.handles = guihandles(obj.thefig);
        end % constructor
        
        % --- Loads the image from Model.
%         function loadImage(obj,handle,event)
%             obj.Img = obj.model.Img; 
%         end
% callback function for Run button
function runThresholding_Callback(obj,~,~)
    obj.controllerGUI.autoThreshModel.myPath = fullfile(obj.imgPath.Value{1},obj.ImageInfoTable.Value{1});
    [thresh, I] = obj.controllerGUI.autoThreshModel.AthreshInternal;
    obj.resultTable.Data = {obj.methodList.Value,thresh};
    imshow(I,'Parent',obj.UIAxes);
    colormap(obj.UIAxes,"gray")

end
        
% reset the parameters from Model.
function resetImage(obj,~,~)
    %initializes the function again
    obj.controllerGUI.reset();
end
%
%         function sayhello3(obj,handle,event)
%             if ~isempty(obj.img)
%                 axes(obj.axright)
%                 imshow(obj.img)
%             end
%             disp('muh4')
%         end

        
        %If someone closes the figure than everything will be deleted !
        function onclose(obj,src,~)
            disp('Closing Auto Threshold App');
            delete(obj) % instance of autoThreshGUI 
            delete(src) %figure (autoThresh_gui) with properties
        end
        
        function loadImage(obj,src,evnt)
            [fileName, pathName] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg';'*.*'},'Select Image',obj.imgPath.Value{1},'MultiSelect','off');
            if ~isempty(fileName)
                obj.imgPath.Value = pathName;
                obj.ImageInfoTable.Value = fileName;
                fprintf('Opening %s \n', fullfile(obj.imgPath.Value{1},obj.ImageInfoTable.Value{1}));
                Idata = imread(fullfile(obj.imgPath.Value{1},obj.ImageInfoTable.Value{1}));
%                 I3 (:,:,1)=Idata;
%                 I3 (:,:,2)=Idata;
%                 I3 (:,:,3)=Idata;
%                 obj.resultImg.ImageSource = I3;
                obj.UIAxes.NextPlot = 'replace'; 
                imshow(Idata,'Parent',obj.UIAxes);
                colormap(obj.UIAxes,"gray")

%                  obj.resultImg.ImageSource = fullfile(obj.imgPath.Value{1},obj.ImageInfoTable.Value{1});
%                  imwrite(Idata,'tempPNG.png');
%                  obj.resultImg.ImageSource = 'tempPNG.png';

            
            else
                disp('NO image is selected')
            end
            
            
        end

        function blackBackgroundcheck_Callback(obj,~,evnt)
           % fprintf('%d: \n', evnt.Value)
            blackBackgroundcheckFlag = evnt.Value;
            if blackBackgroundcheckFlag == 1
               disp('Image has a black background')
            else
                disp('Image has a white whiteground')
            end
            obj.controllerGUI.autoThreshModel.blackBcgd = blackBackgroundcheckFlag;
        end

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

