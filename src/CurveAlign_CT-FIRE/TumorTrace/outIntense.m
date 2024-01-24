% outIntense.m
% measures intensity in outer ROI
% Inputs:
% img = image for intensity measurement
% BWouter = binary outer ROI
% r = row outline locations
% c = column outline locations
% kSize = size of outer ROI
%
% Outputs:
% outerIntensity = vector of intensity values
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function outerIntensity = outIntense(img,BWouter,r,c,kSize)
kSize = round(kSize/2);
img = double(img)/max(max(double(img)));
outImg = immultiply(BWouter,img);
outImg = outImg.*(outImg >= 0);
outerIntensity = zeros(length(r),1);

for bb = 1:length(r)
    if (r(bb)-kSize) >= 1 && (r(bb)+kSize) <= size(img,1) && (c(bb)-kSize) >= 1 && (c(bb)+kSize) <= size(img,2)
        temp = (outImg((r(bb)-kSize):(r(bb)+kSize),(c(bb)-kSize):(c(bb)+kSize)));
        temp = mean2(temp);
    else
        temp = 0;
    end
    outerIntensity(bb) = temp;
    
end


