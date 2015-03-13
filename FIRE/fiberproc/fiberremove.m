function[X F V R] = fiberremove(X,F,V,R,thresh_len,thresh_numv,plotflag)
%remove small fibers (less than p.thresh-flen elements) 
%that are only connected to another fiber at one vertex
%or are connected to the same fiber multiple times
%or two short fibers connect along a 3rd fiber, and that's it
    if nargin<7
        plotflag = 0;
    end
    fremove = [];
    [F Len] = calc_fiberlen(X,F);
    for fi=length(F):-1:1
        vconn = [];
        v1 = F(fi).v(1);
        v2 = F(fi).v(end);
        if Len(fi)<=thresh_len %|| length(F(fi).v)<=thresh_numv %short fiber
            %check to see what it's connected to
            for vi = F(fi).v
                if length(V(vi).f)>1
                    vconn = [vconn vi];
                end
            end
            vconn = unique(vconn);
            if length(vconn) <= 1                    
                if plotflag==1
                    plotfiber(X,F(fi),4,0,'r');
                end
                fremove(end+1) = fi;
                1;
            end
            fconn = F(fi).f; %the fibers that fiber fi are connected to           
            if length(fconn) == 2 %make sure we don't have ------------
                                  %                            \/
                                  %i.e. 2 short fibers running along fiber length
                f2 = fconn(1);
                f3 = fconn(2);
                
                fconn2 = F(f2).f;
                fconn3 = F(f3).f;
                
                if length(fconn2) == 2 && ismember(f3,fconn2) && Len(f2) <= thresh_len
                    fremove(end+1) = fi;
                    fremove(end+1) = f2;
                elseif length(fconn3) == 2 && ismember(f2,fconn3) && Len(f3) <= thresh_len
                    fremove(end+1) = fi;
                    fremove(end+1) = f3;
                end
            end
        end
    end
    F(fremove) = [];
    
    
    [X F V R] = trimxfv(X, F, V, R);
end