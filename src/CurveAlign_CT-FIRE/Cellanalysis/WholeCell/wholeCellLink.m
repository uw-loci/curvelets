function mask4cells = wholeCellLink(image,model,preTrained,cellDiameter,img_mpp)
% This function links deep learning models written in Python to MATLAB.
% image - the image that needs to be segmented
% model - two models available: 'Cellpose' and 'DeepCell'
% preTrained-name of the pre-trained model
% cellDiameter-diameter of cell

%pe = pyenv;
% pathToStardist = fileparts(which('cellpose_seg.py'));
% if count(py.sys.path,pathToStardist) == 0
%     insert(py.sys.path,int32(0),pathToStardist);
% end

if strcmp(model,'Cellpose')
    % terminate(pyenv)
    % pyenv('Version','C:\Users\liu372\.conda\envs\CApy311\python.exe', 'ExecutionMode', 'OutOfProcess')
    py.importlib.import_module('cellpose_seg');
    fprintf('%s pretrained model "%s" is being used for the cell segmentaion \n', ...
        'Cellpose',preTrained);
    mask4cells= uint32(py.cellpose_seg.cyto_seg(image,preTrained,cellDiameter));
    
elseif strcmp(model,'DeepCell') 
%     terminate(pyenv)
%     pyenv('Version','/Users/ympro/opt/anaconda3/envs/deepcell/bin/python')
    py.importlib.import_module('deepcell_seg');
    mask4cells = uint32(py.deepcell_seg.cyto_seg(image,preTrained,img_mpp));
elseif strcmp(model,'FromMask') 
   cellobj = imgCardWholeCell(model,imageName,imagePath);
   mask4cells = cellobj.cellArray.mask;
end
   
end