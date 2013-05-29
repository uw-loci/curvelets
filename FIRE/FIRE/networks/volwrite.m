function[] = volwrite(filename,im3)
%volwrite - writes 3d volume as a 3d tif

for k = 1:size(im3, 1)
    if mod(k,40)==0
        fprintf('%d ',k);
    end
    im = squeeze(im3(k,:,:));
    imwrite(im, filename, 'tif', 'Compression', 'none', 'WriteMode','append');
end