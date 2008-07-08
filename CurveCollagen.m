function  CurveCollagen(img,pctg);
%  Usage: -img the image that is to be processed.  
%         -pctg is the number of curvelet coefficients used in the
%         reconstruction.  1%-10% are good values.
%         -numAngle is the number of angles to seperate out into different
%         images in the output.  This should be either 2,4,8;
%         -keep is a vector with the percentage of the curvelets to output
%         in the images.  The vector keep should be the same length as the
%         value of numAngle.  Keep can also be a single value.

img = double(img(1:512,1:512,1)); % Peel off one layer and make the image dyadic

%% Take the curvelet transform
C = fdct_wrapping(img,1);

% Apply a gradient so that the edges are zero
C = pixel_indent(C,2);

% Get threshold value
cfs =[];
for s=1:length(C)
  for w=1:length(C{s})
    cfs = [cfs; abs(C{s}{w}(:))];
  end
end
cfs = sort(cfs); cfs = cfs(end:-1:1);
nb = round(pctg*length(cfs));
cutoff = cfs(nb);

% Set small coefficients to zero
for s=1:length(C)
  for w=1:length(C{s})
    C{s}{w} = C{s}{w} .* (abs(C{s}{w})>cutoff);
  end
end

C{1}{1} = zeros(size(C{1}{1}));
 
% Take the inverse curvelet transform with angle groupings
 
Coeffs = splitAngle(C);

angle_rec = cell(size(Coeffs));

for ii = 1:length(Coeffs);
    angle_rec{ii} = ifdct_wrapping(Coeffs{ii},1);
end

tmp = zeros(size(angle_rec{1}));

for ii = 1:length(angle_rec)
    curvelet_img = tmp + angle_rec{ii};
    tmp = curvelet_img;
end

curvelet_img = curvelet_img.*(curvelet_img>0);

% Display colors
colorCurvelet(angle_rec,keep,img); 
%colorCurvelet(angle_rec,keep,curvelet_img); 
figure;image(img/4); axis('image'); colormap(gray); title('Original Image'); 
figure;image(curvelet_img/4); axis('image'); colormap(gray); title('Curvelet Transformed Image'); 

