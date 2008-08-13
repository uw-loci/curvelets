%function center_close = dropFar(centers,hull,dist)

dist_hull = cell(size(centers));
center_close = cell(size(centers));

sz = size(hull);

for ii = 1:length(centers)
    goto = size(centers{ii});
    if goto(2) == 0;
        continue
    else
        for jj = 1:goto(2);
            for kk = 1:sz(1)
                center = [centers{ii}(1,jj),centers{ii}(2,jj)];
                dist_hull{ii}(kk,jj) = sqrt((center(1) - hull(kk,1))^2 + (center(2) - hull(kk,2))^2);
            end
        end
    end
end

for ii = 1:length(centers)
    goto = size(centers{ii});
    if goto(2) == 0;
        continue
    else 
        for jj = 1:goto(2)
        temp = find(dist_hull{ii}(:,jj)<dist);
            if isempty(temp)
               continue
            else
               center_close{ii}(:,jj) = center; 
            end
        end
    end
end

