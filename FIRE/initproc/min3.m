function[m i j k] = min3(A);

%MIN3 - returns the minimum and the row and col index of a 2d matrix

[m ind] = min(A(:));
[i j k] = ind2sub(size(A),ind);
