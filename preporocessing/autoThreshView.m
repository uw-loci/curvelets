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
            
%             addlistener(obj.autoThreshModel,'conv8bit','PostSet', ...
%                 @(src,evnt)view.handlePropEvents(obj,src,evnt));
%             addlistener(obj.autoThreshModel,'flag','PostSet', ...
%                 @(src,evnt)view.handlePropEvents(obj,src,evnt));
%             addlistener(obj.autoThreshModel,'blackBcgd','PostSet', ...
%                 @(src,evnt)view.handlePropEvents(obj,src,evnt));

        end
     end
    
       methods (Static)
        function handlePropEvents(obj,src,evnt)
            evntobj = evnt.AffectedObject;
            handles = guidata(obj.gui);
            switch src.Name
                case 'conv8bit'
                    set(handles.conv8bit, 'String', evntobj.conv8bit);
                case 'flag'
                    set(handles.flag, 'String', evntobj.flag);
                case 'blackBcgd'
                    set(handles.blackBcgd,'String',evntobj.blackBcgd);
            end
        end
    end


end
