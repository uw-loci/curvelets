function[LMP] = findLMP(d,u,r,LMPthresh,LMPdist)
%FINDLMP - find local maximum points of d on boundary

if nargin<5
    LMPdist = 0;
end

s  = size(d);

dB = getdB(u,r,s);
%LMPind = [];

dB1 = [dB.side; dB.edge];
dB2 = dB.corner;

dB = dB1;
dV = d(dB(:,1));
dW = d(dB(:,2:end));
ind= dV>=max(dW,[],2) & dV >= LMPthresh;
LMPind = dB(ind);

%{
for i=1:size(dB,1)
    dv = d(dB(i,1));
    dw = d(dB(i,2:end));
    if all(dv>=dw) && dv >= LMPthresh
        LMPind(end+1,1) = dB(i);
    end
end
%}

dB = dB2;
dV = d(dB(:,1));
dW = d(dB(:,2:end));
ind= dV>=max(dW,[],2) & dV >= LMPthresh;
LMPind = [LMPind; dB(ind)];

%{
for i=1:size(dB,1)
    dv = d(dB(i,1));
    dw = d(dB(i,2:end));
    if all(dv>=dw) && dv >= LMPthresh
        LMPind(end+1,1) = dB(i);
    end    
end
%}

[iz iy ix] = ind2sub(s,LMPind);
LMP = [ix iy iz];
LMP = unique(LMP,'rows');
1;

%check to make sure that the edge doesn't go between fibers, i.e. though
%areas where the distance function drops below a threshold
    for k=size(LMP,1):-1:1
        ind = ind_btw_nodes(u,LMP(k,:),size(d));
        if any(d(ind)<LMPthresh);
            LMP(k,:) = [];
        end
    end
    
%check to make sure that teh LMPs are seperated by a given distance
    nLMP = size(LMP,1);
    LMPkeep = ones(nLMP,1);
    if nLMP>1
        for i=1:nLMP-1
            for j=i+1:nLMP
                if norm(LMP(i,:)-LMP(j,:)) < LMPdist
                    LMPkeep(j) = 0;
                end
            end
        end
    end
    LMP = LMP(LMPkeep==1,:);