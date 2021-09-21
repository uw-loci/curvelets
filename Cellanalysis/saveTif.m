function saveTif()

load('labels.mat','labels');
labels = mat2gray(labels);

labels = double(labels);

imwrite(labels,'mask_visual.tif');

% graph(1)
saveTifLightGray()

end

function saveTifLightGray()

t = Tiff('mask_visual.tif','r');
imageData = read(t);
sizeT = size(imageData);

for i=1:sizeT(1)
    for j=1:sizeT(2)
        if imageData(i,j) ~= 0
            remain = mod(imageData(i,j),100);
            imageData(i,j) = 100 + remain;
        end
    end
end

imageData = mat2gray(imageData);

imwrite(imageData,'test.tif');

figure
imshow('test.tif')

end

function graph(j) 

load('details.mat','details');
sizeCoord = size(details.coord);

% for j=1:sizeCoord(1)
%     for i=1:sizeCoord(3)
%         X(i) = details.coord(j,1,i);
%         Y(i) = details.coord(j,2,i);
%     end
%     % plot(Y(:),X(:),'r.','MarkerSize', 10)
%     for i=1:(sizeCoord(3)-1)
%         plot([Y(i); Y(i+1)], [X(i); X(i+1)],'LineWidth',5)
%     end
%     plot([Y(sizeCoord(3)); Y(1)], [X(sizeCoord(3)); X(1)],'LineWidth',5)
% end
for i=1:sizeCoord(3)
    X(i) = details.coord(j,1,i);
    Y(i) = details.coord(j,2,i);
end

pe = pyenv;
pathToRect = fileparts(which('findAxisPoints.py'));
if count(py.sys.path,pathToRect) == 0
    insert(py.sys.path,int32(0),pathToRect);
end

py.findAxisPoints.findRectPoints(Y,X);

load('rect.mat','rect');

figure
imshow('mask_visual.tif')
hold on
for i=1:(sizeCoord(3)-1)
    plot([Y(i); Y(i+1)], [X(i); X(i+1)],'LineWidth',3,'Color','Red')
end
% plot(details.points(:,2), details.points(:,1),'r.','MarkerSize', 10)
% plot(rect(1,1), rect(1,2),'r.','MarkerSize', 10)
% plot(rect(2,1), rect(2,2),'r.','MarkerSize', 10)
plot(rect(3,1), rect(3,2),'r.','MarkerSize', 10)
% plot(rect(4,1), rect(4,2),'r.','MarkerSize', 10)
plot([rect(1,1); rect(2,1)], [rect(1,2); rect(2,2)],'LineWidth',2,'Color','Red')
plot([rect(2,1); rect(3,1)], [rect(2,2); rect(3,2)],'LineWidth',2,'Color','Red')
hold off

o = atan((rect(3,2)-rect(2,2))/(rect(3,1)-rect(2,1))) * 180/pi;
% disp(rect(3,2))
% disp(rect(2,2))
% disp(rect(3,1))
% disp(rect(2,1))
% disp(o)

end