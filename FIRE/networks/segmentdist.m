function[d pt0 pt1 uniqflag] = segmentdist(pts0,pts1,testflag)
%segmentdist(pts1,pts2) - calculates the shortest distance between two line
%segements and the points on each line segment that characterize this
%
%www.geometrictools.com/Documentation/DistanceLine3Line3.pdf
%this code is written for clarity over minimal number of operations
if nargin < 3
    testflag = 0;
end


tol = 1e-6; %tolerance for 2 lines being parallel
uniqflag = 1;

%compute line parameterization properties
    B0 = pts0(1,:);
    M0 = pts0(2,:) - pts0(1,:);

    B1 = pts1(1,:);
    M1 = pts1(2,:) - pts1(1,:);

%compute Q constants - Q = a*s^2 + 2b*st + c*t^2 + 2*d*s + 2*e*t + f
    D = B0-B1;
    a = M0*M0';
    b = -(M0*M1');
    c = M1*M1';
    d = M0*D';
    e = -(M1*D');
    
    if testflag
        f = D*D';
        [S,T] = meshgrid(-.1:.05:1.1);
        Q = a*S.^2 + 2*b*S.*T + c*T.^2 + 2*d*S + 2*e*T + f;
        contour(S,T,Q,100); view(0,90)
        h = line([0 0 1 1 0],[0 1 1 0 0],[1 1 1 1 1]*max(Q(:)));
        set(h,'LineWidth',3,'Color','k')
    end

    det = a*c-b^2;
    s = (b*e - c*d)/det; %note, really, s = (be-cd)/det when s is in [0,1]
    t = (b*d - a*e)/det; %so here, the relevant box is [0,det]
    

%check to see if line segements are parallel
%if they are parallel, we just pick an arbitrary set of points
    if abs(det) < tol
        sig0 = -d/a;
        sig1 = -(b+d)/a;
        
        if (sig0 < 0 && sig1 < 0) || (sig0 > 1 && sig1 > 1) 
        %intervals are disjoint, connect two endpoints
            dall = zeros(4,1);
            ii= [1 1; 1 2; 2 1; 2 2];
            dall(1) = norm(pts0(1,:) - pts1(1,:));
            dall(2) = norm(pts0(1,:) - pts1(2,:));
            dall(3) = norm(pts0(2,:) - pts1(1,:));
            dall(4) = norm(pts0(2,:) - pts1(2,:));
            
            [d imin] = min(dall);
            pt0 = pts0(ii(imin,1),:);
            pt1 = pts1(ii(imin,2),:);
            
        %otherwise, there are a series of points that satifsy requirements
        %we'll arbitarily pick 2
        elseif sig0 > 0 && sig0 < 1 %if sig0 is btw 0 and 1, B1
            pt0 = B0 + sig0*M0;
            pt1 = B1;
            uniqflag = 0;
        else
            pt0 = B0 + sig1*M0;
            pt1 = B1 + M1;
        end
        
    else %lines aren't parallel

        %check to see which region of box the point falls in
        %for clarity, i'm changing regions from (1...9) to ([-1,-1]...[1,1])
        %r = region
            if s<0
                rs = -1;
            elseif s <= 1
                rs = 0;
            else
                rs = 1;
            end
            if t<0
                rt = -1;
            elseif t <= 1
                rt = 0;
            else
                rt = 1;
            end
            

            if rs==0 && rt==0
                %we're done
            elseif rs == 1 && rt == 0
                %F(t) = Q(s=1,t) = (a+2*d+f) + 2*(b+e)*t + c*t^2
                %F'(t) = 2*( b+e+c*t) ), find when this equals zero
                %T = -(b+e)/c
                s = 1;
                T = -(b+e)/c;
                t = max(min(T,1),0);
            elseif rs == -1 && rt == 0
                %F(t) = Q(s=0,t) = f + 2*e*t + c*t^2
                %F'(t) = 2*(e+c*t) ), find when this equals zero
                %T = -e/c 
                s = 0;
                T = -e/c;
                t = max(min(T,1),0);
            elseif rs == 0 && rt == 1
                %F(s) = Q(s,t=1) = (c+2*e+f) + 2*(b+d)*s + a*s^2
                %F'(s) = 2*( b+d+a*s) ), find when this equals zero
                %S = -(b+d)/a or Sa = -(b+d)
                t = 1;
                S = -(b+d)/a;
                s = max(min(S,1),0);
            elseif rs == 0 && rt == -1
                %F(s) = Q(s,t=0) = f + 2d*s + a*s^2
                %F'(s) = 2*(d+a*s) ), find when this equals zero
                %S = -d/a or Sa = -d
                t = 0;
                S = -d/a;
                s = max(min(S,1),0);          
                
            elseif rs == 1 && rt == 1 %Q_s = 2*a*s + 2*b*t + 2*d = (a+b+d) * 2
                Q_s = a+b+d; %(at 1,1)                
                if Q_s > 0
                    %Q_s(1,1) > 0 and intersection occurs on t=1 face
                    %F(s) = Q(s,1) = (c+2*e+f) + 2*(b+d)*s + a*s^2
                    %F'(s) = 2*(b+d) + 2*a*s  
                    %S = -(b+d)/a
                    t = 1;
                    S = -(b+d)/a;
                    s = max(min(S,1),0);
                else %Q_s <= 0
                    s = 1; %inersection occurs on s=1 face
                    %F(t) = (const) + 2bt + ct^2 + 2et
                    %F'(t)= 2*(ct + (b+e))
                    T = -(b+e)/c;
                    t = max(min(T,1),0);
                end
            elseif rs == -1 && rt == 1
                %Q_s(0,1)/2 = b+e, Q_t(0,1)/2 = c+e
                Q_s = b+d;                
                if Q_s > 0 %intersection on s = 0 face
                    %F(t) = Q(0,t) = ct^2 + 2*et + f
                    %F'(t)= 2*ct + 2*e
                    s = 0;
                    T = -e/c;
                    t = max(min(T,1),0);
                else %Q_s <= 0
                    %F(s) = Q(s,1) = const + as^2 + 2(b+d)s
                    %F'(s) = 2as + 2(b+d)
                    t = 1;
                    S = -(b+d)/a;
                    s = max(min(S,1),0);
                end
            elseif rs == 1 && rt == -1 %Q_s = 2*a*s + 2*d (t=0)
                Q_s = a+d;
                if Q_s > 0
                    t = 0;
                    %F(s) = Q(s,0) = as^2 + 2ds + f
                    %F'(s) = 2as + 2d
                    S = -d/a;
                    s = max(min(S,1),0);
                else %Q_s < 0
                    s = 1;
                    %F(t) = (const) + 2bt + ct^2 + 2et
                    %F'(t)= 2*(ct + (b+e))
                    T = -(b+e)/c;
                    t = max(min(T,1),0);
                end
            elseif rs == -1 && rt == -1
                Q_s = d;
                if Q_s > 0
                    %F(t) = Q(0,t) = ct^2 + 2*et + f
                    %F'(t)= 2*ct + 2*e
                    s = 0;
                    T = -e/c;
                    t = max(min(T,1),0);
                else %Q_s < 0
                    t = 0;
                    %F(s) = Q(s,0) = as^2 + 2ds + f
                    %F'(s) = 2as + 2d
                    S = -d/a;
                    s = max(min(S,1),0);
                end
            else
                error('something weird is going on')
            end                        
    
        pt0 = B0 + M0*s;
        pt1 = B1 + M1*t;
        d   = norm(pt0-pt1);
    end