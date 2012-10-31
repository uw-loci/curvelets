%--------------------------------------------------------------------------
% function for calculating statistics
    function stats = makeStats2(vals,tempFolder,imgName,map)
         aveAngle = mean(vals);
         medAngle = median(vals);
         stdAngle = std(vals);         
         refStd = 48.107;
        
         alignMent = 1-(stdAngle/refStd);
         
         %threshold the map file: 0-255 maps to 0 to 90 degrees
         redThresh = 60*(255/90);
         yelThresh = 45*(255/90);
         grnThresh = 20*(255/90);
         %count the number of pixels that are greater than the thresholds
         redMap = sum(sum(map>redThresh));
         yelMap = sum(sum(map>yelThresh));
         grnMap = sum(sum(map>grnThresh));
       
         stats = vertcat(aveAngle,medAngle,stdAngle,alignMent,redMap,yelMap,grnMap);
         saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
         csvwrite(saveStats,stats)
    end