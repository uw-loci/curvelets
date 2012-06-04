% inIntense.m
% finds intensity in inner ROI
% Inputs: 
% img = image for intensity measurement
% BWinner = binary inner ROI
% r = row outline locations
% c = column outline locations
% kSize = ROI size
%
% Outputs:
% innerIntensity = vector of intensity values
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function innerIntensity = inIntense(img,BWinner,r,c,kSize)
kSize = round(kSize/4);
img = double(img)/max(max(double(img)));
inImg = immultiply(BWinner,img);
inImg = inImg.*(inImg >= 0);
innerIntensity = zeros(length(r),1);

for bb = 1:length(r)
    if (r(bb)-kSize) >= 1 && (r(bb)+kSize) <= size(img,1) && (c(bb)-kSize) >= 1 && (c(bb)+kSize) <= size(img,2)
        temp = (inImg((r(bb)-kSize):(r(bb)+kSize),(c(bb)-kSize):(c(bb)+kSize)));
        temp = mean2(temp);
    else
        temp = 0;
    end
    innerIntensity(bb) = temp;
    
end

