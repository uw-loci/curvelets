function [measAngs,measDist,inCurvs,outCurvs,measBndry,inDist,numImPts] = getTifBoundary(coords,img,object,imgName,distThresh,fibKey,fibProcMeth)

% getTifBoundary.m - This function takes the coordinates from the boundary file, associates them with curvelets, and produces relative angle measures. 
% 
% Inputs:
%   coords - the locations of the endpoints of each line segment making up the boundary
%   img - the image being measured
%   object - a struct containing the center and angle of each measured curvelet, generated by the newCurv function
%   distThresh - number of pixels from boundary we should evaluate curvelets
%   boundaryImg - tif file with boundary outlines, must be a mask file
%   fibKey - list indicating the beginning of each new fiber in the object struct, allows for fiber level processing
%
% Output:
%   histData = the bins and counts of the angle histogram
%   inCurvs - curvelets that are considered
%   outCurvs - curvelets that are not considered
%   measBndry = points on the boundary that are associated with each curvelet
%   inDist = distance between boundary and curvelet for each curvelet considered
%   numImPts = number of points in the image that are less than distThresh from boundary
%
%
% By Jeremy Bredfeldt, LOCI, Morgridge Institute for Research, 2013

imHeight = size(img,1);
imWidth = size(img,2);

allCenterPoints = vertcat(object.center);
[idx_dist,dist] = knnsearch(coords,allCenterPoints);

%Make a list of points in the image (points scattered throughout the image)
C = floor(imWidth/20); %use at least 20 per row in the image, this is done to speed this process up
[I, J] = ind2sub(size(img),1:C:imHeight*imWidth);
allImPoints = [I; J]';
%Get list of image points that are a certain distance from the boundary
[~,dist_im] = knnsearch(coords(1:3:end,:),allImPoints); %returns nearest dist to each point in image
%threshold distance
inIm = dist_im <= distThresh;
%count number of points
inPts = allImPoints(inIm);
numImPts = length(inPts)*C;

inIdx = dist <= distThresh; %these are the indices of the curvelets that are near the boundary
inCurvs = object(inIdx); %these are the curvelets that are near the boundary
inDist = dist(inIdx); %these are the distances between the qualifying curvelets and the boundary
in_idx_dist = idx_dist(inIdx); %these are the indices into the coords list that are within the distance threshold

uniqueFibs = zeros(1,length(inCurvs));
inCurvsFib1 = inCurvs;
if fibProcMeth == 0
    %Process all segments
elseif fibProcMeth == 1
    %Process by fibers (not segments)
    %Only allow one location to be counted per fiber
    %In this case, the angle list for each segment is the same for a given
    %fiber.
    %fibkey contains fiber index for each segment
    
    %get a list of unique fiber keys, only one per fiber
    inFibKey = fibKey(inIdx);    
    inFibKeyS = circshift(inFibKey,[0 -1]);
    uniqueFibs = inFibKey ~= inFibKeyS; %find where keys change
    uniqueFibs(end) = 0; %set last one to zero
    inCurvs = inCurvs(uniqueFibs);
    in_idx_dist = in_idx_dist(uniqueFibs);
elseif fibProcMeth == 2
    %only process fiber ends
    inFibKey = fibKey(inIdx);
    inFibKeyL = circshift(inFibKey,[0 -1]);
    inFibKeyR = circshift(inFibKey,[0 1]);
    uniqueFibs = (inFibKey ~= inFibKeyL) | (inFibKey ~= inFibKeyR);
    uniqueFibs(1) = 0; uniqueFibs(end) = 0;
    inCurvs = inCurvs(uniqueFibs);
    in_idx_dist = in_idx_dist(uniqueFibs);
end

inCurvsLen = length(inCurvs);
measAngs = nan(1,inCurvsLen);
measDist = nan(1,inCurvsLen);
measBndry = nan(inCurvsLen,2);

for i = 1:inCurvsLen

    %use the closest distance
    boundaryPt = coords(in_idx_dist(i),:);
    boundaryAngle = FindOutlineSlope(coords,in_idx_dist(i));%allBoundaryAngles(in_idx_dist(i));
    boundaryDist = inDist(i);            
    
    if (abs(inCurvs(i).angle) > 180)
        %fix curvelet angle to be between 0 and 180 degrees
        inCurvs(i).angle = abs(inCurvs(i).angle) - 180;
    end
    tempAng = abs(180 - inCurvs(i).angle - boundaryAngle);
    if tempAng > 90
        %get relative angle between 0 and 90
        tempAng = 180 - tempAng;
    end    
    
    measAngs(i) = tempAng;
    measDist(i) = boundaryDist;
    measBndry(i,:) = boundaryPt;    
end

measAngs = measAngs';
measDist = measDist';

outIdx = dist > distThresh;
outCurvs = [object(outIdx) inCurvsFib1(~uniqueFibs)];

end %of main function

     
function [lineCurv orthoCurv] = getPointsOnLine(object,imWidth,imHeight)
    center = object.center;
    angle = object.angle;
    slope = -tand(angle);
    orthoSlope = -tand(angle + 90); %changed from tand(obj.ang) to -tand(obj.ang + 90) 10/12 JB
    intercept = center(1) - (slope)*center(2);
    orthoIntercept = center(1) - (orthoSlope)*center(2);
    
    [p1 p2] = getIntImgEdge(slope, intercept, imWidth, imHeight, center);
    [lineCurv, ~] = GetSegPixels(p1,p2);
    
    %Not using the orthogonal slope for anything now
    [p1 p2] = getIntImgEdge(orthoSlope, orthoIntercept, imWidth, imHeight, center);
    [orthoCurv, ~] = GetSegPixels(p1,p2);
    
end

function [pt1 pt2] = getIntImgEdge(slope, intercept, imWidth, imHeight, center)
    %Get intersection with edge of image
    %upper left corner of image is 0,0
    
    %check for infinite slope
    if (isinf(slope))
        pt1 = [0 center(2)];
        pt2 = [imHeight center(2)];
        return;
    end
    
    y1 = round(slope*0 + intercept); %intersection with left edge
    y2 = round(slope*imWidth + intercept); %intersection with right edge
    x1 = round((0-intercept)/slope); %intersection with top edge
    x2 = round((imHeight-intercept)/slope); %intersection with bottom edge
    
    img_int_pts = zeros(2,2); %image boundary intersection points
    ind = 1;
    if (y1 > 0 && y1 < imHeight)
        img_int_pts(ind,:) = [y1 0];
        ind = ind + 1;
    end
    
    if (y2 > 0 && y2 < imHeight)
        img_int_pts(ind,:) = [y2 imWidth];
        ind  = ind + 1;
    end
    
    if (x1 > 0 && x1 < imWidth)
        img_int_pts(ind,:) = [0 x1];
        ind = ind + 1;
    end
    
    if (x2 > 0 && x2 < imWidth)
        img_int_pts(ind,:) = [imHeight x2];
        ind = ind + 1;
    end
    
    pt1 = img_int_pts(1,:);
    pt2 = img_int_pts(2,:);
end
