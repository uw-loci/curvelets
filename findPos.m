% Find the position of the center of the curvelet from coefficients


function pos = findPos(C_new)

% Threshold
for ii = 1:length(C_new)-1
    for jj = 1:length(C_new{ii})
        val_cell{ii}(jj) = max(max(C_new{ii}{jj}));
    end
end

for ii = 1:length(val_cell)
    maxVal(ii) = max(val_cell{ii});
end

for ii = 2:length(C_new)-1
    for jj = 1:length(C_new{ii})
        C_new{ii}{jj} = C_new{ii}{jj}.*(C_new{ii}{jj} > .5*maxVal(ii));
    end
end

for ii = 2:length(C_new)-1
    for jj = 1:length(C_new{ii})
        [row,col] = find(C_new{ii}{jj}>0);
        ind{ii}{jj} = [row';col'];
    end
end

[SX,SY] = fdct_wrapping_param(C_new);

for ii = 2:length(C_new)-1
    for jj = 1:length(C_new{ii})
        goto = size(ind{ii}{jj});
        if goto(2) ==0;
            pos{ii-1}{jj} = [];
        else
            for kk = 1:goto(2)
                x_cord(kk) = SX{ii}{jj}(ind{ii}{jj}(1,kk),ind{ii}{jj}(2,kk)); 
                y_cord(kk) = SY{ii}{jj}(ind{ii}{jj}(1,kk),ind{ii}{jj}(2,kk));
            end
        pos{ii-1}{jj} = [x_cord;y_cord];
        x_cord = 0;
        y_cord = 0;
        end
    end
end
        



      