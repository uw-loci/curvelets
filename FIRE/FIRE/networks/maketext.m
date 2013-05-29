function[] = maketext(fpref,X,F)
%MAKETEXT - makes a text file for the network

%print vertex positions
    fid = fopen([fpref 'X.txt'],'w');
    for i=1:size(X,1)
        fprintf(fid,'%d, %d, %d\n',X(i,1),X(i,2),X(i,3));
    end
    fclose(fid);
    
%print fibers
    fid = fopen([fpref 'F.txt'],'w');
    for i=1:length(F)
        v = F(i).v;
        for j=1:length(v)
            vj = v(j);
            fprintf(fid,'%d',vj);
            if j<length(v)
                fprintf(fid,', ');
            end
        end
        fprintf(fid,'\n');
    end
    fclose(fid);