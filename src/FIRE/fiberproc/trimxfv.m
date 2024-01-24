function[X F V R] = trimxfv(Xin, Fin, Vin, Rin)
%removes the vertices that are no longer used from X and renumbers F
%accordingly
    if isempty(Fin)
        X = [];
        F = [];
        V = [];
        R = [];
        return
    end
    
    ind = zeros(size(Xin,1),1);
    for i=1:length(Fin)
        ind(Fin(i).v) = 1;
    end
    IND = find(ind==1);
    imap = zeros(1,size(Xin,1));
    imap(IND) = 1:length(IND);    
    X = Xin(IND,:);
    if nargin > 3
        R = Rin(IND,:);
    else
        R = [];
    end
    
    k=0;
    F(length(Fin)) = struct('v',[]); %preinitialize F so it doesn't grow in a loop
    for i=1:length(Fin)
        if length(Fin(i).v)>=2
            k=k+1;
            F(k).v   = imap(Fin(i).v);
            if isfield(Fin,'r')
                F(k).r   = Fin(i).r;
            end
            if isfield(Fin,'a')
                F(k).a   = Fin(i).a;
            end            
        end
    end
    F = F(1:k);
    
%construct V structure form F and X
    V(size(X,1)) = struct('fe',[],'f',[],'vall',[]);
    for fi=1:length(F)
        vi = F(fi).v;
        
        v1 = vi(1);
        v2 = vi(end);
        
        V(v1).fe(end+1) = fi;
        V(v2).fe(end+1) = fi;

        for vj=vi
            V(vj).f(end+1) = fi;
            V(vj).vall = ([V(vj).vall vi]); 
        end
    end
    
%create an f field in F to indentify which fibers are connected to which
    for fi=1:length(F)
        v = F(fi).v;
        fconn = [];
        for vj=v
            fconn = [fconn setdiff(V(vj).f,fi)];
        end
        F(fi).f = fconn;
    end