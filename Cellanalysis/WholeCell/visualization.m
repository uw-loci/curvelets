function visualization(maskFile, resultFile)

% This function will compare the mask segmented by a model with the ground
% truth by visualize them in one graph. The result mask will be read and
% the boundaries of cells will be drawn with colorful lines, and the ground
% truth will be the background. 
% maskFile - the ground truth 
% resultFile - the mask segmented by a model

result = imread(resultFile);
mask = imread(maskFile);

sizeResult = size(result);
sizeMask = size(mask);

numCells = max(max(max(result)));

imshow(maskFile)
hold on

for i=1:numCells
    
   x = [];
   y = [];
   
   for j=1:sizeResult(1)
       for k=1:sizeResult(2)
           if result(j,k) == i
               x = [x; k*sizeMask(1)/sizeResult(1)];
               y = [y; j*sizeMask(2)/sizeResult(2)];
           end
       end
   end
   if ~isempty(x)
       k = boundary(x,y);
       plot(x(k),y(k),'LineWidth',5);
   end
    
end

hold off

end