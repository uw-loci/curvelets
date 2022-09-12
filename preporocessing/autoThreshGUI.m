classdef autoThreshGUI < handle
    % GUI class for the auto-threshold module
    
    properties
        thefig
        imgPath
        imgList
        msgWindow
        runButton
        loadButton
        resetButton
        blackBackgroundCheck
        convTo8BitCheck
        globalList
        localList
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
            obj.thefig = uifigure('Position',[100 100 855 487],...
                'MenuBar','none',...
                'NumberTitle','off',...
                'Name','Auto Threshold App','Tag','autothreshold_gui');

            set(obj.thefig,'CloseRequestFcn',@(src,event) onclose(obj,src,event))
            
            imgPathLabel = uilabel(obj.thefig,...
                'Position',[14 306 76 22],...
                'Text','Image Folder');
            
            obj.imgPath = uitextarea(obj.thefig,...
                'Position',[14 270 220 37],'Value','');
            
            
%             obj.
%             'Value','ImgPath' from Model
            
            imgListLabel = uilabel(obj.thefig,...
                'Position',[14 237 60 22],...
                'Text','Image List');
            
            obj.imgList = uitextarea(obj.thefig,...
                'Position',[14 168 220 70]);
            
            msgWindowLabel = uilabel(obj.thefig,...
                'Position',[14 134 100 22],...
                'Text','Message Window');
            
            obj.msgWindow = uitextarea(obj.thefig,...
                'Position',[14 86 220 45],'Value','');
            
            obj.loadButton = uibutton(obj.thefig,...
                'Position',[14 424 100 22],...
                'Text','Load Image (s)',...
                'Tag','loadButton','ButtonPushedFcn',{@(src,event) loadImage(obj,src,event)});
            %                 'Callback',@(handle,event) loadImage(obj,handle,event),...
            
            obj.runButton = uibutton(obj.thefig,...
                'Position',[14 389 100 22],...
                'Text','Run');
            
            obj.resetButton = uibutton(obj.thefig,...
                'Position',[14 351 100 22],...
                'Text','Reset', 'ButtonPushedFcn',{@(src,event) resetImage(obj,src,event)});
                
            % 'Callback',@(handle,event) resetImage(obj,handle,event));                
            
            obj.blackBackgroundCheck = uicheckbox(obj.thefig,...
                'Position',[14 51 119 22],...
                'Text','Black Background','ValueChangedFcn',{@(src,event) blackBackgroundcheck_Callback(obj,src,event)});
            
            obj.convTo8BitCheck = uicheckbox(obj.thefig,...
                'Position',[14 21 104 22],...
                'Text','Convert to 8-bit','ValueChangedFcn',{@(src,event) convTo8BitCheck_Callback(obj,src,event)});
            
            globalListlabel = uilabel(obj.thefig,...
                'Position',[258 443 90 22],...
                'Text','Global'); 
            
            obj.globalList = uilistbox(obj.thefig,...
                'Position',[258 258 163 186],...
            'Items',{'Global Otsu Method','Ridler-Calvard (ISO-data) Cluster Method',...
            'Kittler-Illingworth Cluster Method',...
            'Kapur Entropy Method'},'ValueChangedFcn', @(src,evnt)updateGlobalFlag(obj,src,evnt));
%          'ValueChangedFcn', @updateGlobalFlag
            
            localListlabel = uilabel(obj.thefig,...
                'Position',[258 225 83 22],...
                'Text','Local'); 
            
            obj.localList= uilistbox(obj.thefig,...
                'Position',[258 21 163 205],...
            'Items',{'Local Otsu Method','Local Sauvola Method',...
            'Local Adaptive Method'},'ValueChangedFcn', @(src,evnt)updateLocalFlag(obj,src,evnt));
%          'ValueChangedFcn', @updateLocalFlag ->pass the flag to
%          controller->controller pass to function->pass back the image and
%          diaplay on uiimage/uitable
            
            obj.resultTable = uitable(obj.thefig,...
                'Position',[440 389 400 80],...
            'ColumnName',{'Method','Threshold'});
        
            obj.resultImg = uiimage(obj.thefig,...
                'Position',[425 21 423 352]);
%             %yl
%             obj.UIAxes = uiaxes(obj.thefig,...
%                 'Position',[425 21 423 352]);
            
            obj.handles = guihandles(obj.thefig);
        end % constructor
        
        % --- Loads the image from Model.
%         function loadImage(obj,handle,event)
%             obj.Img = obj.model.Img; 
%         end
%         
%         --- resets the image from Model.
function resetImage(obj,~,event)
          %initializes the function again
            autoThresh; 
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
                obj.imgList.Value = fileName;
                fprintf('Opening %s \n', fullfile(obj.imgPath.Value{1},obj.imgList.Value{1}));
                Idata = imread(fullfile(obj.imgPath.Value{1},obj.imgList.Value{1}));
%                 I3 (:,:,1)=Idata;
%                 I3 (:,:,2)=Idata;
%                 I3 (:,:,3)=Idata;
%                 obj.resultImg.ImageSource = I3;
%                obj.UIAxes.NextPlot = 'replaceall'; 
%                 imagesc(Idata,'Parent',obj.UIAxes);
                 
%                  obj.resultImg.ImageSource = fullfile(obj.imgPath.Value{1},obj.imgList.Value{1});
                 imwrite(Idata,'tempPNG.png');
                 obj.resultImg.ImageSource = 'tempPNG.png';

            
            else
                disp('NO image is selected')
            end
            
            
        end

        function blackBackgroundcheck_Callback(obj,~,evnt)
           % fprintf('%d: \n', evnt.Value)
            obj.controllerGUI.autoThreshModel.blackBcgd = evnt.Value;
            if evnt.Value == 1
               disp('Image has a black background')
            else
                disp('Image has a white whiteground')
            end

        end

% callback  
        function convTo8BitCheck_Callback(obj,~,evnt)
           % fprintf('%d: \n', evnt.Value)
            obj.controllerGUI.autoThreshModel.conv8bit = evnt.Value;
            if evnt.Value == 1
                disp('Convert to 8-bit image.')
            else
                disp('NO image format conversion.')
            end
        end
        
        function updateGlobalFlag(obj,~,evnt)
            
            fprintf('%s: \n', evnt.Value)
            if strcmp(evnt.Value,'Global Otsu Method')
                obj.controllerGUI.autoThreshModel.flag = 1;
            elseif strcmp(evnt.Value,'Ridler-Calvard (ISO-data) Cluster Method')
                obj.controllerGUI.autoThreshModel.flag = 2;
            elseif strcmp(evnt.Value,'Kittler-Illingworth Cluster Method')
                obj.controllerGUI.autoThreshModel.flag = 3;
            elseif strcmp(evnt.Value,'Kapur Entropy Method')
                obj.controllerGUI.autoThreshModel.flag = 4;
            else
                 disp('this method is not valid')
            end
            if isempty(obj.imgPath.Value)
                obj.imgPath.Value = './';
                obj.imgList.Value = 'atuoTimg.tif';
            end
            obj.controllerGUI.autoThreshModel.myPath = fullfile(obj.imgPath.Value{1},obj.imgList.Value{1});
           [thresh, I] = obj.controllerGUI.autoThreshModel.AthreshInternal;
            imwrite(I,'autoTimg.png');
            obj.resultTable.Data = {evnt.Value,thresh};
            obj.resultImg.ImageSource = 'autoTimg.png';
        end

        function updateLocalFlag(obj,~,evnt)
            fprintf('%s: \n', evnt.Value)
            if strcmp(evnt.Value,'Local Otsu Method')
                obj.controllerGUI.autoThreshModel.flag = 21;
            elseif strcmp(evnt.Value,'Local Sauvola Method')
                obj.controllerGUI.autoThreshModel.flag = 22;
            elseif strcmp(evnt.Value,'Local Adaptive Method')
                obj.controllerGUI.autoThreshModel.flag = 23;
            else
                 disp('this method is not valid')
            end
            if isempty(obj.imgPath.Value)
                obj.imgPath.Value = './';
                obj.imgList.Value = 'atuoTimg.tif';
            end
            obj.controllerGUI.autoThreshModel.myPath = fullfile(obj.imgPath.Value{1},obj.imgList.Value{1});
           [thresh, I] = obj.controllerGUI.autoThreshModel.AthreshInternal;
            imwrite(I,'autoTimg.png');
            obj.resultTable.Data = {evnt.Value,thresh};
            obj.resultImg.ImageSource = 'autoTimg.png';
        end
        
        
    end
    
    methods
      
    end
end

