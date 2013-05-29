function[X F V] = gconnectfiber(X,F,V)
%GCONNECTFIBER - connect 1 fiber to another

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
    if length(info_struct)~=2
        fprintf('there must be 2 data tips selected\n')
        return
    end

%find fibers associated with 2 selected data tips
    p1 = info_struct(1).Position;
    p2 = info_struct(2).Position;

    v1 = find( X(:,1)==p1(1) & X(:,2)==p1(2) & X(:,3)==p1(3));
    v2 = find( X(:,1)==p2(1) & X(:,2)==p2(2) & X(:,3)==p2(3));
    
    f1 = unique(V(v1).f);
    f2 = unique(V(v2).f);
    
    if length(f1)>1 & length(f2)>1
        fprintf('there is not a unique fiber assoc. with each datatip')
    else   
        %make f1 the fiber index with only one fiber
            if length(f1) > 1
                ftemp = f2;
                f2 = f1;
                f1 = ftemp;
                vtemp = v2;
                v2 = v1;;
                v1 = vtemp;
            end
        %figure out which vertex is at the end
            if v1==F(f1).v(1)
                F(f1).v = [v2 F(f1).v];
            elseif v1==F(f1).v(end)
                F(f1).v = [F(f1).v v2];
            elseif v2==F(f2).v(1)
                F(f2).v = [v1 F(f2).v];
            elseif v2==F(f2).v(end)
                F(f2).v = [F(f2).v v1];
            else
                error('need to select at least one end vertex')
            end


        %trim and plot result
            [X F V] = trimxfv(X,F,V);
            cla
            plotfiber(X,F,2,0,[],'o')
    end
    
%return a structure if the input was a structure
    if nargin==1        
        handles.X = X;
        handles.F = F;
        handles.V = V;
        X = handles;
    end
    1;