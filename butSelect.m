
function butSelect(arg,img)

if nargin == 2
    arg = 'Inintialize';
end

switch arg

case 'Inintialize'
    
m = uicontrol('Style','popupmenu','String','Select...|Alignment|Boundary|Intensity','BackgroundColor','white','setChoice','Position',[60,500,200,100]);

case 'GO'
    
setChoice

otherwise 
    
error('push the button')

end