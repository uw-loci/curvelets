function[] = setfont(fs);
%setfont(fontsize)
%
%this function sets the font of everything in the figure to fs

hf = get(gcf);
HA = get(gcf,'Children');

for i=1:length(HA)
    ha = HA(i);  
    
    a = get(ha);
    
    if isfield(a,'FontSize')
        set(ha,'FontSize',fs)
    end
    
    if isfield(a,'XLabel')
        hx = get(ha,'Xlabel');
        set(hx,'FontSize',fs)
    end
    
    if isfield(a,'YLabel')
        hy = get(ha,'Ylabel');
        set(hy,'FontSize',fs)
    end
    
    if isfield(a,'Title')
        ht = get(ha,'Title');
        set(ht,'FontSize',fs)
    end
end

