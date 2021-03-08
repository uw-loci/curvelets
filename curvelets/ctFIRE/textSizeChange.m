% takes the screen size - finds the height of the screen divides by a ratio
% of 768/8 and scales up the text by the same amount
function[]=textSizeChange(figNumber)
    fig=figNumber;
    SS=get(0,'screensize');
    ratio=768/8;%768 is based on a computer
    newTextSize=floor(SS(4)/ratio);
    set(findall(fig,'-property','FontSize'),'FontSize',newTextSize);
end
