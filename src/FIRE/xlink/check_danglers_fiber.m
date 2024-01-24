function[X F V R] = check_danglers_fiber(X,F,V,R,p)
%check_danglers(X,F,V,R,p) - identify edges that connect only to one x-link.
% if they are running parallel to another edge (dangler or no) remove it.
% if they run in the same direction as a cross-linked edge, keep it.  but
% make sure only to keep one.  otherwise, remove it.
% for all the fibers we decide to keep, check once more to see if we can't
% extend them a bit more.

%calculate number of x-links in each fiber
    nxlinks = zeros(length(F),1);
    xlinki  = zeros(length(F),1);
    for fi=1:length(F)
        for vi = F(fi).v
            if length(V(vi).f) > 1
                nxlinks(fi) = nxlinks(fi) + 1;
                xlinki(fi) = vi;
            end
        end
    end


for fi=1:length(F)
    if nxlinks == 1
        v  = F(fi).v;
        
        vi = xlinki(fi);
        
        if vi==v(1)
            vjrange = v(end);
            ijrange = length(v);
        elseif vi==v(end)
            vjrange = v(1);
            ijrange = 1;
        else
            vjrange = v([1 end]);
            ijrange = [1 length(v)];
        end
        
        
        
    fi = V(vi).f;
    xi = X(vi,:);
        if length(fi)==1 %we have a dangler
            vj = setdiff(F(fi).v,vi); %identify neighboring vertex
            Li = norm(X(vi,:)-X(vj,:)); %calculate length of fiber        
            fj = setdiff(V(vj).f,fi); %identify set of neighboring fibers
            xj = X(vj,:);
        
            di = (xi-xj)/norm(xi-xj);       
            dotp = zeros(size(fj));
        
            for k=1:length(fj)
                vk    = setdiff(F(fj(k)).v,[vj vi]); %set of vertices leaving vj, not including vi
                nf(k) = length(V(vk).f);
                xk    = X(vk,:);
                dk    = (xk - xj)/norm(xk-xj);
                dotp(k) = sum(di.*dk);
            end
        
            %if there is a fiber not already marked for removal that goes in
            %the same direction as you, then you get removed
            if vi==89;
                1;
            end
        
            if max(dotp.*(1-fremove(fj))) > p.thresh_dang_aclose 
                fremove(fi) = 1;
        
            %if you are really short and this cross-link alread has two 
            %legitamate fibers coming out of it that have cross-links of their
            %own
            elseif Li < p.thresh_dang_L && sum(nf>=2) >= 2      
                fremove(fi) = 1;
            
            %if you are really short and  not just an extension of an
            %incoming fiber, you get removed
            elseif -min(dotp) < p.thresh_dang_aextend && Li < p.thresh_dang_L
                fremove(fi) = 1;
            
            %if you are a fiber worth keeping, then check once more to see if
            %you should be extended
            else
            
                %NOT CODED UP YET!
        
            end
        end
    end
end

fprintf('******************fiber extension not coded up yet*******************\n');
F(fremove == 1) =  [];
[X F V R] = trimxfv(X,F,V,R);
1;