function[m] = meannan(v,dim)
%takes the mean along the columns of a vector or matrix
%it ignores any nans that it comes across

if nargin < 2
    dim = 1;
end

ind    = isnan(v);
numnan = sum(ind,dim);

v_nonan = v;
v_nonan(ind) = 0;

v_sum = sum(v_nonan,dim);

N   = size(v,dim)-numnan;
ind = find(N==0);
N(ind) = NaN;

m = (v_sum./N);