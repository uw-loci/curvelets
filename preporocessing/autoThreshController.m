classdef autoThreshController < handle

    % controller class for the auto-threshold module 
    
    properties
        autoThreshModel
        autoThreshView
    end

    methods
        function obj = autoThreshController(autoThreshModel)
            obj.autoThreshModel = autoThreshModel;
            obj.autoThreshView = autoThreshView(obj);
        end
        
        %notifies the model of Data change
        function setFlag(obj,flag)
            obj.autoThreshModel.setFlag(flag)
        end
        
        function setblackBcgd(obj,blackBcgd)
            obj.autoThreshModel.setblackBcgd(blackBcgd)
        end
        
        function setConv8bit(obj,conv8bit)
            obj.autoThreshModel.setConv8bit(conv8bit)
        end
        
        function AthreshInternal(obj)
            
            obj.autoThreshModel.AthreshInternal() 
        end
        
        function reset(obj)
            obj.autoThreshModel.reset()
        end        
        
    end
    
end
