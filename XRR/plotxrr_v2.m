%%
matfile = [scandata.specfile num2str(scandata.spec.scann, '_xrr_%03d') '.mat'];
%roi = scandata.roi;
%save(matfile, 'roi', '-append');


%%

% fname = 'psp4vp35nm'; scans = 13:18;
% corrs = [6.5e5; 1.7e4; 772; 14; 3.5; 1];

% fname = 'psditelechelicflat'; scans = 5:11;
% corrs = [7e5; 1.7e4; 710; 12.5; 3; 1; 2];

%fname = 'ps290k100nmsio2spinads1'; scans = 3:9;
%corrs = [4.5e5; 1.2e4; 0.5e3; 11; 2.8; 0.9;1];

%fname = 'ps290kdippiro3ads'; scans = 6:12;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.49e-1; .85e-1;.078];

%fname = 'ps290kdippiro3adsanothersample'; scans = 7:13;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps290kspinpiro3ads'; scans = 7:13;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps290kspinadspiro3anothersample'; scans = 15:21;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps290kdippiro3flat'; scans = 9:15;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps290kspinpiro3116hflat'; scans = 10:16;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps290kdipadsbsi'; scans = 12:18;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps290kdipflatbsi'; scans = 6:12;
%corrs = [3e4; 0.8e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'ps50k0pcauflatbsi'; scans = 6:12;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'pvoh25k24hannflatpiro3'; scans = 6:12;
%corrs = [2.2e4; 0.7e3; 410e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'pvoh25k24hannadspiro3'; scans = 6:12;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'psp4vp8nm100hann'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'ps290k8nm36hann1'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'sbslam130Cann36hflat'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'psp4vp8nm100hann1'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'sbslam150Cann36h11nm'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'psp4vp140hannflatco2ridge2h'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'psp4vpco2ridge24hflat'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 370e-1; 9e-1; 2.4e-1; .85e-1;.083];

%fname = 'ps50k5pcauflathsi'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vpco24ridge24hads'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vpco2ridge24hads'; scans = 3:9;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'sbslam24hco2ridgeflat'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'sbslam48hco2ridgeads'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at26c'; scans = 4:10;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at170c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at160c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at150c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at140c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at120c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at100c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at80c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 390e-1; 9e-1; 2.5e-1; .85e-1;.083];

%fname = 'psditelechelich2so4at90c'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 390e-1; 9e-1; 2.5e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat24C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat200C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat170C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat150C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat160C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat140C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat120C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

%fname = 'psp4vp140hannflat80C'; scans = 1:7;
%corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];

fname = 'psohpiro3'; scans = 1:7;
corrs = [2.2e4; 0.7e3; 410e-1; 10e-1; 2.6e-1; .85e-1;.083];
%%
use_bksub = 0;

ycol = 'dir';
mon = 'I2';
mon_norm = 1e5;
 
alldata = zeros(10000, 3);
ind_start = 1;
figure(2);
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
    semilogy(x, y)
    hold all
    %fprintf('n = %d\n', length(y))
    ind_end = ind_start + length(y) - 1;
    alldata(ind_start:ind_end, :) = [x y s];
    ind_start = ind_end + 1;
end
alldata = alldata(1:ind_end, :);

save(refl_file, 'alldata', '-ascii')
