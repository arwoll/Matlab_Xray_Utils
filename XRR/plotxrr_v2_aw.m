%%
matfile = [scandata.specfile num2str(scandata.spec.scann, '_xrr_%03d') '.mat'];
save(matfile, 'roi', '-append');


%%

% fname = 'psp4vp35nm'; scans = 13:18;
% corrs = [6.5e5; 1.7e4; 772; 14; 3.5; 1];

% fname = 'psditelechelicflat'; scans = 5:11;
% corrs = [7e5; 1.7e4; 710; 12.5; 3; 1; 2];

%fname = 'ps290k100nmsio2spinads1'; scans = 3:9;
%corrs = [4.5e5; 1.2e4; 0.5e3; 11; 2.8; 0.9;1];

fname = 'psditelechelic6dads'; scans = 3:9;
corrs = [6.5e5; 1.65e4; 690; 12; 3; 1;1];
use_bksub = 1;

ycol = 'dir';
mon = 'I2';
mon_norm = 1e5;

alldata = zeros(10000, 3);
ind_start = 1;
for k = 1:length(scans)
    matfile = [fname num2str(scans(k), '_xrr_%03d') '.mat'];
    
    if exist(matfile, 'file') && ~isempty(whos('-file', matfile, 'roi')) && use_bksub
        fprintf('%s scan %d -- using roi\n', fname, scans(k));
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
    semilogy(x, y)
    hold all
    ind_end = ind_start + length(y) - 1;
    alldata(ind_start:ind_end, :) = [x y s];
    ind_start = ind_end + 1;
end
alldata = alldata(1:ind_end, :);

%save(refl_file, 'alldata', '-ascii')
