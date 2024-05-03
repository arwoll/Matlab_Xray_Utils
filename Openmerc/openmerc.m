function [scandata, errors] = openmerc(mcafile, varargin)
%  function scandata = openmerc(mcaname [,varargin])
%
%  6 Dec: This version neglects to make use of much of the information in
%  the tiff files saved by the EPICS Tiff plugin, especially details such
%  as the number of pixels saved, the number of spectra, the size of each
%  pixel buffer (2304). Rather this information is ignored or hard coded
%  in. In a future version (openxmap), these details will likely be
%  included. And that version will likely be able to handle single-channel
%  tiff files as well as 4-channel devices. 
%  
%  Based on openmca (a part of "Mcaview") but for loading data saved from
%  the XIA Mercury device, in Mapping mode, using of the tiff plugin. 
%
%  Opens and loads data from a group of tiff files, as well as the associated spec file.
%  Format is assumed to be specfile_device_scann_ptn.tiff
%  
%  mcafile    = Name of mca file.  Should be of the form <specfile>_#.mca,
%               Optionally it can be a matlab file containing a variable called
%               'scandata' with the structure defined below
%
%  varargin   = property/value pairs to specify non-default values for mca
%               data.  Allowed properties are:
%               'ecal'          : 1x2 array for channel # to energy conversion
%               'MCA_channels'  :
%               'dead'          : dead.base, dead.channels specify how to get dead
%                                 time info
%               'mcaformat'     : to expand allowed formats. Currently only two
%                                 are allowed, 'esrf' and 'xflash', and these can be
%                                 auto-detected.
%
%  scandata   = mca data structure combining mca, spec, and fitting data.
%
%  errors.code = numerical indication of type
%               of error: 
%               0 = none
%               1 = scandata is empty (file not found or other fatal error)
%               2 = scandata is present but may be incomplete, or some other non-fatal 
%                   error condition, e.g. no spec data, mcafile was incomplete)
%
%  errors.msg  = Error string
%
%  Notes: 
%       * In the tiff file, one word is 16 bits. 
%       * Channel counts are stored as single words, limiting the counts in
%         any single channel to 2^16-1=65535 
%       * The tiff file begins with a 256 word "buffer header" BH:
%          BH(9)  = pixels actually in buffer (e.g. actual spectra in file)
%          BH(21) = channels (e.g. 2048)
%       * Code assumes that tiff files are ORDERED when retrieved with
%       "dir", i.e. that the point number designations in tiff files have
%       leading zeros.
%  Dependencies: add_error, openspec, find_line,
%  Mcaview/mca_strip_pt, Mcaview/channel2energy
%
% -------------------------------------------------------------------------
% -----------------         Initialization         ------------------------
% -------------------------------------------------------------------------

errors.code = 0;
scandata = [];
specscan = [];
mcadata = uint16([]);

if nargin < 1 
    errors=add_error(errors,1,...
        'openmerc takes at least one input -- the filename');
    return
elseif ~exist(mcafile, 'file')
    errors=add_error(errors,1, ...
        sprintf('File %s not found', mcafile));
    return
end

nvarargin = nargin -1;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to openmca_esrf must come in variable/value pairs');
    return
end

MCA_channels = 2048;
ecal = [0 1];

mcaformat = 'g3tiff'; % If this remains empty after processing args, code will try to autodetect
dead = struct('key','xia');

for k = 1:2:nvarargin
    switch varargin{k}
        case 'MCA_channels'
            if isnumeric(varargin{k+1}) || length(varargin{k+1}) == 1
                MCA_channels = varargin{k+1};
            end
        case 'ecal'
            if isnumeric(varargin{k+1})
                ecal = varargin{k+1};
            end
        case 'dead'
            % fields key (none, vortex, xflash, generic)
            fields = fieldnames(varargin{k+1});
            for m = 1:length(fields)
                dead.(fields{m}) = varargin{k+1}.(fields{m});
            end
        case 'mcaformat'
            % g3tiff : specfile_device_scan_pt.tiff
            mcaformat = varargin{k+1};
        case 'scan'
            specscan = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end       

% -------------------------------------------------------------------------
% -----------------   Autodetect mca format if needed     -----------------
% -------------------------------------------------------------------------

[mcapath, mcaname, extn] = fileparts(mcafile);

if isempty(mcaformat)
    errordlg('Unrecognized mca file format...abort');
    return
elseif iscell(mcaformat) && length(mcaformat) == 1
    mcaformat = mcaformat{1};
end

% -------------------------------------------------------------------------
% --------------------------     Load MCA data      -----------------------
% -------------------------------------------------------------------------

% The block below reads in mca data when it is contained in a file other
% than the spec data file.  In this case, unless error code has been set to
% 1, the following variables must be defined:
%   1. specfile
%   2. Dead_time_base, Dead_time_channels
%   3. matfile
%   4. mcadata
%   5. MCA_channels
%   6. spectra
%   7. channels (explict channel numbers for energy calibration)

switch mcaformat
    case 'g3tiff'
        % grab all of the tiff files that match, and load them.
        mcabase = mca_strip_pt(mcaname);
        [specfile, specscan] = mca_strip_pt(mcabase);
        last_uline = find(specfile=='_', 1, 'last');
        device = specfile(last_uline+1:end);
        specfile = specfile(1:last_uline-1);
        % Both specfile and mcabase must be non-empty for us to assume that
        % the requested mca file is one of a set.
        if ~isempty(specfile)
            mcafiles = dir(fullfile(mcapath,[mcabase '_*' extn]));
            mcafiles = {mcafiles.name}';
        else
            mcafiles = {mcafile};
        end
%        MCA_channels = 2048;
        matfile = [mcabase '.mat'];
    otherwise
        errors=add_error(errors,1,...
            sprintf('Uncrecognized mca file format %s', mcaformat));
        return
end

% -------------------------------------------------------------------------
% -----------------          Load spec data         -----------------------
% -------------------------------------------------------------------------
% At this point mcafile and mcadata are determined. mcadata may
% be reshaped if 1) a spec scan is located and has more than one point, or
% 2) no spec file is found but the length of mcadata is an integer
% multiple of MCA_channels.
% -------------------------------------------------------------------------

[scandata.spec, spec_err] = openspec(fullfile(mcapath,specfile), specscan);

if spec_err(end).code > 0
    % Demote fatal error from openspec since at this point we have
    % successfully read in mcadata (we are just missing spec info)
    % Oops -- currently the following message is added twice...
    for k = 1:length(spec_err)
        errors = add_error(errors, spec_err(k).code, spec_err(k).msg);
    end
    if errors(end).code == 1
       % see add_error...
        return
    end
end

if strcmp(mcaformat, 'g3tiff')
    MCA_channels = 2048;
    nfly = scandata.spec.size(1);
    mcadata = zeros(MCA_channels, scandata.spec.npts);
    realtime = zeros(1,scandata.spec.npts);
    livetime = zeros(1,scandata.spec.npts);
    triggers = zeros(1,scandata.spec.npts);
    output_evts = zeros(1,scandata.spec.npts);
    channels = 0:MCA_channels-1;
    for spectra = 1:length(mcafiles)
        a = imread(fullfile(mcapath,mcafiles{spectra}));
        if spectra == 1 && a(21) ~= MCA_channels
                fprintf('%s indicates %d channels; expecting %d\n', mcafiles{spectra}, a(21), MCA_channels);
        end
        if a(9) ~= nfly
            fprintf('%s indicates %d spectra, expecting %d (from spec)\n', mcafiles{spectra}, a(9), nfly);
        end
        c = double(reshape(a(257:end),2304, 455));
        mcadata(:,(spectra-1)*nfly+1:spectra*nfly) = c(257:end, 1:nfly);
        realtime((spectra-1)*nfly+1:spectra*nfly) = c(33, 1:nfly) + bitshift(c(34,1:nfly), 16);
        livetime((spectra-1)*nfly+1:spectra*nfly) = c(35, 1:nfly) + bitshift(c(36,1:nfly), 16);
        triggers((spectra-1)*nfly+1:spectra*nfly) = c(37, 1:nfly) + bitshift(c(38,1:nfly), 16);
        output_evts((spectra-1)*nfly+1:spectra*nfly) = c(39, 1:nfly) + bitshift(c(40,1:nfly), 16);
    end
end

scandata.mcadata = mcadata;
scandata.device = device;
scandata.realtime = realtime;
scandata.livetime = livetime;
scandata.triggers = triggers;
scandata.output_evts = output_evts;
scandata.mcaformat = mcaformat;
scandata.dead = dead;
scandata.depth = 1:size(mcadata, 2);
scandata.channels = channels; 
scandata.mcafile = [mcaname extn];
scandata.matfile = matfile;
scandata.ecal = ecal;
scandata.energy = channel2energy(scandata.channels, ecal);


scandims = size(scandata.spec.data);
if isfield(scandata.spec, 'order')
    % The order field in scandata.spec indicates that the data were not
    % originally ordered in a perfect grid -- e.g. the raster scan switched
    % directions to save time. This could be a 2D OR 3D scan.  A second
    % field, var1_n, takes care of the fact that the different directions
    % may not have different sizes.  
    sorted_mcadata = scandata.mcadata(:,scandata.spec.order);
    nfast = scandata.spec.size(1);
    nslow = scandata.spec.size(2);
    scandata.mcadata = reshape(sorted_mcadata, MCA_channels, nfast, nslow);
    scandata.realtime = reshape(scandata.realtime(scandata.spec.order), nfast, nslow);
    scandata.livetime = reshape(scandata.livetime(scandata.spec.order), nfast, nslow);
    scandata.triggers = reshape(scandata.triggers(scandata.spec.order), nfast, nslow);
    scandata.output_evts = reshape(scandata.output_evts(scandata.spec.order), nfast, nslow);
    spectra = scandata.spec.npts;
else
    if ~scandata.spec.complete
        % Truncate the mcadata to whole number of var2_n
        if spectra > scandata.spec.npts
            scandata.mcadata = scandata.mcadata(:, 1:scandata.spec.npts);
            scandata.depth = scandata.depth(1:scandata.spec.npts);
            spectra = scandata.spec.npts;
        elseif spectra < scandata.spec.npts
            fprintf('Fewer spectra than spec pts written -- sometimes happens when loading a current scan\n')
            scandata.spec.npts = specscan.spec.npts - 1;
        end
    end
    if length(scandims)>2
        scandata.mcadata=reshape(scandata.mcadata, MCA_channels, scandims(2), scandims(3));
    end
end
    
if spectra ~= scandata.spec.npts
    % scandata.spec.npts is supposed to be the number of spec data points
    % actually read, rather than the number of points expected.  Hence this
    % is a true error condition since the number of spec points written
    % does not match the number of mca spectra.  This is distinct from an
    % incomplete scan, in which case these values should match but
    % scandata.spec.complete == 0 so that the condition is caught above
    errors=add_error(errors, 1, ...
        sprintf('Error: mcafile / specfile mismatch. Check %s for duplicate scans',specfile));
    return
end

scandata.specfile = specfile;
% try
%     [scandata.dtcorr,  scandata.dtdel] = dt_calc(scandata);
% catch
%     errors=add_error(errors,1,scandata.dtcorr);
%     return;
% end

if strcmp(mcaformat, 'g3tiff')
    fullmatfile = matfile;
else
    fullmatfile = fullfile(mcapath, matfile);
end
if exist(fullmatfile, 'file')
    overwrite = questdlg(sprintf('Overwrite existing file %s?', ...
        fullmatfile), 'Overwrite?', 'Yes', 'No', 'Yes');
    if strcmp(overwrite, 'Yes')
%        save(fullmatfile,'scandata');
    end
else
    save(fullmatfile,'scandata');
end
