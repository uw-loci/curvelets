function VampireCaller(csv)

pe = pyenv;

pathToPy = fileparts(which('mainbody.py'));
if count(py.sys.path,pathToPy) == 0
    insert(py.sys.path,int32(0),pathToPy);
end

build_model = true;
% csv = ...
%     '/Users/wonderzhu/Desktop/Cell_Segmentation_Tools/folder/VAMPIRE_open/Supplementary Data/Segmented image sets to build model copy.csv';
numOfCoor = 50;
numOfCoor = int8(numOfCoor);
modelName = 'test1';
modelApply = '';
outpth = '../test1';
clnum = 10;
clnum = int8(clnum);

py.getboundary.getboundary(csv)
py.mainbody.mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply);

build_model = false;
% csv = ...
%     '/Users/wonderzhu/Desktop/Cell_Segmentation_Tools/folder/VAMPIRE_open/Supplementary Data/Segmented image sets to build model copy.csv';
modelApply = '../test1/test1/test1.pickle';
py.getboundary.getboundary(csv)
py.mainbody.mainbody(build_model, csv, outpth, clnum, numOfCoor, modelName, modelApply);


end