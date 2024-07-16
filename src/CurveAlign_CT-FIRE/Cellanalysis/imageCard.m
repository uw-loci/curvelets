classdef imageCard
    
    % This class takes an H&E nuclei image and segment it using StarDist
    % and categorize the shapes of nuclei using VAMPIRE. It returns a
    % cellArray which is an array of nuclei objects. The object name of
    % them is cellCardInd.
    
    properties (Access=private)
        imageName
        imagePath
    end
    
    properties
        cellArray
    end
    
    methods
        function obj=imageCard(imageName,imagePath,samplingFactor,parameters_seg)
            % stardistParameters = struct('deepMethod',deepMethod,'modelName',deepModel,'defaultParametersFlag',default_parameters_flag,...
            %         'prob_thresh',0.2,'nms_threshold',0.5,'Normalization_lowPercentile',1,...
            %         'Normalization_highPercentile',99.8);
             method_seg = parameters_seg.deepMethod;
             modelParameters = parameters_seg;
            if ~exist('imagePath','var')
                imagePath = "";
            end
            obj.imageName = imageName;
            obj.imagePath = imagePath;
            if imagePath ~= ""
                image = fullfile(imagePath,imageName);
            else
                image = imageName;
            end
            % addpath 'vampire'
            if strcmp(method_seg,'FromMaskfiles-SD')
                pymatlabflag = 0;
            elseif strcmp(method_seg,'StarDist')
                pymatlabflag = 1; % didnot go through in matlab, pyenv terminated unexpectedly
            else
                error('Invalid segmentation method: %s',method_seg)
            end
            if pymatlabflag == 1
                if samplingFactor == 1
                   samplingFlag = 0;
                else
                    samplingFlag = 1;
                end
                if samplingFlag == 1
                    sampling(image,samplingFactor)  %
                else
                    copyfile(fullfile(imagePath,imageName),'sample.tif');
                end
                stardistLink('sample.tif',0,samplingFactor,modelParameters);
                load('labels_sd.mat','labels');
                load('details_sd.mat','details');
            else
                [fileList, pathGet]=uigetfile({'*.tif;*.mat','Tiff or MAT Files';'*.*','All Files'},...
                    'Select Cell mask file(s) from StarDist output',pwd,'MultiSelect','on');
                if iscell(fileList)
                    for i = 1: length(fileList)
                        [~,~,fileType] = fileparts(fileList{i});
                        if strcmp(fileType,'.mat')
                            load(fullfile(pathGet,fileList{i}));
                        elseif strcmp(fileType,'.tif')
                            labels=imread(fullfile(pathGet,fileList{i}));
                        else
                            fprintf('This file %s is not a valid mask file \n', fullfile(pathGet,fileList{i}))
                        end
                    end
                elseif ischar(fileList)
                    [~,~,fileType] = fileparts(fileList);
                    if strcmp(fileType,'.mat')
                        load(fullfile(pathGet,fileList));
                    elseif strcmp(fileType,'.tif')
                        labels=imread(fullfile(pathGet,fileList));
                    else
                        fprintf('This file %s is not a valid mask file \n', fullfile(pathGet,fileList))
                    end
                end
                % load('labels_sd.mat','labels');
                % load('details_sd.mat','details');
            end

            % for vampire analysis
            % currentDir = pwd;
            % ID = 1;
            % csvData = ["set ID" "condition" "set location" "tag" "note";...
            %     ID "--" currentDir "mask.tif" "--"];
            % writematrix(csvData, 'image.csv')
            % VampireCaller('image.csv')
            % obj.cellArray = cellCreation(imageName);
            % obj.cellArray = cellCreation2(imageName);
            obj.cellArray = cellCreation_MAT(imageName,labels,details); % don't use any vampire results
        end
        
        function imgName=getImageName(obj)
            imgName = obj.imageName;
        end
        
        function path=getPath(obj)
            path = obj.imagePath;
        end
    end
end

function cells=cellCreation2(imageName,labels,details)

stats = regionprops(labels,'Area','Circularity','ConvexArea','Eccentricity',...
    'Extent','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');

numCells = size(stats);
cells = cellCardInd.empty(numCells(1),0);

T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
sizeTable = size(T);
idxVampire = 1;
T3 = T.(3);
T12 = T.(12);

[numCellsArray, minDistanceArray, numPixelsArray] = cellDensity(20,stats); % radius

for i=1:numCells(1)
    
    if T3(idxVampire) == i
        vampireShapeMode = T12(idxVampire);
        if idxVampire < sizeTable(1)
            idxVampire = idxVampire + 1;
        end
    else
        vampireShapeMode = 0;
    end
    
    cell = cellCardInd(imageName,i,details.points(i,:),details.coord(i,:,:),...
        stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,stats(i).Eccentricity,...
        stats(i).Extent,stats(i).MajorAxisLength,stats(i).MinorAxisLength,...
        stats(i).Orientation,stats(i).Perimeter, vampireShapeMode,numCellsArray(i),...
        minDistanceArray(i),numPixelsArray(i));
    cells(i) = cell;
end

save('cells.mat','cells');

end

function cells=cellCreation_MAT(imageName,labels,details)

% img = imread('mask.tif');

stats = regionprops(labels,'Area','Circularity','ConvexArea','Eccentricity',...
    'Extent','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');
numCells = size(stats);
cells = cellCardInd.empty(numCells(1),0);

% T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
% sizeTable = size(T);
% idxVampire = 1;
% T3 = T.(3);
% T12 = T.(12);

[numCellsArray, minDistanceArray, numPixelsArray] = cellDensity(20,stats); % radius

for i=1:numCells(1)
    
    % if T3(idxVampire) == i
    %     vampireShapeMode = T12(idxVampire);
    %     if idxVampire < sizeTable(1)
    %         idxVampire = idxVampire + 1;
    %     end
    % else
    %     vampireShapeMode = 0;
    % end
    vampireShapeMode = [];
    cell = cellCardInd(imageName,i,details.points(i,:),details.coord(i,:,:),...
        stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,stats(i).Eccentricity,...
        stats(i).Extent,stats(i).MajorAxisLength,stats(i).MinorAxisLength,...
        stats(i).Orientation,stats(i).Perimeter, vampireShapeMode,numCellsArray(i),...
        minDistanceArray(i),numPixelsArray(i));
    cells(i) = cell;
end

save('cells.mat','cells');

end

function cells=cellCreation(imageName,details,labels)

T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
sizeTable = size(T);
cells = cellCard.empty(sizeTable(1),0);

% load('details_sd.mat','details')

T3 = T.(3);
T4 = T.(4);
T5 = T.(5);
T6 = T.(6);
T7 = T.(7);
T8 = T.(8);
T9 = T.(9);
T10 = T.(10);
T11 = T.(11);
T12 = T.(12);

for i=1:sizeTable(1)
    cell = cellCard(imageName,T3(i),[T4(i) T5(i)],details.coord(i,:,:),...
        T6(i),T7(i),T8(i),T9(i),T10(i),T11(i),T12(i));
    cells(i) = cell;
end

end