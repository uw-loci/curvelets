% cellDists.m
% finds distance between outline and cell center at each outline pixel
% Inputs:
% r = row locations of outline
% c = column locations of outline
% cent = center of cell
%
% Outputs:
% dists = vector of euclidean distances
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function dists = cellDists(r,c,cent)

dists = zeros(length(r),1);
for aa = 1:length(r)
    tempr = (cent(2) - r(aa))^2;
    tempc = (cent(1) - c(aa))^2;
    dists(aa) = sqrt(tempr + tempc);
end

end