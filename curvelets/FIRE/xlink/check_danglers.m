function[X F V R] = check_danglers(X,F,V,R,p)
%check_danglers(X,F,V,R,p) - identify edges that connect only to one x-link.
% if they are running parallel to another edge (dangler or no) remove it.
% if they run in the same direction as a cross-linked edge, keep it.  but
% make sure only to keep one.  otherwise, remove it.
% for all the fibers we decide to keep, check once more to see if we can't
% extend them a bit more.


fremove = zeros(size(F));
for vi=1:length(V)
    if length(V(vi).f)>1
        fi = V(vi).f;
        xi = X(vi,:);
        if length(fi)==1 %we have a dangler
            vj = setdiff(vi,vi); %identify neighboring vertex
            Li = norm(X(vi,:)-X(vj,:)); %calculate length of fiber        
            fj = setdiff(V(vj).f,fi); %identify set of neighboring fibers
            xj = X(vj,:);

            di = (xi-xj)/(eps+norm(xi-xj));       
            dotp = zeros(size(fj));
            nf = zeros(size(fj));

            if ~isempty(fj) > 0
                for k=1:length(fj)
                    vk    = setdiff(F(fj(k)).v([1 end]),[vj vi]); %set of vertices leaving vj, not including vi
                    nf(k) = length(V(vk).f);
                    xk    = X(vk,:);
                    dk    = (xk - xj)/(eps+norm(xk-xj));
                    dotp(k) = sum(di.*dk);
                end

                %if there is a fiber not already marked for removal that goes in
                %the same direction as you, then you get removed
                if max(dotp.*(1-fremove(fj))) > p.thresh_dang_aextend
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
end
fprintf('\n');
%fprintf('******************fiber extension not coded up yet*******************\n');
F(fremove == 1) =  [];
[X F V R] = trimxfv(X,F,V,R);
1;