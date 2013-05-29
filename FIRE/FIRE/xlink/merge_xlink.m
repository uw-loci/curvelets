function[X F V R] = merge_xlink(X,F,V,R,r,plotflag)
%MERGE_XLINK - merge cross links that share a common fiber and are close
%together
ms = 8; %marker size for plots

[xlink,xlink_indic] = network_xlink(X,F,V); %find crosslinks as places where 2 fibers come together
xlink_ind           = find(xlink_indic);
VM                  = make_vertexmatrix(X,max(ceil(fliplr(X))),xlink_ind);

vmerge_indic        = zeros(length(V),1);

for vi = xlink_ind'
    vm = findclose(X,vi,r,VM);
    vclose = vm(vm~=0);
    xi = X(vi,:);
    for vj = vclose'
        xj = X(vj,:);
        fshare = intersect(V(vi).f,V(vj).f); %fibers the 2 crosslinks have in common        
        if ~isempty(fshare) & vmerge_indic(vj)==0
            
            if plotflag==1
                cla; plotfiber(X,F,3,0,[])
                plot3(xi(1),xi(2),xi(3),'yo','LineStyle','-','Color','k','MarkerFaceColor','y','MarkerSize',ms);
                plot3(xj(1),xj(2),xj(3),'ys','LineStyle','-','Color','k','MarkerFaceColor','y','MarkerSize',ms);
                pause(.001)
                2;
            end                
            
            [F V] = mergevertex(F,V,vi,vj,X);
            X(vi,:) = round((xi+xj)/2);
            X(vj,:) = round((xi+xj)/2);
            vmerge_indic(vj) = 1;
            
            if plotflag==1
                plotfiber(X,F,3,0,[])
                xnew = X(vi,:);
                plot3(xnew(1),xnew(2),xnew(3),'ko','MarkerSize',ms,'MarkerFaceColor','g');
                [vi vj]
                1;
            end                         
        end
    end
end
[X F V R] = trimxfv(X,F,V,R);