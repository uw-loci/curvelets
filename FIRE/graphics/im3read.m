function[im3] = im3read(fname,N)
%IM3READ(fname,N) - reads a 3d image file, N=number of images

im = imread(fname);
s  = size(im);
im3= zeros(N,s(1),s(2),'uint16');
for i=1:N
    if mod(i,40)==0
        fprintf('%d  ',i);
    end
    im3(i,:,:) = imread(fname,i);
end