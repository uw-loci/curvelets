function[imr] = downsample(im3,downspace)

dx = downspace(1);
dy = downspace(2);
dz = downspace(3);

iz = dz:dz:size(im3,1);
iy = dy:dy:size(im3,2);
ix = dx:dx:size(im3,3);
imr = zeros(length(iz),length(iy),length(ix),'double');
for j=1:dz
    for k=1:dy
        for l=1:dx
            imr = imr + double(im3(iz-dz+j,iy-dy+k,ix-dx+l));
        end
    end
end
imr = imr/(dx*dy*dz);
switch class(im3)
    case('uint8')
        imr = uint8(imr);
    case('uint16')
        imr = uint16(imr);
    case('double')
    otherwise
        error('invalid type for image')
end