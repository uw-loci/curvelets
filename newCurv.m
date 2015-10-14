function [inCurvs,Ct,inc] = newCurv(IMG,keep)

% newCurv.m
% This function applies the Fast Discrete Curvelet Transform (see http//curvelet.org for details and source) to an image, then extracts
% the curvelet coefficients at a given scale with magnitude above a given threshold. The orientation (angle, in degrees) and center point of 
% each curvelet is then stored in the struct 'object'.
% 
% Inputs:
% 
%   IMG - image
%   keep - curvelet coefficient threshold, a percent of the maximum value, as a decimal. The default value is .001 (the largest .1% of the 
%        coefficients are kept).
% 
% Outputs:
% 
%   inCurvs - the struct containing the orientation angle and center point of each curvelet (curvelets on the edges removed)
%   Ct - a cell array containing the thresholded curvelet coefficients
%
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation,
% June 2012

% apply the FDCT to the image  
    C = fdct_wrapping(IMG,0,2);
   
    
% create an empty cell array of the same dimensions
    Ct = cell(size(C));
    for cc = 1:length(C)
        for dd = 1:length(C{cc})
            Ct{cc}{dd} = zeros(size(C{cc}{dd}));
        end
    end        
    
% select the scale at which the coefficients will be used
    s = length(C) - 1;
    
% scale coefficients to remove artifacts ****CURRENTLY ONLY FOR 1024x1024   
    tempA = [1 .64 .52 .5 .46 .4 .35 .3];
    tempB = horzcat(tempA,fliplr(tempA),tempA,fliplr(tempA));
    scaleMat = horzcat(tempB,tempB);

    for ee = 1:length(C{s})
        C{s}{ee} = abs(C{s}{ee});%.*scaleMat(ee); JB 12/12 removed this fix
    end

% find the maximum coefficient value, then discard the lowest (1-keep)*100%
 
    absMax = max(cellfun(@max,cellfun(@max,C{s},'UniformOutput',0)));
    bins = 0:.01*absMax:absMax;
    histVals = cellfun(@(x) hist(x,bins),C{s},'UniformOutput',0);
    sumHist = cellfun(@(x) sum(x,2),histVals,'UniformOutput',0);

    aa = 1:length(sumHist);

    totHist = horzcat(sumHist{aa});
    sumVals = sum(totHist,2);
    cumVals = cumsum(sumVals);

    cumMax = max(cumVals);
    loc = find(cumVals > (1-keep)*cumMax,1,'first');
    maxVal = bins(loc);

    Ct{s} = cellfun(@(x)(x .* abs(x >= maxVal)),C{s},'UniformOutput',0);

% get the locations of the curvelet centers and find the angles 

    [X_rows, Y_cols] = fdct_wrapping_param(Ct);
    
    long = length(C{s})/2;
    angs = cell(long);
    row = cell(long);
    col = cell(long);
    inc = 360/length(C{s});
    startAng = 225;
    for w = 1:long
        test = find(Ct{s}{w}); % are there any non-zero coefficients in wedge w of scale s
            if any(test)
               angle = zeros(size(test));
               for bb = 1:2
                   for aa = 1:length(test)
               % convert the value of angular wedge w into the measured
               % angle in degrees, averaging reduces the effect of FDCT bin
               % size
                    tempAngle = startAng - (inc * (w-1));
                    shiftTemp = startAng - (inc * w);
                    angle(aa) = mean([tempAngle,shiftTemp]);
                   end
               end
                
                ind = angle < 0;
                angle(ind) = angle(ind) + 360; 

                IND = angle > 225;
                angle(IND) = angle(IND) - 180;

                idx = angle < 45;
                angle(idx) = angle(idx) + 180;

                angs{w} = angle;
                
                row{w} = round(X_rows{s}{w}(test));
                col{w} = round(Y_cols{s}{w}(test));
                
                angle = [];
            
            else
                angs{w} = 0;
                row{w} = 0;
                col{w} = 0;
                
            end
    
    end  

    cTest = cellfun(@(x) any(x),col);
    
    bb = find(cTest);
    
    col = cell2mat({col{bb}}');
    row = cell2mat({row{bb}}');
    angs = cell2mat({angs{bb}}');
    
    curves(:,1) = row;
    curves(:,2) = col;
    curves(:,3) = angs;
    curves2 = curves;

% group all curvelets that are closer than 'radius'   

    radius = 2;%.01*(max(size(IMG)));  % this parameter should be associated with the actuall (minimum)fiber width      
    groups = cell(1,length(curves));
    for xx = 1:length(curves2)
        if all(curves2(xx,:))
        cLow = curves2(:,2) > ceil(curves2(xx,2) - radius);
        cHi = curves2(:,2) < floor(curves2(xx,2) + radius);
        cRad = cHi .* cLow;
        
        rHi = curves2(:,1) < ceil(curves2(xx,1) + radius);
        rLow = curves2(:,1) > floor(curves2(xx,1) - radius);
        rRad = rHi .* rLow;
        
        inNH = logical(cRad .* rRad);
        curves2(inNH,:) = 0;
        groups{xx} = find(inNH);
        end
    end    
    notEmpty = ~cellfun('isempty',groups);
    combNh = groups(notEmpty);
    nHoods = cellfun(@(x) curves(x,:),combNh,'UniformOutput',false);
    angles = cellfun(@(x) fixAngle(x(:,3),inc),nHoods,'UniformOutput',false);
    centers = cellfun(@(x) [round(median(x(:,1))),round(median(x(:,2)))],nHoods,'UniformOutput',false);
    fields = {'center','angle'};
    
% output structure containing the centers and angles of the curvelets    
    object = cellfun(@(x,y) cell2struct({x,y},fields,2),centers,angles);
    
%get rid of curvelets that are too close to the edge of the image
allCenterPoints = vertcat(object.center);
cen_row = allCenterPoints(:,1);
cen_col = allCenterPoints(:,2);
[im_rows im_cols] = size(IMG);
edge_buf = min(im_rows,im_cols)/100;
inIdx = find(cen_row < im_rows - edge_buf & cen_col < im_cols - edge_buf & cen_row > edge_buf & cen_col > edge_buf);
inCurvs = object(inIdx);

   
end

    

    

    




          








         

         