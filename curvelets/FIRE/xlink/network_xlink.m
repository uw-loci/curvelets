function[xlinks,ii] = network_xlink(X,F,V)
%NETWORK_XLINK - finds crosslinks
ii = zeros(length(V),1);
for i=1:length(V)
    if length(V(i).f)>1
        ii(i) = 1;
    end
end
xlinks = X(ii==1,:);