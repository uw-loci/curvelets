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
        
        function setdarkObjectCheck(obj,darkObjectCheck)
            obj.autoThreshModel.setdarkObjectCheck(darkObjectCheck)
        end
        
        function setConv8bit(obj,conv8bit)
            obj.autoThreshModel.setConv8bit(conv8bit)
        end
        
        function AthreshInternal(obj)
            
            obj.autoThreshModel.AthreshInternal() 
        end
        
        function reset(obj)
            obj.autoThreshModel.reset()
            obj.autoThreshView.gui.convTo8BitCheck.Value= obj.autoThreshModel.conv8bit;
            obj.autoThreshView.gui.ImageInfoTable.Data{2,1} = obj.autoThreshModel.myPath;
%             obj.autoThreshView.gui.imgPath.  
%             resultTable
        end        
        
    end
    
end
