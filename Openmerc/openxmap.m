function [scandata, errors] = openxmap(mcafile, varargin)
%  function scandata = openmerc(mcaname [,varargin])
%
%  6 Dec: (mostly DONE) This version neglects to make use of much of the information in
%  the tiff files saved by the EPICS Tiff plugin, especially details such
%  as the number of pixels saved, the number of spectra, the size of each
%  pixel buffer (2304). Rather this information is ignored or hard coded
%  in. In a future version (openxmap), these details will likely be
%  included. 
%
%  (DONE) Can we make openxmap compatible with the mercury (single channel?)
%  
%  This is based on openmca (a part of "Mcaview") but for loading data saved from
%  the XIA XMAP device, in Mapping mode, using of the tiff plugin. 
%
%  Opens and loads data from a group of tiff files, as well as the associated spec file.
%  Format is assumed to be either specfile_device_scann_ptn.tiff or
%  (probably) specfile_device_scann_ptn_filen.tiff, where the additional
%  number at the end permits unlimited spectra per line.s
%  
%  mcafile    = Name of mca file.  Should be of the form <specfile>_#.mca,
%               Optionally it can be a matlab file containing a variable called
%               'scandata' with the structure defined below
%
%  varargin   = property/value pairs to specify non-default values for mca
%               data.  Allowed properties are:
%               'ecal'          : 1x2 array for channel # to energy conversion
%               (DEV) 'hdf5' : option to spit out an hdf5 file, so this
%               could be used as a conversion routine. Possibly the .mat
%               file would not necessarilly be saved too.
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

if nargin < 1 
    errors=add_error(errors,1,...
        'openmerc takes at least one input -- the filename');
    return
elseif ~exist(mcafile, 'file')
    % Need to add an echo, especially if 2nd output arg is not called for
    errors=add_error(errors,1, ...
        sprintf('File %s not found', mcafile));
    return
end

nvarargin = nargin -1;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to openxmap must come in variable/value pairs');
    return
end

ecal = [0 1];
mcaformat = 'g3tiff'; % If this remains empty after processing args, code will try to autodetect

% one_file_per_line will default to 0, but can be changed with an input
% par. If 0, then check. 
auto_check_file = 1;
one_file_per_line = 0;
dead = struct('key','xia');
onechannel = 0;       % The default, 0, means *all* channels
is_merc = 0;

for k = 1:2:nvarargin
    switch varargin{k}
        case 'ecal'
            if isnumeric(varargin{k+1})
                ecal = varargin{k+1};
            end
        case 'channel'
            onechannel = varargin{k+1};
        case 'single_file'
            auto_check_file = 0;
            one_file_per_line = varargin{k+1};
        case 'mercury'
            is_merc = 1;
            onechannel = 1;
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end       

% -------------------------------------------------------------------------
% -----------------   Autodetect mca format if needed     -----------------
% -------------------------------------------------------------------------

[mcapath, mcaname, extn] = fileparts(mcafile);

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
        % Tiff file format is 'specfilename_eveXMAP_SCANN_POINTN_FILEN.tiff'
        mcaname_split = strsplit(mcaname, '_');
        mcaname_nums = str2double(mcaname_split);
        last_nan = find(isnan(mcaname_nums), 1, 'last');
        trailing_nums = length(mcaname_split) - last_nan;
        if trailing_nums < 2
            fprintf('Error in openxmap: filename must have at least two trailing numbers SCANN & POINTN\n');
            return
        end
        if auto_check_file && trailing_nums == 2
            one_file_per_line = 1;
        elseif one_file_per_line == 0 && trailing_nums == 2
            fprintf('Error in openxmap: filename not consistent with multiple files/line\n');
            fprintf('\tIf more than one file per line, expecting format:\n');
            fprintf('\tspecfilename_DEVICE_SCANN_POINTN_FILEN.tiff\n');
            return
        end
        if one_file_per_line
            scann_ind = length(mcaname_split) - 1;
        else
            scann_ind = length(mcaname_split) - 2;
        end
        specscan = mcaname_nums(scann_ind);
        device = mcaname_split{scann_ind - 1};
        mcabase = strjoin(mcaname_split(1:scann_ind), '_');
        specfile = strjoin(mcaname_split(1:scann_ind-2), '_');
        % Both specfile and mcabase must be non-empty for us to assume that
        % the requested mca file is one of a set.
        if ~isempty(specfile)
            mcafiles = dir(fullfile(mcapath,[mcabase '_*' extn]));
            tic
            % Sort tiff files AND group into (multiple) tiff files for each
            % line of data.
            if one_file_per_line
                mcafilenames = {mcafiles.name}';
                mcafiles = cell(length(mcafiles), 1);
                for k = 1:length(mcafiles)
                    mcafiles{k} = mcafilenames(k);
                end
                files_per_line = 1;
            else
                [mcafiles, files_per_line] = tiff_file_sort({mcafiles.name}');
            end
            fprintf('File sort time: %.1f seconds\n', toc);
        else
            mcafiles = {mcafile};
        end
        a = imread(mcafile);
        if a(3) ~= 256
            errors = add_error(errors, 1, 'Error: Sample fiff file indicates buffer header size ~= 256');
            return
        elseif a(4) ~= 1
            errors = add_error(errors, 1, 'Error: Sample tiff file indicates other than Full Spectrum mode');
            return
        end
        MCA_channels = a(21);
        if onechannel == 0 || is_merc
            matfile = [mcabase '.mat'];
        else
            matfile = [mcabase sprintf('_mca%d',onechannel) '.mat'];
        end
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
tic
[scandata.spec, spec_err] = openspec(fullfile(mcapath,specfile), specscan);
fprintf ('Openspec time: %.1f seconds\n', toc)
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

% tiff_sort_files above groups files into sets
% associated with each line. The data is now loaded into a structure array
% mcadata, where each of 4 elements mcadata(1) has fields spectra,
% realtime, livetime, etc.
%
% Note if we sent the specscan order result to xmap_read_tiff, then all of
% the re-ordring and reshaping could happen there... Moreover it could be
% better at handling incomplete scans (since it could reshape the mcadata
% based on the points per line and number of lines recorded, rather than
% relying on SPEC info...
if strcmp(mcaformat, 'g3tiff')
    channels = 0:MCA_channels-1;
    nfast = scandata.spec.size(1);
    nslow = scandata.spec.size(2);
    % if onechannel == 0 , we should probably check the scan dims, and force
    % onechannel to be 1 if the dimensions are too big, + give a note.
    tic
    mcadata = xmap_read_tiff(mcafiles, 'path', mcapath, ...
        'order', scandata.spec.order, 'reshape', 1, 'channel', onechannel, ...
        'px_per_line', nfast, 'files_per_line', files_per_line); %, 'test', 1)
    fprintf('xmap_read_tiff time: %.1f seconds\n', toc)
    % check, e.g., mcadata.dims against nfly, npts, etc.
    mcadims = size(mcadata(1).spectra);
    nspectra = prod(mcadims(2:3));

    if (nfast ~= mcadims(2) || nslow ~= mcadims(3) || nspectra ~= scandata.spec.npts)
        errors=add_error(errors, 2, ...
            sprintf('Warning: mcafile / specfile mismatch in %s scan %d',specfile, specscan));
        fprintf('Warning: mcafile / specfile mismatch in %s scan %d\n',specfile, specscan)
        fprintf('spec scan dims = %d x %d, found mca dims %d x %d\n', nfast, nslow, mcadims(2), mcadims(3))
        fprintf('spec scan has %d points, mcadata has %d spectra\n', scandata.spec.npts, nspectra);
    end
end

scandata.mcadata = mcadata;
scandata.device = device;
scandata.mcaformat = mcaformat;
scandata.dead = dead;
scandata.depth = scandata.spec.var1(:,1)';
scandata.channels = channels; 
scandata.path = mcapath;
scandata.mcafiles = mcafiles;
scandata.matfile = matfile;
scandata.ecal = ecal;
scandata.energy = channel2energy(scandata.channels, ecal);

scandata.specfile = specfile;
% try
%     [scandata.dtcorr,  scandata.dtdel] = dt_calc(scandata);
% catch
%     errors=add_error(errors,1,scandata.dtcorr);
%     return;
% end


fullmatfile = matfile;
fprintf('Initiating save to matfile %s\n', fullmatfile);
if exist(fullmatfile, 'file')
    overwrite = questdlg(sprintf('Overwrite existing file %s?', ...
        fullmatfile), 'Overwrite?', 'Yes', 'No', 'Yes');
    if strcmp(overwrite, 'Yes')
        save(fullmatfile,'scandata', '-v7.3');
    end
else
    save(fullmatfile,'scandata', '-v7.3');
end
