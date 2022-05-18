function VampireCaller(csv)

pe = pyenv;

pathToPy = fileparts(which('mainbody_figure.py'));
if count(py.sys.path,pathToPy) == 0
    insert(py.sys.path,int32(0),pathToPy);
end

if exist('VAMPIRE datasheet mask.tif.csv','file')
    delete('VAMPIRE datasheet mask.tif.csv')
end

if exist('mask.tif_boundary_coordinate_stack.pickle','file')
    delete('mask.tif_boundary_coordinate_stack.pickle')
end

build_model = true;
numOfCoor = 50;
numOfCoor = int8(numOfCoor);
modelName = 'test1';
modelApply = '';
outpth = 'test1';
clnum = 10;
clnum = int8(clnum);

py.getboundary.getboundary(csv)
py.mainbody_figure.mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply);

build_model = false;
modelApply = './test1/test1/test1.pickle';
py.getboundary.getboundary(csv)
py.mainbody_figure.mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply);

delete('./test1/test1/test1.pickle')
end