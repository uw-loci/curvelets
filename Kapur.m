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
H = histogram(img); %grey-scale histogram
n = length(H);
g = (0:n-1)'; %Grey values
[w_b, w_f, mu_b, mu_f, var_b, var_f] = CumMeanVar(H);
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
thresh = g(indices(1));
end