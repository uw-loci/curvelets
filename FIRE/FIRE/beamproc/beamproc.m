function[Xr Fr Vr] = beamproc(X,F,V,R,p,plotflag)
%BEAMPROC - takes (X,F,V) from FIBERPROC and postprocesses it for FEA

if nargin<6
    plotflag = 0;
end

% headers
    %addpath ../; updatepath;
    minspace = 2; %minimum spacing between nodes (in microns)
    blist    = p.blist; %blist = {1,2,3} indicating (x,y,z) as boundary)
    sc       = p.scale;%[.3 .3 .3]; %microns/pixel in the [x y z] directions
    db       = p.s_boundthick*sc(blist);

%scale X appropriatelyi'm 
    for i=1:3
        X(:,i) = X(:,i)*sc(i);
    end        

%convert fibers to beams by an interpolation
    %fprintf('  beamproc\n');
    %fprintf('    remove repeats\n'); [X F V R] = remove_repeat(X,F,V,R); %find and remove any instances of repeating X or repeating vertices

%remove nonstiff parts of network
    [V B1 B2]  = find_boundary(X,F,V,db,blist); %identify boundary
    [E  Ve]    = fiber2edge(F,V); %get edge matrix and vertex list from fiber structure
    %fprintf('    removing floppy edges\n'); 
    [Xr Fr Vr Rr] = remove_floppy_edges(X,F,E,Ve,R,B1,B2,p.blist,plotflag);
    [V B1 B2]  = find_boundary(Xr,Fr,Vr,db,blist); %identify boundary        
    Xr1 = Xr; Fr1 = Fr; Vr1 = Vr;
    [Xr Fr Vr Rr] = remove_repeatX(Xr,Fr,Vr,Rr); %find and remove any instances of repeating X or repeating vertices

%assign radius to fibers
    Rr = Rr*p.scale(1);
    for fi=1:length(Fr)
        v = Fr(fi).v;
        Fr(fi).r = mean(Rr(v));
    end
    
%interpolate fiber
    fprintf('    interpolating fibers\n'); [Xr Fr Vr] = fiber2beam(Xr,Fr,Vr,Rr,p.s_maxspace,p.lambda,0);    
    
%add angles to output array
    [Fr A Amap]   = add_angle(Xr,Fr,Vr);    
    
    if nargin>5
        if plotflag==1
            plotfiber(X,F)
            hold on
            plotfiber(Xr,Fr,3,1)
            plot3(Xr(B1,1),Xr(B1,2),Xr(B1,3),'ks','LineWidth',4)
            plot3(Xr(B2,1),Xr(B2,2),Xr(B2,3),'kd','LineWidth',4)
            hold off
        end
    end
   