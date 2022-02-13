function visualization(maskFile, resultFile)

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