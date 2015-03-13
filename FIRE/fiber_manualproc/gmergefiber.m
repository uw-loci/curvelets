function[X F V] = gmergefiber(X,F,V)
%GMERGEFIBER - merge 2 fibers together

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
    if length(info_struct)>2
        fprintf('there must be 1 or 2 data tips selected\n')
        return
    end

%find fibers associated with 2 selected data tips
    if length(info_struct)==1
        p = info_struct.Position;
        v = find( X(:,1)==p(1) & X(:,2)==p(2) & X(:,3)==p(3));
        f1= V(v).f(1);
        f2= V(v).f(2);
    end
        
    if length(info_struct)==2
        p1 = info_struct(1).Position;
        p2 = info_struct(2).Position;

        v1 = find( X(:,1)==p1(1) & X(:,2)==p1(2) & X(:,3)==p1(3));
        v2 = find( X(:,1)==p2(1) & X(:,2)==p2(2) & X(:,3)==p2(3));

        f1 = V(v1).f;
        f2 = V(v2).f;
    
        if length(f1)>1 | length(f2)>1
            fprintf('there is not a unique fiber assoc. with each datatip')
            return
        end
    end
    
   
    
%merge the two fibers together
    ve1 = [F(f1).v([1 end])];
    ve2 = [F(f2).v([1 end])];
    if any( any(ve1(1)==ve2) | any(ve1(2)==ve2) )
        vlist = mergefiber(F,V,f1,f2);
        F(f1).v = vlist;
        F(f2).v = [];
    else
        d11 = norm(X(ve1(1),:)-X(ve2(1),:));
        d22 = norm(X(ve1(2),:)-X(ve2(2),:));
        d12 = norm(X(ve1(1),:)-X(ve2(2),:));
        d21 = norm(X(ve1(2),:)-X(ve2(1),:));
        edgedist = [d11 1 1; d22 2 2; d12 1 2; d21 2 1];
        
        [mind ind] = min(edgedist(:,1));
        e1  = edgedist(ind,2);
        e2  = edgedist(ind,3);
        F = mergefiber_sep(F,f1,e1,f2,e2);       
    end
    
%trim and plot result
    [X F V] = trimxfv(X,F,V);
    cla
    plotfiber(X,F,2,0,[],'o')
    1;
    
%return a structure if the input was a structure
    if nargin==1        
        handles.X = X;
        handles.F = F;
        handles.V = V;
        X = handles;
    end    
    
end



%other functions



function[fmerge] = mergefiber(F,V,f1,f2)
    %MERGE - merges 2 fibers together so that they meet at the vertex
    %the two have in common
    %vm = the vertex in between the two fibers
    %ve = the new end vertex for fiber1
    fiber1 = F(f1).v;
    fiber2 = F(f2).v;

    if fiber1(1) == fiber2(1)
        fmerge = [fliplr(fiber2(2:end)) fiber1];
        vm     = fiber1(1);
        ve     = fiber2(end);
    elseif fiber1(1) == fiber2(end)
        fmerge = [fiber2(1:end-1) fiber1];
        vm     = fiber1(1);
        ve     = fiber2(1);
    elseif fiber1(end)==fiber2(1)
        fmerge = [fiber1(1:end) fiber2(2:end)];
        vm     = fiber1(end);
        ve     = fiber2(end);
    elseif fiber1(end)== fiber2(end)
        fmerge = [fiber1(1:end) fliplr(fiber2(1:end-1))];
        vm     = fiber1(end);
        ve     = fiber2(1);
    else
        error('these fibers don''t share an end vertex')
    end
end

function[F] = mergefiber_sep(F,f1,e1,f2,e2)
    %MERGE - merges 2 fibers when they don't share a vertex in common
    %fuse fiber 1, end 1 to fiber 2, end 2
    %here f1, f2 denote fiber indices and e1,e2 = 1 or 2 for beginning and
    %end of fiber
    %vm = the vertex in between the two fibers
    %ve = the new end vertex for fiber1
    fiber1 = F(f1).v;
    fiber2 = F(f2).v;

    if e1==1 & e2==1
        fmerge = [fliplr(fiber2) fiber1];
    elseif e1==1 & e2==2
        fmerge = [fiber2 fiber1];
    elseif e1==2 & e2==1
        fmerge = [fiber1 fiber2];
    elseif e1==2 & e2==2
        fmerge = [fiber1 fliplr(fiber2)];
    else
        error('entered wrong values for e1 and e2')
    end
    
    F(f1).v = fmerge;
    F(f2).v = [];
end
    