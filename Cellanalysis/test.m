function test()

t = Tiff('DX1-Results.tif','r');
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

end