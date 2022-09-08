function autoThresh
%initializes model and controller

model = autoThreshModel();     % initialize the model
controller = autoThreshController(model);  % initialize controller

end

