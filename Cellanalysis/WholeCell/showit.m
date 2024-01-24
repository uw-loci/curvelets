function showit(imgFile)

img = imread(imgFile);
sizeR = size(img);

imgNew = zeros(sizeR);

for i=1:sizeR(1)
    for j=1:sizeR(2)
        
        if img(i,j) == 2
            imgNew(i,j) = 0;
        elseif img(i,j) == 1
            imgNew(i,j) = 100;
        end
        
    end
end

imshow(imgNew)


end