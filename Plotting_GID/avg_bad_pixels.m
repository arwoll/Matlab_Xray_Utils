function cooked = avg_bad_pixels(raw)
%% clean up bad pixels
row_sums = sum(raw, 2);
bad = find(row_sums == 0);
cooked = raw;
for k = 1:length(bad)
   cooked(bad(k), :) = 0.5 * ( raw(bad(k)-1, :) + raw(bad(k)+1, :));
end