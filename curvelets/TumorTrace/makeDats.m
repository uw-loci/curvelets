% makeDats.m 
% write data to file and perform analytics 
% Inputs:
% dats = values from all intensity and alignment measurements
% timeDats = data for timeseries
% outFolder = location to write data
% names = names of image channels
% numR = number of timeseries regions
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% June 2012

function makeDats(dats,timeDats,outFolder,names,numR)

% output to file, analytics

for aa = 1:length(dats)
    addNum = 0;
    fname = strcat(names{aa},'_',num2str(addNum),'.csv');
    fileName = fullfile(outFolder,fname);
    test = exist(fileName,'file');
    while test
        newName = strcat(names{aa},'_',num2str(addNum),'.csv');
        fileName = fullfile(outFolder,newName);
        addNum = addNum + 1;
        test = exist(fileName,'file');
    end
    
    for bb = 1:length(dats{aa})
        dlmwrite(fileName,dats{aa}{bb}','-append');
    end
    
end

if numR ~= 0
    timeSeries = zeros(length(timeDats),length(timeDats{1}),length(timeDats{1}{1}));
    names{length(names)+1} = 'Direction';

    % cc = channels/measurements
    for cc = 1:length(timeDats)
        %dd = timepoints
        for dd = 1:length(timeDats{cc})
            % ee = regions on cell
            for ee = 1:length(timeDats{cc}{dd})
                timeSeries(cc,dd,ee) = timeDats{cc}{dd}(ee);    
                
            end
        end
    end
 
 % region
 for ll = 1:size(timeSeries,3)
    % creating file to write timeseries region data
    addNum = 0;
    fname = strcat(strcat('timeseries_region_',num2str(ll),'_',num2str(addNum),'.csv'));
    fileName = fullfile(outFolder,fname);
    test = exist(fileName,'file');
    while test
        newName = strcat(strcat('timeseries_region_',num2str(ll),'_',num2str(addNum),'.csv'));
        fileName = fullfile(outFolder,newName);
        addNum = addNum + 1;
        test = exist(fileName,'file');
    end
    % image channels/measurements     
    for kk = 1:length(timeDats)
       dlmwrite(fileName,timeSeries(kk,:,ll),'-append');    
    end
end
        
    h = figure; set(h,'NextPlot','replacechildren'); set(h,'Visible','off');
    set(h, 'PaperPositionMode', 'auto'); set(h,'PaperOrientation','landscape'); 
    ax1 = gca; 
    colors = {'b';'r';'g';'m';'k';'c'};
    for gg = 1:size(timeSeries,3)
        for jj = 1:size(timeSeries,1);
            maxT = max(timeSeries(jj,:,gg));
            normT = timeSeries(jj,:,gg)/maxT;
            plot(normT,colors{jj},'Parent',ax1)
            hold on
        end
        set(ax1,'Ylim',[-1.5 1.5]);
        set(ax1,'Title',text('String',['Region ',num2str(gg)]))
        legend(names,'Location','NorthEastOutside')
        F = hardcopy(h,'-DOpenGL','-r0');
        plotImg(:,:,:,gg) = F;
        cla(ax1)
    end
        close(h)
        implay(plotImg)
        
        aa = 1;
        for hh = 1:length(timeDats)-1
            for ii = (hh+1):length(timeDats)
            %create filenames for writing SRCC results
            addNum = 0;
            fname = strcat('SRCC_',strcat('time_',names{hh}),'_',strcat('time_',names{ii}),'_',num2str(addNum),'.csv');
            fileName = fullfile(outFolder,fname);
            test = exist(fileName,'file');
            while test
                newName = strcat('SRCC_',strcat('time_',names{hh}),'_',strcat('time_',names{ii}),'_',num2str(addNum),'.csv');
                fileName = fullfile(outFolder,newName);
                addNum = addNum + 1;
                test = exist(fileName,'file');
            end
                % get derivatives and find SRCC
                for jj = 1:size(timeSeries,3)
                    
                    tempC1 = timeSeries(hh,:,jj);
                    tempC2 = timeSeries(ii,:,jj);
                    
                    dC1 = diff(tempC1');
                    dC2 = diff(tempC2');

                    [rho{aa} P] = corr(dC1,dC2,'type','Spearman');
                    dlmwrite(fileName,rho{aa},'-append');

                    aa = aa+1;
                end
            end
        end
        
        
%
% THIS PORTION EXCLUDED DUE TO LACK OF TIME FOR VALIDATION
%
%
%     % start granger causality analysis based on gcca toolbox demo by Anil Seth
%     for ff = 1:size(timeSeries,3)
%         nvar = size(timeSeries,1);
%         N = size(timeSeries,2);
%         PVAL = 0.01;
%         %de-trend and de-mean data
%         X = cca_detrend(timeSeries(:,:,ff));
%         X = cca_rm_temporalmean(X);
%         X = cca_diff(X);
%         % check covariance stationarity w/ dickey fuller test
%         uroot = cca_check_cov_stat(X,3);
%         idx = find(uroot);
%         
%         if sum(uroot) == 0,
%         disp('OK, data is covariance stationary by ADF');
%         else
%         disp('WARNING, data is NOT covariance stationary by ADF');
% %         disp(['unit roots found in variables: ',num2str([idx])]);
%         end
%         
%         
%         
%         % check covariance stationarity again using KPSS test
%         [kh,kpss] = cca_kpss(X);
%         inx = find(kh==0);
%         if isempty(inx),
%             disp('OK, data is covariance stationary by KPSS');
%         else
%             disp('WARNING, data is NOT covariance stationary by KPSS');
%             disp(['unit roots found in variables: ',num2str(inx)]);
%         end
%         % find model order
%         NLAGS = -1;
%         if NLAGS == -1,
%         disp('finding best model order ...');
%         [bic,aic] = cca_find_model_order(X,1,12);
%         disp(['best model order by Bayesian Information Criterion = ',num2str(bic)]);
%         disp(['best model order by Aikaike Information Criterion = ',num2str(aic)]);
%         NLAGS = max(bic,aic); % change to change model!!
%         end
%         % find time-domain conditional Granger causalities [THIS IS THE KEY FUNCTION]
%         disp('finding conditional Granger causalities ...');
%         ret = cca_granger_regress(X,NLAGS,1);   % STATFLAG = 1 i.e. compute stats
%         % check that residuals are white
%         dwthresh = 0.05/nvar;    % critical threshold, Bonferroni corrected
%         waut = zeros(1,nvar);
%         for ii=1:nvar,
%             if ret.waut<dwthresh,
%                 waut(ii)=1;
%             end
%         end
%         inx = find(waut==1);
%         if isempty(inx),
%             disp('All residuals are white by corrected Durbin-Watson test');
%         else
%             disp(['WARNING, autocorrelated residuals in variables: ',num2str(inx)]);
%         end
%         % check model consistency, ie. proportion of correlation structure of the
%         % data accounted for by the MVAR model
%         if ret.cons>=80,
%             disp(['Model consistency is OK (>80%), value=',num2str(ret.cons)]);
%         else
%             disp(['Model consistency is <80%, value=',num2str(ret.cons)]);
%         end
% 
%         % analyze adjusted r-square to check that model accounts for the data (2nd
%         % check)
%         rss = ret.rss_adj;
%         inx = find(rss<0.3);
%         if isempty(inx)
%             disp(['Adjusted r-square is OK: >0.3 of variance is accounted for by model, val=',num2str(mean(rss))]);
%         else
%             disp(['WARNING, low (<0.3) adjusted r-square values for variables: ',num2str(inx)]);
%             disp(['corresponding values are ',num2str(rss(inx))]);
%             disp('try a different model order');
%         end
%         % find significant Granger causality interactions (Bonferonni correction)
%         [PR,q] = cca_findsignificance(ret,PVAL,1);
%         disp(['testing significance at P < ',num2str(PVAL), ', corrected P-val = ',num2str(q)]);
% 
%         % extract the significant causal interactions only
%         GC = ret.gc;
%         GC2 = GC.*PR;
%         % calculate causal connectivity statistics
%         disp('calculating causal connectivity statistics');
%         causd = cca_causaldensity(GC,PR);
%         causf = cca_causalflow(GC,PR);
% 
%         disp(['time-domain causal density = ',num2str(causd.cd)]);
%         disp(['time-domain causal density (weighted) = ',num2str(causd.cdw)]);
%         % plot time-domain granger results
%         figure('Name',['Region ',num2str(ff)]);
%         FSIZE = 8;
%         colormap(flipud(bone));
% 
%         % plot raw time series
%         for i=2:nvar,
%             X(i,:) = X(i,:)+(10*(i-1));
%         end
%         subplot(231);
%         set(gca,'FontSize',FSIZE);
%         plot(X');
%         axis('square');
%         set(gca,'Box','off');
%         xlabel('time');
%         set(gca,'YTick',[]);
%         xlim([0 N]);
%         title('Causal Connectivity Toolbox v2.0');
% 
%         % plot granger causalities as matrix
%         subplot(232);
%         set(gca,'FontSize',FSIZE);
%         imagesc(GC2);
%         axis('square');
%         set(gca,'Box','off');
%         title(['Granger causality, p<',num2str(PVAL)]);
%         xlabel('from');
%         ylabel('to');
%         set(gca,'XTick',[1:N]);
%         set(gca,'XTickLabel',1:N);
%         set(gca,'YTick',[1:N]);
%         set(gca,'YTickLabel',1:N);
% 
%         % plot granger causalities as a network
%         subplot(233);
%         cca_plotcausality(GC2,[],5);
% 
%         % plot causal flow  (bar = unweighted, line = weighted)
%         subplot(234);
%         set(gca,'FontSize',FSIZE);
%         set(gca,'Box','off');
%         mval1 = max(abs(causf.flow));
%         mval2 = max(abs(causf.wflow));
%         mval = max([mval1 mval2]);
%         bar(1:nvar,causf.flow,'m');
%         ylim([-(mval+1) mval+1]);
%         xlim([0.5 nvar+0.5]);
%         set(gca,'XTick',[1:nvar]);
%         set(gca,'XTickLabel',1:nvar);
%         title('causal flow');
%         ylabel('out-in');
%         hold on;
%         plot(1:nvar,causf.wflow);
%         axis('square');
% 
%         % plot unit causal densities  (bar = unweighted, line = weighted)
%         subplot(235);
%         set(gca,'FontSize',FSIZE);
%         set(gca,'Box','off');
%         mval1 = max(abs(causd.ucd));
%         mval2 = max(abs(causd.ucdw));
%         mval = max([mval1 mval2]);
%         bar(1:nvar,causd.ucd,'m');
%         ylim([-0.25 mval+1]);
%         xlim([0.5 nvar+0.5]);
%         set(gca,'XTick',[1:nvar]);
%         set(gca,'XTickLabel',1:nvar);
%         title('unit causal density');
%         hold on;
%         plot(1:nvar,causd.ucdw);
%         axis('square');
%     end
% else
end

% Calculate spearman rank correlation coefficient for each pair of
% channels, write results to .csv file
aa = 1;
for hh = 1:length(dats)-1
    for ii = (hh+1):length(dats)
            addNum = 0;
            fname = strcat('SRCC_',names{hh},'_',names{ii},'_',num2str(addNum),'.csv');
            fileName = fullfile(outFolder,fname);
            test = exist(fileName,'file');
            while test
                newName = strcat('SRCC_',names{hh},'_',names{ii},'_',num2str(addNum),'.csv');
                fileName = fullfile(outFolder,newName);
                addNum = addNum + 1;
                test = exist(fileName,'file');
            end
        
        for jj = 1:length(dats{hh})
        
        tempC1 = dats{hh}{jj};
        tempC2 = dats{ii}{jj};
        % calcuations are performed on 1st derivatives of curves
        dC1 = diff(tempC1);
        dC2 = diff(tempC2);
        dC1 = dC1(2:end-1);
        dC2 = dC2(2:end-1); 
        
        [rho{aa} P] = corr(dC1,dC2,'type','Spearman');
        dlmwrite(fileName,rho{aa},'-append');
        aa = aa+1;
        end
    end
end


end
        

