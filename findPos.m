% Find the position of the center of the curvelet from coefficients

% Notice that the loops only go from 2:end-1.  This is because we do not
% use the low pass coeffecients in C{1} and C{7} is a wavelet Decomposition
% of the image

function pos = findPos(C_new)

% Threshold

% This loop finds the maximum value in each sub_cell ie. max of {2}{1}
for ii = 1:length(C_new)-1
    for jj = 1:length(C_new{ii})
        val_cell{ii}(jj) = max(max(C_new{ii}{jj}));
    end
end

% This loop finds the maximum value in each cell ie. max of {2}
for ii = 1:length(val_cell)
    maxVal(ii) = max(val_cell{ii});
end

% This loop eliminates small coeffecients (less than 1/2 the max for that
% cell) in absolute value by setting them to zero
for ii = 2:length(C_new)-1
    for jj = 1:length(C_new{ii})
        %C_new{ii}{jj} = C_new{ii}{jj}.*(C_new{ii}{jj} > .5*maxVal(ii));
        C_new{ii}{jj} = C_new{ii}{jj}.*(abs(C_new{ii}{jj}) > .5*maxVal(ii));
    end
end

% This loop finds the indices of the non-zero coeffecients
for ii = 2:length(C_new)-1
    for jj = 1:length(C_new{ii})
        %[row,col] = find(C_new{ii}{jj}>0);
        [row,col] = find(C_new{ii}{jj});
        ind{ii}{jj} = [row';col'];
    end
end

% This function gets the center positions of the curvelets
[SX,SY] = fdct_wrapping_param(C_new);

% The loop puts the positions into a managable vector called pos
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
        



      