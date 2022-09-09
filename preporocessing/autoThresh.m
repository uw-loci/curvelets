function autoThresh
%Initialize model and controller for the auto-threshold module
h = findall(0,'Type','figure','Tag','autothreshold_gui');
if ~isempty(h)
    delete(h)
end
model = autoThreshModel();     % initialize the model
controller = autoThreshController(model);  % initialize controller

end

