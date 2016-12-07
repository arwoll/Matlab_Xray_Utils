function y = norm_by_col(y)

for k = 1:size(y, 2)
    y(:,k) = y(:,k)/max(y(:,k));
end