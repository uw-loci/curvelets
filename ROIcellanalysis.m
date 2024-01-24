function [cellFeatures] = ROIcellanalysis(imageName,tumorIndex)

%ROIcellanalysis.m-extract and visualize the quantitative cell information
%with respect to a specified tumor region
%   1. Boundary analysis = compare cell angles to boundary angles and generate statistics
%   2. Absolute angle analysis = just return absolute cell angles and statistics
%   3. May also select to use the fire results (if fireDir is populated)
%
% Inputs
%   imageName:2D RGB image, size  = [M N 3]
%   tumorIndex: associated the selected ROI(s)
% using naming convensiong 
%   cellBoundaryfile: name of the cell boundary data file- [imageNameNOextension '_cellDetails.mat']
%   cellQuanticationfile: name of the cell measurements data file
%   [imageNameNOextension '_cellMeasurements.csv'];
%   tumorBoundaryfile: name of the cell boundary data file same as the Tumor
%   boundary mask, loaded into the ROI manager as separate ROIs.

% Optional Inputs
% advancedOPT: a structure contains the advanced interface controls 
% 

% Outputs
% cellFeatures: cell density, orientation, 
%
% Eliceiri Lab (aka, Laboratory for Optical and Computational
% Instrumentation 2021)

%% import cell and tumor information
imagePath = 'D:\githubcurvelets2021\ctcq_prototype1\testDataset1';
imageName = '2B_D9_ROI1.tif';
cellBoundaryfile = '2B_D9_ROI1_cellDetails.mat';
cellQuantificationfile = 'VAMPIRE datasheet mask.tif.csv';
tumorBoundaryfile = 'mask for 2B_D9_ROI1.tif.tif';

%% show bright field image with cell overlay
cellBoundaries = load(fullfile(imagePath,'cellImages','cellanalysisOUT',cellBoundaryfile),'details');
%details.coord: outline[x y] of individual cells
%details.points: center [x y] of individual cells
cellCoords = cellBoundaries.details.coord;    % coordinates of cell boundaries
cellNumber = size(cellBoundaries.details.coord,1);  % number of cells
cellCoordsnumber = size(cellBoundaries.details.coord,3); % the number of coordinates for each cell boundary
cellCenters = cellBoundaries.details.points;
close all;
fig1 = figure('Name','cell anlaysis','pos', [50 300 600 600]);
imshow(fullfile(imagePath,'cellImages',imageName));
hold on
cellcolor = 'y'; 
cellBDwidth = 1;
cellCenterMarkerSize = 5;
cellsBDxy = cell(cellNumber,1);  % cell boundaries in a cell structure
for i = 1: cellNumber
    cellX = squeeze(cellCoords(i,1,:));
    cellY = squeeze(cellCoords(i,2,:));
    cellCenter = cellCenters(i,:);
    plot([cellY;cellY(1)],[cellX;cellX(1)],[cellcolor '-'],'LineWidth',cellBDwidth)
    plot(cellCenter(2),cellCenter(1),'r.','MarkerSize',cellCenterMarkerSize);
    cellsBDxy{i} = [cellX cellY];
 end

%% create cells mask from the coordinates
% adapted from 
imgMeta = imfinfo(fullfile(imagePath,'cellImages',imageName));
s2 = 1;  
nrow = imgMeta(s2).Height;
ncol = imgMeta(s2).Width;
binaryMask=zeros(nrow,ncol); %pre-allocate a mask
colorMask = zeros(nrow,ncol,3);
%mask_final = [];
for ic=1:cellNumber %for each region
    fprintf('Processing cell # %d \n',ic);
    cellX = cellsBDxy{ic}(:,1);
    cellY = cellsBDxy{ic}(:,2);
    %make a mask and add it to the current mask
    %this addition makes it obvious when more than 1 layer overlap each
    %other, can be changed to simply an OR depending on application.
    polygonTemp = poly2mask(cellY,cellX,nrow,ncol);
    binaryMask=binaryMask+ic*(1-min(1,binaryMask)).*polygonTemp;%
    colorMask = colorMask + cat(3, rand*polygonTemp, rand*polygonTemp,rand*polygonTemp);
    %binary mask for all objects
    %imshow(ditance_transform)
end

figure;imshow(binaryMask)
figure;imshow(colorMask)

%% import the boundary mask

tumorsBDmask = imread(fullfile(imagePath,'collagenImages','CA_Boundary',tumorBoundaryfile));
fig2 = figure('Name','Tumor mask', 'pos',[1000 400 600 600]);
imshow(tumorsBDmask);
%retrive the coordinates of the tumor boundaries
tumorsBDxy =  bwboundaries(tumorsBDmask);  % coordinates of the tumorboundary
tumorNumber = size(tumorsBDxy,1);

%% get the measurements of the cells within a selected tumor
tumorColor = 'r';
tumorBDwidth = cellBDwidth*1.5;
tumorIndex = 1;
for it = tumorIndex
    %get the mask of individual tumor area
    tumorX = tumorsBDxy{it}(:,1);
    tumorY = tumorsBDxy{it}(:,2);
    tumorsingleMask = poly2mask(tumorY,tumorX,nrow,ncol);
    fig2 = figure('Name','Cell and Tumor','pos',[1000 300 600 600]);
    imshow(fullfile(imagePath,'cellImages',imageName));
    hold on
    tumorX = tumorsBDxy{it}(:,1);
    tumorY = tumorsBDxy{it}(:,2);
    plot([tumorY;tumorY(1)],[tumorX;tumorX(1)],[tumorColor '-'],'LineWidth',tumorBDwidth)
%     figure(fig2)
%     imshow(tumorsingleMask)
    cellsFlag = zeros(size(cellCenters,1),1);
    for ic = 1:cellNumber
        cellcenterY = cellCenters(ic,1);
        cellcenterX = cellCenters(ic,2);
        if tumorsingleMask(cellcenterY,cellcenterX) == 1
            cellsFlag(ic) = 1;
        end
    end
    cellinTumorFlag = find(cellsFlag == 1);
    cellsIn = cellCenters(cellinTumorFlag,:);
    plot(cellsIn(:,2),cellsIn(:,1),'r.','MarkerSize',cellCenterMarkerSize);
    hold off 
end

%% visualize the features of the selected cells.
[cellfeaturesData, cellfeaturesText] = xlsread(fullfile(imagePath,'cellimages','cellanalysisOUT',cellQuantificationfile));
cellFeatureNames = cellfeaturesText(1,2:end);
cellfeatureNumber = size(cellFeatureNames,2);
for ii = 1:cellfeatureNumber
   fprintf('cell feature %d: %s  \n', ii, cellFeatureNames{ii}) 
end

%% histogram of the selected feature
cellfeatureID = 6;
fig4 = figure('Name',sprintf('Cell feature-%s',cellFeatureNames{cellfeatureID}),'pos',[500 300 400 400]);
hist(cellfeaturesData(:,cellfeatureID))


