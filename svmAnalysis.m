clear all;
close all;
data = load('trn.mat');

trnData = data.trnData(:,[3,5,15,16]);
grpData = data.grpData;

options = statset('Display','iter');
grpData = [1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0]';
svmStruct = svmtrain(trnData,grpData,'options',options,'showplot',true,'kernel_function','quadratic');

%validate    
v = svmclassify(svmStruct,trnData);

%Count tp, tn, fp, fn

tp = sum((v == grpData & grpData == 1));
tn = sum((v == grpData & grpData == 0));
fp = sum((v ~= grpData & grpData == 0));
fn = sum((v ~= grpData & grpData == 1));

sens = tp/(tp+fn);
spec = tn/(fp+tn);

disp(sprintf('mean sensitivity: %f',mean(sens)));
disp(sprintf('mean specificity: %f',mean(spec)));
svmStruct.Bias - svmStruct.ScaleData.shift