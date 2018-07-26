function mcadata = falcon_read_tiff(mcafiles, varargin)
% function mcadata = xmap_read_tiff(mcafiles, varargin)
% Read a group of mcafiles assumed to be associated with a particular scan
% line, and stuff the data into a structure array mcadata, where:
%     mcadata(n) has fields spectra, realtime, livetime, triggers, and
%     output_evts, each with dimensions MCA_channels x npixels, where npixels is
%     envisioned as the number of spectra/points per line
%
% for testing, construct an input cell structure like so:
% testf{1} = {'deg70111-2_eveXMAP_007_158_000.tiff', 'deg70111-2_eveXMAP_007_158_001.tiff'}
% The following line was for testing with a test cell array above 
% mcafiles = mcafiles{1};
%
% ToDo:
%    * (DONE) Add optional "order" and reshape arguments to perform ordering and
%      reshaping here. (reshaping should probably default to yes.
%    * (DONE) Calculate & store ICR (triggers*realtime?) and OCR (output_evts*livetime?).
%    * (DONE) edit openxmap to reflect changes here...
%    * (DONE) check ICR/OCR calc & add dead time line.
%
%    * Note that realtime appears to be based on about a 322 ns / 3.11 MHz
%    clock. I might have seen a note stating that this is the decimation
%    time, the sampling interval times the samples / digital measurement.

%
% TODO : 6 Feb 2018:
%   * (DONE) figure out maximum number of files per line, so that this does not
%   need to be auto-detected 
%   * (DONE) Change initialization of data_line to be the same for all files (call
%   'zeros' command -- I doubt it costs extra CPU time
%
% TODO: 14 Feb 2018:
%   * (MOSTLY DONE) evaluate & report realtime/livetime usability. Fix?
%         - possibly create two arrays: one providing the indices of good
%         lines, another with a map of good or bad livetime points
%         - Do we correct for bad times?
%   * Noticed that length(sortorder) can be different from npx_expected.
%   WHy? Because scan was ABORTED.
%

mcadata = [];
mcapath = '';
sortorder = [];
do_reshape = 1;
onechannel = 0;   % 0 means all, 1-4 means single
px_per_line_force = 0;
files_per_line = 0;
TEST_RUN = 0;
no_output = 0;

FIRST_LINE = 1;
LAST_LINE = 1e8;   % An irretreivably large number of scan lines.
MAX_LINES = 2000;

nvarargin = nargin -1;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to xmap_read_tiff must come in variable/value pairs');
    return
end
for k = 1:2:nvarargin
    switch varargin{k}
        case 'path'
            mcapath = varargin{k+1};
        case 'order'
            sortorder = varargin{k+1};
        case 'reshape'
            do_reshape = varargin{k+1};
        case 'channel'
            onechannel = varargin{k+1};
        case 'readlines'
            if length(varargin{k+1}) == 2 && all(varargin{k+1}>0) && ...
                    varargin{k+1}(2) > varargin{k+1}(1)
                FIRST_LINE = int(varargin{k+1}(1));
                LAST_LINE = int(varargin{k+1}(2));
            else
                fprintf('Error: readlines keyword takes a two-element vector as input\n');
            end
        case 'px_per_line'
            px_per_line_force = varargin{k+1};
        case 'files_per_line'
            files_per_line = varargin{k+1};
        case 'test'
            TEST_RUN = varargin{k+1};
        case 'no_output'
            no_output = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end   

if LAST_LINE > length(mcafiles)
    LAST_LINE = length(mcafiles);
end
nlines = LAST_LINE - FIRST_LINE+1;
if nlines > MAX_LINES
    nlines = MAX_LINES;
    LAST_LINE = FIRST_LINE + MAX_LINES - 1;
end

% This code determines files_per_line beforehand... but this is not yet
% used later...
if files_per_line == 0
    for k = FIRST_LINE:LAST_LINE
        if length(mcafiles{k})>files_per_line
            files_per_line = length(mcafiles{k});
        end
    end
end
tic
npx_found = 0;
%
% Check px_per_file for several of the first few tiff files...
px_per_file = 0;
for nline=FIRST_LINE:FIRST_LINE+1
    if nline > nlines 
        break
    end
    for nfile = 1:length(mcafiles{nline})
        a = imread(fullfile(mcapath, mcafiles{nline}{nfile}));
        if double(a(9)) > px_per_file
            px_per_file = double(a(9));
        end
    end
end

for nline = FIRST_LINE:LAST_LINE
    if mod(nline,10) == 0 && nline > FIRST_LINE && ~no_output
        fprintf('Time-per-group: %.1f sec: Starting line %d of %d\n', toc, nline, LAST_LINE);
        tic
    end
    nfiles = length(mcafiles{nline});
    if nfiles == 0
        fprintf('Warning: No mcafiles found at line %d\n', nline);
        continue
    end
    npx_this_line = 0;
    for nfile = 1:nfiles
        a = imread(fullfile(mcapath, mcafiles{nline}{nfile}));
        npx_this_file = double(a(9));
        c = a(257:end);  % From start of first pixel buffer
        pixel_size = double(c(7)) + double(bitshift(c(8), 16));
        if nline == FIRST_LINE && nfile == 1 
            %px_per_file = npx_this_file;  %Vulnerable to bad first files -- e.g. for Nov 2013 data!
            % NOTE: Mercruy manual says a(22, 23, 24) should be set to
            % zero, but evidently they are not.
            % Note though: that the pixel buffer words 10-13 seem to
            % contain the same info, and appears to be followed by the
            % Falcon as well.
            det_channels = a(21:24);
            %det_channels = c(9:12);
            nchannels = sum(det_channels>0);
            MCA_channels = det_channels(1);
            if nchannels == 0 || any(det_channels ~= MCA_channels)
                if ~no_output
                    fprintf('Warning in xmap_read_tiff: channels/detector are not identical,\n\t or zeros found in buffer header bytes 20-23\n');
                    fprintf('Assume that this is a Mercury -- only one channel\n');
                end
                nchannels = 1;
                onechannel = 1;
                if MCA_channels == 0
                   % This is a guess; not sure why this appears to work for
                   % Mercury and xmap. Perhaps the xmap REALLY puts the
                   % number of channels in the buffer header.
                   MCA_channels = c(9); % half of the number of words, since falcon uses 32 bit ints.
                end
            end
            if onechannel > nchannels
                if ~no_output
                    fprintf('Warning; requested non-existant channel %d of %d -- trying all\n',...
                        onechannel, nchannels);
                end
                onechannel=0;
            end
            if onechannel
                nchannels = 1;
                % assume all channels are the same size (probably 2048)
                ch_size =  double(c(9));
                pixel_indices = [1:256 256+(onechannel-1)*ch_size+1:256+onechannel*ch_size]';
            else
                pixel_indices = (1:pixel_size)';
            end
            nkeep = length(pixel_indices);
            
        end
        if nfile == 1
            data_line = zeros(pixel_size, px_per_file, files_per_line, 'uint16');
        end
        
        if ~TEST_RUN
            data_line(:, 1:npx_this_file, nfile) = double(reshape(c(1:pixel_size*npx_this_file),...
                pixel_size, npx_this_file));
        end
        npx_this_line = npx_this_line + npx_this_file;
    end
    % Done with line. Now, create an array for all blocks in scan.
    if nline == FIRST_LINE
        if (px_per_line_force)
            px_per_line = px_per_line_force;
        else
            px_per_line = npx_this_line;
        end
        npx_expected = nlines*px_per_line;
        % We now know how many lines and how many pixels per line, so can initialize the master arrays
        try
            data_scan = zeros(nkeep, px_per_line, nlines, 'uint16');
        catch
            fprintf('Error in map_read_tiff: insufficient memory. Try one detetor or a subset of lines?\n');
            return
        end
    end
    if npx_this_line ~= px_per_line
       fprintf('Warning: discrepancy between px_per_line (%d) and npx_this_line (%d)\n', ...
           px_per_line, npx_this_line);
    end
    data_line = reshape(data_line(:, 1:px_per_line), pixel_size, px_per_line);
%    data_line = reshape(data_line, pixel_size, px_per_file*files_per_line);
    data_scan(:,1:px_per_line, nline-FIRST_LINE+1) = data_line(pixel_indices, 1:px_per_line);
    npx_found = npx_found + px_per_line;
%    data_scan(:,1:npx_this_line, nline-FIRST_LINE+1) = data_line(pixel_indices, 1:npx_this_line);
%    npx_found = npx_found + npx_this_line;
end
if ~no_output
    toc;
end

clear data_line c a;
if npx_expected ~= npx_found
    fprintf('Warning on group with %s: Expecting %d points/spectra, found %d.\n', ...
        mcafiles{1}{1}, npx_expected, npx_found);
end
data_scan = reshape(data_scan, nkeep, npx_expected);

for j = 1:nchannels
    spectrum_offset = 256+(j-1)*MCA_channels;
    spectra_raw = data_scan(spectrum_offset+1:spectrum_offset+MCA_channels,:);
    mcadata(j).spectra = uint32(spectra_raw(1:2:MCA_channels-1, :))+bitshift(uint32(spectra_raw(2:2:MCA_channels, :)), 16);
    stats_offset = (j-1)*8+32;
    mcadata(j).realtime = uint32(data_scan(stats_offset+1, :)) + ...
        bitshift(uint32(data_scan(stats_offset+2,:)), 16);
    mcadata(j).livetime = uint32(data_scan(stats_offset+3, :)) + ...
        bitshift(uint32(data_scan(stats_offset+4,:)), 16);
    mcadata(j).triggers = uint32(data_scan(stats_offset+5, :)) + ...
        bitshift(uint32(data_scan(stats_offset+6,:)), 16);
    mcadata(j).output_evts = uint32(data_scan(stats_offset+7, :)) + ...
        bitshift(uint32(data_scan(stats_offset+8,:)), 16);
    mcadata(j).bad_times = (mcadata(j).realtime == 0) | (mcadata(j).livetime == 0);
    mcadata(j).bad_trigs = (mcadata(j).triggers == 0) | (mcadata(j).output_evts == 0);
end

MCA_channels = MCA_channels/2;

if ~isempty(sortorder) && do_reshape
    nsort = length(sortorder);
    if nsort < (LAST_LINE*px_per_line)
        NEW_LAST_LINE = floor(nsort/px_per_line);
        fprintf(['xmap_read_tiff: Warning: nsort < LAST_LINE*px_per_line...\n' ...
            'Truncating at line %d, not %d, to conform to sortorder passed to xmap_read_tiff\n'], ...
            NEW_LAST_LINE, LAST_LINE);
        LAST_LINE = NEW_LAST_LINE;
        nlines = LAST_LINE - FIRST_LINE + 1;
    end
    sortorder = sortorder((FIRST_LINE-1)*px_per_line+1:LAST_LINE*px_per_line);
    if FIRST_LINE > 1 
        sortorder = sortorder - sortorder((FIRST_LINE-1)*px_per_line);
    end

    for k=1:nchannels
        mcadata(k).spectra = reshape(mcadata(k).spectra(:, sortorder), MCA_channels, px_per_line, nlines);
        mcadata(k).realtime = reshape(mcadata(k).realtime(sortorder), px_per_line, nlines);
        mcadata(k).livetime = reshape(mcadata(k).livetime(sortorder), px_per_line, nlines);
        mcadata(k).triggers = reshape(mcadata(k).triggers(sortorder), px_per_line, nlines);
        mcadata(k).output_evts = reshape(mcadata(k).output_evts(sortorder), px_per_line, nlines);
        mcadata(k).bad_times = reshape(mcadata(k).bad_times(sortorder), px_per_line, nlines);
        mcadata(k).bad_trigs = reshape(mcadata(k).bad_trigs(sortorder), px_per_line, nlines);
    end
elseif do_reshape
    for k=1:nchannels
        mcadata(k).spectra = reshape(mcadata(k).spectra, MCA_channels, px_per_line, nlines);
        mcadata(k).realtime = reshape(mcadata(k).realtime, px_per_line, nlines);
        mcadata(k).livetime = reshape(mcadata(k).livetime, px_per_line, nlines);
        mcadata(k).triggers = reshape(mcadata(k).triggers, px_per_line, nlines);
        mcadata(k).output_evts = reshape(mcadata(k).output_evts, px_per_line, nlines);
        mcadata(k).bad_times = reshape(mcadata(k).bad_times, px_per_line, nlines);
        mcadata(k).bad_trigs = reshape(mcadata(k).bad_trigs, px_per_line, nlines);
    end
end

%%Evaluate/act on bad real/livetime
bad_times = false(size(mcadata(1).bad_times));
bad_trigs = false(size(bad_times));
bad_lines = false(size(any(bad_times))); %  should be 1 x nlines

for k = 1:nchannels
   bad_times = bad_times | mcadata(k).bad_times; 
   bad_trigs = bad_trigs | mcadata(k).bad_trigs;
   bad_pixels = mcadata(k).bad_times | mcadata(k).bad_trigs;
   bad_lines = bad_lines | any(bad_pixels);
end
if do_reshape 
    nbadt = sum(bad_times(:));
    if nbadt > 0
        fprintf(['Found %d pixels with bad time stats (zero real or livetime)\n' ...
            '\tand %d pixels with bad input output trigs, together affecting %d lines\n'], ...
            nbadt, sum(bad_trigs(:)), sum(bad_lines(:)));
    end
end
% calc ICR, OCR
for k=1:nchannels
    mcadata(k).icr = single(mcadata(k).triggers)./single(mcadata(k).livetime) ;
    mcadata(k).ocr = single(mcadata(k).output_evts)./single(mcadata(k).realtime);
    these_bad_pix = mcadata(k).bad_times | mcadata(k).bad_trigs;
    if any(any(these_bad_pix))
        if ~no_output
            fprintf('Forcing %d bad pixels in MCA %d to their averagein good pixels\n', ...
                sum(these_bad_pix(:)), k);
        end
        mcadata(k).icr(these_bad_pix) = ...
            mean(mean(mcadata(k).icr(~these_bad_pix)));
        mcadata(k).ocr(these_bad_pix) = ...
            mean(mean(mcadata(k).ocr(~these_bad_pix)));
    end
    mcadata(k).mean_dt = mean(mean(mcadata(k).icr./mcadata(k).ocr));
    if ~no_output
        fprintf('Mean icr/ocr for MCA %d is %f\n', k, mcadata(k).mean_dt);
    end
end