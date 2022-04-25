classdef autoThreshModel < handle 
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetObservable)
        I
        % variable for keeping instances of Image
        numSections 
        %# of images in stack
        flag
        conv8bit
        blackBcgd
        info
        % store tif meta-data tags
        ws
        % local window size (ws X ws) as required
        myPath
        % file path
        
    end
    
    methods
        function obj = autoThreshModel()
            obj.reset();
        end
        
        function reset(obj)
            obj.I = [];    
            obj.numSections = 1;
            obj.conv8bit = 1;
            obj.blackBcgd = 1; 
            obj.flag = 1;
            obj.myPath = '\';   % define directory
            obj.info = []; 
            obj.ws = 32; 
        end
        
        function setnumSections(obj,numSections)
            obj.numSections = numSections;
        end
        
        function setConv8bit(obj,conv8bit)
            obj.conv8bit = conv8bit;
        end
        
        function setFlag(obj,flag)
            obj.flag = flag;
        end
        
        function setblackBcgd(obj,blackBcgd)
            obj.blackBcgd = blackBcgd;
        end
        
        function setPath(obj,myPath,info,numSections)
            obj.myPath = myPath;
            obj.info = imfinfo(ff); % store tif meta-data tags
            obj.numSections = numel(info); % # of images in stack
        end
        
    end
end

