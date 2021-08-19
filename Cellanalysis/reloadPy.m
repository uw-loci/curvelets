function reloadPy(file)
    warning('off','MATLAB:ClassInstanceExists')
    clear classes
    mod = py.importlib.import_module(file);
    py.importlib.reload(mod);
end