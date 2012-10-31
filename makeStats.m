%--------------------------------------------------------------------------
% function for calculating statistics
    function stats = makeStats(vals,tempFolder,imgName)
         aveAngle = mean(vals);
         medAngle = median(vals);
         stdAngle = std(vals);         
         refStd = 48.107;
        
         alignMent = 1-(stdAngle/refStd); 
       
         stats = vertcat(aveAngle,medAngle,stdAngle,alignMent);
         saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
         csvwrite(saveStats,stats)
    end