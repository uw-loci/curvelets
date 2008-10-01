function track(imagefig,varargins)

%%% Setting figure properties to start tracking
set(gcf,'windowbuttondownfcn',@dataout);
set(gcf,'WindowButtonMotionFcn',@datain);
set(gcf,'userdata',[]);

temp=get(gca,'currentpoint');
set(gcf,'userdata',[get(gcf,'userdata'); temp(1,1:2)]);





    

