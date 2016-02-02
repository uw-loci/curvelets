fig=gcf;
ratio=1366/8;
newTextSize=floor(max(get(0,'screensize'))/ratio);
set(findall(fig,'-property','FontSize'),'FontSize',8);