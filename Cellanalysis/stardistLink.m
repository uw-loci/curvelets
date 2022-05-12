function stardistLink(images, index)

% Recognize the pass to Python that can be run in matlab and contains
% tensorflow and stardist
% If Python version needs to be changed, the following line needs to be
% run, with 'Python' replaced by the exact pass to the right version of
% python that is executable and contains tensorflow and stardist.
% pyenv('Version','Python')

pe = pyenv;
%pe = pyenv(Version="/Users/ympro/opt/anaconda3/envs/SDpy38/bin/python",ExecutionMode = "OutOfProcess");

% Recognize the path to the python code file
pathToStardist = fileparts(which('StarDistPrediction.py'));
if count(py.sys.path,pathToStardist) == 0
    insert(py.sys.path,int32(0),pathToStardist);
end

index = int8(index);

py.StarDistPrediction.prediction(images, index);

load('labels.mat','labels');
load('details.mat','details');

details.coord = details.coord./2;
details.points = details.points./2;
details.prob = details.prob./2;

szLabels = size(labels);

x_g = 1:szLabels(1);
y_g = 1:szLabels(2);
desample = griddedInterpolant({x_g,y_g},double(labels));

x_q = (0:2:szLabels(1))';
y_q = (0:2:szLabels(2))';
labels = uint8(desample({x_q,y_q}));

save('details.mat','details');
save('labels.mat','labels');

end

% function reloadPy()
%     warning('off','MATLAB:ClassInstanceExists')
%     clear classes
%     mod = py.importlib.import_module('StarDistPrediction');
%     py.importlib.reload(mod);
% end