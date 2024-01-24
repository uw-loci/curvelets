i = 1;

pts0(i,:,:) = [0 0 0; 1 0 0]; pts1(i,:,:) = [0 0 0; 0 1 0]; i=i+1;
pts0(i,:,:) = [0 0 0; 1 0 0]; pts1(i,:,:) = [.5 .5 0; 0 1 0]; i=i+1;
pts0(i,:,:) = [0 0 0; 1 0 0]; pts1(i,:,:) = [.5 -1 0; .5 1 0]; i=i+1;
pts0(i,:,:) = [0 0 0; 1 0 0]; pts1(i,:,:) = [.5 -1 1; .5 1 1]; i=i+1;
for j=1:4
    pts0(i,:,:) = rand(2,3); pts1(i,:,:) = rand(2,3); i=i+1;
end
for k=1:4
    pts0(i,:,:) = rand(2,3); pts1(i,:,:) = rand(2,3)+[1 0 0; 1 0 0]; i=i+1;
end
for k=1:4
    pts0(i,:,:) = (rand(2,3)-.5).*10; pts1(i,:,:) = (rand(2,3)-.5).*10; i=i+1;
end

n = i-1;
rr = ceil(n/4);
cc = ceil(4);

clf
for i=1:n
    L0 = squeeze(pts0(i,:,:));
    L1 = squeeze(pts1(i,:,:));
    [d(i) pt0(i,:) pt1(i,:)] = segmentdist(L0,L1);
    
    Lc = [pt0(i,:); pt1(i,:)];
    subplot(rr,cc,i)
        plot3(L0(:,1),L0(:,2),L0(:,3),'b','LineWidth',3);
        hold on
        plot3(L1(:,1),L1(:,2),L1(:,3),'r','LineWidth',3);
        plot3(Lc(:,1),Lc(:,2),Lc(:,3),'ko--','LineWidth',3,'MarkerFaceColor','g');        
        hold off
end