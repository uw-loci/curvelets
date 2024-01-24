function[Xout Fout] = cut_edges(X,F,boxdim)
%CUT_EDGES(X,F,boxdim) - keeps only the fibers within boxdim

box1 = boxdim(1:3);
box2 = boxdim(4:6);

for fi=1:length(F)
    v = F(fi).v;
    
    inbox = zeros(length(v),1);
    seg = [];
    iseg = 0;
    numseg = 0;
    newseg_flag = 1;
    for iv=1:length(v)
        vi = v(iv);
        xi = X(vi,:);
        if all(xi>=box1) && all(xi<=box2) %we're ni a new box
            if newseg_flag == 1 
                newseg_flag = 0; %this is to create a new segment
                numseg = numseg+1;
            end
            seg{numseg}(end+1) = vi;
        else
            newseg_flag = 1;
        end
    end
end  % YL: add 'end', need to check how this function is used in fire
%YL: comment out the syntax error(s)
%     seg = [];
%     for 
%     
%     ind = find(inbox==1);
    