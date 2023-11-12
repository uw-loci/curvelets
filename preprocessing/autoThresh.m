function autoThresh(filePath,stackvalue,methodID)

%Initialize model and controller for the auto-threshold module
h = findall(0,'Type','figure','Tag','autothreshold_gui');
if ~isempty(h)
    delete(h)
end
if nargin == 0
    ATmodel = autoThreshModel();
elseif nargin == 1
    ATmodel = autoThreshModel(filePath);     % initialize the model
elseif nargin == 2
    ATmodel = autoThreshModel(filePath,stackvalue);     % initialize the model
elseif nargin == 3
    ATmodel = autoThreshModel(filePath,stackvalue,methodID);     % initialize the model
end
ATcontroller = autoThreshController(ATmodel);  % initialize controller

end

