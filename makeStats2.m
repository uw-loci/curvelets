%--------------------------------------------------------------------------
% function for calculating statistics
function stats = makeStats2(vals,tempFolder,imgName,map,tr,ty,tg)

%vals is a column vector of angles
%temp Folder is the output folder
%imgName is the name of the original image file
%map is the 2D map image for counting pixels crossing thresholds
%tr, ty, tg are red, yellow and green thresholds respectively

    aveAngle = mean(vals);
    medAngle = median(vals);
    stdAngle = std(vals);         
    refStd = 48.107;

    alignMent = 1-(stdAngle/refStd);

    %threshold the map file:
    %count the number of pixels that are greater than the thresholds
    redMap = sum(sum(map>tr));
    yelMap = sum(sum(map>ty))-redMap;
    grnMap = sum(sum(map>tg))-redMap-yelMap;

    stats = vertcat(aveAngle,medAngle,stdAngle,alignMent,redMap,yelMap,grnMap);
    saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
    csvwrite(saveStats,stats)
end