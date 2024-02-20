function ROImeasurementsAll = getAlignment2ROI(ROIlist,OBJlist,distThresh)
% getAlignment2ROI.m. This function is based on function getRelativeangles.m to fiber alignment with respect to each ROI for fibers within the
% distance thresheold.
%Inputs:
% ROIlist-list of ROIs, struct with
% OBJlist- list of fiber centers and angles
% distThresh-maximum distance from the fiber to the boundary
%Output:
%   ROImeasurementsAll - ROI measurements, a structure containing:
% 1) angle2boundaryEdge
% 2) angle2boundaryCenter
% 3) angle2centersline]
% 4) fibercenterList
% 5) fiberangleList
% 6) distance(between fiber and boundary)
% 7) nfibers (within the distance to each boundary)
% example shown in getTifBoundary.m
%By Laboratory for Optical and Computational Instrumentation, UW-Madison
%since 2009

nROIs = length(ROIlist);
nObjects = length(OBJlist);
ROImeasurementsAll = repmat(struct('angle2boundaryEdge',[],'angle2boundaryCenter',[],...
    'angle2centersLine',[],'fibercenterList',[],'fiberangleList',[],...
    'distanceList',[],'boundaryPoints',[],'nFibers',[]),nROIs,1);

if nargin<3
    distThresh = [];
    selectObjectFlag = 0;  % donot select fibers based on the distance threshold
elseif nargin == 3
    selectObjectFlag = 1;  % select fibers based on the distance threshold
end

for iR = 1: nROIs
    bwROI.coords = ROIlist(iR).coords;
    bwROI.imageWidth = ROIlist(iR).imWidth;
    bwROI.imageHeight = ROIlist(iR).imHeight;
    if selectObjectFlag == 1
        [idx_dist,dist] = knnsearch(bwROI.coords,vertcat(OBJlist.center));
        fiberIndexs = find(dist <= distThresh);
    else
        fiberIndexs = 1:length(OBJlist);
        distPrecalculated = ROIlist(iR).dist;
    end
    %intitialization for each ROI
    angle2boundaryEdge = [];
    angle2boundaryCenter = [];
    angle2centersLine = [];
    fibercenterList = [];
    fiberangleList = [];
    distanceList = [];  %(between fiber and boundary)
    boundaryPoints = [];
    nFibers = []; % (within the distance to each boundary)

    if ~isempty(fiberIndexs)
         nFibers = length(fiberIndexs);
         if selectObjectFlag == 1
             if nFibers == 1
                 fprintf('ROI %d: Found one fiber within the %d distance to the boundary \n',iR,distThresh)
             else
                 fprintf('ROI %d: Found %d fibers within the %d distance to the boundary \n',iR, nFibers,distThresh)
             end
         else
             fprintf('Calculate all the relative alignment of pre-selected fibers. Total fiber number is %d \n',nFibers)
         end
        for iOBJ = 1:nFibers
            i = fiberIndexs(iOBJ);
            if selectObjectFlag == 1
                bwROI.index2object  = idx_dist(i);
            else
                bwROI.index2object = ROIlist(iR).index2object(iOBJ);
            end
            fiberobject.center = OBJlist(i).center; % [y x]
            fiberobject.angle = OBJlist(i).angle;
            angleOption = 0; figFlag = 0;% caclulate all angles and show them in a figure
            [relativeAngles,~] = getRelativeangles(bwROI,fiberobject,angleOption,figFlag);
            angle2boundaryEdge(iOBJ,1) = relativeAngles.angle2boundaryEdge;
            angle2boundaryCenter(iOBJ,1) = relativeAngles.angle2boundaryCenter;
            angle2centersLine(iOBJ,1) = relativeAngles.angle2centersLine;
            fibercenterList(iOBJ,1:2)= fiberobject.center;% [y x]
            fiberangleList(iOBJ,1) = fiberobject.angle;
            if selectObjectFlag == 1
                distanceList(iOBJ,1) = dist(i);
            else
                distanceList(iOBJ,1) = distPrecalculated(iOBJ);
            end
            boundaryPoints(iOBJ,1:2) = bwROI.coords(bwROI.index2object,:);
        end
    else
        if selectObjectFlag == 1
            fprintf('ROI %d: NO fiber is within the specified distance (%d) to the boundary \n',iR,distThresh)
        else
            fprintf('ROI %d: NO fiber is selected \n',iR)
        end
        continue
    end
    ROImeasurementsAll(iR,1).angle2boundaryEdge = angle2boundaryEdge;
    ROImeasurementsAll(iR,1).angle2boundaryCenter = angle2boundaryCenter;
    ROImeasurementsAll(iR,1).angle2centersLine = angle2centersLine;
    ROImeasurementsAll(iR,1).fibercenterList = fibercenterList;
    ROImeasurementsAll(iR,1).fiberangleList = fiberangleList;
    ROImeasurementsAll(iR,1).distanceList = distanceList;
    ROImeasurementsAll(iR,1).boundaryPoints = boundaryPoints;
    ROImeasurementsAll(iR,1).nFibers = nFibers;
end

end