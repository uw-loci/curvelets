function[ind] = ind_btw_nodes(p,q,sized)
%IND_BTW_NODES - takes two nodes at points p and q and finds a set of indices
%that run between them. 
%
    len= max(1,sqrt(sum( (p-q).^2 )));
    x = 0:(1/len):1;    
    P = round((1-x')*p + x'*q);
    ind= sub2ind(sized,P(:,3),P(:,2),P(:,1));
    1;
    

