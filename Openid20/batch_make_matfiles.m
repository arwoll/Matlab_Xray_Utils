logfile = 'sample_scan_spectra.csv';
fid = fopen(logfile, 'rt');
a = textscan(fid, '%s %s %d %d %*[^\n]', 'delimiter', ',');
fclose(fid);

dirs = a{1};
labviewbase = a{2};
labviewnum = a{3};
mdanum = a{4};

%%
nfiles = length(dirs);
mdadir = 'MDA';

%k = 32 is first 2d scan (in 2013_feb_22)


for k = 186:187
    current_dir = dirs{k};
    scan_group = labviewbase{k};
    scann = labviewnum(k);
    labviewfile = sprintf('%s.%04d', scan_group, scann);
    fname = fullfile(current_dir, labviewfile );
    mdafile = sprintf('20id_%04d.asc', mdanum(k));
    mdafname = fullfile(current_dir, mdadir, mdafile);
    
%     fprintf(['Processing ' fname ' : ' mdafname '\n']);

    labviewdata = openid20(fname);  
    labviewdata.scann = scann;
%     labviewdata.scanline = '';
    mdadata = open_id20_mda(mdafname);
   
    if any(labviewdata.size ~= mdadata.size)
        fprintf('Size mismatch (k = %d) ... abort\n', k)
        break
    else
        clear scandata
        scandata.spec = labviewdata;
        scandata.dead = struct('key', '');
        scandata.mcadata = mdadata.mcadata;
        scandata.mcaformat = 'id20';
        scandata.mcafile = mdafile;
        scandata.channels = (1:mdadata.channels)';
        scandata.ecal = [0 1 0]; 
        scandata.energy = scandata.channels;
        scandata.specfile = labviewfile;
         
        i0 = squeeze(labviewdata.data(strcmp(labviewdata.headers,'PreKB'),:,:)); 
        norm = squeeze(labviewdata.data(strcmp(labviewdata.headers,'MERCURY:DT Corr I0'),:,:)); 
        scandata.dtcorr = norm./i0;
        scandata.dtdel = ones(size(scandata.dtcorr));
        matfile = [labviewfile '.mat'];
        if ~exist(fullfile(current_dir, matfile), 'file')
            fprintf('k = %d, mdafile = %s, Saving file %s to directory %s\n', ...
                k, mdafile, matfile, current_dir);
            save(fullfile(current_dir, matfile), 'scandata');
        end
        
    end
end

%%
% ecal from metal_ml.0001.mat : 
% ecal  = [-0.107047302220056   0.030943528983599  -0.000001645024333];

matfiles = dir('*.mat');
for k = 1:length(matfiles)
    f = matfiles(k).name;
    load(f);
    scandata.ecal = ecal;
    scandata.energy = channel2energy(scandata.channels, ecal);
    save(f, 'scandata');
end


