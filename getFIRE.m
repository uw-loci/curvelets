function [object fibKey totLengthList endLengthList curvatureList widthList denList alignList] = getFIRE(imgName,fireDir,fibProcMeth,featCP)

% getFIRE.m - get the output of the Fire process and convert to something that can be used by CurveAlign
%
% Inputs
%   imgName     name of the image we would like to get the fire output for
%   fireDir     directory where the fire output is located (string)
%   fibProcMeth method by which to process fibers (user selectable)
%                   segments (0): process all fiber segments individually
%                   fibers (1): process each fiber as a single entity
%   featCP: control parameters for extracted features
%     featCP.minimum_nearest_fibers: minimum nearest fibers for localized fiber
%     density and alignment calculation
%     featCP.minimum_box_size: minimum box size for localized fiber
%     featCP.fiber_midpointEST: 1: based on the end points coordinate; 2:
%     based on the fiber length
%     density and alignment calculation

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
imgNameShort = imgName;

%YL match the exact .mat filename
ctFireName = ['ctFIREout_' imgName '.mat'];
fibListStruct = load(fullfile(fireDir,'ctFIREout', ctFireName));

% options for width calculation, should be the same as in ctFIRE_1.m
try
    widMAX = fibListStruct.cP.widMAX;
    widcon = fibListStruct.cP.widcon; % all the control parameters for width calculation
    wid_mm = widcon.wid_mm; % minimum maximum fiber width
    wid_mp = widcon.wid_mp; % minimum points to apply fiber points selection
    wid_sigma = widcon.wid_sigma; % confidence region, default +- 1 sigma
    wid_max = widcon.wid_max;     % calculate the maximum width of each fiber, deault 0, not calculate; 1: caculate
    wid_opt = widcon.wid_opt;     % choice for width calculation, default 1 use all
    if widMAX < wid_mm
        disp(sprintf('Please make sure the maximum fiber width is correct. Using default min maximum width %d.',wid_mm));
        wid_th = wid_mm;
    else
        wid_th = widMAX;
    end
    widOPTflag = 1;    % 1: use advanced width calculation
    disp('Use advanced width calculation method.')
catch TCexception
    disp(TCexception.message)
    widOPTflag = 0;
    disp('Use the original width calculation method.')
    
end
  
% for i = 1:length(dirList)
%     if ~isempty(regexp(dirList(i).name,imgNameShort,'once')) && ~isempty(regexp(dirList(i).name,'ctFIREout_','once'))
%         fibListStruct = load(fullfile(fireDir, dirList(i).name));
%         break;
%     end
% end

fibStruct = fibListStruct.data; %extract the fiber list structure
LL1 = fibListStruct.cP.LL1; %get the length limit that was used during the CT-FIRE process

%check if struct is empty, if so, return an empty object
if isempty(fibStruct)
    object = [];
    return;
end

num_fib = length(fibStruct.Fai);
X = fibStruct.Xai;


%--Process segments--
totSeg = 0;
if fibProcMeth == 0
    %if processing by segments, loop through all fibers, get the center and angle of each point in each fiber
    %search first to find the number of segments    
    for i = 1:num_fib
        if fibStruct.M.L(i) > LL1
            numSeg = length(fibStruct.Fai(i).v);
            totSeg = totSeg + numSeg;
        end
    end
else
    for i = 1:num_fib
        if fibStruct.M.L(i) > LL1
            totSeg = totSeg + 1;
        end
    end
    if fibProcMeth == 2
        totSeg = 2*totSeg; %one for each endpoint
    end
end
%make objects of the right length
object(totSeg) = struct('center',[],'angle',[],'weight',[]);
fibKey = nan(totSeg,1); %keep track of the segNum at the beginning of each fiber
%These are features that only involve individual fibers
totLengthList = nan(totSeg,1);
endLengthList = nan(totSeg,1); 
curvatureList = nan(totSeg,1); 
widthList = nan(totSeg,1);

segNum = 0;
fibNum = 0;

%%
%QA: Make sure angles and positions are correct
% heImgFF = ['P:\\Conklin data - Invasive tissue microarray\\Validation\\Composite\\RGB\\' imgNameShort '_RGB.tif'];
% figure(500);
% clf;
% heImg = imread(heImgFF);
% imshow(heImg);
% len = size(heImg,1)/256;
% hold on;
IMGinfo = imfinfo(fullfile(fireDir,fibListStruct.imgName)); 

%YL:modify the coordinates of the fiber segments that are outside the image range. 
% Though Coordinates of the CTF extracted fiber are all within the image range,
% after interpolation, x,y coordinate of the fiber segments might be beyond image range
if fibProcMeth == 0
    Hmin = find (fibListStruct.data.Xai(:,2) < 1); 
    Hmax = find (fibListStruct.data.Xai(:,2) > IMGinfo.Height); 
    Wmin = find(fibListStruct.data.Xai(:,1) < 1);
    Wmax = find(fibListStruct.data.Xai(:,1)> IMGinfo.Width);
        
    if ~isempty(Hmin)||~isempty(Hmax)|| ~isempty(Wmin) || ~isempty(Wmax)
        if ~isempty(Hmin)
            fprintf('the Y coordinate of %s is smaller than 1 and will be modified to 1',num2str(Hmin'));
            fprintf('Original Y of postions in lower height limit: \n');fibListStruct.data.Xai(Hmin,2)
            fibListStruct.data.Xai(Hmin,2) = 1;
        end
        if ~isempty(Hmax)
            
            fprintf('the Y coordinate of %s is larger than %d and will be modified to %d \n',...
                num2str(Hmax'),IMGinfo.Height,IMGinfo.Height);
            fprintf('Original Y of postions in upper height limit: \n');fibListStruct.data.Xai(Hmax,2)
            fibListStruct.data.Xai(Hmax,2) = IMGinfo.Height;
        end
        if ~isempty(Wmin)
            
            fprintf('the X coordinate of %s is smaller than 1 and will be modified to 1 \n',num2str(Wmin'));
            fprintf('Original X of postions in lower width limit: \n');fibListStruct.data.Xai(Wmin,1)
            fibListStruct.data.Xai(Wmin,1) = 1;
        end
        
        if ~isempty(Wmax)
            
            fprintf('the X coordinate of %s is larger than %d and will be modified to %d \n',...
                num2str(Wmax'),IMGinfo.Width,IMGinfo.Width);
            fprintf('Original X of postions in upper width limit: \n');fibListStruct.data.Xai(Wmax,1)
            fibListStruct.data.Xai(Wmax,1) = IMGinfo.Width;
            
        end
        
        X = fibListStruct.data.Xai;  % update X
        fibStruct.Xai = fibListStruct.data.Xai;
    end
      
end
%%
ii = 0;  % to check the number of fv
for i = 1:num_fib
    fv = fibStruct.Fai(i).v;
    %numSeg = length(fibStruct.M.FangI(i).angle_xy);
    numSeg = length(fv);
    %initialize fiber width
    widave = nan;
    if numSeg > 0 && fibStruct.M.L(i) > LL1
        %get fiber end to end length
        fsp = fibStruct.Fa(i).v(1);
        fep = fibStruct.Fa(i).v(end);
        sp = fibStruct.Xa(fep,:);
        ep = fibStruct.Xa(fsp,:);
        dse = norm(sp-ep); %end to end length of the fiber
        if featCP.fiber_midpointEST ~= 2 % estimate center point of the fiber based on the end points coordinates
            cen = round(mean([sp; ep])); 
        elseif featCP.fiber_midpointEST == 2 % estimate center point of the fiber based on the fiber length
            vertex_indices_INT = fibStruct.Fai(i).v;
            s2 = size(vertex_indices_INT,2);
            cen(1) = round(fibStruct.Xai(vertex_indices_INT(round(s2/2)),1));
            cen(2) = round(fibStruct.Xai(vertex_indices_INT(round(s2/2)),2));
            if cen(1)> IMGinfo.Width ||cen(2)>IMGinfo.Height || cen(1) < 1 || cen(2) < 1
                vertex_indices = fibStruct.Fa(i).v;
                s2 = size(vertex_indices,2);
                cen(1) = round(fibStruct.Xa(vertex_indices(round(s2/2)),1));
                cen(2) = round(fibStruct.Xa(vertex_indices(round(s2/2)),2));
                fprintf('Interpolated coordinates of fiber %d is out of boundary, orignial coordinates is used for length-based fiber middle point estimation. \n',i)
            end
        end
        %get fiber curvature
        fstr = dse/fibStruct.M.L(i);   % fiber straightness
        %calculate fiber width
        try
            %YL: make the width calculation consistent with ctFIRE_1.m of CT-FIRE 2.0
            VFa.LL = fibStruct.Fa(1,i).v;  % YL FN(LL) - > i
            XFa.LL = fibStruct.Xa(VFa.LL,:);
            % to calculate the width
            if widOPTflag == 1  % advanced width calculation
                NPnum = length(XFa.LL(:,1)); % nuber of vectors in each fiber
                widall = 2*fibStruct.Ra(VFa.LL);
                temp = find(widall <= wid_th); % exclude the points out of the maximum width
                wtemp = widall(temp);
                %YL02142014
                if wid_opt == 1            % use all the points except artifact to calculate fiber width
                    widave_sp = mean(wtemp); % estimated average fiber width
                    widmax_sp = max(wtemp);  % estimated maximum fiber width
                else
                    if length(wtemp) > wid_mp     % set a minimum sample size(wid_mp) for statistic analysis
                        widstd = std(wtemp);   % std of the points
                        widmean = mean(wtemp); % mean of the points
                        temp2 = find(wtemp<= widmean+wid_sigma*widstd & wtemp>= widmean - wid_sigma*widstd);
                        widave_sp = mean(wtemp(temp2));  % averaged fiber width of the selected points
                        widmax_sp = max(wtemp(temp2));   % maximum fiber width of the selected points
                    else
                        widave_sp = mean(wtemp);% estimated average fiber width
                        widmax_sp = max(wtemp);% estimated maxium fiber width
                    end
                end
                widave = widave_sp;
                
            elseif widOPTflag == 0  % use previous width calculation method
                widall = 2*fibStruct.Ra(VFa.LL);
                widave = mean(widall); % estimated average fiber width
            end
        catch
            ii = ii + 1;
            disp(sprintf('%d fiber(s) are skipped due to updated width calculation,number of vectors in this fiber=%d \n',ii, fv));
            
        end
    
        fibNum = fibNum + 1;
        
        if fibProcMeth == 0
            %process segments
            for j = 1:numSeg
                segNum = segNum + 1;              
                fibKey(segNum) = i;
                v1 = fv(j);
                x1 = X(v1,:);
                pt1 = [x1(2) x1(1)];
                %get the center of the segment
                object(segNum).center = round(pt1);                
                %set angle to be that of the current segment
                theta = -1*fibStruct.M.FangI(i).angle_xy(j); %neg is to make angle match boundary file
                thetaDeg = theta*180/pi;
                if thetaDeg < 0
                    thetaDeg = thetaDeg + 180;
                end
                object(segNum).angle = thetaDeg;

                totLengthList(segNum) = fibStruct.M.L(i);
                endLengthList(segNum) = dse; 
                curvatureList(segNum) = fstr; 
                widthList(segNum) = widave;            
            end
            
            
        else
            %process fibers or end points
            %write out fiber angle
            theta = -1*fibStruct.M.angle_xy(i); %neg is to make angle match boundary file
            thetaDeg = theta*180/pi;
            if thetaDeg < 0
                thetaDeg = thetaDeg + 180;
            end            
            object(fibNum).angle = thetaDeg;            
            totLengthList(fibNum) = fibStruct.M.L(i);
            endLengthList(fibNum) = dse; 
            curvatureList(fibNum) = fstr; 
            widthList(fibNum) = widave;
            fibKey(fibNum) = i;
            
            %write out fiber position
            if fibProcMeth == 1 %one point per fiber
                object(fibNum).center = [cen(2) cen(1)];
            elseif fibProcMeth == 2 %process fiber endpoints
                totSeg2 = totSeg/2;
                object(fibNum).center = round([sp(2) sp(1)]);
                object(fibNum+totSeg2).center = round([ep(2) ep(1)]);
                object(fibNum+totSeg2).angle = thetaDeg;            
                totLengthList(fibNum+totSeg2) = fibStruct.M.L(i);
                endLengthList(fibNum+totSeg2) = dse; 
                curvatureList(fibNum+totSeg2) = fstr; 
                widthList(fibNum+totSeg2) = widave;  
                fibKey(fibNum+totSeg2) = i;
            end
        end
        
        %QA: Make sure angles and positions are correct
        %figure(500);
%         pts = zeros(numSeg,2);
%         for m = 1:numSeg
%             fsp = fibStruct.Fa(i).v(m);
%             pt = fibStruct.Xa(fsp,:);
%             pts(m,:) = [pt(2) pt(1)];
%         end
%         plot(pts(:,2),pts(:,1)); 
    end
end
% figure(500);
% c = vertcat(object.center);
% plot(c(:,2),c(:,1),'or');
% overAx = gca();
% drawCurvs(object,overAx,len,0,zeros(length(object),1)+90,10,1);

% figure(1);
% hist(gca,totLengthList); title('Length');
% figure(2);
% hist(gca,curvatureList); title('Curvature');
% figure(3);
% hist(gca,widthList); title('Width');
% drawnow;

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
c = vertcat(object.center);
x = c(:,1);
y = c(:,2);
a = vertcat(object.angle);
[nnIdx nnDist] = knnsearch(c,c,'K',n(end) + 1);
for i = 1:length(object)
    
    ai = a(nnIdx(i,:));
    for j = 1:lenN
        if n(j) <= size(nnDist,2)-1  % YL: nnDist(:,1) is the distance to itsself, 
            try   % YL
            denList(i,j) = mean(nnDist(i,2:n(j)+1)); %average nearest distances (throw out first)
            alignList(i,j) = circ_r(ai(2:n(j)+1)*2*pi/180); %vector sum nearest angles (throw out first)
            catch
                disp(sprintf('%s,size of denLiST= %d x %d, i =%d, j = %d',imgName, size(denList,1),size(denList,2),i,j));
            end
        else
%             denList(i,j) = mean(nnDist(i,2:end)); %average nearest distances (throw out first)
%             alignList(i,j) = circ_r(ai(2:end)*2*pi/180); %vector sum nearest angles (throw out first)
%           YL: if fiber number is less than the number of the nearest neighbors, then don't calculate  
            denList(i,j) = nan;   % YL: if fiber number is less than the number of the nearest neighbors, then don't calculate this distance value
            alignList(i,j) = nan; % vector sum nearest angles (throw out first)

        end
    end      

    %Density box filter
    for j = 1:lenB
        %find any positions that are in a square region around the
        %current fiber
        ind2 = x > x(i)-fSize2(j) & x < x(i)+fSize2(j) & y > y(i)-fSize2(j) & y < y(i)+fSize2(j);        
        %get all the fibers in that area
        vals = vertcat(object(ind2).angle);
        %Density and alignment measures based on square filter
        denList(i,lenN+2+j) = length(vals);
        alignList(i,lenN+2+j) = circ_r(vals*2*pi/180);
    end
    
    %Join features together into weight
    use_flag = curvatureList(i) > 0.92 && widthList(i) < 4.6755 && denList(i,lenN+5) < 4.8 && alignList(i,lenN+5) > 0.7;
    object(i).weight = use_flag*denList(i,lenN+5);       
end

denList(:,lenN+1) = mean(denList(:,1:lenN),2);
denList(:,lenN+2) = std(denList(:,1:lenN),0,2);
alignList(:,lenN+1) = mean(alignList(:,1:lenN),2);
alignList(:,lenN+2) = std(alignList(:,1:lenN),0,2);

end