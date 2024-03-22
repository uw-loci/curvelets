function cellPropertyTest(number)

load('labels_sd.mat','labels');
sizeLabels = size(labels);

for i=1:sizeLabels(1)
    for j=1:sizeLabels(2)
        if labels(i,j) == number
            labels(i,j) = 1;
        else
            labels(i,j) = 0;
        end
    end
end

save('fortest.mat','labels')

pe = pyenv;

pathToStardist = fileparts(which('CellPropertyTest.py'));
if count(py.sys.path,pathToStardist) == 0
    insert(py.sys.path,int32(0),pathToStardist);
end

py.CellPropertyTest.CellPropertyTest();

end