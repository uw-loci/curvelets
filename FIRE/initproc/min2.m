function[m i j] = min2(A);

%MIN2 - returns the minimum and the row and col index of a 2d matrix



[m1 i1] = min(A);

[m j]  = min(m1);

i = i1(j);