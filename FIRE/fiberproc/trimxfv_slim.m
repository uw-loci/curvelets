function[F] = trimxfv_slim(F, V)
% This function is the final step in trimxfv.

    for fi=1:length(F)
        F(fi).f=unique(horzcat(V(F(fi).v).f));
        F(fi).f(F(fi).f==fi)=[];
    end
    
%     C compilable version
%     for fi=1:length(F)
%         y=V(F(fi).v);
%         a=[];
%         for yi=1:length(y)
%             a=[a, y(yi).f];
%         end
%         F(fi).f=unique(horzcat(a));
%         F(fi).f(F(fi).f==fi)=[];
%     end
%     