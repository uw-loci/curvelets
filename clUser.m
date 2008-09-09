function clUser(arg)

global img;

if nargin == 0;
close all;
end
imagefig=figure('units','normalized','position',[0.1 0.1 0.8 0.8]);    

figure(1);image(img/4);colormap(gray);axis('image');

hold on

set(imagefig,'windowbuttondownfcn',{@track}); 
butGo('arg',img);
butClear;
fillDist('arg',img);
