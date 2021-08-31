function boundaries = getboundary_matlab(img,imgCompare)

t = Tiff('TCGA-A7-A13E-01Z-00-DX1-cellprofiler.tiff','r');
imageData = read(t);

sizeImg = size(imageData);

max = 0;

for i=1:sizeImg(1)
    for j=1:sizeImg(2)
        if imageData(i,j) > max
            max = imageData(i,j);
        end
    end
end

boundaries = boundaryCard.empty(max,0);

for i=1:max
    boundaries(i) = boundaryCard();
end

for i=1:sizeImg(1)
    for j=1:sizeImg(2)
        if imageData(i,j) > 0
            index = imageData(i,j);
            boundaries(index).cellPoints = [boundaries(index).cellPoints; i j];
        end
    end
end

for i=1:max
    sizeCell = size(boundaries(i).cellPoints);
    if sizeCell ~= 0
        X = double.empty;
        Y = double.empty;
        for j=1:sizeCell(1)
            X = [X; boundaries(i).cellPoints(j,1)];
            Y = [Y; boundaries(i).cellPoints(j,2)];
        end
        boundaries(i).boundaryPoints = boundaryCalculation(X,Y,imageData);
    end
end

compare('test.tif', boundaries)

end

function compare(img,boundaries)

sizeBoundaries = size(boundaries);

figure
imshow(img)
hold on
for i=1:sizeBoundaries(2)
    if ~isempty(boundaries(i).boundaryPoints)
        for j=1:length(boundaries(i).boundaryPoints)
            X(j) = boundaries(i).boundaryPoints(j,1);
            Y(j) = boundaries(i).boundaryPoints(j,2);
        end
        plot(Y(:),X(:),'r.','MarkerSize', 5,'Color','Red')
%         for j=1:(length(boundaries(i).boundaryPoints)-1)
%             plot([Y(j); Y(j+1)], [X(j); X(j+1)],'LineWidth',2,'Color','Red')
%         end
%         plot([Y(length(boundaries(i).boundaryPoints)); Y(1)], [X(length(boundaries(i).boundaryPoints)); X(1)],...
%             'LineWidth',2,'Color','Red')
    end
end

hold off

end

function boundaryPoints = boundaryCalculation(X,Y,imgData)

numPoints = length(X);

Xres = double.empty;
Yres = double.empty;

for i=1:numPoints
    if X(i) == 1 || Y(i) == 1 || X(i) == 1000 || Y(i) == 1000
        Xres = [Xres; X(i)];
        Yres = [Yres; Y(i)];
    elseif imgData(X(i)-1,Y(i)) ~= imgData(X(i),Y(i)) || imgData(X(i),Y(i)-1) ~= imgData(X(i),Y(i))...
            || imgData(X(i)+1,Y(i)) ~= imgData(X(i),Y(i)) || imgData(X(i),Y(i)+1) ~= imgData(X(i),Y(i))
        Xres = [Xres; X(i)];
        Yres = [Yres; Y(i)];
    end
end

boundaryPoints(:,1) = Xres;
boundaryPoints(:,2) = Yres;

end