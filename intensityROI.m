function intensityROI()
global img;

img_sz = size(img);
wide = img_sz(2);
tall = img_sz(1);
C = 0; 
X = 0; 
Y = 0; 



for aa = 1:tall/100:tall
    [cx,cy,c] = improfile(img,[1 wide],[aa aa]);
    
    C = cat(1,C,c);
    X = cat(1,X,cx);
    Y = cat(1,Y,cy);
end


map = cat(2,C,X,Y);

max1 = max(map,[],1);

maxC = max1(:,1)

%imshow(img);

for bb = 1:1:length(map)
if map(bb,1) > (.5*maxC) && map(bb,1) < (.8*maxC)
    plot(map(bb,2),map(bb,3),'xr');
end
end









