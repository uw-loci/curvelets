% bwROIS.m
% Creates inner and outer regions of interest from mask and outline
% 
% Inputs:
% BWborder = single-pixel outline
% BWmask = binary mask of outlined region
% name = cell array of channel names
% kSize = size of outer ROI
% numR = number of regions, used only in timeseries processing
% r = row locations of outline
% c = column locations of outline
% outFolder = location to write mask, outline and ROI images
%
% Outputs:
% BWshow = thickened outline for display purposes only
% BWinner = inner ROI for each numR region
% BWouter = outer ROI for each numR region
% tempInner = inner ROI for whole cell
% tempOuter = outer ROI for whole cell
% tempBorder = outline for each numR region
% pts = endpoints of each numR region
%
% Written by Carolyn Pehlke, 
% Laboratory for Optical and Computational Instrumentation
% April 2012

function [BWshow,tempInner,tempOuter,varargout] = bwROIs(BWborder,BWmask,name,kSize,numR,r,c,outFolder)

% filter to creat outer ROI
k = fspecial('disk',kSize); 
kk = k > 0;
k(kk) = 1;
% filter to create inner ROI
kIn = fspecial('disk',7);
kk = kIn > 0;
kIn(kk) = 1;
% initialize variables
if numR == 0
    tempThick = cell(size(BWborder));
    tempThickIn = cell(size(BWborder));
    tempOuter = cell(size(BWborder));
    tempInner = cell(size(BWborder));
    BWshow = cell(size(BWborder));
else
    BWthick = cell(size(BWborder));
    BWthickIn = cell(size(BWborder));
    BWouter = cell(size(BWborder));
    BWinner = cell(size(BWborder));
    BWshow = cell(size(BWborder));
    tempBorder = cell(size(BWborder));
    tempOuter = cell(size(BWborder));
    tempInner = cell(size(BWborder));
end
wb3 = waitbar(0,'Finding ROIs','Position',[150 300 300 75]);

addNum = 0;
for aa = 1:length(BWborder)
    if numR == 0
        % if no timeseries regions, create inner and outer ROI
        tempThick{aa} = imfilter(BWborder{aa},k);
        tempThickIn{aa} = imfilter(BWborder{aa},kIn);
        tempOuter{aa} = imsubtract(logical(tempThick{aa}),BWmask{aa});
        tempInner{aa} = imsubtract(logical(tempThickIn{aa}),logical(tempOuter{aa}));
    else
        % if numR timeseries regions, create inner and outer ROIs for each
        % section between pts
        pnts = 1:length(r{aa})/numR:length(r{aa});
        pnts = round(pnts);
        pts{aa} = horzcat(pnts,length(r{aa}));
        tempOuter{aa} = zeros(size(BWborder{aa}));
        tempInner{aa} = zeros(size(BWborder{aa}));
        for bb = 1:length(pts{aa})-1
            newTemp = zeros(size(BWborder{aa}));
            tmpPts = pts{aa}(bb):pts{aa}(bb+1);
            for cc = 1:length(tmpPts)
                newTemp(r{aa}(tmpPts(cc)),c{aa}(tmpPts(cc))) = 1;   
            end
            tempBorder{aa}{bb} = newTemp;
            BWthick{aa}{bb} = imfilter(newTemp,k);
            BWthickIn{aa}{bb} = imfilter(newTemp,kIn);
            BWouter{aa}{bb} = imsubtract(logical(BWthick{aa}{bb}),BWmask{aa});
            BWouter{aa}{bb} = BWouter{aa}{bb}.*(BWouter{aa}{bb} >= 0);
            BWinner{aa}{bb} = imsubtract(logical(BWthickIn{aa}{bb}),logical(BWouter{aa}{bb})) + double(BWborder{aa});
            BWinner{aa}{bb} = BWinner{aa}{bb}.*(BWinner{aa}{bb} >= 0);
            BWouter{aa}{bb} = BWouter{aa}{bb} + double(BWborder{aa});

            BWouter{aa}{bb} = logical(BWouter{aa}{bb});
            BWinner{aa}{bb} = logical(BWinner{aa}{bb});

            tempOuter{aa} = tempOuter{aa} + BWouter{aa}{bb};
            tempInner{aa} = tempInner{aa} + BWinner{aa}{bb};
        end

    end
    BWshow{aa} = bwmorph(BWborder{aa},'dilate');    
    % Write images to file
    tempName = strcat(name,'_',num2str(addNum),'_outline.tif');
    tempOut = fullfile(outFolder,tempName);
    test = exist(tempOut,'file');
    if aa ==  1
        while test
            addNum = addNum + 1;
            tempName = strcat(name,'_',num2str(addNum),'_outline.tif');
            tempOut = fullfile(outFolder,tempName);
            test = exist(tempOut,'file');
        end
    end

    imwrite(BWborder{aa},tempOut,'tiff','WriteMode','append','Compression','none');
    
    tempName = strcat(name,'_',num2str(addNum),'_mask.tif');
    tempOut = fullfile(outFolder,tempName);
    imwrite(BWmask{aa},tempOut,'Compression','none','WriteMode','append');
    
    tempName = strcat(name,'_',num2str(addNum),'_outerROI.tif');
    tempOut = fullfile(outFolder,tempName);
    imwrite(tempOuter{aa},tempOut,'tiff','WriteMode','append','Compression','none');
    
    tempName = strcat(name,'_',num2str(addNum),'_innerROI.tif');
    tempOut = fullfile(outFolder,tempName);
    imwrite(tempInner{aa},tempOut,'tiff','WriteMode','append','Compression','none');
    
    waitbar(aa/length(BWborder))
end

close(wb3)

if nargout > 3
        varargout(1) = {BWinner};
        varargout(2) = {BWouter};
        varargout(3) = {tempBorder};
        varargout(4) = {pts};
end

end