function[] = saveim3(fdir,fpref,im3)

    if fdir(end)=='/'
        fdir(end) = [];
    end

    im3 = uint8(round(im3));
    for i=1:size(im3,1)
        im = squeeze(im3(i,:,:));
        fname = sprintf('%s/%s%1.3d.tif',fdir,fpref,i);
        imwrite(im,fname,'tif')
    end