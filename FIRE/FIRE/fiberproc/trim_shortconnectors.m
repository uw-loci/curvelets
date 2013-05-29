function[X F V] = trim_shortconnectors(X,F,V)
%remove the short fibers that connect pairs of fibers that are already self
%connected

fremove = zeros(length(F),1);
for fi=1:length(F)
    if length(F(fi).v)<=5 %fiber is short
        ficonn = F(fi).f;
        if length(ficonn)==2 %short fiber connects two other fibers
            f1 = ficonn(1);
            f2 = ficonn(2);
            if ismember(f1,F(f2).f) %if these 2 fibers are already connected
                fremove(fi) = 1;
            end
        end
    end
end
F(fremove==1) = [];

[X F V] = trimxfv(X,F,V);