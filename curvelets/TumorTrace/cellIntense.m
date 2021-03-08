% cellIntense.m
% find intensity of the 8-connect pixel neighborhood of each outline pixel
% Inputs:
% img = image for intensity measurement
% r = row outline locations
% c = column outline locations
%
% Outputs:
% intensity = vector of intensity values
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function intensity = cellIntense(img,r,c)
% initialize variables
intensity = zeros(length(r),1);
% find the intensity of the 8-connect neighborhood around each outline
% pixel
for aa = 1:length(r)
    if (r(aa)-1) >= 1 && (r(aa)+1) <= size(img,1) && (c(aa)-1) >= 1 && (c(aa)+1) <= size(img,2)
        temp = mean2((img((r(aa)-1):(r(aa)+1),(c(aa)-1):(c(aa)+1))));
    else
        temp = 0;
    end
    intensity(aa) = temp;
end


end