function[f] = sphere_filter(d)
%SPHERE_FILTER - returns a spherical filter of 1s with diameter d

dr = ceil(d);
r  = d/2;
rr = ceil(r); %rounded radius of filter
f  = zeros(dr,dr,dr);

if dr==1
    f(1,1,1) = 1;
elseif dr==2
    f = ones(2,2,2);
elseif mod(dr,2)==1 %d is odd       
    %make appropriate quadrants for center planes
        [x y]   = ndgrid(1:rr-1);
        R       = sqrt(x.^2 + y.^2);
        Q       = R<r;
        
    %fill in the appropriate pixels in positive octant         
        [x y z] = ndgrid(1:rr-1);
        R       = sqrt(x.^2+y.^2+z.^2);
        Osmall  = R<r; %the octant (doesn't include center line)
        
    %make a full octant that includes the center line
        O                = zeros(rr,rr,rr);
        O(1   ,1   ,:   )= 1;
        O(1   ,:   ,1   )= 1;
        O(:   ,1   ,1   )= 1;
        O(1   ,2:rr,2:rr)= Q;
        O(2:rr,1   ,2:rr)= Q;
        O(2:rr,2:rr,1   )= Q;
        O(2:rr,2:rr,2:rr)= Osmall;
        
    %complete filter using oct
        for i=1:2
        for j=1:2
        for k=1:2
            %rotate octant accordingly
                OR = O;
                if i==2
                    OR = flipdim(OR,1);
                end
                if j==2
                    OR = flipdim(OR,2);
                end
                if k==2
                    OR = flipdim(OR,3);
                end
                
            %choose proper indices of pixels to fill in
                if i==1
                    ix=rr:dr;
                else
                    ix=1:rr;
                end
                if j==1
                    jy=rr:dr;
                else
                    jy=1:rr;
                end
                if k==1
                    kz=rr:dr;
                else
                    kz=1:rr;
                end
                
            %fill in filter
                f(ix,jy,kz) = OR;
                1;
        end
        end
        end
                
elseif mod(dr,2)==0 %d is even
    [x y z] = ndgrid(.5:rr-.5);
    R       = sqrt(x.^2+y.^2+z.^2);
    O       = R<r; %the octant (doesn't include center line)

    %complete filter using oct
        for i=1:2
        for j=1:2
        for k=1:2
            %rotate octant accordingly
                OR = O;
                if i==2
                    OR = flipdim(OR,1);
                end
                if j==2
                    OR = flipdim(OR,2);
                end
                if k==2
                    OR = flipdim(OR,3);
                end

            %choose proper indices of pixels to fill in
                if i==1
                    ix=rr+1:dr;
                else
                    ix=1:rr;
                end
                if j==1
                    jy=rr+1:dr;
                else
                    jy=1:rr;
                end
                if k==1
                    kz=rr+1:dr;
                else
                    kz=1:rr;
                end

            %fill in filter
                f(ix,jy,kz) = OR;
                1;
        end
        end
        end

end
1;
