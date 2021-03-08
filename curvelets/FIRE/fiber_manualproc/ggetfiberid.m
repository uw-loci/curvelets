function[f v] = ggetfiberid(X,F,V)
%GGETFIBERID - gets id of selected fiber

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
        f{i} = V(v).f;
    end    
  

    