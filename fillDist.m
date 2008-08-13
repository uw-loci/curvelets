function fillDist(arg,img)

if nargin == 2
    arg = 'Inintialize';
end

switch arg

case 'Inintialize'
    
uicontrol('Style','edit','Position',[90,230,50,28],'Tag','dist')
uicontrol('Style','edit','Position',[500,20,50,28],'Tag','micron')
uicontrol('Style','text','String', 'Width in Microns','Position',[450,22,50,22])
uicontrol('Style','text','String', 'Distance in Microns','Position',[90,210,50,20])

end