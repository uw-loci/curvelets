function stardistLink(images, index)

% Recognize the pass to Python that can be run in matlab and contains
% tensorflow and stardist
% If Python version needs to be changed, the following line needs to be
% run, with 'Python' replaced by the exact pass to the right version of
% python that is executable and contains tensorflow and stardist.
% pyenv('Version','Python')

pe = pyenv;

% Recognize the path to the python code file
pathToStardist = fileparts(which('StarDistPrediction.py'));
if count(py.sys.path,pathToStardist) == 0
    insert(py.sys.path,int32(0),pathToStardist);
end

index = int8(index);

py.StarDistPrediction.prediction(images, index);

end

% function reloadPy()
%     warning('off','MATLAB:ClassInstanceExists')
%     clear classes
%     mod = py.importlib.import_module('StarDistPrediction');
%     py.importlib.reload(mod);
% end