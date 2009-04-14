function setChoice(menVal,clearFlag,tag,varargins)
persistent pickMenu;
global img;
global menVal;


if nargin == 2
    pickMenu
else    
    pickMenu= get(menVal,'Value');

end

% sets gui according to the menu choice

if pickMenu == 2 
    close all
   
    imagefig=figure('units','normalized','position',[0.1 0.1 0.8 0.8]);    
    figure(1);image(img/4);colormap(gray);axis('image');
    hold on
   
    butROI;
    butRef;
    butThresh;
    butAlign;
    butReset;
    menu;
    
elseif pickMenu == 3
    close all
    
    imagefig=figure('units','normalized','position',[0.1 0.1 0.8 0.8]);    
    figure(1);image(img/4);colormap(gray);axis('image');
    hold on
    set(imagefig,'windowbuttondownfcn',{@track}); 
    butGo('arg',img);
    butClear;
    fillDist('arg',img);
    menu;
   
elseif pickMenu == 4 
    close all
    
    imagefig=figure('units','normalized','position',[0.1 0.1 0.8 0.8]);    
    figure(1);image(img/4);colormap(gray);axis('image');
    hold on

    butROI;
    menu;
  
end

