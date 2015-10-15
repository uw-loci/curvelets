function[F A Amap] = add_angle(X,F,V)
%ADD_ANGLE - add angle structure to Fand create angle array
%when 2 fibers intersect, we need to record two different starting angles
%Amap is an nx1 vector which maps an angle id to it's associated vertex id

    for fi=1:length(F) %create an angle index list in addition to the vertex index list
        F(fi).a = F(fi).v;
    end
    
    an = size(X,1);
    Amap = 1:an;
    for vi=1:length(V)
        f = unique(V(vi).f);
        if length(f)>1 %if more than one fiber passes through the vertex
            for j=2:length(f)
                fj = f(j);
                an  =an+1;
                
                ind = find(F(fj).a==vi);
                F(fj).a(ind) = an;
                Amap(an) = F(fj).v(ind(1));
                1;
            end
        end
    end
    A = zeros(an,3);