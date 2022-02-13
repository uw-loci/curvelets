function brokenLine = ansAna(answer)

brokenLine = zeros(6,1);

% more6 = 0;
% more7 = 0;
% more8 = 0;

% for i=1:length(answer)
%     if answer(i) > 0.6
%         more6 = more6 + 1;
%         if answer(i) > 0.7
%             more7 = more7 + 1;
%             if answer(i) > 0.8
%                 more8 = more8 + 1;
%             end
%         end
%     end
% end

% disp(more6)
% disp(more7)
% disp(more8)

for i=1:length(answer)
    for j=5:10
        if answer(i) > (j/10)
            brokenLine(j-4) = brokenLine(j-4) + 1;
        end
    end
end

end