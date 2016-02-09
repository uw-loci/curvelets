function [BDmask] = BDcreationHE(BDCparameters)

% Feb 3,2016: this function was originally developed by Adib Keikhosravi, a 
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

HEdata=im2double(HEdata);
%figure;imshow(HEdata)
max_HEdata=max(max(max(HEdata)));
HEdata_adj = imadjust(HEdata,[0 max_HEdata],[0 1]);
HEdata=im2uint8(HEdata_adj);

% figure;imshow(HEdata), title('H&E image');

cform = makecform('srgb2lab');
lab_HEdata = applycform(HEdata,cform);
ab_gray=im2double(rgb2gray(HEdata));
%     figure;imshow(ab_gray)

ab = double(lab_HEdata(:,:,2:3));
nrows = size(ab,1);
ncols = size(ab,2);
ab = reshape(ab,nrows*ncols,2);

nColors = 4;
tic
disp('clustering begins')
% repeat the clustering 3 times to avoid local minima
[cluster_idx, cluster_center] = kmeans(ab,nColors,'distance','sqEuclidean', ...
                                      'Replicates',3);
disp('clustering ends')
toc
                                  
                                  
pixel_labels = reshape(cluster_idx,nrows,ncols);
% figure;imshow(pixel_labels,[]), title('image labeled by cluster index');

segmented_images = cell(1,3);
rgb_label = repmat(pixel_labels,[1 1 3]);
    mean_cluster_intensity=zeros(nColors,1);

for k = 1:nColors
    colorData = HEdata;
    colorData(rgb_label ~= k) = 0;
    segmented_images{k} = colorData;
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
    
L = lab_HEdata(:,:,1);
blue_idx = find(pixel_labels == blue_cluster_num);
L_blue = L(blue_idx);
is_light_blue = im2bw(L_blue,graythresh(L_blue));

nuclei_labels = repmat(uint8(0),[nrows ncols]);
nuclei_labels(blue_idx(is_light_blue==false)) = 1;
nuclei_labels = repmat(nuclei_labels,[1 1 3]);
blue_nuclei = HEdata;
blue_nuclei(nuclei_labels ~= 1) = 0;
% figure;imshow(blue_nuclei), title('blue nuclei');

epith_cell=cell2mat(segmented_images(blue_cluster_num));
I_gray=im2double(rgb2gray(epith_cell));
BW=im2bw(I_gray,0.001);
% figure;imshow(BW)
BW2 = bwareaopen(BW,12*12*(pixelpermicron^2));
% figure;imshow(BW2)

I_gray_discard=I_gray.*BW2;
% figure;imshow(I_gray_discard)



 I_filt=imfilter(I_gray_discard,fspecial('average',round(5*pixelpermicron)));
% SE = strel('disk', 5, 0);
%  I_filt = imdilate(I_gray_discard,SE);
% I_filt=imfilter(I_filt,fspecial('average',20));
I_filt=imfilter(I_filt,fspecial('gaussian',round(12.5*pixelpermicron),0.4));

I_filt = imadjust(I_filt);
I_filt_BW=im2bw(I_filt,0.01);
% figure; imshow(I_filt)
% figure;imshow(I_filt_BW)

se=strel('disk',round(pixelpermicron*7));
BW_close=imclose(I_filt_BW,se);
% 

% figure;imshow(BW_close)

IM2 = imcomplement(BW_close);
IM2 = bwareaopen(IM2, round((40*pixelpermicron)^2));

IM3=bwareaopen(~IM2,areaThreshold);
BDmask = uint8(255*IM3);
savePath = fullfile(SHGfilepath,'CA_BDboundary');
maskName = ['mask for ' strrep(HEfilename,'HE','SHG') '.tif'];
if ~exist(savePath,'dir')
   mkdir(savePath); 
end
imwrite(BDmask,fullfile(savePath,maskName))
disp(sprintf('%s was saved at %s',maskName,savePath))
% figure;imshow(IM3)

end

