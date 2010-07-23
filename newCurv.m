function [object,Ct,inc] = newCurv(IMG,keep)

% newCurv.m
% This function applies the Fast Discrete Curvelet Transform (see http//curvelet.org for details and source) to an image, then extracts
% the curvelet coefficients at a given scale with magnitude above a given threshold. The orientation (angle, in degrees) and center point of 
% each curvelet is then stored in the struct 'object'.
% 
% Inputs:
% 
% IMG - image
% 
% keep - curvelet coefficient threshold, a percent of the maximum value, as a decimal. The default value is .001 (the largest .1% of the 
%        coefficients are kept).
% 
% Outputs:
% 
% object - the struct containing the orientation angle and center point of each curvelet
% 
% Ct - a cell array containing the thresholded curvelet coefficients
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010


if nargin < 2
    keep = .001;
end
    
% apply the FDCT to the image    
    C1 = fdct_wrapping(IMG,0,2);
    trim = 5;
    C = pixel_indent(C1,trim);
    
% create a blank image the size of IMG and apply the transform to obtain an empty cell array with the exact dimensions of C    
    BW2 = zeros(size(IMG));
    Ct1 = fdct_wrapping(BW2,0,2);
    Ct = pixel_indent(Ct1,trim);
    
% select the scale at which the coefficients will be used
    s = length(C) - 1;
    
% find the maximum coefficient value, then discard the lowest (1-keep)*100%    
    absVal = cellfun(@abs,C{s},'UniformOutput',0);
    absMax = max(cellfun(@max,cellfun(@max,absVal,'UniformOutput',0)));
%     absMed = median(cellfun(@max,cellfun(@max,absVal,'UniformOutput',0)))
    bins = 0:.01*absMax:absMax;

    histVals = cellfun(@(x) hist(x,bins),absVal,'UniformOutput',0);
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
    for w = 1:long
        test = find(Ct{s}{w}); % are there any non-zero coefficients in wedge w of scale s
            if any(test)
               angle = zeros(size(test));
               for aa = 1:length(test)
	       % convert the value of angular wedge w into the measured angle in degrees
                angle(aa) = 45 - ((360/length(C{s})) * (w-1));
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
    curves = horzcat(row,col,angs);
  
% find the distances between all curvelet centers  

    D = dists(curves,curves);
   
% group all curvelets that are closer than 'radius'    
    radius = .01*(max(size(IMG)));  
    nH = cellfun(@(x) find(x <= radius),D,'UniformOutput',false);
    nIdx = 1:length(nH);
    nIdx = circshift(nIdx,round(length(nH)/4));
    nHshift = nH(nIdx);
    testvals = cellfun(@(x,y) cellCompare(x,y),nH,nHshift);
    tIdx = testvals > 0;
    testvals = testvals(tIdx);
    combNh = {nH{unique(testvals)}};
    nHoods = cellfun(@(x) curves(x,:),combNh,'UniformOutput',false);
    angles = cellfun(@(x) fixAngle(x(:,3),inc),nHoods,'UniformOutput',false);
    centers = cellfun(@(x) [round(median(x(:,1))),round(median(x(:,2)))],nHoods,'UniformOutput',false);
    fields = {'center','angle'};
    
% output structure containing the centers and angles of the curvelets    
    object = cellfun(@(x,y) cell2struct({x,y},fields,2),centers,angles);




    

    

    




          








         

         