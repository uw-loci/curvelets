function object = ctFIRE(img,imgName);

%get the output of the ctFIRE process

%we would compute the ctFIRE process here

%instead, for now, we will just open the ctFIRE result file, then collate the results

%number of nucleation points to skip between segment endpoints
lag = 9;

% *******************************
% This section is to be replaced with the actual ctFIRE computation
ctFireDir = 'P:\Conklin data - Invasive tissue microarray\Slide 2B FIRE results\';

dirList = dir(ctFireDir);

imgNameNoExt = imgName(1:end-5);

for i = 1:length(dirList)
    if ~isempty(regexp(dirList(i).name,imgNameNoExt,'once'))
        fibListStruct = load([ctFireDir dirList(i).name]);
        break;
    end
end
   
% ********************************

fibStruct = fibListStruct.data;

%loop through all fibers, get the center and angle of each point in each fiber
num_fib = length(fibStruct.Fai);
X = fibStruct.Xai;

%search first to find the number of segments
totSeg = 0;
for i = 1:num_fib    
    fv = fibStruct.Fai(i).v;    
    numSeg = length(fv)-lag;
    if numSeg > 2
        totSeg = totSeg + numSeg;
    end
end
        
%make an object of the right length
object(totSeg) = struct('center',[],'angle',[]);
segNum = 0;
for i = 1:num_fib    
    fv = fibStruct.Fai(i).v;    
    numSeg = length(fv)-lag;
    if numSeg > 2
        for j = 1:numSeg
            segNum = segNum + 1;
            v1 = fv(j);
            v2 = fv(j+lag);
            x1 = X(v1,:);
            x2 = X(v2,:);

            pt1 = [x1(2) x1(1)];
            pt2 = [x2(2) x2(1)];
            seg = [pt1; pt2];        
            %get the center of the segment
            object(segNum).center = round(mean(seg));
            run = pt1(2) - pt2(2);
            rise = pt1(1) - pt2(1);
            theta = atan(-rise/run); %range -pi/2 to pi/2, neg is to make angle match boundary file
            thetaDeg = theta*180/pi;
            if thetaDeg < 0
                thetaDeg = thetaDeg + 180;
            end
            object(segNum).angle = thetaDeg;
        end
    end
end    

end