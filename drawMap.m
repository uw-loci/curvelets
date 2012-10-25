%--------------------------------------------------------------------------
% draw curvelets on an image that indicates the relative angle in grey
% scale
function map3 = drawMap(object, angles, img)
    map = zeros(size(img));
    for ii = 1:length(object)
        xc = object(ii).center(1,2);            
        yc = object(ii).center(1,1);
        map(yc,xc) = 255.0*(angles(ii)/90.0);
    end
    
    %max filter the map
    fSize = 12;
    fSize2 = ceil(fSize/2);
    map2 = zeros(size(img));
    for i = fSize2+1:size(img,1)-(fSize2+1)
        for j = fSize2+1:size(img,2)-(fSize2+1)
            map2(i,j) = max(max(map(i-fSize2:i+fSize2,j-fSize2:j+fSize2)));
        end
    end
    
    %Gaussian blur the map
    sig = 6; %in pixels
    h = fspecial('gaussian', [10*sig 10*sig], sig);
    map3 = imfilter(map2,h,'replicate');
    
end