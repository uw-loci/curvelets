function  [registeredImage,transformMatrix]= ManualRegistration(BDCparameters)
%% manual registration
%input directories *****************
if  nargin == 1
    hePath = BDCparameters.HEfilepath;
    heName = BDCparameters.HEfilename{1};
    shgName = heName;
    shgPath = BDCparameters.SHGfilepath;
elseif  nargin == 0
    [shgName shgPath] = uigetfile({'*SHG*.tif';'*SHG*.tiff';'*.*'},'Load SHG file as fixed image',pwd,'MultiSelect','off');
    if isempty(shgName)
        fprintf('Fixed image is not properly loaded. Reload image to proceed \n')
        return
    end
    [heName hePath] = uigetfile({'*HE*.tif';'*HE*.tiff';'*.*'},'Load HE file as image to be registered',shgPath,'MultiSelect','off');
    if isempty(heName)
        fprintf('Moving HE image is not properly loaded. Reload image to proceed \n')
        return
    end
end

HEinfo = imfinfo(fullfile(hePath,heName));
SHGinfo = imfinfo(fullfile(shgPath,shgName));
he_dir_out = fullfile(hePath,'ManualRegisteredImage');
if ~exist(he_dir_out,'dir')
    mkdir(he_dir_out)
end
he = imread(fullfile(hePath,heName));
shg_dir_out = shgPath;
shg = imread(fullfile(shgPath,shgName));
shg_adj = imadjust(shg);
figure('Position', [100 50 768 768]);
%%
ax3(1) = subplot(2,2,1);
imshow(he);
title(sprintf('HE image,original, %d x %d,%d-bit',...
    HEinfo.Width,HEinfo.Height, HEinfo.BitDepth))
colormap('jet');
ax3(2) = subplot(2,2,2);
imshow(shg);
colormap('gray');
title(sprintf('SHG image ,original, %d x %d,%d-bit',...
    SHGinfo.Width,SHGinfo.Height, SHGinfo.BitDepth))
%manually register
home,disp('press ''ctrl-W'' to finish the landmark selection')
[he_pts,shg_pts] = cpselect(he,shg_adj,'Wait',true);
tform = cp2tform(he_pts, shg_pts, 'affine');
%tform = fitgeotrans(he_pts, shg_pts, 'affine');
tform_fname = sprintf('%stform_%s.mat',he_dir_out,heName);
save(tform_fname, 'tform');
fprintf('Transform maxtrix is saved as %s \n',tform_fname)
pre_registered = imtransform(he,tform,...
    'FillValues', 0,...
    'XData', [1 size(shg,2)],...
    'YData', [1 size(shg,1)]);
%%
%save the results
registeredImage = pre_registered;
transformMatrix = tform;

he_fname_out = fullfile(he_dir_out,heName); %full path  for he out
imwrite(pre_registered,he_fname_out,'tiff','Compression','packbits');
HEtinfo = imfinfo(he_fname_out);
ax3(3) = subplot(2,2,3);
imshow(pre_registered);
title(sprintf('HE image,transformed, %d x %d,%d-bit',...
    HEtinfo.Width,HEtinfo.Height, HEtinfo.BitDepth))
colormap('jet');
% Composite of two images
HEandSHG = imfuse(pre_registered,shg,'blend');
ax3(4) = subplot(2,2,4);
imshow(HEandSHG);
title(sprintf('Combined HE and SHG, %d x %d,%d-bit',...
    HEtinfo.Width,HEtinfo.Height, HEtinfo.BitDepth))
colormap('jet');
linkaxes(ax3,'xy');
if nargin == 0
    button = questdlg('Registrate new HE with this same spatial transformation ?', ...
        'New HE registration Dialog','Yes','No','Yes');
    switch button
        case 'Yes',
            disp('Register new HE(s) with the associated SHG(s) ');
            [he2Name, he2Path] = uigetfile({'*HE*.tif';'*HE*.tiff';'*.*'},'Load new HE file',hePath,'MultiSelect','on');
            if isempty(he2Name)
                fprintf('Moving HE image is not properly loaded. Reload image to proceed \n')
                return
            end
            he2_dir_out = he2Path;
            if ~iscell(he2Name)
                he2Name = {he2Name};
            end
            he2_dir_out = fullfile(he2Path,'ManualRegisteredImage');
            if ~exist(he2_dir_out,'dir')
                mkdir(he2_dir_out)
            end
            for ii = 1:length(he2Name)
                he2 = imread(fullfile(he2Path,he2Name{ii}));
                pre_registered = imtransform(he2,tform,...
                    'FillValues', 0,...
                    'XData', [1 size(shg,2)],...
                    'YData', [1 size(shg,1)]);
                he2_fname_out = fullfile(he2_dir_out,he2Name{ii}); %full path for new HE out
                imwrite(pre_registered,he2_fname_out,'tiff','Compression','packbits');
                fprintf('New manual registrated image is saved at: %s \n',he2_fname_out);
            end
        case 'No',
            disp(sprintf('Done with the manual spatial tranform and the transform matrix is saved as %s',tform_fname));
    end
end

return