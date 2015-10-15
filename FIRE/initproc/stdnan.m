function[s] = stdnan(v,dim)
%takes the stdev along the columns of a matrix
%it ignores nans
if nargin < 2
    dim = 1;
end

ind    = isnan(v);
numnan = sum(ind,dim);

mm = meannan(v);

v = v-ones(size(v,dim),1)*mm;

v_nonan = v;
v_nonan(ind) = 0;

v_sum = sum(v_nonan,dim);
v_sum2= sum(v_nonan.^2,dim);

N   = size(v,dim)-numnan;
ind = find(N==0);
N(ind) = NaN;

m = v_sum./(N-1);
m2= v_sum2./(N-1);

s = sqrt(m2-m.^2);

if any(isnan(s))
    1;
end
1;