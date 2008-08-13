function center_new = dropFar(centers,hull,dist)

sz = size(hull);
for kk = 1:sz(1)
    for ii = 1:length(centers)
    goto = size(centers{ii});
        if goto(2) == 0;
        continue
        else
            for jj = 1:goto(2);
            center = [centers{ii}(1,jj),centers{ii}(2,jj)];
            dist_hull = sqrt((center(1) - hull(kk,1))^2 + (center(2) - hull(kk,2))^2);
                if dist_hull < dist
                    center_new{ii}(:,jj) = center;
                else
                    center_new{ii} = [];
                end
            end
        end
    end
end