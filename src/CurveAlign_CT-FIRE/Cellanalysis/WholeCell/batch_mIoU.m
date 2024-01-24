function batch_mIoU(maskFolder, resultFolder)

getMasks = uigetdir(maskFolder, 'Select a folder');
masks = dir(fullfile(getMasks, '*.tif'));
getResults = uigetdir(resultFolder, 'Select a folder');
results = dir(fullfile(getResults, '*.tif'));

PAsum = 0;
IoUsum = 0;
for i=1:length(masks)
    maskImgfilename = masks(i).folder + "/" + masks(i).name;
    maskImg = imread(maskImgfilename);
    newSize = size(maskImg);
    resultImgfilename = results(i).folder + "/" + results(i).name;
    resultImg = imread(resultImgfilename);
    resultImgNew = resampling(resultImg, newSize);
    resultImgNewNew = recoloring(resultImgNew);
    [pixelAccuracy, IoU] = mIoU(resultImgNewNew, maskImg);
    PAsum = PAsum + pixelAccuracy;
    IoUsum = IoUsum + IoU;
end

disp(PAsum / length(masks))
disp(IoUsum / length(masks))

end

function [pixelAccuracy, IoU] = mIoU(resultImg, maskImg)

sizeR = size(resultImg);
sizeM = size(maskImg);

% To see if the mask or the reading result is in multiple layers. If they
% are, combine the layers.
if size(sizeM) > 2
    flatMaskImg = combine(sizeM(3), maskImg);
else 
    flatMaskImg = maskImg;
end
if size(sizeR) > 2
    flatResultImg = combine(sizeR(3), resultImg);
else
    flatResultImg = resultImg;
end

TP = 0; % True positive
TN = 0; % True negative
FP = 0; % False positive
FN = 0; % False negative

for i=1:sizeM(1) % going through each pixel
    for j=1:sizeM(2) 
        if flatMaskImg(i,j) > 0 && flatResultImg(i,j) > 0
            TP = TP + 1;
        elseif flatMaskImg(i,j) == 0 && flatResultImg(i,j) > 0
            FP = FP + 1;
        elseif flatMaskImg(i,j) > 0 && flatResultImg(i,j) == 0
            FN = FN + 1;
        elseif flatMaskImg(i,j) == 0 && flatResultImg(i,j) == 0
            TN = TN + 1;
        end
    end
end

pixelAccuracy = (TP + TN) / (TP + TN + FP + FN);
IoU = TP / (TP + FP + FN);
% disp(pixelAccuracy)
% disp(IoU)

end

function flatImg = combine(layers, img)

sizeImg = size(img);
flatImg = zeros(sizeImg(1),sizeImg(2));

for i=1:sizeImg(1)
    for j=1:sizeImg(2)
        for k=1:layers
            if img(i,j,k) > 0
                flatImg(i,j) = 1;
            end
        end
    end
end

end

function vq = resampling(img, new)

sz = size(img);
xg = 1:sz(1);
yg = 1:sz(2);
F = griddedInterpolant({xg,yg},double(img));

xr = sz(1)/new(1);
yr = sz(2)/new(2);

xq = (0:xr:sz(1))';
yq = (0:yr:sz(2))';
vq = uint8(F({xq,yq}));

end

function imgNew = recoloring(img)

sizeR = size(img);

imgNew = zeros(sizeR);

for i=1:sizeR(1)
    for j=1:sizeR(2)
        
        if img(i,j) == 0
            imgNew(i,j) = 0;
        else
            imgNew(i,j) = 10;
        end
        
    end
end


end