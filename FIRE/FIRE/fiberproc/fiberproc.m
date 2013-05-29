function[X F E V R] = fiberproc(X,F,R,size_im,p,plotflag)
%FIBERPROC - takes a tree and turns it into a matrix of fibers

if nargin<6
    plotflag=0;
end

%INITIAL PREPROCESSING
    [X F V R] = trimxfv(X,F,[],R);
    X1 = X; F1 = F; V1 = V;    
    [X F V R] = remove_repeat(X,F,V,R);

%LINK FIBERS OF LIKE ORIENTATION THAT INTERSECT AT AN END PONIT
    NN = 5;
    fprintf('  linking fibers (%d) - ',NN)
    for i=1:NN
        fprintf('%d, ',i);
        [X F V R] = fiberlink(X,F,V,R,p.thresh_linka,p.s_fiberdir,plotflag);  %link fibers together if they have similar orientation
        [X F V R] = remove_repeat(X,F,V,R);
    end

%LINK FIBERS OF LIKE ORIENTATION ACROSS GAP
    fprintf('\n');
    X2 = X; F2 = F; V2 = V;
    fprintf('  linking fibers across gaps\n'); [X F V] = fiberlinkgap(X,F,V,size_im,p.s_fiberdir,p.thresh_linkd,p.thresh_linka,plotflag); %links same oriented fibers across gaps (even if image is dark there)

%REMOVE SHORT FIBERS AND THEN LINK FIBERS OF LIKE ORIENTATION AGAIN    
    fprintf('\n');
    X3 = X; F3 = F; V3 = V;  
    fprintf('  removing short fibers\n')
    [X F V R] = fiberremove(X,F,V,R,p.thresh_flen,p.thresh_numv,plotflag);
    
%construct an edge matrix
    E = zeros(length(F),2);
    for i=1:length(F)
        E(i,1:2) = [F(i).v(1) F(i).v(end)];
    end   
    
%{    
%report fiber lengths
    for fi=1:length(F)
        fv = F(fi).v;
        len = 0;
        for j = 1:length(fv)-1;
            v1 = fv(j);
            v2 = fv(j+1);
            len = len + norm(X(v1,:)-X(v2,:));
        end
        F(fi).len = len;
    end
%}
    
%plot final configuration
    if plotflag==1
        pause(.5)
        clf
        plotfiber(X,F)
        title('final configuration')
    end
end
          
%*******************************************************************************************************
%*******************************************************************************************************
%*******************************************************************************************************
%*******************************************************************************************************
%
%                              FUNCTIONS
%
%*******************************************************************************************************
%*******************************************************************************************************
%*******************************************************************************************************


function[vect] = getvect(X,vi,fiber,sp)
    %GETVECT - gets the fiber orientation vector that starts at the end
    %vertex i and points along the fiber
    len = length(fiber);
    if fiber(1)==vi %if the fiber starts at vertex i
        ii = min(sp,len);
        vj = fiber(ii);
        vect = X(vj,:) - X(vi,:);
    elseif fiber(end)==vi
        ii = max(1,len-sp);
        vj = fiber(ii);
        vect = X(vj,:) - X(vi,:);
    else
        error('some kind of mistake')
    end
    vect = vect/(norm(vect)+eps);
end



function[F V] = mergefiber(F,V,f1,f2)
    %MERGE - merges 2 fibers together so that they meet at the vertex
    %the two have in common
    %vm = the vertex in between the two fibers
    %ve = the new end vertex for fiber1
    fiber1 = F(f1).v;
    fiber2 = F(f2).v;

    if fiber1(1) == fiber2(1)
        fmerge = [fliplr(fiber2(2:end)) fiber1];
        vm     = fiber1(1);
        ve     = fiber2(end);
    elseif fiber1(1) == fiber2(end)
        fmerge = [fiber2(1:end-1) fiber1];
        vm     = fiber1(1);
        ve     = fiber2(1);
    elseif fiber1(end)==fiber2(1)
        fmerge = [fiber1(1:end) fiber2(2:end)];
        vm     = fiber1(end);
        ve     = fiber2(end);
    elseif fiber1(end)== fiber2(end)
        fmerge = [fiber1(1:end) fliplr(fiber2(1:end-1))];
        vm     = fiber1(end);
        ve     = fiber2(1);
    else
        error('these fibers don''t share an end vertex')
    end

    %change the vertex list to that the vertex dangling off of fiber 2,
    %which has been removed, is now listed as dangling off fiber 1
        F(f1).v = fmerge;
        F(f2).v = [];

        V(vm).fe= sort(   setdiff(V(vm).fe,[f1 f2])  ); %remove 2 fibers from end list of middle vertex
        V(ve).fe= sort(  [setdiff(V(ve).fe,f2) f1]   ); %remove fiber 2 and add fiber 1 to end list of end vertex from fiber 2

        for vi=fiber2
            V(vi).f   = [setdiff(V(vi).f   ,f2)     f1];     %add f1 and remove f2 from all vi
            V(vi).vall= [setdiff(V(vi).vall,fiber2) fiber1];
            V(vi).f   = unique(V(vi).f);
            V(vi).vall= unique(V(vi).vall);
        end

end

function[F] = mergefiber_sep(F,f1,e1,f2,e2)
    %MERGE - merges 2 fibers when they don't share a vertex in common
    %fuse fiber 1, end 1 to fiber 2, end 2
    %here f1, f2 denote fiber indices and e1,e2 = 1 or 2 for beginning and
    %end of fiber
    %vm = the vertex in between the two fibers
    %ve = the new end vertex for fiber1
    fiber1 = F(f1).v;
    fiber2 = F(f2).v;

    if e1==1 && e2==1
        fmerge = [fliplr(fiber2) fiber1];
    elseif e1==1 && e2==2
        fmerge = [fiber2 fiber1];
    elseif e1==2 && e2==1
        fmerge = [fiber1 fiber2];
    elseif e1==2 && e2==2
        fmerge = [fiber1 fliplr(fiber2)];
    else
        error('entered wrong values for e1 and e2')
    end
    
    F(f1).v = fmerge;
    F(f2).v = [];
end

%*******************************************************************************************************
%*******************************************************************************************************
%*******************************************************************************************************
%*******************************************************************************************************
%
%                              FUNCTIONS
%
%*******************************************************************************************************
%*******************************************************************************************************
%*******************************************************************************************************

function[X F V] = fiber_gapfill(X,F,V,d,nhoodlink,thresh_fibconnect,thresh_angle,sp,plotflag)
%Fill in gaps between fibers that should be filled because d is large there
%Essentially, these are branches that the tree finding algorithm missed
    X = round(X);    
    VM = make_vertexmatrix(X,size(d));
    
    F = fiberdir(X,F,sp);
    for fi=1:length(F)
        if length(F(fi).v)>=2
            fe_ind = 0;
            indv = 0;
            for vi = F(fi).v([1 end])
                indv = indv+1;
                fe_ind = fe_ind+1;
                %only look at nodes that are ends, not joints
                %if length(V(vi).f)==1
                    %find vertices that are are close to fiber, not in same
                    %fiber and are connected by a staright nonzero d segment
                        xi = X(vi,:);
                        vclose = findclose(X,vi,nhoodlink,VM);                  
                        vdiff = setdiff(vclose,V(vi).vall); %vertices close and in different fibers
                        vcont = []; %vertices that are close, in diff fibers, and are connected through a bright area in the image
                        for vj = vdiff
                            xj  = X(vj,:);
                            ind = ind_btw_nodes(xi,xj,size(d));
                            if all(d(ind)>thresh_fibconnect)
                                vcont(end+1) = vj;
                            end
                        end
                    %find which of these vertices go in approximately the
                    %same direction as the fiber
                        vdir = [];
                        for vj = vcont
                            dirfib = F(fi).dir(indv,:);
                            xj   = X(vj,:);
                            dirj = (xj-xi)/(norm(xj-xi)+eps);
                            if dot(dirfib,dirj) > thresh_angle
                                vdir(end+1) = vj;
                            end
                        end
                            
                        
                    %use only the closest vertex
                        if length(vdir>=1)
                            dj = dcalc(xi,X(vdir,:));
                            [min_d iv] = min(dj);
                            vj = vdir(iv);
                        else
                            vj = [];
                        end
                    %add a new, temporary one-element fiber if applicable
                        if ~isempty(vj)
                            if length(V(vj).f)==1 % this new tiny fiber is involved in one other fiber                                
                                fj = V(vj).f;
                                ivj= find(F(fj).v==vj);
                                if ivj~=1 && ivj~=length(fj) %then the vertex the new fiber will 
                                                            %intersect falls in the middle of a fiber so, 
                                                            %we need to split it in 2
                                    fj1 = fj;
                                    fj2 = length(F)+1;
                                    fiberv = F(fj).v;
                                    F(fj1).v = fiberv(1    :ivj);
                                    F(fj2).v = fiberv(ivj  :end);
                                    if plotflag==1
                                        plotfiber(X,F([fj1 fj2]),2)
                                    end
                                end %the vertex the new fiber intersects with is just an end vertex
                            end                                                      
                            F(end+1).v = [vi vj];                                                       
                            xj = X(vj,:);
                            
                            if plotflag==1
                                title('adding linking fibers between gaps')
                                plot3(xi(1),xi(2),xi(3),'ko','MarkerSize',7,'MarkerFaceColor','y')
                                plot3(xj(1),xj(2),xj(3),'ko','MarkerSize',7,'MarkerFaceColor','y')
                                P = [xi; xj];
                                plot3(P(:,1),P(:,2),P(:,3),'k','LineWidth',2);
                                pause(.001)
                            end
                        end                    
                %end                           
            end
        end
    end
    [X F V] = trimxfv(X, F, V);
end

function[X F V R] = fiberlink(X,F,V,R,thresha,sp,plotflag)              
%link fibers together across gaps if they have similar orientation
%find the places where multiple fibers edges come together to form a
%vertex.  check to see if these fibers are close to being aligned and align
%them

    for i=1:length(F)
    if length(F(i).v) >=2
        vrange = F(i).v([1 end]);
        for vi = vrange
            fe= V(vi).fe;
            n = length(fe);
       
            if n==2
                fj = fe(1);
                fk = fe(2);               
                fiber1 = F(fj).v;
                fiber2 = F(fk).v;
                vect1  = getvect(X,vi,fiber1,sp);
                vect2  = getvect(X,vi,fiber2,sp);
                a      = dot(vect1,vect2);
                if a < thresha
                    if plotflag==1
                        title('linking fibers together')
                        plotfiber(X,F(fj),1,1,'y');
                        pause(.001)
                        plotfiber(X,F(fk),1,1,'y');
                        xlabel(num2str(i));                            
                        pause(.001)                           
                    end
                    [F V] = mergefiber(F,V,fj,fk);
                end
            elseif n > 2 %if the vi end of fiber i touches another fiber
                fe = V(vi).fe;
                for j=1:n-1                    
                    fj     = fe(j);
                    fiber1 = F(fj).v;
                    vect1   = getvect(X,vi,fiber1,sp);
                    for k=j+1:n
                        fk = fe(k);
                        fiber2 = F(fk).v;
                        vect2 = getvect(X,vi,fiber2,sp);
                        A(j,k)= dot(vect1,vect2);
                    end
                end
                
                %find angles that are near threshold for being the same fiber
                [a l m] = min2(A);
                while a < thresha      
                    
                    %then the 2 fibers are close in alignment so we combine them
                        f1 = fe(l);
                        f2 = fe(m);

                        if plotflag==1
                            title('linking fibers together')
                            plotfiber(X,F(f1),1,1,'y');
                            pause(.001)
                            plotfiber(X,F(f2),1,1,'y');
                            xlabel(num2str(i));                            
                            pause(.001)                           
                        end
                        [F V] = mergefiber(F,V,f1,f2);
                        1;

                    %we also ensure that these 2 fibers will not be
                    %combined with anything else at this point of
                    %intersection
                        A(l,:) = 0;
                        A(m,:) = 0;
                        A(:,l) = 0;
                        A(:,m) = 0;
                    %compute next angle
                        [a l m] = min2(A);
                end
            end
        end
    end
    end
    [X F V R] = trimxfv(X, F, V, R);
end

function[X F V R] = fiberremove_star(X,F,V,R,num_star,len_star)
%finds stars (vertices with at least num_star vertices) and removes any
%fibers that connects only to other fibers at that node
    fremove = [];
    for vi=1:length(V)
        fv = V(vi).f;
        if length(fv) > num_star
            for fj = fv
                keep_flag = 0;
                if F(fj).len < len_star
                    for vk = setdiff(F(fj).v,vi)
                        if length(V(vk).f)>1 %if the fiber connects to something else
                            keep_flag = 1;    %keep it
                        end
                    end
                    if keep_flag == 0
                        fremove(end+1) = fj;
                    end
                end
            end
        end
    end
    F(fremove) = [];
    [X F V R] = trimxfv(X,F,V,R);
end
            
function[X F V] = fiberremove_z(X,F,V,angle_thresh,len_thresh,plotflag)
%remove fibers primarily oriented in the z direction because that is where
%we frequently make mistakes
    for fi=length(F):-1:1
        vconn = [];
        v1 = F(fi).v(1);
        v2 = F(fi).v(end);
        x1 = X(v1,:);
        x2 = X(v2,:);
        
        len(fi) = norm(x2-x1);
        zorient = (x2(3)-x1(3))/(len(fi)+eps);
        plotflag =1 ;
        if zorient > angle_thresh && len(fi) < len_thresh
            F(fi) = [];
            if plotflag == 1;
                plotfiber(X,F(fi),4,4,'r','s')
                pause(.001);
            end
        end
    end
    [X F V] = trimxfv(X, F, V);
end

function[X F V] = fiberlinkgap(X,F,V,size_im,anglecomp_space,thresh_linkd,thresh_linka,plotflag)
%links fibers that are somewhat close together and have the same
%orientation
    %first get the fiber orientations and positions for both ends
        sp = anglecomp_space;
        len = length(F);
        Vend = zeros(len,2);
        for fi=1:length(F)            
            fv  = F(fi).v;  
            len = length(fv);            
            
            v1  = fv(1);            
            F(fi).pos(1,:) = X(v1,:);
            F(fi).dir(1,:) = getvect(X,v1,F(fi).v,sp);            
            
            v2  = fv(end);
            F(fi).pos(2,:) = X(v2,:);
            F(fi).dir(2,:) = getvect(X,v2,F(fi).v,sp);
            
            Vend(fi,:) = [v1 v2];
        end
     
        VM = make_vertexmatrix(X,size_im,Vend(:));        
        
    %now set aside fibers to link if it makes sense to do so
        ifuse = 0;
        fuse = [];
        fuseflag = zeros(length(F),2);
        for fi=1:length(F)            
            %calculate all of fi's direct connections
                fconnect = [];
                for vi=F(fi).v;
                    fconnect = [fconnect V(vi).f];
                end

            for j=1:2
                if j==1
                    vj = F(fi).v(1);
                else
                    vj = F(fi).v(end);
                end                               
                
                xj    = F(fi).pos(j,:);
                vectj = F(fi).dir(j,:);

                %distances between fiber ends
                    vclose = findclose(X,vj,thresh_linkd,VM);
                    if ~isempty(vclose)
                        %angles between fiber orientations
                            a = [1 1 1 1]*Inf;
                            ai = 1;
                            for vk=vclose'
                                for fek = setdiff(V(vk).fe,fconnect)
                                    if fek > fi %so that each fiber pair is checked only once
                                        ai=ai+1;
                                        if vk==F(fek).v(1)
                                            m = 1;
                                        elseif vk==F(fek).v(end)
                                            m = 2;
                                        else
                                            error('something''s wrong')
                                        end
                                        xk = X(vk,:);
                                        a(ai,1:3) = [fek m dotcalc(vectj,F(fek).dir(m,:))]; %angle between the two fibers
                                        a(ai,4) = dotcalc(vectj, (xk-xj)/norm(xk-xj+eps)); %angle between fi and the small, new piece
                                    end
                                end
                            end

                            angle = max(a(:,3:4),[],2);
                            [amin jj] = min(angle);
                            fk = a(jj,1);
                            l  = a(jj,2);

                            if amin < thresh_linka
                                if fuseflag(fi,j)==0 && fuseflag(fk,l)==0
                                    fuseflag(fi,j) = 1;
                                    fuseflag(fk,l) = 1;
                                    ifuse=ifuse+1;
                                    fuse(ifuse,1:4) = [fi j fk l]; %denote fiber fi at end j to fuse with fiber fcheck(k) at end l
                                    if plotflag==1
                                        plotfiber(X,F(fi),6,0,'r');
                                        plotfiber(X,F(fk),6,0,'y');
                                        1;
                                    end
                                end
                            end
                    end 

            end
        end
        fuse1 = fuse;
    %now fuse the fibers together
        for i=1:size(fuse,1)
            f1 = fuse(i,1); f2 = fuse(i,3);
            e1 = fuse(i,2); e2 = fuse(i,4);            

            
            if e1==1
                v1 = F(f1).v(1);
            else
                v1 = F(f1).v(end);
            end
            if e2==1
                v2 = F(f2).v(1);
            else
                v2 = F(f2).v(end);
            end
            
            if norm(X(v2,:)-X(v1,:))>25
                1;
            end
            
            F = mergefiber_sep(F,f1,e1,f2,e2); %f1 contains both fibers, f2 is empty
            
            %just in case we need to fuse with f2 again, we replace all the
            %f2s in fuse with f1
            ind = find(fuse(i+1:end,1)==f2);
            fuse(ind+i,1)=f1;
            fuse(ind+i,2)=e1;
            ind = find(fuse(i+1:end,3)==f2);
            fuse(ind+i,3)=f1;
            fuse(ind+i,4)=e1;
            
            if plotflag==1
                cla; plotfiber(X,F)
                1;
            end
            1;

        end

    %and finally, reconstruct the fiber matrix
        [X F V]   = trimxfv(X,F,V);
end

function[X F V] = fibersplit(X,F,V,p,plotflag)
%split a single fiber up that changes direction
    for fi=1:length(F)
        fv = F(fi).v;
        xf = X(fv,:);    
        cosa = [];
        cosb = [];   
        sp = p.anglecomp_space;
        %compute the theta (a) and phi (b) angle of the fiber (polar cord)
        if length(fv) > 2*sp+1
            for i=1:length(fv)-sp
                x1 = xf(i,:);
                x2 = xf(i+sp  ,:);
                v  = x2-x1;
                cosa(i) = v(1)/norm(v(1:2)+eps);
                cosb(i) = v(3)/norm(v+eps);
            end        

            erra1= sum( (cosa-mean(cosa)).^2 )/length(cosa);
            errb1= sum( (cosb-mean(cosb)).^2 )/length(cosb);

            erra2 = [];
            errb2 = [];
            for i=1:length(cosa)-1
                i1 = 1:i;
                i2 = i+1:length(cosa);
                erra2(i) = sum( [(cosa(i1)-mean(cosa(i1))).^2 (cosa(i2)-mean(cosa(i2))).^2 ])/length(cosa);
                errb2(i) = sum( [(cosb(i1)-mean(cosb(i1))).^2 (cosb(i2)-mean(cosb(i2))).^2 ])/length(cosb);        
            end

            %the minimum has to be somewher in the middle
                erra2([1:sp end-sp:end]) = Inf;
                errb2([1:sp end-sp:end]) = Inf;

            [minerra ia] = min(erra2);
            [minerrb ib] = min(errb2);

            ia = ia + round(sp/2);
            ib = ib + round(sp/2);

            %split fiber into parts if there is a big dip in the error by
            %splitting the fiber in two
                if erra1 > p.err_thresh && minerra/erra1 < p.err_ratio
                    F(end+1).v = fv(ia:end);
                    F(fi).v    = fv(1:ia);
                    if plotflag==1
                        plotfiber(X,F(fi),2,0,[1 0 0]);
                        plotfiber(X,F(end),2,0,[0 0 1]);                    
                        pause(.001)
                    end
                elseif errb1 > p.err_thresh && minerrb/errb1 < p.err_ratio
                    F(end+1).v = fv(ia:end);
                    F(fi).v    = fv(1:ia);
                    if plotflag==1
                        plotfiber(X,F(fi),2,0,[1 0 0]);
                        plotfiber(X,F(end),2,0,[0 0 1]); 
                        pause(.001)
                    end
                end                
        end          
    end
    %and finally, reconstruct the fiber matrix
        [X F V]   = trimxfv(X,F,V);
end