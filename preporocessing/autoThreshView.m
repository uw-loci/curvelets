classdef autoThreshView < handle
    
    properties
        gui
        autoThreshModel
        autoThreshController
    end

     methods
        function obj = autoThreshView(autoThreshController)
            obj.autoThreshController = autoThreshController;
            obj.autoThreshModel = autoThreshController.autoThreshModel;
            obj.gui = autoThreshGUI('controller',obj.autoThreshController);
            
            addlistener(obj.autoThreshModel,'conv8bit','PostSet', ...
                @(src,evnt)autoThreshView.handlePropEvents(obj,src,evnt));
            addlistener(obj.autoThreshModel,'flag','PostSet', ...
                @(src,evnt)autoThreshView.handlePropEvents(obj,src,evnt));
            addlistener(obj.autoThreshModel,'blackBcgd','PostSet', ...
                @(src,evnt)autoThreshView.handlePropEvents(obj,src,evnt));

        end
     end
    
       methods (Static)
        function handlePropEvents(obj,src,evnt)
            evntobj = evnt.AffectedObject;
            handles = obj.gui;
            switch src.Name
                case 'conv8bit'
                    set(handles.convTo8BitCheck, 'Value', evntobj.conv8bit);
                case 'flag'
                    set(handles.globalList, 'Value', evntobj.thresholdOptions_Global{evntobj.flag});
                case 'blackBcgd'
                    set(handles.blackBackgroundCheck,'Value',evntobj.blackBcgd);
                    if handles.blackBackgroundCheck.Value == 1
                        handles.msgWindow.Value = [handles.msgWindow.Value;{'Image has a back background'}];
                    else
                        handles.msgWindow.Value = [handles.msgWindow.Value;{'Image has a white background'}];
                    end
            end
        end
    end


end
