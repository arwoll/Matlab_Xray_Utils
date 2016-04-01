%% For now don't use this section 
%matfile = [scandata.specfile num2str(scandata.spec.scann, '_xrr_%03d') '.mat'];
%roi = scandata.roi;
%save(matfile, 'roi', '-append');


%%

% fname = 'SLS_0HR_PH3'; scans = [13:19];
% corrs = [1.67e4; 531.2; 82.87; 6.85; 1.1745; 0.227; 0.083];

% fname = 'SLS_0HR_PH3'; scans = [27:33];
% corrs = [4.5767e4; 586.8545; 86.6031; 9.6437; 5.4364; 0.2269; 0.2282];

% fname = 'SLS_1HR_PH3'; scans = [3:9];
% corrs = [4.8516e4; 631.8803; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'SLS_5HR_PH3'; scans = [3:9];
% corrs = [4.8516e4; 631.8803; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'SLS_10HR_PH3'; scans = [3:9];
% corrs = [4.8516e4; 631.8803; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'SLS_50HR_PH3'; scans = [3:9];
% corrs = [4.8516e4; 631.8803; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'SLS_100HR_PH3'; scans = [3:9];
% corrs = [4.8516e4; 631.8803; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'SLS_150HR_PH3'; scans = [3:9];
% corrs = [4.8516e4; 631.8803; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'SLS_200HR_PH3'; scans = [3:9];
% corrs = [4.4714e4; 642.7328; 95.8946; 10.6321; 5.6579; 0.227; 0.2282];

% fname = 'D263_0HR_PH3_NEW'; scans = [7:13];
% corrs = [4.2611e4; 228.0231; 84.7083; 2.2865; 0.2282; 0.2282; 0.2282];

% fname = 'D263_1HR_PH3'; scans = [3:9];
% corrs = [3.5936e4; 206.5298; 77.4822; 2.1051; 0.2282; 0.2282; 0.2282];

% fname = 'D263_5HR_PH3'; scans = [3:9];
% corrs = [3.819e4; 196.1265; 74.2318; 2.0075; 0.2282; 0.2282; 0.2282];

% fname = 'D263_10HR_PH3'; scans = [3:9];
% corrs = [3.1164e4; 181.5356; 68.0940; 1.9204; 0.2282; 0.2282; 0.2282];

% fname = 'D263_50HR_PH3'; scans = [3:9];
% corrs = [3.4208e4; 194.8815; 73.2592; 2.1076; 0.2282; 0.2282; 0.2282];

% fname = 'D263_100HR_PH3'; scans = [3:9];
% corrs = [4.4067e4; 608.0161; 92.7038; 9.9753; 0.9123; 0.2282; 0.2282];

% fname = 'D263_150HR_PH3'; scans = [3:9];
% corrs = [3.4782e4; 581.1970; 86.9192; 9.9753; 0.9123; 0.2282; 0.2282];

% fname = 'D263_200HR_PH3'; scans = [3:9];
% corrs = [4.4102e4; 612.0013; 90.7767; 9.9753; 0.9123; 0.2282; 0.2282];

% fname = 'D263_250HR_PH3'; scans = [7:13];
% corrs = [4.4102e4; 612.0013; 230.7853; 9.9753; 0.9123; 0.2282; 0.2282];

% fname = 'D263_1HR_PH9'; scans = [3:9];
% corrs = [4.4102e4; 612.0013; 89.9906; 5.5684; 0.9123; 0.2282; 0.2282];

% fname = 'D263_5HR_PH9'; scans = [3:9];
% corrs = [4.1938e4; 599.6450; 242.2155; 9.8263; 1.3338; 0.2282; 0.2282];

% fname = 'D263_10HR_PH9'; scans = [3:9];
% corrs = [4.5078e4; 599.6450; 242.2155; 9.8263; 1.3338; 0.6432; 0.2282];
 
% fname = 'D263_50HR_PH9'; scans = [3:9];
% corrs = [4.3608e4; 581.1725; 234.6604; 9.8263; 1.3487; 0.2282; 0.2282];

% fname = 'D263_100HR_PH9'; scans = [3:9];
% corrs = [4.5938e4; 642.5100; 258.4646; 9.8263; 0.6048; 0.2282; 0.2282];

% fname = 'MICROSLIDES_0D'; scans = [3:9];
% corrs = [5.3259e4; 691.9995; 269.2406; 10.4490; 0.6277; 0.2282; 0.2282];

fname = 'MICROSLIDES_1D'; scans = [3:9];
corrs = [4.8638e4; 642.4727; 269.2406; 3.5818; 0.2189; 0.2282; 0.2282];

%fname = 'MICROSLIDES_2D'; scans = [3:9];
%corrs = [4.8638e4; 614.4201; 93.1111; 3.3615; 0.2270; 0.2282; 0.2282];

%fname = 'MICROSLIDES_4D'; scans = [3:9];
%corrs = [4.5943e4; 585.8684; 86.2572; 3.2786; 0.2270; 0.2282; 0.2282];

%fname = 'MICROSLIDES_7D'; scans = [3:9];
%corrs = [4.5943e4; 654.1481; 95.5367; 3.5381; 0.2291; 0.2282; 0.2282];

%fname = 'MICROSLIDES_1M'; scans = [3:9];
%corrs = [4.5943e4; 623.0535; 90.9487; 3.3465; 0.2245; 0.2282; 0.2282];

%fname = 'MICROSLIDES_2M'; scans = [3:9];
%corrs = [4.1231e4; 606.1589; 88.3790; 1.3205; 0.2245; 0.2282; 0.2282];

% fname = 'MICROSLIDES_3M'; scans = 3:9;
% corrs = [5.6103e4; 243.0573; 88.3790; 1.3205; 0.2245; 0.2282; 0.2282];

%fname = 'BORONFLOAT_1D'; scans = [3:9];
%corrs = [4.7267e4; 249.0587; 35.3516; 5.7630; 0.9361; 0.2282; 0.2282];
%%
fign = 2;
outname_base = [fname '-scans-' num2str(scans(1)) '-' num2str(scans(end))];
use_bksub = 0;


ycol = 'dir';
mon = 'I2';
mon_norm = 1e5;
 
alldata = zeros(10000, 3);
ind_start = 1;
figure(fign);
for k = 1:length(scans)
    matfile = [fname num2str(scans(k), '_xrr_%03d') '.mat'];
    
    if exist(matfile, 'file') && ~isempty(whos('-file', matfile, 'roi')) && use_bksub
        fprintf('hello\n');
        load(matfile, '-mat', 'roi')
        x = double(roi.x);
        y = double(roi.y);
        s = sqrt(y);
        refl_file = [fname '_bksub.ref'];
    else   
        if exist(matfile, 'file') && ~isempty(whos('-file', matfile, 'scandata'))
            load(matfile)
        else
            scandata = openspec(['../raw/' fname], scans(k));
            %save(matfile, 'scandata', '-append');
        end
        x = scandata.var1;
        y = scandata.data(strcmp(scandata.headers, ycol), :)';
        s = sqrt(y);
        m = scandata.data(strcmp(scandata.headers, mon), :)';
        y = y./m * mon_norm * corrs(k);
        s = s./m * mon_norm * corrs(k);     
        refl_file = [fname '.ref']; 
    end
    if k == 1
        hold off
    end
    semilogy(x, y, 'linewidth', 1.5)
    hold all
    %fprintf('n = %d\n', length(y))
    ind_end = ind_start + length(y) - 1;
    alldata(ind_start:ind_end, :) = [x y s];
    ind_start = ind_end + 1;
end
%%
fign_pos = get(gcf, 'Position');
set(gcf, 'Position', [fign_pos(1) fign_pos(2) 840 560]);

xlabel 'Two-theta (degrees)'
title(strrep(outname_base, '_', '\_'));
x = alldata(:,1); y = alldata(:,2);
axis([floor(min(x)) ceil(max(x)) 10^(floor(log10(min(y)))) 10^(ceil(log10(max(y))))]);
export_png(fign, outname_base);

alldata = alldata(1:ind_end, :);

%%
save(refl_file, 'alldata', '-ascii')

