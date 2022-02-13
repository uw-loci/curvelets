function answers = individual_IoU(imageFile, maskFile)

image = imread(imageFile);
mask = imread(maskFile);

newSize = size(mask);

%imageNew = resampling(image(:,:,1), newSize);
imageNew = imresize(image(:,:,1), [newSize(1); newSize(2)], 'nearest');
%disp(imageNew)

numImg = 0; % check how many cells are segmented by the tool
for i=1:newSize(1)
    for j=1:newSize(2)
        if imageNew(i,j)>numImg
            numImg = imageNew(i,j);
        end
    end
end

answers = zeros(numImg,1); % stores the IoU for each cell

for i=1:newSize(3)
    [L,n] = bwlabel(mask(:,:,i));
    for j=1:numImg
        maximum = 0;
        for k=1:n
            IoU = IoUCalc(imageNew, L, j, k);
            if IoU > maximum
                maximum = IoU;
            end
        end
        answers(j) = maximum;
    end
end

% disp(answers);

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

function IoU = IoUCalc(img, mask, imgLabel, maskLabel)
    
TP = 0; % True positive
TN = 0; % True negative
FP = 0; % False positive
FN = 0; % False negative

sizeM = size(mask);

for i=1:sizeM(1) % going through each pixel
    for j=1:sizeM(2)
        if img(i,j) == imgLabel && mask(i,j) == maskLabel
            TP = TP + 1;
        elseif img(i,j) == imgLabel && mask(i,j) ~= maskLabel
            FP = FP + 1;
        elseif img(i,j) ~= imgLabel && mask(i,j) == maskLabel
            FN = FN + 1;
        elseif img(i,j) ~= imgLabel && mask(i,j) ~= maskLabel
            TN = TN + 1;
        end
    end
end

IoU = TP / (TP + FP + FN);

end