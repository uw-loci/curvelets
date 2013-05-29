function[X,F,V] = fiber2beam(X,F,V,R,minspace,lam,plotflag)
%FIBER2BEAM - converts fiber array to a reduced fiber array based on beam
%interpolations.
if nargin<7
    plotflag = 0;
end
if isempty(F)
    return
end

%For each fiber, pin down the vertices and end points and find a curv that
%passes near the rest of the points
    fprintf('    finding curves for %d fibers\n',length(F));
    for i=1:length(F);        
        %find the vertices that are pinned down
            vi = F(i).v;
            vind  = vi(1);
            fvind = 1;
            jj=1;
            for vj=vi(2:end-1)
                jj=jj+1;
                if length(V(vj).f) > 1
                    vind (end+1) = vj;
                    fvind(end+1) = jj;
                end
            end
             vind(end+1) = vi(end);
            fvind(end+1) = length(vi);
            
        %make a reduced F
            Fred(i).v = F(i).v(fvind);
            if isfield(F,'r')
                Fred(i).r = F(i).r;
            end
        %find best curve 
            Xi   = X(vi,:);
            [AL{i} AR{i}] = bestcurv(Xi,fvind,lam,plotflag);
            if plotflag == 1
                title([num2str(i) ' of ' num2str(length(F))]);
                pause(.1)
            end
            Xcrit{i} = X(vind,:); %critical X points for a fiber
    end
    
% create new {X,F,V,A} matrix, where points along fiber are a minimum of
%"minspace" away from each other
    Fred_old = Fred;
    N = size(X,1);
    for i=1:length(F)
        for j=size(Xcrit{i},1)-1:-1:1
            X1 = Xcrit{i}(j,:);
            X2 = Xcrit{i}(j+1,:);
            [x y z] = plotbeam([X1;X2],AL{i}(j,:),AR{i}(j,:),0,10);
            d = sum(len3d(x,y,z));
            if d > minspace %we need to break fiber up into n smaller pieces
                n = round(d/minspace);
                [x y z] = plotbeam([X1;X2],AL{i}(j,:),AR{i}(j,:),0,n+2);
                if length(x) > 1
                    X(N+1:N+n,:) = [x(2:n+1) y(2:n+1) z(2:n+1)];

                    Fred(i).v = [Fred(i).v(1:j) N+1:N+n Fred(i).v(j+1:end)];
                    N = N+n;
                end
            end
      
        end
        1;
    end
    X1 = X; F1 = Fred; V1 = V;
    [X F V] = trimxfv(X,Fred,[]);
    
  