function [thresh,J] = kittlerMinErrThresh(img)
%KITTLERMINERRTHRESH Compute an optimal image threshold.
%   Computes the Minimum Error Threshold as described in:
%   
%   'J. Kittler and J. Illingworth, "Minimum Error Thresholding," Pattern
%   Recognition 19, 41-47 (1986)'.
%   
%   The image 'img' is expected to have integer values from 0 to 255.
%   'optimalThreshold' holds the found threshold. 'J' holds the values of
%   the criterion function.
%   
%   Contribution from kocki (https://stackoverflow.com/users/789248/kocki)
%


%Initialize the criterion function
J = Inf * ones(255, 1);

%Compute the relative histogram
histogram = double(histc(img(:), 0:255)) / size(img(:), 1);

%Walk through every possible threshold. However, T is interpreted
%differently than in the paper. It is interpreted as the lower boundary of
%the second class of pixels rather than the upper boundary of the first
%class. That is, an intensity of value T is treated as being in the same
%class as higher intensities rather than lower intensities.
for T = 1:255

    %Split the hostogram at the threshold T.
    histogram1 = histogram(1:T);
    histogram2 = histogram((T+1):end);

    %Compute the number of pixels in the two classes.
    P1 = sum(histogram1);
    P2 = sum(histogram2);

    %Only continue if both classes contain at least one pixel.
    if (P1 > 0) && (P2 > 0)

        %Compute the standard deviations of the classes.
        mean1 = sum(histogram1 .* (1:T)') / P1;
        mean2 = sum(histogram2 .* (1:(256-T))') / P2;
        sigma1 = sqrt(sum(histogram1 .* (((1:T)' - mean1) .^2) ) / P1);
        sigma2 = sqrt(sum(histogram2 .* (((1:(256-T))' - mean2) .^2) ) / P2);

        %Only compute the criterion function if both classes contain at
        %least two intensity values.
        if (sigma1 > 0) && (sigma2 > 0)

            %Compute the criterion function.
            J(T) = 1 + 2 * (P1 * log(sigma1) + P2 * log(sigma2)) ...
                     - 2 * (P1 * log(P1) + P2 * log(P2));

        end
    end

end

%Find the minimum of J.
[~, optimalThreshold] = min(J);
thresh = optimalThreshold - 0.5;
end