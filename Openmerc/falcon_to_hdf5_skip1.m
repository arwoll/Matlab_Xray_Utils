function [errors, varargout] = falcon_to_hdf5(fullspecfilename, scann, varargin)
%function info = flyscan_to_hdf5()
% Given a spec filename and scan number corresponding to an XRF mapping
% scan with mercury or XMAP hardware writing data to tiff files,  read the
% spec file line by line and its associated spectra (in tiff files), and
% export data to an hdf5 readable by PyMCA and GeoPIXE.

% Ideally, this should be able to function while a scan is being taken, so
% that the data can be inspected while being taken. (perhaps by default,
% the function could autodetect whether a scan is the last in a file and/or
% complete, and if incomplete, wait for new data. This function should
% provide functionality only, but could be used by, say, a script or gui to
% call PyMCA in batch mode and plot the map, or just provide basic
% statistics and/or sum spectra for each line.
%
% Original motivation is to convert very large data sets obtained from
% daguerreotypes in November 2017, which were in fact too large to convert
% with original conversion software, which loaded ALL data into memory
% before writing data to a file.

SPEC_LABEL_REGEXP = '[\w-]+( ?[\w-]+)*';

errors.code=0;

nvarargin = nargin -2;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to flyscan_to_hdf5 must come in variable/value pairs');
    return
end

nlines = [];


EXPORT_MCADATA = 0;
if nargout>1
    EXPORT_MCADATA = 1;
    export_lines = 20;
end



for k = 1:2:nvarargin
    switch varargin{k}
        case 'nlines'
            nlines = varargin{k+1};
        case 'export_lines'
            if EXPORT_MCADATA == 1
               export_lines = varargin{k+1}; 
            end
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end   

[datapath, specname, extn] = fileparts(fullspecfilename);


specscan = struct('specfile', specname, 'scann', scann);

specfile = fopen(fullspecfilename, 'r');
if specfile == -1
    errors = add_error(errors, 1, sprintf('Error: spec file %s not found',...
        fullspecfilename));
    return
end
[scan_start, scan_data_start, scan_end, motor_start, motor_end] = ...
    openmerc_find_scan(specfile, scann);
if isempty(scan_end)
   %eof was reached, mark last read position.? 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%  PROCESS HEADERS -- this should probably be modularized %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if scan_start < 0
    errstr = sprintf('Error: scan %d not found in %s\n', scann, fullspecfilename);
    fprintf(errstr)
    errors = add_error(errors, 1, errstr);
    return
end
fseek(specfile, scan_start, -1);
scan_head = fread(specfile, scan_data_start-scan_start, '*char*1')';
specscan.scanline = strjoin(regexp(scan_head, '(?<=#S \d+ + )[^\n]*', 'match'));
scan_pars = strsplit(specscan.scanline);
if isempty(strfind(scan_pars{1}, 'fly'))
        errstr = sprintf('Error: Scan %d in file %s is type %s, not a flyscan -- ABORT\n', ...
            scann, specfilename, scan_pars{1});
    fprintf(errstr)
    errors = add_error(errors, 1, errstr);
    return
else
    fast_start = str2double(scan_pars{3});
    fast_end = str2double(scan_pars{4});
    specscan.nfast = str2double(scan_pars{5})+1;
end

if strcmp(scan_pars{1}, 'flymesh')
    specscan.mot1 = scan_pars{2};
    specscan.mot2 = scan_pars{6};
end
%scanline = regexp(scan_head, '(?<=#S \d+ + ).*', 'match', 'dotexceptnewline');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read motor names  & positions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

motor_names = [];
if ~isempty(motor_start)
    fseek(specfile, motor_start, -1);
    motor_str = fread(specfile, motor_end - motor_start, '*char*1')';
    name_lines = regexp(motor_str, '(?<=#O\d+ )[\w ]*(?=\n)', 'match');
    motor_names = regexp(strjoin(name_lines, '  '), SPEC_LABEL_REGEXP, 'match')';
end
    
if ~isempty(motor_names)
    position_lines = regexp(scan_head, '(?<=#P\d+ ).*(?=\n)', 'match', 'dotexceptnewline');
    motor_positions = sscanf(strjoin(position_lines, '  '), '%g');
    if length(motor_names) ~= length(motor_positions)
        errors = add_error(errors,2, sprintf('Warning: Found %d motor names, but %d motor positions.', ...
            length(motor_names), length(motor_positions)));
    end
    specscan.motor_names = motor_names;
    specscan.motor_positions = motor_positions;
end

chann = regexp(scan_head, '(?<=#@CHANN +)[^\n]*', 'match');
if ~isempty(chann)
    mcachan = sscanf(strjoin(chann, '  '), '%d');
    MCA_channels = mcachan(1);
    channels = (mcachan(2):mcachan(3))';
end

ecalcell = regexp(scan_head, '(?<=#@CALIB +)[^\n]*', 'match');
if ~isempty(ecalcell)
    specscan.ecal = sscanf(strjoin(ecalcell, '  '), '%g')';
end

headerline = regexp(scan_head, '(?<=#L +)[^\n]*', 'match');
specscan.headers = regexp(strjoin(headerline), SPEC_LABEL_REGEXP, 'match');
%specscan.ncolumns = length(specscan.headers);
fprintf('WARNING: overriding openspec to force ncolumns to 6\n');
specscan.ncolumns = 6;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%  END PROCESS HEADERS %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize speec_array. ncolumns is first because that is how it will be
% filled
spec_array = zeros(specscan.ncolumns, specscan.nfast);
chunk_length = numel(spec_array);

SINGLE_MODE = 0;
mcafiles = dir(fullfile(datapath, ...
    sprintf('%s_*TORO*_%04d_0000_000.tiff', specscan.specfile, specscan.scann)));
if isempty(mcafiles)
    mcafiles = dir(fullfile(datapath, ...
        sprintf('%s_*TORO*_%04d_000.tiff', specscan.specfile, specscan.scann)));
    if ~isempty(mcafiles)
       SINGLE_MODE = 1; 
    end
end
    
if length(mcafiles) > 1
   fprintf('Oops -- cannot handle more than one device yet\n'); 
else
   foo = strsplit(mcafiles.name(length(specname)+2:end), '_');
   specscan.device = foo{1};
end

mcabase = sprintf('%s_%s_%04d', specname, specscan.device, specscan.scann);
if isempty(nlines)
    specscan.h5file = [mcabase '.h5'];
else
    specscan.h5file = sprintf('%s_%dlines.h5', mcabase, nlines);
end

status = flyscan_hdf5_init(specscan, 'force', 1);

% Initialize H5 file -- e.g. write everthing OTHER than data.

%% Begin loop. 
% Read a row of data & comments
% There is probably a regexp way to do this such that the comment lines are
% tokens...

fseek(specfile, scan_data_start,-1);
specscan.nslow = 0;
tic
while ~feof(specfile)
    % star_pos = ftell(specfile);
    [data_cell, stop_pos] = textscan(specfile, '%f32', chunk_length, 'CommentStyle', '#');
    % Check number of points read
    n = numel(data_cell{1});
    if isempty(data_cell{1})
        break
    elseif numel(data_cell{1}) ~= chunk_length
       fprintf('Warning: seem to have encountered an incomplete line -- abort?\n');
       break
    end
    specdata = reshape(data_cell{1}, specscan.ncolumns, specscan.nfast);
    if isempty(specdata)
        %fprintf('No data while reading line %d\n', specscan.nslow+1);
        break;
    end
    [specdata, thisrow_order] = sortrows(specdata', 1);
    specdata = specdata';
    % Check, e.g. that the endpoints match those specified in scanline
    % [optionally] rewind and scan for comments. Note that if we want to to
        % this, we should read the entire scan in, either to scan_end or to
        % eof. In that case this loop should be inside a larger loop that can
        % do the read, close the file, then check on the file afterwords for
        % changes.
    if SINGLE_MODE
        mcafiles_info = dir(fullfile(datapath, ...
            sprintf('%s_%03d*.tiff', mcabase, specscan.nslow)));
    else
        mcafiles_info = dir(fullfile(datapath, ...
            sprintf('%s_%04d_*.tiff', mcabase, specscan.nslow)));
    end
    if isempty(mcafiles_info)
        %fprintf('No data while reading line %d\n', specscan.nslow+1);
        break;
    end
    mcafilenames = {mcafiles_info.name}';
    mcafiles = cell(1,1);
    mcafiles{1} = mcafilenames;
    mcadata = falcon_read_tiff(mcafiles, 'path', datapath, ...
        'order', thisrow_order, 'reshape', 1, ...
        'px_per_line', specscan.nfast, 'no_output', 1); 
    specscan.nslow = specscan.nslow + 1;

    
    if EXPORT_MCADATA && specscan.nslow <= export_lines
        mcaout(specscan.nslow) = mcadata;
    end
    
    if specscan.nslow == 1
        fprintf('Skipping first line...');
        continue
    end
    
    % for to skip first -- subtract here but have to add later
    specscan.nslow = specscan.nslow - 1;
    falcon_hdf5_writerow(specscan, specdata, mcadata);
    if mod(specscan.nslow,10) == 0
        fprintf('Time-per-group of 10 lines: %.1f sec\n', toc);
        tic
    end
    if ~isempty(nlines) && specscan.nslow >= nlines
        break
    end
    % add here...
    specscan.nslow = specscan.nslow + 1;
end

fprintf('Wrote %d lines to %s\n', specscan.nslow, specscan.h5file);

if EXPORT_MCADATA
   varargout{1} = mcaout; 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% END CODE %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for k = 1:length(comments)
%     comments(k).line = comments(k).point/ncolumns;
% end
% lines = length(data)/ncolumns;

%
% Algorithm:
%    1. Detect spec file, read header info and find the scan mark(as in "openspec")
%    2. Detect an image file -- e.g. specfile_*0000_000.tif(f), where the '*'
%    is analyzed as in openxmap currently, and searched for the scan
%    number. This is used to define the search for all tiff files
%    associated with each line.
%    3. Read all header info (this, also, should eventually be saved to the
%       h5 file). For the moment this will be used to build the normal
%       "spec" structure, but perhaps exlcuding the mca data.
%    4. Construct an hdf5 filename and open.
%    5. Loop: 
%       - Read a line of spec data, determing order (BTW how does Gerry do
%       this?). (This requires parsing the scan line sooner, in openspec,
%       than is currently done. note too: openspec can tolerate inline mca
%       data. This, presumably, should NOT. BUT: should we anticipate
%       multiple detectors, e.g. two ME4's? 
%       - read the tiff file names for that line
%       - Call xmap_read_tiff with just that lines worth of tiffs
%       - Write that line of spec data and xmap data to the h5 file
%       - If the scan is complete or was aborted, end. Otherwise, (possibly
%       as an option) close the specfile and poll it from time to time for
%       updates.