%--------------------------------------------------------------------------
% draw curvelets on an image that indicates the relative angle in grey
% scale
function [rawmap, procmap] = drawMap(object, angles, img, bndryMeas)
    rawmap = nan(size(img));
    for ii = 1:length(object)
        xc = object(ii).center(1,2);            
        yc = object(ii).center(1,1);
        
        if bndryMeas
            %scale 0 to 90 degrees into 0 to 255
            rawmap(yc,xc) = 255.0*(angles(ii)/90.0);
        else
            %scale 0 to 180 degrees into 0 to 255
            rawmap(yc,xc) = 255.0*(angles(ii)/180.0);
        end
    end
    
    if bndryMeas
        %max filter the map
        fSize = 8;
        fSize2 = ceil(fSize/2);
        map2 = nan(size(img));
        for i = fSize2+1:size(img,1)-(fSize2+1)
            for j = fSize2+1:size(img,2)-(fSize2+1)
                map2(i,j) = nanmax(nanmax(rawmap(i-fSize2:i+fSize2,j-fSize2:j+fSize2)));
            end
        end        
        
        %Gaussian blur the map
        sig = 4; %in pixels
        h = fspecial('gaussian', [10*sig 10*sig], sig);
        procmap = imfilter(uint8(map2),h,'replicate');
    else
        %Stnd Dev Filter the Map
        fSize = 8;
        fSize2 = ceil(fSize/2);
        map2 = nan(size(img));
        for i = fSize2+1:size(img,1)-(fSize2+1)
            for j = fSize2+1:size(img,2)-(fSize2+1)
                submap = rawmap(i-fSize2:i+fSize2,j-fSize2:j+fSize2);
                ind = find(~isnan(submap));
                if (length(ind)>2)
                    map2(i,j) = nanstd(submap(ind));
                end
            end
        end
        
        %invert to make this a measure of alignment
        for i = 1:size(img,1)
            for j = 1:size(img,2)
                if (map2(i,j) > 0.5)
                    map2(i,j) = 1/map2(i,j);
                end
            end
        end
        map2 = map2*255/nanmax(nanmax(map2));
        %procmap = map2;
        %Gaussian blur the map
        sig = 4; %in pixels
        h = fspecial('gaussian', [10*sig 10*sig], sig);
        procmap = imfilter(uint8(map2),h,'replicate');  
    end
    
end