function[] = fiberhist_compare(Xt,Ft,Xa,Fa,arg5,arg6)

    if nargin==4
        [Lt tht pht] = fiberhist(Xt,Ft);
        [La tha pha] = fiberhist(Xa,Fa);
    elseif nargin==6
        Lt = Xt;
        tht= Ft;
        pht= Xa;
        La = Fa;
        tha= arg5;
        pha= arg6;
    end
       
    figure; df
    clf
    rr = 2; cc = 3;
    binnum = 6;
    subplot(rr,cc,1)
        hist(Lt,binnum);
        ylabel('True Answer')
        title('L')
        set(gca,'XLim',[0 max(Lt)]);
        xlabel(['Num. Fib. = ' num2str(length(Lt))])
    subplot(rr,cc,2)
        hist(tht,binnum);
        title('theta (xy)')
        set(gca,'XLim',[0 180])
    subplot(rr,cc,3)
        hist(pht,binnum);
        title('phi (xz)')
        set(gca,'XLim',[0 180])        
    subplot(rr,cc,4)
        hist(La,binnum);
        set(gca,'XLim',[0 max(Lt)]);
        xlabel(['Num. Fib. = ' num2str(length(La))]);
        ylabel('Algorithm Approximation')
    subplot(rr,cc,5)
        hist(tha,binnum);
        set(gca,'XLim',[0 180])        
    subplot(rr,cc,6)
        hist(pha,binnum);
        set(gca,'XLim',[0 180])     