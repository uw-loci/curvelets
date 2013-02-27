% ctFeatureExt.m
% Feature Extraction with Curvelet Transform

% This script pulls runs the feature extraction function, then uses SVM
% cross validation to verify the quality of the features.

% Yuming Liu, Jeremy Bredfeldt, LOCI, UW-Madison, Feb 2013
clear all;
close all;

%these are the dependancies, must get these folders installed first
addpath('../CurveLab-2.1.2/fdct_wrapping_matlab');
addpath(genpath(fullfile('../FIRE')));
addpath(genpath('../CircStat2012a'));

% Start by selecting two images. One from each class (ie tumor & normal)
[imgName imgPath] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','off');
[imgName2 imgPath2] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','off');
close all;

%imgName = 'IDC_M1F2.tif';
%imgName2 = 'NAT2.tif';
%imgPath = 'P:\curvelets\curvelets-master\curvelets-master\ctFIRE\';
%imgPath2 = 'P:\curvelets\curvelets-master\curvelets-master\ctFIRE\';

fctr = 'test1.mat';
%pct = [0.4 0.2 0.02 0.002 0.0002 0.00002];
pct = [0.5];
SS = 5;
plotflag = 1;

%Extract features from each
[Ct OUTct training_set_IDC] = ctFeatures(imgPath,imgName,fctr,pct,SS,plotflag,0);
fctr = 'test2.mat';
[Ct OUTct training_set_NAT] = ctFeatures(imgPath2,imgName2,fctr,pct,SS,plotflag,1);

%%
% Perform SVM training and cross validation

xdata = [training_set_IDC; training_set_NAT];
gIDC = 'IDC';
lenIDC = length(training_set_IDC);
lenNAT = length(training_set_NAT);
for i = 2:lenIDC
    gIDC = [gIDC; gIDC(1,:)];
end
gNAT = 'NAT';
for i = 2:lenNAT
    gNAT = [gNAT; gNAT(1,:)];    
end
group = [gIDC; gNAT];
%group = [zeros(length(training_set_IDC),1); ones(length(training_set_NAT),1)];

%train classifier
%figure(1); clf;
%svmStruct = svmtrain(xdata,group,'showplot',true);

%do cross validation
folds = 3;
%[sens spec] = xval1(training_set_IDC,traing_set_NAT,group,folds);

sens = zeros(1,folds);
spec = zeros(1,folds);
for i = 1:folds
    %split data into folds number of pieces
    I = round(lenIDC/folds);
    N = round(lenNAT/folds);
    Istr = (i-1)*I;
    Ii = mod(Istr:Istr+I-1,lenIDC)+1; %list for training
    Io = mod(Istr+I:Istr+3*I-1,lenIDC)+1; %list for validation
    
    Nstr = (i-1)*N;
    Ni = mod(Nstr:Nstr+N-1,lenNAT)+1; %list for training
    No = mod(Nstr+N:Nstr+3*N-1,lenNAT)+1; %list for validation
    
    tIDC = training_set_IDC(Ii,:); %training data
    tNAT = training_set_NAT(Ni,:); %training data
    tgIDC = gIDC(Ii,:); %training labels
    tgNAT = gNAT(Ni,:); %training labels
    
    tset = [tIDC; tNAT]; %complete training matrix
    tg = [tgIDC; tgNAT]; %complete label matrix
    
    vset = [training_set_IDC(Io,:); training_set_NAT(No,:)];
    vgrp = [gIDC(Io,:); gNAT(No,:)];
    
    %train
    figure(i); clf;
    svmStruct = svmtrain(tset,tg,'showplot',true);
    xlabel('Prevalence (# of coefficients)');
    ylabel('Alignment (A.U.)');
    
    %validate    
    v = svmclassify(svmStruct,vset,'showplot',true);
    
    %Count tp, tn, fp, fn
    
    tp = sum((v(:,1) == vgrp(:,1) & v(:,1) == 'I'));
    tn = sum((v(:,1) == vgrp(:,1) & v(:,1) == 'N'));
    fp = sum((v(:,1) ~= vgrp(:,1) & v(:,1) == 'I'));
    fn = sum((v(:,1) ~= vgrp(:,1) & v(:,1) == 'N'));
    
    sens(i) = tp/(tp+fn);
    spec(i) = tn/(fp+tn);    
end

disp(sprintf('mean sensitivity: %f',mean(sens)));
disp(sprintf('mean specificity: %f',mean(spec)));