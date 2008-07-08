function  colorCurvelet(angle_rec,keep,img);

if length(angle_rec) == 2;
    colors = {'red','blue'};
elseif length(angle_rec) == 4;
    colors = {'red';'green';'blue';'orange'};
else 
    colors = {'red' 'green' 'blue' 'yellow' 'magenta' 'cyan' 'violet' 'orange'};
end



% normalize the angle grouping matrices to be above zero

% for ii = 1:length(angle_rec);
%     angle_rec_norm{ii} = angle_rec{ii} - min(min(angle_rec{ii}));
% end

% % Find the Threshold value
% 
% for ii = 1:length(angle_rec_norm)
%     max_array(ii) = max(max(angle_rec_norm{ii}));
% end
% 
% thresh = max(max_array);

% Remove a percentage of small pixel values for better viewing.
for ii = 1:length(angle_rec);
    if length(keep)==1;
    angle_rec{ii} = angle_rec{ii}.*(angle_rec{ii}>(1-keep)*max(max(angle_rec{ii})));
    else
    angle_rec{ii} = angle_rec{ii}.*(angle_rec{ii}>(1-keep(ii))*max(max(angle_rec{ii})));
    end
end

for jj = 1:length(angle_rec);
  overlap_plot(abs(img),abs(angle_rec{jj}),colors{jj});
end


    