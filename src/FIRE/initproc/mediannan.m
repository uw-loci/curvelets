function[m] = mediannan(v)
%takes the mean along the columns of a vector or matrix
%it ignores any nans that it comes across

ind = ~isnan(v);
for i=1:size(v,2)
    m(i) = median(v(ind(:,i),i));
end