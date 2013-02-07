function[Fang] = calc_fiberang2(X,F,k)
%CALC_FIBERANG - calculates the angles of the fibers at each points and returns them in
%the form of a field in F and a Length array
% k: number of lag, the number of continous vertices for tangent angle calculation

for fi=1:length(F)
    fv = F(fi).v;
    Lf = length(fv);
%  ym: 03/12/12
    if Lf <= k; 
        
        v1 = fv(1);
        v2 = fv(end);
        x1 = X(v1,:);
        x2 = X(v2,:); 
        angxz = atan( (x2(:,3)-x1(:,3))./(x2(:,1)-x1(:,1)+eps) );
        angxy = atan( (x2(:,2)-x1(:,2))./(x2(:,1)-x1(:,1)+eps) );
        
        Fang(fi).angle_xz   = repmat(angxz,1,k);
        Fang(fi).angle_xy   = repmat(angxy,1,k);
        
    else 
        
        for j=1:Lf-k
            
        %calculate angle orientation of fibers at each fv point
            v1 = fv(j);
            v2 = fv(j+k);
            x1 = X(v1,:);
            x2 = X(v2,:); 

            Fang(fi).angle_xz(j)   = atan( (x2(:,3)-x1(:,3))./(x2(:,1)-x1(:,1)+eps) );
            Fang(fi).angle_xy(j)   = atan( (x2(:,2)-x1(:,2))./(x2(:,1)-x1(:,1)+eps) );
        end
      % the last k points have the same angle  
         Fang(fi).angle_xz(j+1:Lf)   = repmat(Fang(fi).angle_xz(j),1,k);
         Fang(fi).angle_xy(j+1:Lf)   = repmat(Fang(fi).angle_xy(j),1,k);
    end
        
end

   

   