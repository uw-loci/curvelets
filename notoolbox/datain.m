function datain(imagefig,varargins)

temp=get(gca,'currentpoint'); % Sample current mouse position, in axes units
%%% keep current position in figure property 'USERDATA'
set(gcf,'userdata',[get(gcf,'userdata'); temp(1,1:2)]);
%%%

X=get(gcf,'userdata'); %%% Get data for processing
Len=size(X,1);

plot(X(Len,1),X(Len,2),'xr'); %%% Plot the last sampled position
