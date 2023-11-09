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
            addlistener(obj.autoThreshModel,'darkObjectCheck','PostSet', ...
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
                    if handles.convTo8BitCheck.Value == 1
                        handles.msgWindow.Value = [handles.msgWindow.Value;{'Convert image to 8-bit format.'}];
                    else
                        handles.msgWindow.Value = [handles.msgWindow.Value;{'NO image format conversion.'}];
                    end
                case 'flag'
                    set(handles.methodList, 'Value', evntobj.thresholdOptions_List{evntobj.flag});
                    handles.msgWindow.Value = [handles.msgWindow.Value;{sprintf('Selected thresholding method is: %s ',handles.methodList.Value)}];
                case 'darkObjectCheck'
                    set(handles.darkObjectCheck,'Value',evntobj.darkObjectCheck);
                    if handles.darkObjectCheck.Value == 1
                        handles.msgWindow.Value = [handles.msgWindow.Value;{'Dark objects checkbox is checked. Dispaying colormap inverted image.'}];
                    else
                        handles.msgWindow.Value = [handles.msgWindow.Value;{'Dark object checkbox is unchecked. Displaying original image'}];
                    end
            end
        end
    end


end
