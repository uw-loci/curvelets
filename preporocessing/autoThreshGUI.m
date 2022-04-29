classdef autoThreshGUI< handle
    %AUTOTHRESHGUI Summary of this class goes here
    %   Detailed explanation goes here
    
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
    end
    
    
    methods
        %% Constructor
        function obj = autoThreshGUI(varargin)
            obj.thefig = uifigure('Position',[100 100 855 487],...
                'MenuBar','none',...
                'NumberTitle','off',...
                'Name','Auto Threshold App');
            set(obj.thefig,'CloseRequestFcn',@(src,event) onclose(obj,src,event))
            
            imgPathLabel = uilabel(obj.thefig,...
                'Position',[14 306 76 22],...
                'Text','Image Folder');
            
            obj.imgPath = uitextarea(obj.thefig,...
                'Position',[14 270 220 37]);
            
            imgListLabel = uilabel(obj.thefig,...
                'Position',[14 237 60 22],...
                'Text','Image List');
            
            obj.imgList = uitextarea(obj.thefig,...
                'Position',[14 168 220 70]);
            
            msgWindowLabel = uilabel(obj.thefig,...
                'Position',[14 134 100 22],...
                'Text','Message Window');
            
            obj.msgWindow = uitextarea(obj.thefig,...
                'Position',[14 86 220 45]);
            
            obj.loadButton = uibutton(obj.thefig,...
                'Position',[14 424 100 22],...
                'Text','Load Image (s)',...
                'Callback',@(handle,event) loadImage(obj,handle,event),...
                'Tag','loadButton');
            
            obj.runButton = uibutton(obj.thefig,...
                'Position',[14 389 100 22],...
                 'Callback',@(handle,event) loadImage(obj,handle,event),...
                'Text','Run');
            
            obj.resetButton = uibutton(obj.thefig,...
                'Position',[14 351 100 22],...
                'Text','Reset');
            
            obj.blackBackgroundCheck = uicheckbox(obj.thefig,...
                'Position',[14 51 119 22],...
                'Text','Black Background');
            
            obj.convTo8BitCheck = uicheckbox(obj.thefig,...
                'Position',[14 21 104 22],...
                'Text','Convert to 8-bit');
            
            globalListlabel = uilabel(obj.thefig,...
                'Position',[258 443 90 22],...
                'Text','Global'); 
            
            obj.globalList = uilistbox(obj.thefig,...
                'Position',[258 258 163 186],...
            'Items',{'Global Otsu Method','Ridler-Calvard (ISO-data) Cluster Method',...
            'Kittler-Illingworth Cluster Method',...
            'Kapur Entropy Method'});
            
            localListlabel = uilabel(obj.thefig,...
                'Position',[258 225 83 22],...
                'Text','Local'); 
            
            obj.localList= uilistbox(obj.thefig,...
                'Position',[258 21 163 205],...
            'Items',{' Local Otsu Method','Local Sauvola Method',...
            'Local Adaptive Method'});
            
            obj.resultTable = uitable(obj.thefig,...
                'Position',[440 389 400 80],...
            'ColumnName',{'Method','Threshold'});
        
            obj.resultImg = uiimage(obj.thefig,...
                'Position',[425 21 423 352]);
            
            obj.handles = guihandles(obj.thefig);
        end % constructor
        
        % --- Loads the image from Model.
        function loadImage(obj,handle,event)
            if isa(varargin{1}, 'autoThreshController');    obj.autoThreshController = varargin{1}; end
            obj.model = obj.autoThreshController.autoThreshModel; 
            obj.Img = obj.model.Img; 
        end
%         
%         function sayhello2(obj,handle,event)
%             if ~isempty(obj.img)
%                 axes(obj.axright)
%                 imshow(obj.img)
%             end
%             disp('muh2')
%         end
%         
%         function sayhello3(obj,handle,event)
%             if ~isempty(obj.img)
%                 axes(obj.axright)
%                 imshow(obj.img)
%             end
%             disp('muh4')
%         end
        
        %If someone closes the figure than everything will be deleted !
        function onclose(obj,src,event)
            disp('Closing Auto Threshold App');
            delete(src)
            delete(obj)
        end
        
    end
    
    methods
      
    end
end

