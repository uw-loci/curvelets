function butClear

if nargin == 0
    arg = 'Inintialize';
end

switch arg

case 'Inintialize'
    
uicontrol('Style','pushbutton','String','Clear','BackgroundColor','blue','Callback','clUser','Position',[190,130,50,100])

case 'GO'
    
angleTumorCollagen(img)

otherwise 
    
error('push the button')

end