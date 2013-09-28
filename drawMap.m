function [rawmap, procmap] = drawMap(object, angles, img, bndryMeas)
% drawMap.m - creates an image where the grey level at each curvelet center
% location corresponds with it's angle information
%
% Inputs
%   object      list of curvelet centers
%   angles      list of curvelet angles
%   img         original image
%   bndryMeas   flag indicating if the analysis is wrt a boundary
%
% Optional Inputs
%
% Outputs
%   rawmap      2D image where grey levels indicate angle information
%   procmap     A filtered version of the rawmap
%
% By Jeremy Bredfeldt Laboratory for Optical and
% Computational Instrumentation 2013

    rawmap = nan(size(img));
    for ii = 1:length(object)
        xc = object(ii).center(1,2);            
        yc = object(ii).center(1,1);
        
        if bndryMeas
            %scale 0 to 90 degrees into 0 to 255
            rawmap(yc,xc) = 255.0*(angles(ii)/90.0)*object(ii).weight;
        else
            %scale 0 to 180 degrees into 0 to 255
            rawmap(yc,xc) = 255.0*(angles(ii)/180.0);
        end
    end
    
    %find the positions of all non-nan values
    map2 = rawmap;
    [J I] = size(img);
    ind = find(~isnan(rawmap));
    [y x] = ind2sub([J I],ind);    
    
	if ~bndryMeas                     
        %standard deviation filter
        fSize = round(J/8);
        fSize2 = ceil(fSize/2);                
        map2 = nan(size(img));        
        for i = 1:length(ind)
            %find any positions that are in a square region around the
            %current curvelet
            ind2 = find(x > x(i)-fSize2 & x < x(i)+fSize2 & y > y(i)-fSize2 & y < y(i)+fSize2);
            %convert these positions to linear indices
            ind3 = sub2ind([J I],y(ind2),x(ind2));
            %get all the grey level values
            vals = rawmap(ind3);
            if length(vals) > 2
                %Perform the circular angle uniformity test, first scale values from 0-255 to 0-2*pi
                %Then scale from 0-1 to 0-255
                map2(y(i),x(i)) = (circ_r(vals*pi/127.5))*255;
            end
        end    
        %figure(600); imagesc(map2); colorbar;        
    end
    %max filter
    fSize = round(J/64);
    fSize2 = ceil(fSize/2);
    map4 = nan(size(img));
    tic
    for i = 1:length(ind)
        val = map2(y(i),x(i));
        rows = y(i)-fSize2:y(i)+fSize2;
        cols = x(i)-fSize2:x(i)+fSize2;
        %get rid of out of bounds coordinates
        ind4 = find(rows > 0 & rows < J & cols > 0 & cols < I);
        rows = rows(ind4);
        cols = cols(ind4);
        %now make a square collection of indices
        lenInd = length(ind4);
        lenInd2 = lenInd*lenInd;
        rows = repmat(rows,1,lenInd);
        cols = reshape(repmat(cols,lenInd,1),1,lenInd2);
        %get the linear indices in the original map
        ind5 = sub2ind([J I],rows,cols);
        
        
        %find the number of fibers within the filter region for normalization
        % creates a metric of alignment per fiber, normalizes away density
        % we don't really care about density, we care much more about alignment
        ind6 = find(~isnan(rawmap(ind5)));
        numFibs = length(ind6);
                
        %set the value to the max of the current or what was there
        map4(ind5) = max(map4(ind5),val/numFibs);
    end
    %figure(675); imagesc(map4); colorbar;
    %gaussian filter
    sig = round(J/96); %in pixels
    h = fspecial('gaussian', [10*sig 10*sig], sig);
    %uint 8 converts nans to zeros
    procmap = imfilter(uint8(map4),h,'replicate');
    %figure(700); imagesc(procmap); colorbar;
end