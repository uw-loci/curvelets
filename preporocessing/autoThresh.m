function autoThresh
%UNTITLED2 Summary of this function goes here
%   initializes model and controller

model = antoThreshModel();     % initialize the model
controller = autoThreshController(model);  % initialize controller

end

