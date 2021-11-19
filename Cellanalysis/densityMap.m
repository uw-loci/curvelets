function densityMask = densityMap(gridSize,densityThres)

% cell ceters (not ideal)
% load('cells.mat','cells')
% sizeCells = size(cells);
% for i=1:sizeCells(2)
%     X(i) = cells(i).position(1);
%     Y(i) = cells(i).position(2);
% end
% points = [transpose(X) transpose(Y)];
% load('labels.mat','labels')
% sizeLabels = size(labels);

% scatters density plot (not good)
% scatOut = scatplot(X,Y);

% points using mask
points = [];
load('labels.mat','labels')
sizeLabels = size(labels);
for i=1:sizeLabels(1)
    for j=1:sizeLabels(2)
        if labels(i,j) > 0
            points = [points; i j];
        end
    end
end

% densityMask = 
hist3(points,'Nbins',[gridSize gridSize],'CdataMode','auto');
colorbar
view(2)

% imshow('2B_D9_ROI1 copy.tif');
% hold on
% for i=1:gridSize
%     for j=1:gridSize
%         if densityMask(i,j) > densityThres
%             y = [i*sizeLabels(1)/gridSize;(i+1)*sizeLabels(1)/gridSize;...
%                 (i+1)*sizeLabels(1)/gridSize;i*sizeLabels(1)/gridSize;...
%                 i*sizeLabels(1)/gridSize];
%             x = [j*sizeLabels(1)/gridSize;j*sizeLabels(1)/gridSize;...
%                 (j+1)*sizeLabels(1)/gridSize;(j+1)*sizeLabels(1)/gridSize;...
%                 j*sizeLabels(1)/gridSize];
%             fill(x,y,'r','edgecolor','none')
%         end
%     end
% end
% hold off

end