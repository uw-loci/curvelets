function VampireCaller(csv)

pe = pyenv;

pathToPy = fileparts(which('mainbody.py'));
if count(py.sys.path,pathToPy) == 0
    insert(py.sys.path,int32(0),pathToPy);
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
py.mainbody.mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply);

build_model = false;
modelApply = 'test1/test1/test1.pickle';
py.getboundary.getboundary(csv)
py.mainbody.mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply);

delete('test1/test1/*')
end