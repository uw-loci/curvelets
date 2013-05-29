function[X F V] = deletefiber(X,F,V)
%DELETEFIBER - deletes fiber that is selected by a datatip
%if more than one fiber is selected, it prompts the user and then
%deletes all fibers if desired

%if a handles structure is used instead of three seperate inputs
    if nargin==1
        handles = X;
        X = handles.X;
        F = handles.F;
        V = handles.V;
    end

%get the datatip object
    dcm_obj = datacursormode(gcf);
    
%get info on the datatip(s)
    info_struct = getCursorInfo(dcm_obj);
    
if isempty(info_struct)
    fprintf('no data tips are in place\n')
else
    %make a vector of all the vertices to be deleted
        v = [];
        for i=1:length(info_struct)
            pos = info_struct(i).Position;
            ind = find( X(:,1)==pos(1) & X(:,2)==pos(2) & X(:,3)==pos(3));
            if ~isempty(ind)
                v = [v; ind];
            end
        end
    %make a vector of all the fibers to be deleted
        f = [];
        for i=1:length(v)
            f = [f V(v(i)).f];
        end
    %delete fibers
    %check with user if more than one is selected
        if length(f)==1
            F(f) = [];
        end
        if length(f)>1
            plotfiber(X,F(f),1,0,'r');
            in = input('are you sure you want to delete multiple fibers in red (y or n)? ->','s');
            if in=='y'
                F(f) = [];
            end
        end            
end
[X F V] = trimxfv(X,F,V);
cla
plotfiber(X,F,2,0,[],'o')

%return a structure if the input was a structure
    if nargin==1        
        handles.X = X;
        handles.F = F;
        handles.V = V;
        X = handles;
    end