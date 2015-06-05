function[pts] = findlocmax(d,r,dmin,plotflag)
%FINDLOCMAX - finds points that are local maxima, meaning that within a box
%of size r, they are the largest values in that region

r = round(r);

[K J I] = size(d);
%YL: fix the rand number generator type and seed
% so that 'rand' function produces a predictable/reproducible sequence of
% numbers either in parfor and for loop
% let parallel loop use the same random number generator type  as the
% general one 'twister', the default one for parfor (or workers) is 'CombRecursive''
s = RandStream('twister','Seed',100);   % 'twister' i.e. 'mt19937ar'
RandStream.setGlobalStream(s); 
RandStream.getGlobalStream; 
rngstate = rng;
disp(sprintf('rng status in findlocmax function: type-%s Seed-%d , state-last element is %d',rngstate.Type,rngstate.Seed,rngstate.State(end,1)));

% RandStream.getGlobalStream, disp('check random number generator status'),pause(2)
% *****************************************
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