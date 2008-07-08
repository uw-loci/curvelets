
function but(arg,img)

if nargin == 2
    arg = 'Inintialize';
end

switch arg

case 'Inintialize'
    
uicontrol('Style','pushbutton','String','GO','BackgroundColor','red','Callback','angleTumorCollagen(img)','Position',[190,130,50,100])

case 'GO'
    
angleTumorCollagen(img)

otherwise 
    
error('push the button')

end