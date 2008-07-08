
% Extract out endpoints from list of interesection points
function endpoints = extractEndpoints(int_points)

if int_points == 0;
    endpoints = {0};
    return
end

flag = 1;
for ii =1:(length(int_points)-1)
    if ~(abs(int_points(ii,1)-int_points(ii+1,1)) == 1|abs(int_points(ii,2)-int_points(ii+1,2)) == 1)
        keep = int_points(ii:-1:1,:);
        keep_cell{ii} = keep;
        temp = int_points(ii+1:end,:);
        int_points = [zeros(size(keep));temp]; 
        flag = flag + 1;
    else
        continue
    end
end

if flag ==1;
    keep_cell{1} = int_points;
    temp = [];
end

count2 = 1;
% Remove empty_cells
for ii = 1:length(keep_cell)
    if ~isempty(keep_cell{ii})
        int_cell_temp{count2} =flipud(keep_cell{ii});
        count2 = count2 + 1;
    else 
        continue
    end
end

int_cell_temp{end+1} = temp;

% Remove zeros from cells
count3 = 1;
for ii = 1:length(int_cell_temp)
    goto = size(int_cell_temp{ii});
    for jj = 1:goto(1);
        if ~(int_cell_temp{ii}(jj,:)==[0 0])
            int_cell{ii}(count3,:) = int_cell_temp{ii}(jj,:);
            count3 = count3 + 1;
        else 
            continue
        end
    end
    count3 = 1;
end

% get endpoints

for ii = 1:length(int_cell)
    endpoints{ii} = [int_cell{ii}(1,:);int_cell{ii}(end,:)];
end



        
