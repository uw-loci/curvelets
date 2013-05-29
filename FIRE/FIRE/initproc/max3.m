function[m i j k] = max3(A);
%MAX3 - returns the maximum and the row and col index of a 3d matrix

[m ind] = max(A(:));
[i j k] = ind2sub(size(A),ind(1));
