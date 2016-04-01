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

% fname = 'D263-0HR'; scans = 5:10;

% fname = 'SLS_0HR_PH3'; scans = [13:19];

% fname = 'SLS_0HR_PH3'; scans = [27:33];

% fname = 'SLS_1HR_PH3'; scans = [3:9];

% fname = 'SLS_5HR_PH3'; scans = [3:9];

% fname = 'SLS_10HR_PH3'; scans = [3:9];

% fname = 'SLS_50HR_PH3'; scans = [3:9];

% fname = 'SLS_100HR_PH3'; scans = [3:9];

% fname = 'SLS_150HR_PH3'; scans = [3:9];

% fname = 'SLS_200HR_PH3'; scans = [3:9];

% fname = 'D263_0HR_PH3_NEW'; scans = [7:13];

% fname = 'D263_1HR_PH3'; scans = [3:9];

% fname = 'D263_5HR_PH3'; scans = [3:9];

% fname = 'D263_10HR_PH3'; scans = [3:9];

% fname = 'D263_50HR_PH3'; scans = [3:9];

% fname = 'D263_100HR_PH3'; scans = [3:9];

% fname = 'D263_150HR_PH3'; scans = [3:9];

% fname = 'D263_200HR_PH3'; scans = [3:9];

% fname = 'D263_250HR_PH3'; scans = [7:13];

% fname = 'D263_1HR_PH9'; scans = [3:9];

% fname = 'D263_5HR_PH9'; scans = [3:9];

% fname = 'D263_10HR_PH9'; scans = [3:9];

% fname = 'D263_50HR_PH9'; scans = [3:9];

% fname = 'D263_100HR_PH9'; scans = [3:9];

% fname = 'MICROSLIDES_0D'; scans = [3:9];

% fname = 'MICROSLIDES_1D'; scans = [3:9];

% fname = 'MICROSLIDES_2D'; scans = [3:9];

% fname = 'MICROSLIDES_4D'; scans = [3:9];

% fname = 'MICROSLIDES_7D'; scans = [3:9];

% fname = 'MICROSLIDES_1M'; scans = [3:9];

% fname = 'MICROSLIDES_2M'; scans = [3:9];

% fname = 'MICROSLIDES_3M'; scans = 3:9;

% fname = 'BORONFLOAT_1D'; scans = [3:9];

% fname = 'BORONFLOAT_2D'; scans = [5:11];

% fname = 'BORONFLOAT_4D'; scans = [7:13];

% fname = 'BORONFLOAT_7D'; scans = [3:9];

% fname = 'BORONFLOAT_1M'; scans = [5:11];

% fname = 'BORONFLOAT_2M'; scans = [7:13];

% fname = 'BORONFLOAT_3M'; scans = [5:11];

fname = 'P1_UNCOATED'; scans = [7:13];

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
    scandata = openspec(['../raw/' fname], scans(k));
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

xlabel 'Two-theta (degrees)'
title(strrep(outname_base, '_', '\_'));
x = alldata(:,1); y = alldata(:,2);
axis([floor(min(x)) ceil(max(x)) 10^(floor(log10(min(y)))) 10^(ceil(log10(max(y))))]);

fign_pos = get(gcf, 'Position');
set(gcf, 'Position', [fign_pos(1) fign_pos(2) 840 560]);
export_png(fign, outname_base);

save(refl_file, 'alldata', '-ascii')

