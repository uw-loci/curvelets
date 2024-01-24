function[v] = getnodeinfo(X,F,V)
%GDELETEVERTEX - delete 1 vertex from the end of a fiber

%get the datatip object
    dcm_obj = datacursormode(gcf);
    
%get info on the datatip(s)
    info_struct = getCursorInfo(dcm_obj);

    p = info_struct(1).Position;
    if length(p)==3
        v = find( X(:,1)==p(1) & X(:,2)==p(2) & X(:,3)==p(3));    
    elseif length(p)==2
        v = find( X(:,1)==p(1) & X(:,2)==p(2));    
    end
    if nargin>2
        V(v)
    else
        V = [];
        for i=1:length(F)
            if ismember(v,F(i).v)
                V(end+1) = i;
            end
        end
        fibers = V
    end