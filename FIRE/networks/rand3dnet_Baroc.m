function[X0 F E V] = rand3dnet(num_fibers,len_fiber,diamsq_fiber,randseed,plotflag)
%RAND3DNET - computes a random 3d network using Barocas3d_mod
%use a tweaked version of Victor Barocas's student's code to generate a 
%random 3d lattice60;
%
%rand3dnet(num_fibers,len_fiber,diamsq_fiber,randseed,plotflag)
    if nargin==0
        num_fibers = 60;    %number of fibers
        len_fiber  = 0.1;   %width of 3d cube is 1
        diamsq_fiber=.03^2; %diameter^2 of fiber
        randseed    = 0;    %random number seed
        plotflag    = 0;    %set to 1 to automatically plot results
    end
    if nargin < 4
        randseed = 0;
    end
    if nargin < 5
        plotflag = 0;
    end

    if plotflag==1
        subplot(2,1,1)
    end
    [X0 E] = Barocas3d_mod(num_fibers,len_fiber,diamsq_fiber,randseed,plotflag);
    n = max(E(:)); %number of vertices
    m = size(E,1); %number of edges

%generate a vertex structure for better representation of network
    for i=1:n
        V(i).e = []; %the edges that vertex i connects to
        V(i).f = [];
    end
    for vi=1:n
        edgenum = find(E(:,1)==vi | E(:,2)==vi);
        V(vi).e = edgenum;
        for ej=edgenum
            eset = E(ej,:);
            V(vi).v = setdiff(eset(:),vi);
        end
        numedges(vi) = length(edgenum);
    end

%generate a fiber structure, that contains the edges
    vstart = find(numedges==1);
    fi = 0;
    while ~isempty(vstart)
        fi = fi + 1;
        vi = vstart(1);
        x1 = X0(vi,:);
        vstart(1) = [];
        
        F(fi).v = vi;
        V(vi).f = fi;
       
        vn = setdiff(V(vi).v,vi);
        dir= X0(vn,:) - x1;
        dir= dir/norm(dir);

        while ~isempty(vn)
            F(fi).v(end+1) = vn;
            V(vn).f(end+1) = fi;
           
            vn = setdiff(V(vn).v,F(fi).v);
            if length(vn)==2
                dir1 = X0(vn(1),:) - x1;
                a1   = sum(dir.*dir1)/norm(dir1);
                dir2 = X0(vn(2),:) - x1;
                a2   = sum(dir.*dir2)/norm(dir2);
                if a1>a2 %next node in fiber is a1
                    vn = vn(1);
                else
                    vn = vn(2);
                end
            else %we reached the end
                vstart = setdiff(vstart,F(fi).v(end));
            end
        end
    end
    
    if plotflag==1
        subplot(2,1,2)
        plotfiber(X0,F,.5);
        view(0,90);
    end