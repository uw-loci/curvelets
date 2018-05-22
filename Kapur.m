function thresh = Kapur(img)
%Computes image threshold based on Kapur's method Described by:
% Kapur, Jagat Narain, Prasanna K. Sahoo, and Andrew KC Wong. "A new
% method for gray-level picture thresholding using the entropy of the
% histogram." Computer vision, graphics, and image processing
% 29.3 (1985): 273-285.
%
%INPUT
% img: image matrix
%
%OUTPUT
% thresh: threshold
%
% Contributions from:
% Bianconi, Francesco, et al. "A sequential machine vision procedure for
% assessing paper impurities." Computers in Industry 65.2 (2014): 325-332.

%setup local functions
    function [w_b, w_f, mu_b, mu_f, var_b, var_f] = CumMeanVar(H)
        %Computes cumulative mean and variance of a probability density function
        %
        %INPUT
        %H        :   probability desnity function (histogram)
        %
        %OUTPUT
        %w_b      :   background weight
        %w_f      :   foreground weight
        %mu_b     :   background means (1 x n array)
        %mu_f     :   foreground means (1 x n array)
        %sig_b    :   background standard deviations (1 x n array)
        %sig_f    :   foreground standard deviations (1 x n array)
        
        %Get the number of grey levels
        n = length(H);
        
        %Grey values
        g = (0:n-1)';
        
        %Weights
        for t = 1:n
            w_b(t) = sum(H(1:t));
            w_f(t) = sum(H((t+1):n));
        end
        
        %Cumulative means of background and foreground
        for t = 1:n
            mu_b(t) = sum(g(1:t).*H(1:t))/w_b(t);
            mu_f(t) = sum(g((t+1):n).*H((t+1):n))/w_f(t);
        end
        
        %Cumulative variances of background and foreground
        for t = 1:n
            var_b(t) = sum(((g(1:t) - mu_b(t)).^2).*H(1:t))/w_b(t);
            var_f(t) = sum(((g((t+1):n) - mu_f(t)).^2).*H((t+1):n))/w_f(t);
        end
        
        mu_b(isnan(mu_b)) = 0;
        mu_f(isnan(mu_f)) = 0;
        var_b(isnan(var_b)) = 0;
        var_f(isnan(var_f)) = 0;
        
    end
%Main function
%Compute grey-scale histogram
H = imhist(img,256);
H = H/sum(H);
n = length(H); %bin count
g = (0:n-1)'; %Grey values
[w_b, w_f, ~, ~, ~, ~] = CumMeanVar(H);
%Compute foreground and background entropy
E_b = zeros(1,n);
E_f = zeros(1,n);
for i = 1:n
    H_b = [H(1:i); zeros(1,n-1)'];
    H_f = [zeros(1,i)'; H((i+1):n)];
    if w_b(i) ~= 0
        H_b = H/w_b(i);
    end
    if w_f(i) ~= 0
        H_f = H/w_f(i);
    end
    for j = 1:n
        if H_b(j) ~= 0
            E_b(i) = E_b(i) + H_b(j).* (-log2(H_b(j)));
        end
    end
    for j = 1:n
        if H_f(j) ~= 0
            E_f(i) = E_f(i) + H_f(j).* (-log2(H_f(j)));
        end
    end
end
[maxVal, indices] = max(E_b + E_f);
threshi = g(indices(1));
thresh = ((1-0)*(threshi-0))/(256-0)+0; %scale to range [0 1]
end