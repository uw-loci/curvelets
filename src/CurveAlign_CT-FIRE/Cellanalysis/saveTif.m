function saveTif()
% This function saves the result mask from StarDist (labels.mat) into
% visible mask of TIF file. 

load('labels.mat','labels');
labels = mat2gray(labels);

labels = double(labels);

imwrite(labels,'mask_visual.tif');

graph(1)
%saveTifLightGray()

end

function saveTifLightGray()
% This function is called by saveTif() to modify the gray colors to a
% visible range and save the image.

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
% This function (currently not being used) will draw the boundary of a
% nucleus of choosing. 
% j - the index of nucleus that will be displayed.

load('details.mat','details');
sizeCoord = size(details.coord);

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

% load('rect.mat','rect');

figure
imshow('mask_visual.tif')
hold on
for i=1:(sizeCoord(3)-1)
    plot([Y(i); Y(i+1)], [X(i); X(i+1)],'LineWidth',3,'Color','Red')
end
plot([Y(i+1); Y(1)], [X(i+1); X(1)],'LineWidth',3,'Color','Red')
hold off

% o = atan((rect(3,2)-rect(2,2))/(rect(3,1)-rect(2,1))) * 180/pi;

end