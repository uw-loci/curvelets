function mIoU(resultImg, maskImg)

sizeR = size(resultImg);
sizeM = size(maskImg);

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

TP = 0;
TN = 0;
FP = 0;
FN = 0;

for i=1:sizeR(1)
    for j=1:sizeR(2)
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
disp(pixelAccuracy)
disp(IoU)

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