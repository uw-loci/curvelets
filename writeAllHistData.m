%function writeAllHistData(hist,bins,name_list,topLevelDir)
function writeAllHistData(histData,idName, leasionNum, NorT, outDir, checkFirst, date, stats)
    if checkFirst == 1
        %if it's the first file after starting the program, start a new output file
        fid = fopen([outDir 'AllHistData.txt'],'w+');
    else
        %append the current file
        fid = fopen([outDir 'AllHistData.txt'],'a+');
    end
            
    for ii = 1:size(histData,1)
        fprintf(fid,'%s\t%s\t%s\t%.2f\t%d\t%s\t',date,idName,leasionNum,histData(ii,1),histData(ii,2),NorT);
        if ii == 1
            for jj = 1:size(stats)
                fprintf(fid,'%0.2f\t',stats(jj));
            end
        end
        fprintf(fid,'\r\n');
    end    
    fclose(fid);
end