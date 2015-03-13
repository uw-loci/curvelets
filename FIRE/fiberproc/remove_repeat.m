function[X F V R] = remove_repeat(X,F,V,R,plotflag,thresh_emerge)
%REMOVE_REPEAT - account for cases where a particular X is repeated
%or when two identifical vertices are in a row, or a middle and edge of teh
%same fiber

if nargin<5
    plotflag = 0;
end
if nargin<5
    thresh_emerge=Inf;
end
    
lenold = Inf;
len    = length(F);

%fprintf('   removing repeats - ');
while lenold~=len
    lenold = len;
    %fprintf('%d, ',len);
    %find when different X's are identical
        Xr = max(ceil(X/max(X(:))*1000),1);
        s  = max(Xr);
        ind = sub2ind(s,Xr(:,1),Xr(:,2),Xr(:,3));
        [isort idsort] = sort(ind);
        dsort = diff(isort);
        idiff = find(dsort==0);
        same  = [idsort(idiff) idsort(idiff+1)];

    %replace all identical x's with the same vertex id
        for i=1:size(same,1)
            vi = same(i,1);
            vj = same(i,2);
            f = V(same(i,1)).f;
            for j=f
                F(j).v(F(j).v==vi) = vj;
            end
        end    

    %remove instances of two identical vertices being in a row in a fiber
    %i. e. F(i).v = [3 23 45 45 9] -> [3 23 45 9]
        for i=1:length(F)
            vi = F(i).v;
            vd = diff(vi);
            F(i).v(vd==0) = []; %same vertices next to each other
        end

    %remove cases where end vertices appear also in fiber middle
        for i=1:length(F)
            vi = F(i).v;
            ve1 = vi(1);
            ind = find(vi==ve1);
            ind = setdiff(ind,1);
            if ~isempty(ind)
                F(i).v(1) = [];
            end
            ve2 = vi(end);
            ind = find(vi==ve2);
            ind = setdiff(ind,length(vi));
            if ~isempty(ind)
                F(i).v(end) = [];
            end
        end

        [X F V R] = trimxfv(X,F,[],R);

    %find cases where two fibers share at least two points and deal with them accordingly
    %keep one fiber (fi) as is and break the other fiber (fj) into pieces,
    %removing any portions of intersection.
        for ii=1:length(V)
            f = V(ii).f;
            if length(f)>1
                for i=1:length(f)-1
                    fi = f(i);
                    for j=i+1:length(f)
                        fj = f(j);                     
                        vi = F(fi).v;
                        vj = F(fj).v;

                        [vshare ij] = intersect(vj,vi);
                        if length(vshare) >= 2 && fi~=fj
                            if plotflag
                                cla
                                plotfiber(X,F(fi),2,0,'b','o')
                                plotfiber(X,F(fj),2,0,'k','o')
                            end
                            v1 = vj(min(ij));
                            v2 = vj(max(ij));
                            x1 = X(v1,:);
                            x2 = X(v2,:);
                            if norm(x2-x1) < thresh_emerge
                                if min(ij)>1
                                    F(end+1).v = vj(1:min(ij));
                                    if isfield(F,'r')
                                        F(end).r = F(fj).r;
                                    end
                                    if plotflag
                                        plotfiber(X,F(end),2,0,'r','o')
                                    end
                                end
                                if max(ij)<length(vj)
                                    F(end+1).v = vj(max(ij):end);
                                    if isfield(F,'r')
                                        F(end).r = F(fj).r;
                                    end
                                    if plotflag
                                        plotfiber(X,F(end),2,0,'r','o')
                                    end
                                end
                                F(fj).v = [];
                            end
                        end
                    end
                end
            end
        end
    
    [X F V R] = trimxfv(X,F,V,R);
    len = length(F);
end
%fprintf('\n');