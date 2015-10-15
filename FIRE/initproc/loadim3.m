function[im3] = loadim3(fdir,n,fstr,fsuff,zerofloat,yind,xind)
%LOADIM3 - loads in a stack of images of format im##.tif
%fdir is the directory of the stack
%n is either a final index or a range or indices to read in
%
%zerofloat = 0 - means it goes im1, im2, ...
%zerofloat = 2 - means it goes im001, im002, ...

if length(n)==1 %then n is a final index
    irange = 1:n;
else %n is actually a range of indices
    irange = n;
end

if nargin<3
    fstr = 'im';
end
if nargin<4
    fsuff = '.tif';
end
if nargin<5
    zerofloat = 0;
end
if nargin<7
    yind = [];
    xind = [];
end

i=irange(1);
if zerofloat == 0
    fname = sprintf('%s/%s%d%s',fdir,fstr,i,fsuff);
elseif zerofloat == 1
    fname = sprintf('%s/%s%1.2d%s',fdir,fstr,i,fsuff);
elseif zerofloat == 2
    fname = sprintf('%s/%s%1.3d%s',fdir,fstr,i,fsuff);
elseif zerofloat == 3
    fname = sprintf('%s/%s%1.4d%s',fdir,fstr,i,fsuff);
else
    error('invalid zerofloat')
end
im = imread(fname);

c  = class(im);
cmax = double(intmax(c));
[y x] = size(im);
if isempty(yind)
    yind = 1:y;
    xind = 1:x;
end

im3 = zeros(length(irange),length(yind),length(xind),c);
%fprintf('%s\n',fname);

ii = 0;
fprintf(' ');
for i=irange
    ii=ii+1;
    if mod(ii,40)==0
        fprintf('%d ',i);
    end
    if zerofloat == 0
        fname = sprintf('%s/%s%d%s',fdir,fstr,i,fsuff);
    elseif zerofloat == 1
        fname = sprintf('%s/%s%1.2d%s',fdir,fstr,i,fsuff);
    elseif zerofloat == 2
        fname = sprintf('%s/%s%1.3d%s',fdir,fstr,i,fsuff);
    elseif zerofloat == 3
        fname = sprintf('%s/%s%1.4d%s',fdir,fstr,i,fsuff);   
    else
        error('invalid zerofloat')
    end
    im = imread(fname);
    im3(ii,:,:) = im(yind,xind); %we scale image if its not uint8
end
fprintf('\n')