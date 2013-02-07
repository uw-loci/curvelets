%function writeAllHistData(hist,bins,name_list,topLevelDir)
function writeAllHistData2(histData, NorT, outDir, checkFirst, stats, imgName, sliceNum)
    if checkFirst == 1
        %if it's the first file after starting the program, start a new output file
        fid = fopen([outDir 'AllHistData.txt'],'w+');
    else
        %append the current file
        fid = fopen([outDir 'AllHistData.txt'],'a+');
    end
    
    if isempty(histData)
        fprintf(fid,'%s\t%d\t%.2f\t%d\t%s\t',imgName,sliceNum,0,0,NorT);
        fprintf(fid,'\r\n');        
    else
        %for ii = 1:size(histData,1)
        for ii = 1:1
            fprintf(fid,'%s\t%d\t%.2f\t%d\t%s\t',imgName,sliceNum,histData(ii,1),histData(ii,2),NorT);
            if ii == 1
                for jj = 1:size(stats)
                    fprintf(fid,'%0.4f\t',stats(jj));
                end
            end
            fprintf(fid,'\r\n');
        end
    end
    fclose(fid);
end