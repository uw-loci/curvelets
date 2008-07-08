function [im] = overlap_plot(x,y,color)
% x is the background image and y is the image that is desired to overlap
% x.  y should only have non-zero values where you want color to show over the
% background image.  This function also assumes that every value of y is >= 0;
 

grad = repmat(linspace(0,1,128)',1,3);

if strcmp(color,'red')
    mymap = grad.*repmat([1 0 0],128,1);
elseif strcmp(color,'green')
    mymap =  grad.*repmat([0 1 0],128,1);
elseif strcmp(color,'blue')
    mymap =  grad.*repmat([0 0 1],128,1);
elseif strcmp(color,'yellow')
    mymap =  grad.*repmat([1 1 0],128,1);
elseif strcmp(color,'magenta')
    mymap =  grad.*repmat([1 0 1],128,1);
elseif strcmp(color,'cyan')
    mymap =  grad.*repmat([0 1 1],128,1);
elseif strcmp(color,'violet')
    mymap =  grad.*repmat([.67 0 1],128,1);
elseif strcmp(color,'orange')
    mymap =  grad.*repmat([1 .4 0],128,1);
else
    error('Enter Valid Color')
end

%Scale input images to be between 0 and 128
if max(max(y)) ~=0;
x = abs(128*x./max(max(x)));
y = abs(128*y./max(max(round(y))));
map=[gray(128);mymap];
im = floor(x).*(y==0)+(y~=0)*128+y;
figure;imagesc(im);colormap(map);axis('image');
%figure;image(im);colormap(map);axis('image');
else
figure;imagesc(x);colormap(gray);axis('image');
end