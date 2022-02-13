function a = test()

image = imread('results-mesmer/F01_120w1_copy_mesmer.tif');
new = [520 696];

a = resampling(image, new);


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