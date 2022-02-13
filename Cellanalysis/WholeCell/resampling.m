function imgNew = resampling(img, size)

imgNew = zeros(size(1), size(2));

sizeImg = size(img);

for i=1:size(1)
    for j=1:size(2)
        pixelPosition = [fix(i/size(1)*sizeImg(1)); fix(i/size(2)*sizeImg(2))];
        
    end
end


end