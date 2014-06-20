
clear all;
close all;

%Load all feature files into RAM as a big array, if possible...

% fibFeatDir = 'P:\\Conklin data - Invasive tissue microarray\\TrainingSets20131113\\CA_Out\\';
% heDir = 'P:\\Conklin data - Invasive tissue microarray\\Validation\\Composite\\RGB\\';
% maskDir = 'P:\\Conklin data - Invasive tissue microarray\\TrainingSets20131113\\';
fibFeatDir = 'Z:\\bredfeldt\\Conklin data - Invasive tissue microarray\\TrainingSets20131113\\CA_Out\\';
heDir = 'Z:\\bredfeldt\\Conklin data - Invasive tissue microarray\\Validation\\Composite\\RGB\\';
maskDir = 'Z:\\bredfeldt\\Conklin data - Invasive tissue microarray\\TrainingSets20131113\\';

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
obsFileIdx = zeros(lenFeatFiles,1);
totFeat = 0;
for i = 1:lenFeatFiles
    %Find how many observations are in each file
    obsName = featFiles(i).name;
    bff = [fibFeatDir obsName];
    feat = load(bff);
    [lenFeat widFeat] = size(feat.fibFeat);
    totFeat = totFeat + lenFeat;
    obsFileIdx(i) = totFeat;
end
%Allocate space for complete feature array (For all images)
compFeat = zeros(totFeat,widFeat+1);
compFeatMeta(lenFeatFiles) = struct('imageName',[],'topLevelDir',[],'fireDir',[],'outDir',[],'numToProc',[],'fibProcMeth',[],'keep',[],'distThresh',[]);

%Put together big array
prevTot = 1;
totFeat = 0;
for i = 1:lenFeatFiles
    obsName = featFiles(i).name;
    bff = [fibFeatDir obsName];
    feat = load(bff);
    [lenFeat widFeat] = size(feat.fibFeat);
    totFeat = totFeat + lenFeat; %Pointer to last array position
    compFeat(prevTot:totFeat,1:end-1) = feat.fibFeat; %Add to array
    compFeat(prevTot:totFeat,end) = zeros(lenFeat,1)+i; %Add index into meta data array
    compFeatMeta(i).imageName = feat.imgNameP;
    prevTot = totFeat+1; %Pointer to first array position
end
featNames = feat.featNames;

%Save feature array and meta array to disk
compFeatFF = [fibFeatDir 'compFeat.mat'];
% save(compFeatFF,'compFeat','compFeatMeta');

%%
%Read from file just to check
temp = load(compFeatFF);
compFeat = temp.compFeat;
compFeatMeta = temp.compFeatMeta;

%% Train based on image annotations as a whole
labelMeta = [1 0 0 0 1 0 0 1 0 0 0 1 1 1 1 1]; %label for each of 16 training images (label image as a whole)

[lenFeat widFeat] = size(compFeat); %get size of the complete feature matrix (including meta index)
labelObs = zeros(lenFeat,1); %The label for each observation
for i = 1:lenFeat
    labelObs(i) = labelMeta(compFeat(i,end)); %last col contains index to metaData
end
labelObs = logical(labelObs);

    %1. fiber Key into CTFIRE list
    %2. row
    %3. col
    %4. abs ang
    %5. fiber weight
    %6. total length
    %7. end to end length
    %8. curvature
    %9. width
    %10. dist to nearest 2
    %11. dist to nearest 4
    %12. dist to nearest 8
    %13. dist to nearest 16
    %14. mean dist
    %15. std dist
    %16. box density 32
    %17. box density 64
    %18. box density 128
    %19. alignment of nearest 2
    %20. alignment of nearest 4
    %21. alignment of nearest 8
    %22. alignment of nearest 16
    %23. mean align
    %24. std align
    %25. box alignment 32
    %26. box alignment 64
    %27. box alignment 128
    %28. nearest dist to bound
    %29. inside epi region
    %30. nearest relative boundary angle
    %31. extension point distance
    %32. extension point angle
    %33. boundary point row
    %34. boundary point col
    
posObs = compFeat(labelObs,:); %positive fiber observations
negObs = compFeat(~labelObs,:); %negative fiber observations

posM = nanmean(posObs); %average over observations
negM = nanmean(negObs);
posStd = nanstd(posObs);
negStd = nanstd(negObs);

compM = [posM; negM]; %composite matrix
compStd = [posStd; negStd];
maxM = nanmax(compM); %max between positive and neg
compMN(1,:) = compM(1,:)./maxM; %normalize
compMN(2,:) = compM(2,:)./maxM;
compStdN(1,:) = compStd(1,:)./maxM;
compStdN(2,:) = compStd(2,:)./maxM;

feats = [6 8:9 14:18 23:32]; %Best feature set
%feats = [28:32];
featNamesS = featNames(feats); %throw out names that are not included
lenSubFeats = length(feats);

%Now make each image an observation by calculating the mean over fibers
imgObsM = zeros(lenFeatFiles,widFeat);
for i = 1:lenFeatFiles    
    imgObsM(i,:) = nanmean(compFeat(compFeat(:,end) == i,:));
end

%check to make sure these features can classify the training set
SVMStruct = svmtrain(imgObsM(:,feats),labelMeta,'showplot','true');
if lenSubFeats == 2
    xlabel(featNamesS(1));
    ylabel(featNamesS(2));
end
v = svmclassify(SVMStruct,imgObsM(:,feats));
labelMeta = labelMeta';
tp = sum((v(:,1) == labelMeta(:,1) & labelMeta(:,1) == 1));
tn = sum((v(:,1) == labelMeta(:,1) & labelMeta(:,1) == 0));
fp = sum((v(:,1) ~= labelMeta(:,1) & labelMeta(:,1) == 0));
fn = sum((v(:,1) ~= labelMeta(:,1) & labelMeta(:,1) == 1));
sens = tp/(tp+fn);
spec = tn/(fp+tn);   
disp(sprintf('mean sensitivity: %f',mean(sens)));
disp(sprintf('mean specificity: %f',mean(spec)));

%Plot normalized average feature values for each class
figure(500);
%set(gcf,'Position',[1 1 1000 750]);
difCompMN = compMN(1,:) - compMN(2,:);
difCompStd = sqrt(compStdN(1,:).^2 + compStdN(2,:));
difMN = difCompMN(:,feats);
difStdS = difCompStd(:,feats);
[difS, idxS] = sort(difMN);
barh(difS);
featNamesS1 = featNamesS(idxS); %Sorted name list
difStdS = difStdS(idxS)./10; %shrink to make plotable
%xlim([0.2 1.0]);
set(gca,'YTick',1:lenSubFeats,'YTickLabel',featNamesS1);
set(gca,'XGrid','off','YGrid','on');
xlabel('Normalized Difference (Pos-Neg)');
for i = 1:lenSubFeats
    %plot relative error
    yp = lenSubFeats-i+1;
    line([difS(i)-difStdS(yp) difS(i)+difStdS(yp)],[i i],'Color','g');
end

%Plot feature rank
wtSVM = SVMStruct.Alpha'*SVMStruct.SupportVectors;
absWt = wtSVM.^2;
[absWtS, idxS] = sort(absWt); %Sort based on importance
figure(501); barh(absWtS); %plot bar graph
%set(gcf,'Position',[1 1 1000 750]);
featNamesS = featNamesS(idxS); %sort feature names
set(gca,'YTick',1:lenSubFeats,'YTickLabel',featNamesS);
xlabel('Classification Importance');

%Save rank to file
fibFeatDir2 = pwd;
featRankFF = [fibFeatDir2 'featRank.txt'];
fid = fopen(featRankFF,'w+');
difMNS = difMN(idxS);
for i = 1:lenSubFeats
    fprintf(fid,'%d\t%s\t%f\t%f\r\n',i,featNamesS{i},absWtS(i),difMNS(i));
end   
fclose(fid);

%% Try to use each fiber as an observation
compFeat(isnan(compFeat)) = 0;
folds = 50;
rndIdx = logical(round(rand(lenFeat,1)*(0.5+1/folds)));
%train
SVMStruct = svmtrain([compFeat(rndIdx,feats)],labelObs(rndIdx),'kernel_function','linear','showplot','true');
if lenSubFeats == 2
    xlabel(featNamesS(1));
    ylabel(featNamesS(2));
end
v = svmclassify(SVMStruct,compFeat(:,feats));
tp = sum((v(:,1) == labelObs(:,1) & labelObs(:,1) == 1));
tn = sum((v(:,1) == labelObs(:,1) & labelObs(:,1) == 0));
fp = sum((v(:,1) ~= labelObs(:,1) & labelObs(:,1) == 0));
fn = sum((v(:,1) ~= labelObs(:,1) & labelObs(:,1) == 1));
sens = tp/(tp+fn);
spec = tn/(fp+tn);   
disp(sprintf('mean sensitivity: %f',mean(sens)));
disp(sprintf('mean specificity: %f',mean(spec)));

wtSVM = SVMStruct.Alpha'*SVMStruct.SupportVectors;
absWt = wtSVM.^2;
figure(300); barh(absWt);
 
return;
%% Train based on each individual fiber annotation
% numToTrain = 50;
% if numToTrain >= totFeat
%     Error
%     disp('Cannot train more fibers than exist in data.');
%     return;
% end
% 
% %make a table to look at feature data of fiber
% %guiTable = figure('Resize','on','Units','pixels','Position',[340 395 450 300],'Visible','off','MenuBar','none','name','CurveAlign Results Table','NumberTitle','off','UserData',0);
% 
% [lenFeat widFeat] = size(compFeat); %get size of the complete feature matrix (including meta index)
% trainFeat = zeros(numToTrain,widFeat+1); %make space for training set, +1 for annotation (First column is annotation!)
% trnIdx = zeros(numToTrain,1); %save index of already trained fibers
% numTrn = 0;
% %Loop begin
% for i = 1:50
%     %Choose a fiber at random
%     repFg = 1; %repeat flag
%     while repFg
%         ridx = round(lenFeat*rand);
%         if ridx == 0 %don't want a zero index
%             repFg = 1; %throw out and draw again
%         elseif ~isempty(intersect(ridx,trnIdx)) %don't want a repeat
%             repFg = 1; %throw out and draw again
%         else
%             repFg = 0;
%         end      
%     end
%     trnIdx(i) = ridx;    
% 
%     %Store current fiber features into a training array
%     trainFeat(i,2:end) = compFeat(ridx,:);
% 
%     %Open the H&E image
%     imgName = compFeatMeta(trainFeat(i,2)).imageName; %col 2 contains index to metaData
%     [pathstr, name, ext] = fileparts(imgName);
%     heFF = [heDir name '_RGB' ext];
%     info = imfinfo(heFF);
%     heImg = imread(heFF,1,'Info',info);
%     
%     %Overlay the test fiber on H&E image
%     guiOver = figure(100);
%     set(guiOver,'Position',[10 70 500 500],'name','CurveAlign Overlay','Visible','on');    
%     clf;
%     overPanel = uipanel('Parent', guiOver,'Units','normalized','Position',[0 0 1 1]);
%     overAx = axes('Parent',overPanel,'Units','normalized','Position',[0 0 1 1]);   
%     imshow(heImg);
%     hold on;    
%     len = size(heImg,1)/56; %defines length of lines to be displayed, indicating curvelet angle
%     plotRidx = max(1,ridx-50):min(lenFeat,ridx+50); %plot a few fibers    
%     for k = plotRidx
%         object = struct('center',compFeat(k,2:3),'angle',compFeat(k,4),'weight',0);
%         if k == ridx
%             drawCurvs(object,overAx,len,0,90,10,1);
%         else
%             drawCurvs(object,overAx,len,1,90,10,1);
%         end
%     end
%     
%     %May want to overlay the boundary too
%     %Open the mask image
%     maskFF = [maskDir 'mask for ' imgName '.tif'];
%     bdryImg = imread(maskFF);
%     [B,L] = bwboundaries(bdryImg,4);    
%     coords = B;
%     for k = 1:length(coords)
%        boundary = coords{k};
%        plot(boundary(:,2), boundary(:,1), 'y');
%     end 
%     
%     c = compFeat(ridx,2:3);
%     xAxLim = [c(2)-400 c(2)+400]; %Zoom in on fiber
%     yAxLim = [c(1)-400 c(1)+400]; %Zoom in on fiber
%     xlim(xAxLim);
%     ylim(yAxLim);
%     
%     %Ask the user if fiber is positive or negative
%     choice = questdlg('Is this fiber positive or negative?', ...
%                       'Fiber Annotation', ...
%                       'Positive','Negative','Quit','Negative');
%     %Store annotation in training matrix (First column is annotation!)
%     switch choice
%         case 'Positive'
%             trainFeat(i,1) = 1;
%         case 'Negative'
%             trainFeat(i,1) = 0;
%         case 'Quit'
%             break;
%     end   
%     numTrn = numTrn + 1;
% end
%%
%Loop end
if numTrn == 0
    return;
else
    finTrnSet = trainFeat(1:numTrn,:);
end
%%
%Save training array, with annotations
c = clock;
dateStr = sprintf('%d%d%d%d%d%d', c(1), c(2), c(3), c(4), c(5), round(c(6)));
trnFF = [fibFeatDir 'trnMatrix_' dateStr '.mat'];
save(trnFF,'finTrnSet');

%%
temp = load(trnFF);
finTrnSet = temp.finTrnSet;

feats = [4 18]; %6:end

%Run SVM on training array to generate a model
SVMStructA = svmtrain(finTrnSet(:,[4 18]),finTrnSet(:,1)); %(First column is annotation!)
%Save the SVM model for application to entire cohort
svmFF = [fibFeatDir 'svmStruct_' dateStr '.mat'];
save(svmFF,'SVMStructA');
%%
%Cross validation
folds = 3;
[lenFeat widFeat] = size(finTrnSet);
figure(200);
for i = 1:folds
    %create a vector of random indices
    rndIdx = logical(round(rand(lenFeat,1)*(0.5+1/folds)));
    foldTrn = finTrnSet(rndIdx,:);
    foldVal = finTrnSet(~rndIdx,:);
    SVMStruct = svmtrain(foldTrn(:,feats),foldTrn(:,1),'kernel_function','linear','showplot','true');
    pause;
    v = svmclassify(SVMStruct,foldVal(:,feats));
    
    tp = sum((v(:,1) == foldVal(:,1) & foldVal(:,1) == 1));
    tn = sum((v(:,1) == foldVal(:,1) & foldVal(:,1) == 0));
    fp = sum((v(:,1) ~= foldVal(:,1) & foldVal(:,1) == 1));
    fn = sum((v(:,1) ~= foldVal(:,1) & foldVal(:,1) == 0));
    
    sens(i) = tp/(tp+fn)
    spec(i) = tn/(fp+tn)    
end
disp(sprintf('mean sensitivity: %f',mean(sens)));
disp(sprintf('mean specificity: %f',mean(spec)));    

%Test each feature to determine correlation with classification 
%Rank features based on best correlation

wtSVM = SVMStructA.Alpha'*SVMStructA.SupportVectors;
absWt = abs(wtSVM);
figure(3); bar(absWt);

%Apply SVM model to rest of cohort
%Count positive fibers per ROI in each core
%Create final score
