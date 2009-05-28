
function menVal = menu()
global menVal;

   
menVal = uicontrol('Style','popupmenu','String','Select...|Alignment|Boundary','BackgroundColor','white','Callback','setChoice(menVal)','FontSize',14,'FontName','fixedwidth','Position',[60,500,150,100]);

