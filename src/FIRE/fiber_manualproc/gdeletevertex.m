function[X F V] = gdeletevertex(X,F,V)
%GDELETEVERTEX - delete 1 vertex from the end of a fiber

%if a handles structure is used instead of three seperate inputs
    if nargin==1
        handles = X;
        X = handles.X;
        F = handles.F;
        V = handles.V;
    end

%get the datatip object
    dcm_obj = datacursormode(gcf);
    
%get info on the datatip(s)
    info_struct = getCursorInfo(dcm_obj);

%make sure there are 2 data tips
    for i=1:length(info_struct)
        p = info_struct(i).Position;
        v = find( X(:,1)==p(1) & X(:,2)==p(2) & X(:,3)==p(3));    
        f = V(v).f;
        for fi=f
            if F(fi).v(1) == v
                F(fi).v(1) = [];
            elseif F(fi).v(end)==v
                F(fi).v(end) = [];
            end
        end
    end    
  
%trim and plot result
    [X F V] = trimxfv(X,F,V);
    cla
    plotfiber(X,F,2,0,[],'o')
    
%return a structure if the input was a structure
    if nargin==1        
        handles.X = X;
        handles.F = F;
        handles.V = V;
        X = handles;
    end
    1;
    