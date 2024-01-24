% cellTrace.m
% Threshold and find outline of selected cell channel
%
% Inputs:
% img = image channel selected for mask
% intT = intensity threshold
% firstR = row location of previous starting point, for timeseries analysis
% firstC = col location of previous starting point, for timeseries analysis
%
% Outputs:
% BW = binary version of original image
% BWborder = single-pixel outline of cell
% cent = center of cell
% r = row locations of outline
% c = row locations of outline
% r1 = row starting point for morph analysis
% c1 = column starting point for morph analysis
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function [BW,BWborder,BWmask,cent,r,c,r1,c1] = cellTrace(img,intT,varargin)

% if nargin > 2, accept starting points of first image as input
if nargin > 2
    firstR = varargin{1};
    firstC = varargin{2};
end

% Determine if input image is a binary mask, skip thresholding if true
if ~islogical(img)

    % find appropriate threshold for binarizing image
    [counts ~] = imhist(img);
    [maxVal loc] = max(counts);
    threshVal = intT*maxVal;
    ind = find(counts < threshVal,5,'first');
    ind2 = find(ind > loc,1,'first');
    iVal = ind(ind2)/max(max(double(img)));

    % make binary and find objects in binary image
    BW = im2bw(img,iVal);
    BW = bwmorph(BW,'majority',2);
    BW = bwmorph(BW,'close');
    
else
    BW = img;
end

STATS = regionprops(BW,'Centroid','Extrema','Area','PixelList');

% find largest object in binary image -> cell
temp = 1;

if length(STATS) > 1
    for zz = 1:length(STATS)
        if STATS(zz).Area > STATS(temp).Area
            temp = zz;
        end
    end
end

area = STATS(temp).Area;
pix = STATS(temp).PixelList;
perms = bwperim(BW);
[rr cc] = find(perms);
reg = horzcat(cc,rr);
tf = ismember(reg,pix,'rows');
TF = horzcat(tf,tf);
reg = reg.*TF;

if nargin > 2
% is starting point close enough to original starting point? 
[idx dist] = knnsearch([firstC,firstR],reg);
[val ind] = min(dist);
r1 = reg(ind,2);
c1 = reg(ind,1);
   
else
% find starting point 
r1 = round(STATS(temp).Extrema(8,2));
c1 = round(STATS(temp).Extrema(8,1));
    if BW(r1,c1) == 0
       r1 = floor(STATS(temp).Extrema(8,2));
       c1 = ceil(STATS(temp).Extrema(8,1));
    if BW(r1,c1) == 0
       r1 = floor(STATS(temp).Extrema(8,2));
       c1 = ceil(STATS(temp).Extrema(8,1));
       if BW(r1,c1) == 0
           r1 = floor(STATS(temp).Extrema(8,2));
           c1 = floor(STATS(temp).Extrema(8,1));
           if BW(r1,c1) == 0
               r1 = ceil(STATS(temp).Extrema(8,2));
               c1 = ceil(STATS(temp).Extrema(8,1));
           end
       end
    end
    end 
    
end

% trace perimeter of cell 
P = bwtraceboundary(BW,[r1 c1],'NW');
c = P(:,2); r = P(:,1);  
% create border image
BWborder = logical(zeros(size(img)));
for aa = 1:length(r)
    BWborder(P(aa,1),P(aa,2)) = 1; 
end

% find center of cell
cent = STATS(temp).Centroid;
% create binary mask
BWmask = poly2mask(c,r,size(img,1),size(img,2));
% size criteria for finding correct object
testVal = sum(sum(BWmask))/area;

% if the size criteria fails, find new object
if testVal < .9

    P = bwtraceboundary(BW,[r1 c1],'SW');
    BWborder = logical(zeros(size(img)));
    c = P(:,2); r = P(:,1);

    for aa = 1:length(r)
        BWborder(P(aa,1),P(aa,2)) = 1; 
    end

    % find center of cell
    cent = STATS(temp).Centroid;
    % create binary mask
    BWmask = poly2mask(c,r,size(img,1),size(img,2));         
end

end
    