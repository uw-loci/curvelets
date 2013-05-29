function[IMR] = loadim3_shift(fdirpref,stacknum,shift,siz)
%LOADIM3_SHIFT - loads in the aligned portion of a set of image stacks 
%where the alignment is specified by shift
%
%the subdirectory containing the images ends in a number, stacknum

%find maximum and minimum shifts
    [maxshift ind] = max(shift,[],1);
    sxmax = shift(ind(1),1);
    symax = shift(ind(2),2);
    szmax = shift(ind(3),3);
    
    [minshift ind] = min(shift,[],1);
    sxmin = shift(ind(1),1);
    symin = shift(ind(2),2);
    szmin = shift(ind(3),3);

    K = siz(1);
    M = siz(2);
    N = siz(3);
    
%establish image indices of overlap    
    ix = -sxmin+1:N-sxmax;
    iy = -symin+1:M-symax;
    iz = -szmin+1:K-szmax;

%loop through images and keep only the parts that can be aligned
    for j=1:length(stacknum)
        jnum = stacknum(j);
        sj  = shift(j,:);        
        ixj = ix+sj(1);
        iyj = iy+sj(2);
        izj = iz+sj(3);  
        
        fdir = [fdirpref num2str(jnum)];
        im3  = loadim3(fdir,izj-1);  %we subtract 1 from izj because images start at im0                 
        IMR{j} = im3(:,iyj,ixj);
    end
