%% plotxrr_v4.m 
%
% Given a spec filename (fname) and a set of scans, loads a series of XRR
% scans and concatenates them into a single x,y pair. 
%
% v4 :  assumes that adjacent scans have at least one IDENTICAL 
%       x value, and uses the y values at those points to compute a correction
%       factor, which is then applied. 

%%
%corrs = [5.6103e4; 243.0573; 88.3790; 1.3205; 0.2245; 0.2282; 0.2282];

% fname = ''; scans = [8:14];
fname = 'CUALE20170225-1'; scans = [12:18];

corrs = ones(20,1);
corrs(1) = 2e4;

%%
fign = 2;
outname_base = [fname '-scans-' num2str(scans(1)) '-' num2str(scans(end))];
refl_file = [fname '.ref'];

ycol = 'dir';
mon = 'I2';
mon_norm = 1e5;
 
alldata = zeros(10000, 3);
ind_start = 1;
figure(fign);
for k = 1:length(scans)
    scandata = openspec(fname, scans(k));
    %save(matfile, 'scandata', '-append');
    x = scandata.var1;
    y = scandata.data(strcmp(scandata.headers, ycol), :)';
    s = sqrt(y);
    m = scandata.data(strcmp(scandata.headers, mon), :)';
    
    y = y./m * mon_norm;
    s = s./m * mon_norm;
    if k == 1
        hold off
    else
        % find_norm
        x_matches = intersect(x, x0);
        y_ratios = zeros(size(x_matches));
        for j = 1:length(x_matches)
            y_new = y(x == x_matches(j));
            y_old = y0(x0 == x_matches(j));
            y_ratios(j) = y_old/y_new;
        end
        corrs(k) = mean(y_ratios);
    end
    y = y * corrs(k);
    s = s * corrs(k);
    x0 = x; y0 = y;
    semilogy(x, y, 'linewidth', 1.5)
    hold all
    ind_end = ind_start + length(y) - 1;
    alldata(ind_start:ind_end, :) = [x y s];
    ind_start = ind_end + 1;
end
alldata = alldata(1:ind_end, :);

xlabel(scandata.mot1); % 'Two-theta (degrees)'
title(strrep(outname_base, '_', '\_'));
x = alldata(:,1); y = alldata(:,2);
axis([floor(min(x)) ceil(max(x)) 10^(floor(log10(min(y)))) 10^(ceil(log10(max(y))))]);

%fign_pos = get(gcf, 'Position');
%set(gcf, 'Position', [fign_pos(1) fign_pos(2) 840 560]);
%export_png(fign, outname_base);

save(refl_file, 'alldata', '-ascii')

