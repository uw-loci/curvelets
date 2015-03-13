function[pts] = findlocmax(d,r,dmin,plotflag)
%FINDLOCMAX - finds points that are local maxima, meaning that within a box
%of size r, they are the largest values in that region

r = round(r);

[K J I] = size(d);
d = d+1e-3*rand(size(d));

ind = find(d>dmin);% & X>r & X<I-r+1 & Y>r & Y<J-r+1 & Z>r & Z<K-r+1);
[z y x] = ind2sub([K J I],ind);

for i=-r:r
    fprintf('%d ',i);        
    for j=-r:r
        for k=-r:r    
            offset = i*K*J + j*K + k;
            if ~(i==0 && j==0 && k==0)
                %look at only the indices with a neighbor in the (i,j,k)
                %direction
                    icheck = find(    x+i>=1 & x+i<=I & ...
                                      y+j>=1 & y+j<=J & ...
                                      z+k>=1 & z+k<=K);

                %find the indices that aren't global maxes
                    iremove = icheck( d(ind(icheck)) <= d(ind(icheck)+offset) );

                %remove them from list
                    ind(iremove) = [];
                    z  (iremove) = [];
                    y  (iremove) = [];
                    x  (iremove) = [];
            end
        end
    end
end
[kk jj ii] = ind2sub(size(d),ind);
pts = [ii jj kk];
fprintf('\n');

if nargin<4
    plotflag = 0;
end
if plotflag==1
    cla
    plot3bw(d>.05)
    plot3(pts(:,1),pts(:,2),pts(:,3),'ro','LineWidth',5)
    view(0,90);
end