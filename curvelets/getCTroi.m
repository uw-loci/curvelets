function [object fibKey totLengthList endLengthList curvatureList widthList denList alignList,Ct] = getCTroi(imgName,IMG,curveCP,featCP)

%getCT.m, based on getFIRE.m - get the output of the Fire process and convert to something that can be used by CurveAlign
%
% Inputs
%   imgName     name of the image we would like to get the fire output for
%   IMG         2D image
% curveCP:  Control Parameters for curvelets appliaction  
%     curveCP.keep = keep;   % fraction of the curvelets to be kept 
%     curveCP.scale = advancedOPT.seleted_scale; % scale to be analyzed
%     curveCP.radius = advancedOPT.curvelets_group_radius; % radius to
%     group the adjacent curvelets.
% featCP: control parameters for extracted features
%     featCP.minimum_nearest_fibers: minimum nearest fibers for localized fiber
%     density and alignment calculation
%     featCP.minimum_box_size: minimum box size for localized fiber
%     density and alignment calculation

% Outputs
%   object  structure containing information about each fiber segment position and angle in image
%   fibKey  list containing the index of the beginning of each fiber within object
%
%
% By Jeremy Bredfeldt and Carolyn Pehlke Laboratory for Optical and
% Computational Instrumentation 2013

%load the fiber list from the fire output mat file (this is generated by the CT-Fire program

[object1, Ct, ~] = newCurv(IMG,curveCP);

fibKey = [];
totLengthList = [];
endLengthList = [];
curvatureList = [];
widthList = [];

fibStruct = object1; %extract the fiber list structure
%check if struct is empty, if so, return an empty object
if isempty(fibStruct)
    object = [];
    return;
end

num_fib = length(fibStruct);
X = fibStruct.center;

%--Process segments--
totSeg = num_fib;

%make objects of the right length
object(totSeg) = struct('center',[],'angle',[],'weight',[]);
object1(totSeg).weight = [];
object = object1; clear object1;

fibKey = nan(totSeg,1); %keep track of the segNum at the beginning of each fiber
%These are features that only involve individual fibers
totLengthList = nan(totSeg,1);
endLengthList = nan(totSeg,1);
curvatureList = nan(totSeg,1);
widthList = nan(totSeg,1);

segNum = 0;
fibNum = 0;


%These are features that involve groups of fibers
%Density features: average distance to n nearest neighbors
%Alignment features: abs of vect sum of n nearest neighbors
mnf = featCP.minimum_nearest_fibers;  % temporary varible
mbs = featCP.minimum_box_size;        % temporary varible
n = [2^0*mnf, 2^1*mnf,2^2*mnf,2^3*mnf];  % keep 4 original nearest fiber features
fSize = [2^0*mbs, 2^1*mbs,2^2*mbs];  % keep 3 original box features
clear mnf mbs

fSize2 = ceil(fSize./2);
lenB = length(fSize2);

lenN = length(n);
denList = nan(totSeg,lenN+2+lenB);
alignList = nan(totSeg,lenN+2+lenB);
%YL
% c = vertcat(object.center);
% x = c(:,1);
% y = c(:,2);
% a = vertcat(object.angle);
% [nnIdx nnDist] = knnsearch(c,c,'K',n(end) + 1);
% for i = 1:length(object)
%     ai = a(nnIdx(i,:));
%     for j = 1:lenN
%         if n(j) <= size(nnDist,2)  % YL
%             denList(i,j) = mean(nnDist(i,2:n(j)+1)); %average nearest distances (throw out first)
%             alignList(i,j) = circ_r(ai(2:n(j)+1)*2*pi/180); %vector sum nearest angles (throw out first), ...
%                    %YL: consider to add the fiber itself for alignment calculation 
%         else
% %             denList(i,j) = mean(nnDist(i,2:end)); %average nearest distances (throw out first)
% %             alignList(i,j) = circ_r(ai(2:end)*2*pi/180); %vector sum nearest angles (throw out first)
%         %           YL: if curvelets number is less than the number of the nearest neighbors, then don't calculate  
%             denList(i,j) = nan;   % YL: if fiber number is less than the number of the nearest neighbors, then don't calculate this distance value
%             alignList(i,j) = nan; % vector sum nearest angles (throw out first)
% 
%         end
%     end
%     
%     %Density box filter
%     for j = 1:lenB
%         %find any positions that are in a square region around the
%         %current fiber
%         ind2 = x > x(i)-fSize2(j) & x < x(i)+fSize2(j) & y > y(i)-fSize2(j) & y < y(i)+fSize2(j);
%         %get all the fibers in that area
%         vals = vertcat(object(ind2).angle);
%         %Density and alignment measures based on square filter
%         denList(i,lenN+2+j) = length(vals);
%         alignList(i,lenN+2+j) = circ_r(vals*2*pi/180);
%     end
%     
%     %Join features together into weight
% %     use_flag = curvatureList(i) > 0.92 && widthList(i) < 4.6755 && denList(i,lenN+5) < 4.8 && alignList(i,lenN+5) > 0.7;
% %     object(i).weight = use_flag*denList(i,lenN+5);
%     object(i).weight = NaN;  % YL: add the 'NaN' column for weight, otherwise this column will be not shown in the final feature list 
%  
% end
% 
% denList(:,lenN+1) = mean(denList(:,1:lenN),2);
% denList(:,lenN+2) = std(denList(:,1:lenN),0,2);
% alignList(:,lenN+1) = mean(alignList(:,1:lenN),2);
% alignList(:,lenN+2) = std(alignList(:,1:lenN),0,2);

end