function[dsm d ims imt] = impreproc(im,p,dtype)
% Image preprocessing, before running FIRE
    if nargin <= 2
        dtype = 'euclidean';
    end

    %smoothing image
        fprintf('  smoothing original image\n');
        ims = round(smooth(im,p.sigma_im));

    %threshold image
        imt = ims>p.thresh_im*max(ims(:));
        %imt = perc_thresh(ims,p.threshi);

    %perform distance transform
        fprintf('  calculating Euclidian distance to background\n')
        d = single(bwdist(~imt,dtype));
        dsm = single(smooth(d,p.sigma_d));
        1;
        