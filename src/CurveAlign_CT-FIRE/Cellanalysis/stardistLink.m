function stardistLink(images, index,samplingFactor,modelParameters)
% This function calls StarDistPrediction.py, which calls StarDist to
% segment nuclei, from MatLab. 
% images - an array of strings of images
% index - the index of image in the array that needs to be segmented
% modelParameters -  parameters of the pre-trained model

% Recognize the pass to Python that can be run in matlab and contains
% tensorflow and stardist
% If Python version needs to be changed, the following line needs to be
% run, with 'Python' replaced by the exact pass to the right version of
% python that is executable and contains tensorflow and stardist.
% pyenv('Version','Python')

% pe = pyenv;
% 
% if pe.Status == "Terminated" || pe.Status == "Unloaded" 
%     disp('python environment is terminated.')
%     terminate(pyenv)
%     % pyenv(Version="C:\Users\liu372\.conda\envs\CApy311\python.exe",ExecutionMode = "OutOfProcess")
%     py.print('python environment restarted \n')
%     pypath = py.sys.path;
%     fprintf(' restart python environment.\n current python search path include: \n ')
%     fprintf('  %s \n',pypath)   
% end
% 
% % pe = pyenv(Version="/Users/ympro/opt/anaconda3/envs/SDpy38/bin/python",ExecutionMode = "OutOfProcess");
% % Recognize the path to the python code file
% pathToStardist = fileparts(which('StarDistPrediction.py'));
% if ~isempty(pathToStardist)
%     if count(py.sys.path,pathToStardist) == 0
%         insert(py.sys.path,int32(0),pathToStardist);
%         fprintf('Added %s to the python search path  \n',pathToStardist)
%     else
%         fprintf('path to stardist module is already in the python search path')
%     end
% else
%     error('stardist module is not found.')
% end

index = int8(index);
% reload an user defined python module
% clear classes
py.importlib.import_module('StarDistPrediction');
% py.StarDistPrediction.prediction(images,index,modelName);
 % stardistParameters = struct('deepMethod',deepMeathod,'modelName',deepModel,'defaultParametersFlag',default_parameters_flag,...
            %         'prob_thresh',0.2,'nms_threshold',0.5,'Normalization_lowPercentile',1,...
            %         'Normalization_highPercentile',99.8);
model_name = modelParameters.modelName;
default_parameters_flag =modelParameters.defaultParametersFlag;
prob_thresh = modelParameters.prob_thresh;
nms_threshold = modelParameters.nms_threshold;
Normalization_lowPercentile = modelParameters.Normalization_lowPercentile;
Normalization_highPercentile = modelParameters.Normalization_highPercentile;
py.StarDistPrediction.prediction(images,index,model_name,default_parameters_flag,prob_thresh, nms_threshold, Normalization_lowPercentile, Normalization_highPercentile)
if samplingFactor == 1
    samplingFlag = 0;
else
    samplingFlag = 1;
end
if samplingFlag == 1
    load('labels_sd.mat','labels');
    load('details_sd.mat','details');
    details.coord = details.coord./2;
    details.points = details.points./2;
    details.prob = details.prob./2;

    szLabels = size(labels);

    x_g = 1:szLabels(1);
    y_g = 1:szLabels(2);
    desample = griddedInterpolant({x_g,y_g},double(labels));

    x_q = (1:2:szLabels(1))';
    y_q = (1:2:szLabels(2))';
    labels = uint32(desample({x_q,y_q}));

    save('details_sd.mat','details');
    save('labels_sd.mat','labels');
    %imwrite(labels,'mask.tif');
end
end

% function reloadPy()
%     warning('off','MATLAB:ClassInstanceExists')
%     clear classes
%     mod = py.importlib.import_module('StarDistPrediction');
%     py.importlib.reload(mod);
% end