function[F V] = mergevertex(F,V,v1,v2,X)
    %MERGEVERTEX - merges 2 vertices together
    %by removing one vertex and have it's neighbors link to the new
    %the other vertex    

    f1 = V(v1).f;
    f2 = V(v2).f;
    fboth = intersect(f1,f2);
    f1only = setdiff(f1,fboth);
    f2only = setdiff(f2,fboth);
    
    %if v1 and v2 are in the same fiber, and not at the ends, then we break
    %that fiber up into 2 or 3 pieces (depending on where v1 and v2 are)
    %if v1 and v2 are right next to each other, than only 2
        for fi=fboth
            v = F(fi).v;
            iv1 = find(v==v1);
            iv2 = find(v==v2);

            iva = min(iv1,iv2);
            ivb = max(iv1,iv2);
    
            iv = 1;
            if iva > 1 %if there are vertices to the left of va
                vnew{iv} = [v(1:iva-1) v1];
                iv=iv+1;
            end
            if ivb < length(v) %there ave vercites to the right of vb
                vnew{iv} = [v1 v(ivb+1:end)];
                iv=iv+1;
            end
            if ivb>iva+1  %there ave vertices in between iva and ivb
                vnew{iv} = [v1 v(iva+1:ivb-1)];
            end

            if iv == 1 %then no new fibers are created.  this can happen if there is a single fiber with only 2 vertices
                for vj = v
                    V(vj).f = setdiff(V(vj).f,fi);
                end
            else %new fibers are created
                for i=1:length(vnew)
                    fnew = length(F)+1;
                    F(fnew).v = vnew{i};
                    for vj=vnew{i}
                        V(vj).f(end+1) = fnew;
                        V(vj).f = setdiff(V(vj).f,fi); %fi is being removed
                    end
                end
                F(fi).v = [];        
            end
        end            
    
    for fi = f2only
        %first, find the vertices that v2 connects to in each fiber          
            len = length(F(fi).v);
            iv2 = find(F(fi).v==v2);
            iv2 = iv2(1);
            if iv2==1 || iv2 == len; %if v2 is at the end of the fiber, no problem
                                    %just switch it over to v1
                F(fi).v(iv2) = v1;
                V(v1).f(end+1) = fi;
            else %v2 is in the middle of the fiber, so we gotta split the fiber in two                
                fnew = length(F)+1;
                F(fnew).v = [v1 F(fi).v(iv2+1:end)];
                F(fi).v = [F(fi).v(1:iv2-1) v1];
                for vj = F(fnew).v
                    V(vj).f(end+1) = fnew;
                    V(vj).f = setdiff(V(vj).f,fi);
                end
                V(v1).f(end+1) = fi;
            end
    end

    %we also need to split any fibers that happen to pass through v1
    for fi=f1only
        iv1 = find(F(fi).v==v1);
        iv1 = iv1(1);
        len = length(F(fi).v);
        if iv1==1 || iv1 == len
            %do nothing, we're ok
        else
            %split fiber
            fnew = length(F)+1;
            F(fnew).v = F(fi).v(iv1:end);
            F(fi).v     = F(fi).v(1:iv1);
            for vj = F(fnew).v
                V(vj).f(end+1) = fnew;
                V(vj).f = setdiff(V(vj).f,fi);
            end    
        end
    end
    
    V(v2).vall = [];
    V(v2).f    = [];
    V(v2).fe   = [];
    1;
end