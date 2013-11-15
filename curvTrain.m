
clear all;
close all;

%Load all feature files into RAM as a big array, if possible...

fibFeatDir = 'P:\\Conklin data - Invasive tissue microarray\\TrainingSets20131113\\CA_Out\\';
heDir = 'P:\\Conklin data - Invasive tissue microarray\\Validation\\HE\\';
maskDir = 'P:\\Conklin data - Invasive tissue microarray\\TrainingSets20131113\\';

fileList = dir(fibFeatDir);

lenFileList = length(fileList);
feat_idx = zeros(1,lenFileList);
%Search for feature files
for i = 1:lenFileList
    if ~isempty(regexp(fileList(i).name,'fibFeatures.mat', 'once', 'ignorecase'))
        feat_idx(i) = 1;
    end
end
featFiles = fileList(feat_idx==1);
lenFeatFiles = length(featFiles);
%Compile a big array of features in RAM
totFeat = 0;
for i = 1:lenFeatFiles
    featName = featFiles(i).name;
    bff = [fibFeatDir featName];
    feat = load(bff);
    [lenFeat widFeat] = size(feat.fibFeat);
    totFeat = totFeat + lenFeat;
end
%Allocate space
compFeat = zeros(totFeat,widFeat+1);
compFeatMeta(lenFeatFiles) = struct('imageName',[],'topLevelDir',[],'fireDir',[],'outDir',[],'numToProc',[],'fibProcMeth',[],'keep',[],'distThresh',[]);

%Put together big array
prevTot = 1;
totFeat = 0;
for i = 1:lenFeatFiles
    featName = featFiles(i).name;
    bff = [fibFeatDir featName];
    feat = load(bff);
    [lenFeat widFeat] = size(feat.fibFeat);
    totFeat = totFeat + lenFeat; %Pointer to last array position
    compFeat(prevTot:totFeat,2:end) = feat.fibFeat; %Add to array
    compFeat(prevTot:totFeat,1) = zeros(lenFeat,1)+i; %Add index into meta data array
    compFeatMeta(i).imageName = feat.imageName;
    prevTot = totFeat+1; %Pointer to first array position
end

%Save feature array and meta array to disk
compFeatFF = [fibFeatDir 'compFeat.mat'];
save(compFeatFF,'compFeat','compFeatMeta');

%Read from file just to check
temp = load(compFeatFF);
compFeat = temp.compFeat;
compFeatMeta = temp.compFeatMeta;

numToTrain = 50;
if numToTrain >= totFeat
    %Error
    disp('Cannot train more fibers than exist in data.');
    return;
end

[lenFeat widFeat] = size(compFeat); %get size of the complete feature matrix (including meta index)
trainFeat = zeros(numToTrain,widFeat+1); %make space for training set, +1 for annotation (First column is annotation!)
trnIdx = zeros(numToTrain,1); %save index of already trained fibers
numTrn = 0;
%Loop begin
for i = 1:50
    %Choose a fiber at random
    repFg = 1; %repeat flag
    while repFg
        ridx = round(lenFeat*rand);
        if ridx == 0 %don't want a zero index
            repFg = 1; %throw out and draw again
        elseif ~isempty(intersect(ridx,trnIdx)) %don't want a repeat
            repFg = 1; %throw out and draw again
        else
            repFg = 0;
        end      
    end
    trnIdx(i) = ridx;    

    %Store current fiber features into a training array
    trainFeat(i,2:end) = compFeat(ridx,:);

    %Open the H&E image
    imgName = compFeatMeta(trainFeat(i,2)).imageName; %col 2 contains index to metaData
    [pathstr, name, ext] = fileparts(imgName);
    heFF = [heDir name '_HE' ext];
    info = imfinfo(heFF);
    heImg = imread(heFF,1,'Info',info);
    
    %Overlay the test fiber on H&E image
    guiOver = figure(100);
    set(guiOver,'Position',[10 70 500 500],'name','CurveAlign Overlay','Visible','on');
    %guiOver = figure('Resize','on','Units','pixels','Position',[215 90 600 600],'name','CurveAlign Overlay','NumberTitle','off','UserData',0);
    clf;
    overPanel = uipanel('Parent', guiOver,'Units','normalized','Position',[0 0 1 1]);
    overAx = axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);
    %overAx = gca();
    %IMG = imadjust(IMG);
    %imshow(IMG,'Parent',overAx);
    imshow(heImg);
    hold on;    
    len = size(heImg,1)/64; %defines length of lines to be displayed, indicating curvelet angle  
    object = struct('center',trainFeat(i,3:4),'angle',trainFeat(i,5),'weight',0);
    drawCurvs(object,overAx,len,0,90);
    
    %May want to overlay the boundary too
    %Open the mask image
    maskFF = [maskDir 'mask for ' imgName '.tif'];
    bdryImg = imread(maskFF);
    [B,L] = bwboundaries(bdryImg,4);
    %coords = vertcat(B{:,1});
    coords = B;
    for k = 1:length(coords)
       boundary = coords{k};
       plot(boundary(:,2), boundary(:,1), 'y');
       %drawnow;
    end    
    %plot(coords(:,2), coords(:,1), 'y');
    
    %May want to show more of the fiber, not just end point
    
    %Ask the user if fiber is positive or negative
    choice = questdlg('Is this fiber positive or negative?', ...
                      'Fiber Annotation', ...
                      'Positive','Negative','Quit','Negative');
    %Store annotation in training matrix (First column is annotation!)
    switch choice
        case 'Positive'
            trainFeat(i,1) = 1;
        case 'Negative'
            trainFeat(i,1) = 0;
        case 'Quit'
            break;
    end   
    numTrn = numTrn + 1;
end
%Loop end
if numTrn == 0
    return;
else
    finTrnSet = trainFeat(1:numTrn,:);
end

%Save training array, with annotations
trnFF = [fibFeatDir 'trnMatrix.mat'];
save(trnFF,'finTrnSet');

temp = load(trnFF);
finTrnSet = temp.finTrnSet;

%Run SVM on training array to generate a model
SVMStruct = svmtrain(finTrnSet(:,6:end),finTrnSet(:,1)); %(First column is annotation!)
%Save the SVM model for application to entire cohort
svmFF = [fibFeatDir 'svmStruct.mat'];
save(svmFF,'SVMStruct');

%Cross validation
folds = 3;
[lenFeat widFeat] = size(finTrnSet);
for i = 1:folds
    foldLen = round(lenFeat/folds);
    %create a vector of random indices
    rndIdx = logical(round(rand(foldLen,1)*(0.5+1/folds)));
    foldTrn = finTrnSet(rndIdx);
    foldVal = finTrnSet(~rndIdx);
    SVMStruct = svmtrain(foldTrn(:,6:end),foldTrn(:,1));
    Grp = svmcalssify(SVMStruct,foldVal(:,6:end));
end
    

%Test each feature to determine correlation with classification 
%Rank features based on best correlation

%Apply SVM model to rest of cohort
%Count positive fibers per ROI in each core
%Create final score
