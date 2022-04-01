function wholeCellLink(image,model)

pe = pyenv;

pathToStardist = fileparts(which('cellpose_seg.py'));
if count(py.sys.path,pathToStardist) == 0
    insert(py.sys.path,int32(0),pathToStardist);
end

if strcmp(model,'Cellpose')
    py.cellpose_seg.cyto_seg(image)
elseif strcmp(model,'DeepCell') 
    py.deepcell_seg.cyto_seg(image)
end

end