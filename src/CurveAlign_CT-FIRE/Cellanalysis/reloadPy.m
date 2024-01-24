function reloadPy(file)
% This function will try to force the Python file of choosing to reload and
% recompile, so that the programmer will not have to restart MATLAB. It
% may not work every time.
% file - the Python file of choosing
    warning('off','MATLAB:ClassInstanceExists')
    clear classes
    mod = py.importlib.import_module(file);
    py.importlib.reload(mod);
end