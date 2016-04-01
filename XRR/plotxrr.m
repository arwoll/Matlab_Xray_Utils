% fname = 'psp4vp35nm'; scans = 13:18;
% corrs = [6.5e5; 1.7e4; 772; 14; 3.5; 1];

% fname = 'psditelechelicflat'; scans = 5:11;
% corrs = [6.5e5; 1.7e4; 710; 12.5; 3; 1; 2];

fname = 'ps290kdipon100nmsio2adsmicrobeam'; scans = 4:10;
corrs = [5e5; 1.3e4; 580; 12; 3; 1;1];

ycol = 'dir';
mon = 'I2';
mon_norm = 1e5;

alldata = zeros(10000, 3);
ind_start = 1;
figure(3)
for k = 1:length(scans)
    matfile = [fname num2str(scans(k), '_xrr_%03d') '.mat'];
    if exist(matfile, 'file')
        load(matfile)
    else
        scandata = openspec(['../raw/' fname], scans(k));
        save(matfile, 'scandata');
    end
    
    x = scandata.var1;
    y = scandata.data(strcmp(scandata.headers, ycol), :)';
    s = sqrt(y);
    m = scandata.data(strcmp(scandata.headers, mon), :)';
    y = y./m * mon_norm * corrs(k);
    s = s./m * mon_norm * corrs(k);
    if k == 1
        hold off
    end
    semilogy(x, y)
    hold all
    %fprintf('n = %d\n', length(y))
    ind_end = ind_start + length(y) - 1;
    alldata(ind_start:ind_end, :) = [x y s];
    ind_start = ind_end + 1;
end
alldata = alldata(1:ind_end, :);

refl_file = [fname '.ref'];
save(refl_file, 'alldata', '-ascii')
