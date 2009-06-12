function dataout(imagefig,varargins)

set(gcf,'WindowButtonMotionFcn',[]);
set(gcf,'windowbuttondownfcn',{@track});


