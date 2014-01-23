
function [centers, prob] = facet_hist(angles, lengths, nbins)
%  DOCUMENT facet_hist(angles,lengths, nbins) produces a weighted histogram
%  of the 1D array angles, where the probability is weighted by the values
%  in the equal length array lengths.

% First: find longest facet and make it the zero reference
%  which could make angles have a range as low as -360.

lengths = lengths/mean(lengths);
[maxl, maxi] = max(lengths);
angles = angles - angle(maxi);

% Next, make angular range -10 to 350. Input was -180 to 180.
low_ang = find(angles<0);
angles(low_ang) = 350 + angles(low_ang);

mn=min(angles); mx=max(angles);
nbins = floor(nbins); %% Force nbins to be an integer

binsize = 360/nbins;

n_angles = length(angles);

mid = mean([mx mn]);
lower = mid-(nbins/2.0*binsize);

upper = lower + nbins*binsize;
cuts  = lower:binsize:upper;

prob  = zeros(1,nbins);
for k = 1:n_angles
    j = 1 + floor((angles(k)-lower)/binsize);
    prob(j) = prob(j) + 1*lengths(k);
end
centers = cuts(1:end-1)+ binsize/2;


