function [object fibKey] = ctFIRE(imgName,fireDir)

% ctFIRE.m - get the output of the Fire process and convert to something that can be used by CurveAlign
%
% Inputs
%   imgName     name of the image we would like to get the fire output for
%   fireDir     directory where the fire output is located (string)
%
% Optional Inputs
%
% Outputs
%   object  structure containing information about each fiber segment position and angle in image
%   fibKey  list containing the index of the beginning of each fiber within object
% 
%
% By Jeremy Bredfeldt and Carolyn Pehlke Laboratory for Optical and
% Computational Instrumentation 2013

%load the fiber list from the fire output mat file (this is generated by the CT-Fire program
dirList = dir(fireDir);
for i = 1:length(dirList)
    if ~isempty(regexp(dirList(i).name,imgName,'once'))
        fibListStruct = load([fireDir dirList(i).name]);
        break;
    end
end

fibStruct = fibListStruct.data; %extract the fiber list structure
%check if struct is empty, if so, return an empty object
if isempty(fibStruct)
    object = [];
    return;
end

%loop through all fibers, get the center and angle of each point in each fiber
num_fib = length(fibStruct.Fai);
X = fibStruct.Xai;

%search first to find the number of segments
totSeg = 0;
for i = 1:num_fib
%     fv = fibStruct.Fai(i).v;
%     numSeg = length(fv)-lag;
%     if numSeg > 0
%         totSeg = totSeg + numSeg;
%     end
    numSeg = length(fibStruct.Fai(i).v);
    totSeg = totSeg + numSeg;
end
        
%make an object of the right length
object(totSeg) = struct('center',[],'angle',[]);
fibKey = nan(1,num_fib); %keep track of the segNum at the beginning of each fiber
segNum = 0;
for i = 1:num_fib
    fv = fibStruct.Fai(i).v;
    %numSeg = length(fibStruct.M.FangI(i).angle_xy);
    numSeg = length(fv);
    if numSeg > 0
        for j = 1:numSeg
            segNum = segNum + 1;
            if j == 1
                %beginning of a fiber, list segNum
                fibKey(i) = segNum;
            end
            v1 = fv(j);
            %v2 = fv(j+lag);
            x1 = X(v1,:);
            %x2 = X(v2,:);

            pt1 = [x1(2) x1(1)];
            %pt2 = [x2(2) x2(1)];
            %seg = [pt1; pt2];
            %get the center of the segment
            %object(segNum).center = round(mean(seg));
            object(segNum).center = round(pt1);
%             run = pt1(2) - pt2(2);
%             rise = pt1(1) - pt2(1);
            theta = -1*fibStruct.M.FangI(i).angle_xy(j);
            %theta = atan(-rise/run); %range -pi/2 to pi/2, neg is to make angle match boundary file
            thetaDeg = theta*180/pi;
            if thetaDeg < 0
                thetaDeg = thetaDeg + 180;
            end
            object(segNum).angle = thetaDeg;
        end
    end
end

end