clear all;
close all;
curvData = load('Features\trn.mat');
[~,~,survData] = xlsread('dataTACS.xls');

%Arrange data, make sure it's all in the same order, and all removed samples are accounted for
[numCases, ~] = size(survData);
[numCurvCases,numFeat] = size(curvData.trnData);
numCases = numCases-1; %account for label row
featData = zeros(numCases,numFeat); %make a new matrix of features
for survIdx = 1:numCases
    survNm = survData(survIdx+1,1);
    survNm = survNm{1};
    if strcmp(survNm(1),'A')
        survNmMod = '1B_';
    else
        survNmMod = '2B_';
    end
    survNmMod = [survNmMod survNm(2:end) '.tif'];
    
    %search feature list for matching name
    for curvIdx = 1:numCurvCases
        curvNm = curvData.nameList(curvIdx).name;
        if strcmpi(survNmMod,curvNm) %case insensitive
            debug = 1;
            %put features into the right spot in new feature matrix
            featData(survIdx,:) = curvData.trnData(curvIdx,:);
            break;
        end
    end
end

%classifiy based on survival
dfs = survData(2:end,5);
dfs = vertcat(dfs{:});
dfse = survData(2:end,6);
dfse = vertcat(dfse{:});
dss = survData(2:end,7);
dss = vertcat(dss{:});
dsse = survData(2:end,8);
dsse = vertcat(dsse{:});
dsse(isnan(dsse)) = 0;

mdfs = nanmean(dss);
grpVal = dfs<mdfs; %validation labels based on survival

%Train
trnList = [1, 27, 34, 170, 173, 181, 192, 199, ...
           5, 8, 17, 29, 32, 50, 80, 126];
curvData.nameList(trnList).name; %check to make sure training set is correct
featList = [18:19];
trnData = curvData.trnData(trnList,featList);
%grpData = data.grpData;

%Find thresholds for length, curvature, width, density, and alignment
if length(featList) == 20
posLen = mean(trnData(1:8,1));
negLen = mean(trnData(9:16,1));
posCurv = mean(trnData(1:8,3));
negCurv = mean(trnData(9:16,3));
posWid = mean(trnData(1:8,5));
negWid = mean(trnData(9:16,5));
posDen = mean(trnData(1:8,14));
negDen = mean(trnData(9:16,14));
posAlign = mean(trnData(1:8,16));
negAlign = mean(trnData(9:16,16));
posROI = mean(trnData(1:8,20));
negROI = mean(trnData(9:16,20));
fprintf('Length pos: %0.3f, neg: %0.3f, mid: %0.3f\n',posLen,negLen,posLen-(posLen-negLen)/2);
fprintf('Curvature pos: %0.3f, neg: %0.3f, mid: %0.3f\n',posCurv,negCurv,posCurv-(posCurv-negCurv)/2);
fprintf('Width pos: %0.3f, neg: %0.3f, mid: %0.3f\n',posWid,negWid,posWid-(posWid-negWid)/2);
fprintf('Den pos: %0.3f, neg: %0.3f, mid: %0.3f\n',posDen,negDen,posDen-(posDen-negDen)/2);
fprintf('Align pos: %0.3f, neg: %0.3f, mid: %0.3f\n',posAlign,negAlign,posAlign-(posAlign-negAlign)/2);
end

options = statset('Display','iter');
grpData = [1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0]';
figure(1);
svmStruct = svmtrain(trnData,grpData,'options',options,'showplot',true,'kernel_function','linear');

%validate    
%figure(2);
v = svmclassify(svmStruct,featData(:,featList));

%Count tp, tn, fp, fn

tp = sum((v == grpVal & grpVal == 1));
tn = sum((v == grpVal & grpVal == 0));
fp = sum((v ~= grpVal & grpVal == 0));
fn = sum((v ~= grpVal & grpVal == 1));

sens = tp/(tp+fn);
spec = tn/(fp+tn);

disp(sprintf('mean sensitivity: %f',mean(sens)));
disp(sprintf('mean specificity: %f',mean(spec)));
%svmStruct.Bias - svmStruct.ScaleData.shift


for i = 2:3
    if i == 2
        %hazard analysis
        %Cox Prop Hazard Fit to DFS
        survS = dfs;
        survSE = ~dfse;
        txt = 'DFS';
        xpos = 60;
    elseif i == 3
        survS = dss;
        survSE = ~dsse;
        txt = 'DSS';
        xpos = 90;
    end
    [b_1,logL_1,H,stats_1] = coxphfit(v,survS,'censoring',survSE);

    disp([txt ' exponents:']);
    fprintf('  sc1: %0.3f\n',exp(b_1));
    disp([txt ' p values:']);
    fprintf('  sc1: %0.3f\n',stats_1.p);

    %Kaplan-Meier Curvs
    v = logical(v);
    survPos = survS(v);
    survPosE = survSE(v);
    survNeg = survS(~v);
    survNegE = survSE(~v);
    [f,x,flo,fup] = ecdf(survPos,'censoring',survPosE,'function','survivor');
    disp([txt ' positive N:']);
    fprintf(' %d\n',length(survPos));
    disp([txt ' negative N:']);
    fprintf(' %d\n',length(survNeg));
    
    figure(i); clf;
    axes('LineWidth',5,'FontSize',18);
    stairs(x,f,'k','LineWidth',5);
    hold on;

    [f,x,flo,fup] = ecdf(survNeg,'censoring',survNegE,'function','survivor');
    stairs(x,f,'k--','LineWidth',5); 
    L = legend('TACS-3 Pos','TACS-3 Neg');
    set(L, 'Box', 'off');
    text(xpos,0.95,txt,'FontSize',24);
    xlabel('Months');
    ylabel('Survival Fraction');
    ylim([0.4 1.0]);
end

%compute correlation between man and auto scores
sc1 = survData(2:end,2);
sc1 = double(vertcat(sc1{:}));
sc2 = survData(2:end,3);
sc2 = vertcat(sc2{:});
sc3 = survData(2:end,4);
sc3 = vertcat(sc3{:});

[c1,p1] = corrcoef(v,sc1);
[c2,p2] = corrcoef(v,sc2);
[c3,p3] = corrcoef(v,sc3);
fprintf('Cor sc1: %0.3f, sc2: %0.3f, sc3: %0.3f\n',c1(2),c2(2),c3(2));
fprintf('CorP sc1: %0.6f, sc2: %0.6f, sc3: %0.6f\n',p1(2),p2(2),p3(2));