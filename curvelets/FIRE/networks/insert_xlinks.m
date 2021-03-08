function[X2 F2 V2] = insert_xlinks(X,F,E,V,B,Ecent,q,plotflag)

if nargin < 8
    plotflag = 0;
end

Xlinks = zeros(size(X,1),7); %[x y z e1 e2 f1 f2]
nxlink = 0;
ne = size(E,1);
if plotflag == 1
    clf
    plotfiber(X,F)
    view(0,90)
end

for ei=1:size(E,1)
    L1 = X(E(ei,1:2),:);    
    
    fi = E(ei,3);
    xc = Ecent(ei,:);
    
    I1 = max(xc-1,1);
    I2 = min(xc+1,max(Ecent(:)));
        
    
    e_indic = zeros(ne,1);
    for ii = I1(1):I2(1)
    for ij = I1(2):I2(2)
    for ik = I1(3):I2(3)
        n = B(ik,ij,ii).n;
        e = B(ik,ij,ii).e(1:n);

        e_indic(e) = 1;
    end
    end
    end
    e_indic(E(:,3)==fi) = 0;   
    e_indic(1:ei) = 0; %this way, we don't find each x-link twice
    eclose = find(e_indic==1);
    nclose = length(eclose);
    fclose = E(eclose,3);
    
    funiq  = unique(fclose); %fibers that are close to e1    
    fmap   = zeros(max(funiq),1);
    fmap(funiq) = 1:length(funiq);
    
    nfclose = length(fclose);
    d_list = Inf*ones(nfclose,1);
    xlink_list = zeros(nfclose,7);
    
    for eci = 1:nclose
        e2 = eclose(eci);
        f2 = fclose(eci);
        fmapi = fmap(f2);
        L2 = X(E(e2,1:2),:);
        [d p1 p2] = segmentdist(L1,L2);
        
        if d <= q.D && d < d_list(fmapi);
            d_list(fmapi) = d;
            xlink_list(fmapi,1:3) = (p1 + p2)/2;
            xlink_list(fmapi,4:5) = [ei e2];
            xlink_list(fmapi,6:7) = [fi f2];
            if plotflag==1
                h(1) = line(L1(:,1),L1(:,2),L1(:,3));
                h(2) = line(L2(:,1),L2(:,2),L2(:,3));                
                set(h,'LineWidth',4,'Color','k','LineStyle','--')
                plot3(xlink_list(fmapi,1),xlink_list(fmapi,2),xlink_list(fmapi,3),'ro','LineWidth',6)
                1;
            end
        end
    end
    
    ind = find(d_list < Inf);
    nadd = length(ind);
    if ~isempty(ind)
        Xlinks(nxlink+1:nxlink+nadd,:) = xlink_list(ind,:);
        nxlink = nxlink + nadd;
    end
end
Xlinks = Xlinks(1:nxlink,:);

if plotflag==2
    clf; plotfiber(X,F,2,0,[]);
end

for ix = 1:nxlink    
    xlinki = Xlinks(ix,1:3);
    ei = zeros(2,1);
    fi = zeros(2,1);
    vi = zeros(2,2);
    xi = zeros(2,2,3);
    di = zeros(2,2);

    %first check for merging: i.e. x-links are close to existing nodes
        for j=1:2
            ei(j) = Xlinks(ix,3+j);
            fi(j) = Xlinks(ix,5+j);
            
            for k=1:2
                vi(j,k)   = E(ei(j),k);
                xi(j,k,:) = X(vi(j,k),:); 

                di(j,k)   = norm(squeeze(xi(j,k,:)) - xlinki');
            end
        end
        merge_check = (di <= q.Dmerge);
        
        if plotflag==2
            L1 = squeeze(xi(1,:,:));
            L2 = squeeze(xi(2,:,:));

            h(1) = line(L1(:,1),L1(:,2),L1(:,3));
            h(2) = line(L2(:,1),L2(:,2),L2(:,3));                
            set(h,'LineWidth',4,'Color','k','LineStyle','--')
            plot3(xlinki(1),xlinki(2),xlinki(3),'ro','LineWidth',6)
            1;
        end        
        
        if sum(merge_check>=3)
            error('dmerge is too big')
        end

        if any(merge_check(1,:)) && any(merge_check(2,:))
        %x-link is really close to ends of both fibers so we merge those
        %two vertices together and that's that           
            [dmin i1] = min(di(1,:));
            [dmin i2] = min(di(2,:));
            v1 = vi(1,i1);
            v2 = vi(2,i2);
            
            X(v1,:) = xlinki;
            X(v2,:) = xlinki;
            
            %replace all instances of v2 with v1
            for j=1:2
                ind = find(F(fi(j)).v==v2);
                F(fi(j)).v(ind) = v1;

                ind = find(E(:,j)==v2);
                e(ind,j) = v1;
            end
            
        elseif any(merge_check(1,:)) == 1
        
        %x-link is only really close to 1 end
            [dmin ii] = min(di(1,:));
            vmerge = vi(1,ii);
            X(vmerge,:) = xlinki;            
            F(fi(2)).v = insert_vertex(X,F(fi(2)).v,vi(2,:),vmerge);
        
        elseif any(merge_check(2,:)) == 1
        %x-link is only really close to the other end
            [dmin ii] = min(di(2,:));
            vmerge = vi(2,ii);
            
            X(vmerge,:) = xlinki;                       
            F(fi(1)).v = insert_vertex(X,F(fi(1)).v,vi(1,:),vmerge);            
            
        else
        %x-link is close to neither end, so we create a new vertex\
            X(end+1,:) = xlinki;
            vnew = size(X,1);
            for j=1:2
                F(fi(j)).v = insert_vertex(X,F(fi(j)).v,vi(j,:),vnew);
            end
        end
end
[X2 F2 V2] = trimxfv(X,F,V);
1;
  
function[v_out] =  insert_vertex(X,vall,vinsert,vnew)

    v1 = vinsert(1);
    v2 = vinsert(2);

    iv1 = find(vall==v1);
    iv2 = find(vall==v2);

    vspace = abs(iv1-iv2);
    if abs(vspace)==1
        v_out = [vall(1:iv1) vnew vall(iv2:end)];
    else
       % keyboard %this code hasn't been throgouhly tested yet

        vect    = X(v2  ,:) - X(v1,:);
        vectnew = X(vnew,:) - X(v1,:);
        dotprodnew = sum(vect.*vectnew);

        iva = iv2-1;
        ivb = iv2;
        for iv = iv1+1:iv2-1
            xi = X(vall(iv),:);
            dotprod = sum(vect.*(xi-X(v1,:)));
            if dotprodnew < dotprod
                iva = iv-1;
                ivb = iv;
            end                    
        end
        v_out = [vall(1:iva) vnew vall(ivb:end)];
    end


