function[Box E Ecent] = boxify(X,F,Linc,W)
%boxify(X,F,Linc,W) - put elements into boxes so that dist. can be
%calculated more efficiently


%make edge matrix
ei = 0;

E = zeros(2*size(X,1),3);
for fi=1:length(F)
    v = F(fi).v;
    for iv = 1:length(v)-1
        ei = ei+1;
        E(ei,:) = [v(iv) v(iv+1) fi];
    end
end
E(ei+1:end,:) = [];
Ecent = zeros(size(E));
%initialize Box
    n = ceil(W/Linc);
    nsub = 100;
    Box(n,n,n).e = [];
    Box(n,n,n).n = 0;
    
    for i=1:numel(Box)
        Box(i).n = 0;
    end
    
%fill in box
    Xr = ceil(X/Linc);
    for ei = 1:size(E,1)
        v1 = E(ei,1);
        v2 = E(ei,2);
        fi = E(ei,3);

        xi = Xr([v1 v2],:);
        Ecent(ei,:) = ceil(mean(X([v1 v2],:))/Linc);
        for hh = 1:2
            x = xi(hh,:);
            
            I1 = max(x-1,1);
            I2 = min(x+1,n);
            
            for ii = I1(1):I2(1)
                for ij = I1(2):I2(2)
                    for ik = I1(3):I2(3)
                        Box(ik,ij,ii).n = Box(ik,ij,ii).n + 1; 
                        if Box(ik,ij,ii).n > length(Box(ik,ij,ii).e)
                            Box(ik,ij,ii).e(end+nsub) = 0;
                        end
                        Box(ik,ij,ii).e( Box(ik,ij,ii).n ) = ei;
                    end
                end
            end
        end
    end
