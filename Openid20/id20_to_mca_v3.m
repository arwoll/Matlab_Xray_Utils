function scandata = id20_to_mca_v3(varargin)
% id20_to_mca is a script to extra spectra from APS ID20 data (after August
% 2014) and output one spectrum per file to a series of mca files, which
% can subsequently be fit in batch mode by PyMCA. The mca spectra so
% generated are, here, normalized and corrected for dead time. The
% normalized ion chamber photocurrent (in nanoCoulombs) is stored in the
% structure and printed in the mca files.
%
% The output from PyMCA is one text file per batch-mode fit, which includes
% the obtained peak areas.
%
% Requires Mcaview/open_id20_hdf5.m and Mcaview/open_id20_hdf5_parse_head

%  eg runplots('mncal_ge2um_A',8,1)
%   runplots('bical_ge2um_A_2D',7,1)
%   runplots('tical_ge2um_A_2D',1,1)
%   runplots('ptcal_ge2um_A_2D',1,1)
%   runplots('cucal_ge2um_A_2D',1,1)
%   runplots('aucal_ge2um_A_2D',1,1)
%   runplots('kcal_ge_2um_A',1,5)
 

%% Initialization. 
%fname = 'srm1843_ge_2um_A.0002';
%
% Note 5/22: work-flow is probably better if mcafiles{} is a new field
% added to scandata (with our without mcadir as convenient later) and for
% fitdir, specified here, should be specified outside and in the next step.

fname_in = '';
matfile_out = '';
ecal = [-0.000468454143428  0.0301015425781  0.0];
export_sum = 1;
cttime = [];
dry_run = 0;
Energy = [];

for k = 1:2:nargin
    switch varargin{k}
        case 'fname'
            if ischar(varargin{k+1})
                fname_in = varargin{k+1};
            end
        case 'ecal'
            if isnumeric(varargin{k+1}) && length(varargin{k+1}) == 3
                ecal = varargin{k+1};
            end
        case 'export_sum'
            if isnumeric(varargin{k+1})
                export_sum = varargin{k+1};
            end
        case 'cttime'
            if isnumeric(varargin{k+1})
                cttime = varargin{k+1};
            end
        case 'dry_run'
            if isnumeric(varargin{k+1})
                dry_run = varargin{k+1};
            end
        case 'matfile_out'
            if ischar(varargin{k+1})
                matfile_out = varargin{k+1};
            end
        case 'Energy'
            if isnumeric(varargin{k+1})
                Energy = varargin{k+1};
            end
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end    

if isempty(fname_in)
    [fname_in, fpath, filter_index] = uigetfile({'*.hdf5'; '*.mat'},...
        'id20_to_mca input file selection');
    [foo, fname, extn] = fileparts(fname_in);
    if ~isempty(fpath)
        fname_in = fullfile(fpath, fname_in);
    end
else
    [fpath, fname, extn] = fileparts(fname_in);
end
analysis_dir = fname;
if isempty(matfile_out)
    matfile_out = [fname '_fit.mat'];
end
mcadir = [fname '_MCA'];
fitdir = [fname '_FIT/FIT'];

if exist(fname_in, 'file')
    if strcmp(extn, '.mat')
        s = load(fname_in, 'scandata');
        if ~isempty(fieldnames(s))
            scandata = s.scandata;
        else
            fprintf('Error : scandata variable not found in %s\n', fname_in);
            return
        end
    elseif strcmp(extn, '.hdf5')
        %hdf5file = [fname '.hdf5'];
        scandata = open_id20_hdf5(fname_in);
    else
        fprintf('Error : unrecognized file %s\n', fname_in);
        return
    end
end
        
%% load Ecal
% [srm1843_ge_2um_A_0002_roi_|_mca 1_|_1_|_1_|_1 Fit]
% A = -0.000468454143428
% C = 0.0
% B = 0.0301015425781
% order = 1
scandata.ecal = ecal; 

if ~isempty(Energy)
    scandata.Energy = Energy;
end


%% Determine Ion Chamber charge per point, and do DT correction
norm_ic = 'PreKB_I0';%'PreKB';
dt = 'MERCURY:DT Corr I0 ';
ic_settings = scandata.spec.ion_chambers(strcmp(norm_ic, ...
    {scandata.spec.ion_chambers().name}));

ic_vals = scandata.spec.data(strcmp(norm_ic, scandata.spec.headers), :);
dt_vals = scandata.spec.data(strcmp(dt, scandata.spec.headers), :);
if isempty(scandata.spec.cttime)
    if isempty(cttime) 
       cttime_cell = inputdlg('Count time for scan (in seconds) :', 'Manual Count Time Entry');
       cttime = str2double(cttime_cell{1});
       scandata.spec.cttime = cttime;
    else
       scandata.spec.cttime = cttime;
    end
else
    cttime = scandata.spec.cttime;
end
freq_per_volt = ic_vals(1) / (ic_settings.V0 * cttime);
%init_ic_I = ic_settings.V0*ic_settings.sensitivity;
%charge_per_ct = init_ic_I * cttime / ic_vals(1);
%nC_per_point = dt_vals * charge_per_ct * 1e9; 
%       == %sens * dt_vals*V0*cttime/ic_vals(1) * 1e9

% This is a very temporary fix! newer files appear to have a Timer, as well
% as ICR and OCR (but NOT realtime and livetime???
if isempty(dt_vals)
    dt_vals = 1;
end

nC_per_point = ic_settings.sensitivity * dt_vals / freq_per_volt * 1e9;

norm_nC = nC_per_point(1);
%% Actually normalize all spectra to norm_nC
% first index in mcadata is always the number of MCA channels
mcadims = size(scandata.mcadata);
nspectra = prod(mcadims(2:end));
norm_mca = double(scandata.mcadata);
scandata.dtcorr = norm_nC ./ nC_per_point;
if numel(scandata.dtcorr) == 1
   scandata.dtcorr = scandata.dtcorr*ones(nspectra, 1);
end
for k = 1:nspectra
   norm_mca(:,k) = scandata.mcadata(:,k) * scandata.dtcorr(k);
end

scandata.norm_note = ['mcadata DT corrected, flattened to normalized ' ...
 norm_ic ' integracted charge of norm_nC = ' num2str(norm_nC)];
scandata.freq_per_volt = freq_per_volt;
scandata.norm_nC = norm_nC;
scandata.norm_ic = norm_ic;
scandata.mcadata = norm_mca;

% 
% if dry_run
%     return
% end

%% Write Mcafiles
if ~dry_run
    if exist(analysis_dir, 'file') == 2
        fprintf('Error trying to create dir %s; it is an existing file,\n', analysis_dir);
        return
    elseif exist(analysis_dir, 'file') == 7
        old_folder = cd(analysis_dir);
    else
        mkdir(analysis_dir);
        old_folder = cd(analysis_dir);
    end
    
    existance_check = exist(mcadir, 'file');
    if existance_check  == 2
        fprintf('Error trying to create dir %s; it is an existing file,\n', mcadir);
        return
    elseif existance_check == 7
        foo_str = input(['Warning : directory ' mcadir ' already exists -- continue?'], 's');
        if ~(foo_str(1) == 'y' || foo_str == 'Y')
            fprintf('Abort\n');
            return
        end
    end
    mkdir(mcadir);
    mkdir(fitdir);
    fprintf('Creating directories %s and\n\t%s for MCA files and PyMCA fit output\n',...
        mcadir, fitdir);
end

spectra = scandata.mcadata;
mcadims = size(spectra);
nchannels = mcadims(1);
nspectra = prod(mcadims(2:end));

% Export sum spectrum (to use with PyMCA to make a good cfg file)
if ~dry_run && export_sum == 1
   full_mca_outfile = [fname '_SUM.mca'];
   sum_spectrum= sum(reshape(spectra, nchannels, nspectra), 2);
   success = spectrum_to_mca(sum_spectrum, scandata, full_mca_outfile);
   if ~success
       fprintf(['Error: unsuccessful call from id20_to_mca to spectrum_to_mca\n' ...
           'on %s\n'], full_mca_outfile);
       return
   end
end

% Export individual spectra
for j = 1:nspectra
    mcafile = [fname '_' num2str(j, '%04d') '.mca'];
    mcafiles{j} = mcafile;
    if dry_run
        continue
    end
    full_mca_outfile = [mcadir '/' mcafile];
    success = spectrum_to_mca(spectra(:, j), scandata, full_mca_outfile);
    if ~success
       fprintf(['Error: unsuccessful call from id20_to_mca to spectrum_to_mca\n' ...
           'on %s\n'], full_mca_outfile);
       return
    end
end


scandata.matfile_out = matfile_out;
scandata.mcafiles = mcafiles;
scandata.mcadir = mcadir;
scandata.fitdir = fitdir;

%%
% The MCA files being written, the state should be saved so that it can be
% resumed after fitting is done during a different session.

if ~dry_run
    save(matfile_out, 'scandata')
    fprintf('State saved to %s\n', matfile_out);
    cd(old_folder);
end
