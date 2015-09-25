function stats = makeStats(vals,tempFolder,imgName,map,tr,ty,tg,bdryMeas,numImPts)

% makeStats.m - writes histogram data out for a batch processed group of files. 
%   This was created to fulfill a specific need of the Keely lab.
% 
% Inputs:
%   vals        = a column vector of angles (0-90 deg if bdryMeas, 0-180 if ~bdryMeas)
%   tempFolder  = the output folder
%   imgName     = the name of the original image file
%   map         = the 2D map image for counting pixels crossing thresholds
%   tr, ty, tg  = red, yellow and green thresholds respectively
%   bdryMeas    = flag indicating if the measurement is wrt a boundary
%   numImPts    = total number of image points that were evaluated 
%
% Output:
%   stats = array of floating point values
%
%
% By Jeremy Bredfeldt, LOCI, Morgridge Institute for Research, 2013



    if bdryMeas        
        aveAngle = nanmean(vals);
        medAngle = nanmedian(vals);        
        varAngle = nanvar(vals);
        stdAngle = nanstd(vals);        
        alignMent = nan; %not important with a boundary
        skewAngle = skewness(vals); %measure of symmetry
        kurtAngle = kurtosis(vals); %measure of peakedness
        omniAngle = 0; %not important with boundary
    else
        %convert to radians
        %mult by 2, then divide by 2: this is to scale 0 to 180 up to 0 to 360, this makes the analysis circular, since we are using orientations and not directions
        vals2 = 2*(vals*pi/180);
        aveAngle = (180/pi)*circ_mean(vals2)/2;
        aveAngle = mod(180+aveAngle,180);
        medAngle = (180/pi)*circ_median(vals2)/2;        
        medAngle = mod(180+medAngle,180);
        varAngle = circ_var(vals2); %large var means uniform distribution, but not exactly, could be bimodal, between 0 and 1
        stdAngle = circ_std(vals2); 
        alignMent = circ_r(vals2); %large alignment means angles are highly aligned, result is between 0 and 1
        skewAngle = circ_skewness(vals2); %measure of symmetry
        kurtAngle = circ_kurtosis(vals2); %measure of peakedness
        omniAngle = circ_otest(vals2); %this is a p value (significance level), low means the distribution is very aligned, high means uniform or can't tell
    end
    %threshold the map file:
    %count the number of pixels that are greater than the thresholds
    redMap = sum(sum(map>tr));
    yelMap = sum(sum(map>ty))-redMap;
    grnMap = sum(sum(map>tg))-redMap-yelMap;
    
   %% circular statistics about the angles
   rowN = {'Mean','Median','Variance','Std Dev','Coef of Alignment','Skewness','Kurtosis','Omni Test','red pixels','yellow pixels','green pixels'};
   stats = vertcat(aveAngle,medAngle,varAngle,stdAngle,alignMent,skewAngle,kurtAngle,omniAngle,redMap,yelMap,grnMap,numImPts);
   saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
   %     csvwrite(saveStats,stats)
   fid = fopen(saveStats,'w');
   for i = 1:length(rowN)
       fprintf(fid,'%12s\t  %5.2f\n',rowN{i},stats(i));
   end
   fclose(fid);
end