function[F] = fiberdir(X,F,sp)
%FIBERDIR - calculates the direction of the fiber and returns the direction
%of the 2 ends as a couple of structures
    shortfibers = [];
    for fi=1:length(F)
        fv  = F(fi).v;  
        len = length(fv);            

        if len>1
            v1  = fv(1);
            x1  = X(v1,:);
            ii  = min(sp,len);
            v2  = fv(ii);
            x2  = X(v2,:);
            F(fi).dir(1,:) = (x1-x2)/norm(x2-x1+eps); %orientation of fiber end 1

            v4  = fv(end);
            x4  = X(v4,:);
            ii  = max(1,len-sp);
            v3  = fv(ii);
            x3  = X(v3,:);
            F(fi).dir(2,:) = (x4-x3)/norm(x3-x4+eps); %orientation of fiber end 2
        else
            F(fi).dir = [0 0 0; 0 0 0];
        end
    end