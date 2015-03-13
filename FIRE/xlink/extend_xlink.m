function[X F V R] = extend_xlink(d_unpadded,xlink,p,plotflag)
%EXTEND_XLINK - takes a set of cross-link points and extends them out to
%populate a fiber network

if nargin<4
    plotflag = 0;
end
lam = p.lam_dirdecay;

%pad d with a few zeros because the LMP tracker has issues with
%boundaries
    zpad = 3;
    d    = zeros(size(d_unpadded)+zpad*2);
    d(zpad+1:end-zpad,zpad+1:end-zpad,zpad+1:end-zpad) = single(d_unpadded);
    xlink= xlink+zpad;
    
XM = make_vertexmatrix(xlink,size(d)); %make a matrix of size d that is nonzero where a crosslink is present
s  = size(d);
m  = 0; %fiber index
X  = xlink;
n  = size(X,1); %vertex index
fprintf('  %d nucleation pts - ',n);

%make radius vector
    ind = sub2ind(size(d),X(:,3),X(:,2),X(:,1));
    R   = d(ind);

if plotflag==1
    cla;
    plot3dist(d,1);
    plot3(xlink(:,1),xlink(:,2),xlink(:,3),'kx','LineWidth',3,'MarkerSize',8)
end

for i=1:size(xlink,1)    
    if mod(i,25)==0 && i~=size(xlink,1)
        fprintf('%d ',i);
        if mod(i,400)==0
            fprintf('\n                    ');
        end
    end

    x  = xlink(i,:);
    r  = max(2,ceil(d(x(3),x(2),x(1))));%min(p.s_maxstep,ceil(2*d(x(3),x(2),x(1))));
    LMP= findLMP(d,x,r,p.thresh_LMP,p.thresh_LMPdist); %find branches from crosslink        
        
    %make sure LMPs are seperated by a certain number of pixels
    
    
    %loop through each LMP, extending fiber until
    %  1) you reach another cross link
    %  2) you reach the end of the fiber
    %  3) you reach the edge of the box
        for j=1:size(LMP,1)
            xold = x;
            %add a new fiber and vertex
                m = m + 1;
                F(m).v(1) = i;
                xj = LMP(j,:);
            
            stopflag = 0;
            dir= xj-x; %directon of fiber
            dir= dir/(norm(dir)+eps);
            1;
            while stopflag==0
                %update X and F
                    n  = n+1;
                    X(n,:) = xj;
                    R(n,:) = d(xj(3),xj(2),xj(1));
                    F(m).v(end+1) = n;
                    if plotflag==1        
                        hold on
                        xnew = xj;
                        P = [xold; xnew];
                        plot3(P(:,1),P(:,2),P(:,3),'bo','LineStyle','-','LineWidth',2,'MarkerFaceColor','b')
                        plot3(x(1),x(2),x(3),'go','LineWidth',4,'MarkerFaceColor','g')
                        xold = xnew;
                        pause(.001);
                    end
                
                %check to see if xj is near another crosslink
                    r = ceil(d(xj(3),xj(2),xj(1)));                       
                    B = getbox(xj,r,s);
                    xm= XM(B);
                    xend = find(xm~=0 & xm~=i);
                    if ~isempty(xend)
                        F(m).v(end+1) = xm(xend(1));
                        %xx = X(xm(xend(1)));
                        break;
                    end                    
                    
                %calculate LMPs from xj stop if there aren't any
                    LMPj = findLMP(d,xj,r,p.thresh_LMP);                    
                    if isempty(LMPj)
                        break;
                    end
                    
                %find LMPs that go in the right direction
                    nLMP = size(LMPj,1);
                    dirj = LMPj - ones(nLMP,1)*xj;
                    dirj = dirj./(sqrt(sum(dirj.^2,2))*[1 1 1]+eps);
                    aj   = dotcalc(dir,dirj);
                    
                    if max(aj) < p.thresh_ext
                        break;
                    end
                    LMPj = LMPj(aj >= p.thresh_ext,:);
                    dirj = dirj(aj >= p.thresh_ext,:);
                       
                %choose LMP that maximizes distance function
                    ind   = sub2ind(size(d),LMPj(:,3),LMPj(:,2),LMPj(:,1));                    
                    dnear = d(ind);
                    [dmax ind] = max(dnear);

                %we passed all the tests, so extend the fiber, update
                %the fiber direction and update xj
                    dirj = dirj(ind,:);
                    dir = 1/(1+lam)*dir + lam/(1+lam)*dirj;
                    dir = dir/norm(dir);
                    xj  = LMPj(ind,:); 
                    1;
            end
            1;
            
            %{
            %remove the really short fibers that do not connect crosslinks
                if plotflag==1
                    xend = X(F(m).v(end),:);
                    plot3(xend(1),xend(2),xend(3),'rs','LineWidth',2,'MarkerFaceColor','r')
                    1;
                end
                flen = norm(X(F(m).v(1),:) - X(F(m).v(end),:));
                if ( flen<=p.thresh_flen || length(F(m).v)<2 ) && F(m).v(end) > length(xlink)
                    F(m) = [];
                    m = m-1;
                end
            %}
        end
end

%create a reduced matrix Fiber list, such that between any pair of
%vertices, there is at most 1 fiber.
    n = length(X);
    A  = spalloc(n,n,10*n);
    fremove = zeros(length(F),1);
    for fi=1:length(F)
        v1 = F(fi).v(1);
        v2 = F(fi).v(end);
        if A(v1,v2)==1
            fremove(fi) = 1;
        end
        A(v1,v2) = 1;
        A(v2,v1) = 1;
    end
    Fred = F;
    Fred(fremove==1) = [];


%create a further reduced matrix that just contains the fiber ends
%{
    Fred2 = Fred;
    for fi=1:length(Fred)
        Fred2(fi).v = Fred(fi).v([1 end]);
    end
%}
Fred2 = Fred;

%trim X and R to match reduced fiber
    [X F V R] = trimxfv(X,Fred2,[],R);
    
X = X - zpad; %subtract off the padding from the beginning

fprintf('\n');
if plotflag == 1
    clf
    plot3dist(d,3)
    plotfiber(X,Fred,4,0,[],'o')
    plot3(xlink(:,1),xlink(:,2),xlink(:,3),'ro','MarkerFaceColor','r','MarkerSize',10)
end
            