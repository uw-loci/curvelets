function [BDmask] = BDcreationHE(BDCparameters)

%October 21,2016: this function was originally developed by Adib Keikhosravi, a
% LOCI graduate student, to automatically generate the tumor boundary based
% on the epithelial cells segmentation and cluster from the RGB bright field
% HE image that is pre-registrated with the SHG image. This output mask will
% be used in CurveAlign. The function is pushed to the github for a verison
% control and will be incorporated into the CurveAlign.
% input:BDCparameters
% BDCparameters.HEfilepath: HE file path;
% BDCparameters.HEfilename: HE file name;
% BDCparameters.pixelpermicron: pixel per micron ratio of the HE image;
% BDCparameters.areaThreshold: threshold of the segmented areas;
% BDCparameters.SHGfilepath: SHG image file path ;
% Output: BDmask: mask for the boundary

HEfilepath = BDCparameters.HEfilepath;
HEfilename = BDCparameters.HEfilename;
pixelpermicron = BDCparameters.pixelpermicron;
areaThreshold = BDCparameters.areaThreshold;
SHGfilepath = BDCparameters.SHGfilepath;
% pixelpermicron=1.5;
HEdata = imread(fullfile(HEfilepath, HEfilename));
pixpermic = pixelpermicron;

S = decorrstretch(HEdata,'tol',0.01);
cform = makecform('srgb2lab');
lab_he = applycform(HEdata,cform);
ab_gray=im2double(rgb2gray(HEdata));
[m n]=size(ab_gray);
H = fspecial('disk',round(7*pixpermic));
for j=1:3
    k=padarray(S(:,:,j),[70 70],'symmetric');
    k2=histeq(k);
    k1(:,:,j)= imfilter(imfilter(k2,H),H);
    k3(:,:,j)=k1(71:70+m,71:70+n,j);
    
end
ab=double(k3);
nrows = size(ab,1);
ncols = size(ab,2);
ab = reshape(ab,nrows*ncols,3);
nColors =4;
[cluster_idx, cluster_center] = kmeans(ab,nColors,'distance','sqEuclidean','Replicates',3);
pixel_labels = reshape(cluster_idx,nrows,ncols);
segmented_images = cell(1,3);
rgb_label = repmat(pixel_labels,[1 1 3]);
mean_cluster_intensity=zeros(nColors,1);
for k = 1:nColors
    color = k3;
    color(rgb_label ~= k) = 0;
    segmented_images{k} = color;
    mean_cluster_intensity(k,1)=mean(nonzeros(rgb2gray(cell2mat(segmented_images(k)))));
    
end
mean_cluster_value = mean(cluster_center,2);
[tmp, idx] = sort(mean_cluster_value);
[temp1 idx1]=sort(mean_cluster_intensity);

cluster_val=zeros(nColors,1);
for k=1:nColors
    cluster_val(k,1)=find(idx==k)*find(idx1==k);
end
[temp2 idx2]=sort(cluster_val);
blue_cluster_num = idx2(1);

epith_cell=im2double(cell2mat(segmented_images(blue_cluster_num)));
epith_cell_BW=im2bw(rgb2gray(epith_cell),0.001);
se = strel('disk',round(4*pixpermic));
epith_cell_BW_open = imdilate(epith_cell_BW,se);
BWx= imfill(epith_cell_BW_open,'holes');
BWy=bwareaopen(~BWx,round((60*pixpermic)^2));
mask_image=bwareaopen(~BWy,round((35*pixpermic)^2));

IM3=mask_image;
BDmask = uint8(255*IM3);
savePath = fullfile(SHGfilepath,'CA_Boundary');
maskName = ['mask for ' strrep(HEfilename,'HE','SHG') '.tif'];
if ~exist(savePath,'dir')
    mkdir(savePath);
end
imwrite(BDmask,fullfile(savePath,maskName))
disp(sprintf('%s was saved at %s',maskName,savePath))

end


