function wholeCellLink(image)

pe = pyenv;

pathToStardist = fileparts(which('cellpose_seg.py'));
if count(py.sys.path,pathToStardist) == 0
    insert(py.sys.path,int32(0),pathToStardist);
end

py.cellpose_seg.cyto_seg(image)

end