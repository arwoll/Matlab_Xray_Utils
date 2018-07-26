function mcadata = xmap_read_tiff(mcafiles, varargin)
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


mcadata = [];
mcapath = '';
sortorder = [];
do_reshape = 1;
onechannel = 0;   % 0 means all, 1-4 means single

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
tic
npx_found = 0;
for nline = FIRST_LINE:LAST_LINE
%for nline = 1:nlines
    if mod(nline,10) == 0 && nline > FIRST_LINE
        fprintf('Time-per-group: %.1f sec: Starting line %d of %d\n', toc, nline, LAST_LINE);
        tic
    end
    % GOTCHA 1: LENGTH IS EITHER A STRING OR CELL 
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
        if nfile == 1
            det_channels = a(21:24);
            nchannels = sum(det_channels>0);
            MCA_channels = det_channels(1);
            if any(det_channels ~= MCA_channels)
                fprintf('Error in xmap_read_tiff: channels/detector are not identical\n');
                return
            end
            if onechannel > nchannels
                fprintf('Warning; requested non-existant channel %d of %d -- trying all\n',...
                    onechannel, nchannels);
                onechannel=0;
            end
            if onechannel
                nchannels = 1;
            end
            if nline == FIRST_LINE 
                px_first_file = npx_this_file;
                files_per_line = nfiles;
                if onechannel
                    % assume all channels are the same size (probably 2048)
                    ch_size =  double(c(9)) + double(bitshift(c(10), 16));
                    pixel_indices = [1:256 256+(onechannel-1)*ch_size+1:256+onechannel*ch_size]';
                else
                    pixel_indices = (1:pixel_size)';
                end
                nkeep = length(pixel_indices);
                data_line = zeros(pixel_size, px_first_file, files_per_line, 'uint16');
            else
                data_line = reshape(data_line, pixel_size, px_first_file, files_per_line);
            end
        elseif npx_this_file > px_first_file
            fprintf(['Error in xmap_read_tiff: cannot handle case where the first file\n' ...
                '\tin a line has fewer spectra than a subsequent file on the same line\n']);
            return
        end
        data_line(:, 1:npx_this_file, nfile) = double(reshape(c(1:pixel_size*npx_this_file),...
            pixel_size, npx_this_file));
        npx_this_line = npx_this_line + npx_this_file;
    end
    % Done with line. Now, create an array for all blocks in scan.
    if nline == FIRST_LINE
        px_per_line = npx_this_line;
        npx_expected = nlines*px_per_line;
        % We now know how many lines and how many pixels per line, so can initialize the master arrays
        try
            data_scan = zeros(nkeep, px_per_line, nlines, 'uint16');
        catch
            fprintf('Error in map_read_tiff: insufficient memory. Try one detetor or a subset of lines?\n');
            return
        end
    end
    try
        data_line = reshape(data_line, pixel_size, px_first_file*files_per_line);
    catch
        fprintf('Error on reshape(data_line...)\n');
    end
    data_scan(:,1:npx_this_line, nline-FIRST_LINE+1) = data_line(pixel_indices, 1:npx_this_line);
    npx_found = npx_found + npx_this_line;
end
toc;

clear data_line c a;

fprintf('Expecting %d points/spectra, found %d.\n', npx_expected, npx_found);
data_scan = reshape(data_scan, nkeep, npx_expected);

for j = 1:nchannels
    spectrum_offset = 256+(j-1)*MCA_channels;
    mcadata(j).spectra = data_scan(spectrum_offset+1:spectrum_offset+MCA_channels,:);
    stats_offset = (j-1)*8+32;
    mcadata(j).realtime = uint32(data_scan(stats_offset+1, :)) + ...
        uint32(bitshift(data_scan(stats_offset+2,:), 16));
    mcadata(j).livetime = uint32(data_scan(stats_offset+3, :)) + ...
        uint32(bitshift(data_scan(stats_offset+4,:), 16));
    mcadata(j).triggers = uint32(data_scan(stats_offset+5, :)) + ...
        uint32(bitshift(data_scan(stats_offset+6,:), 16));
    mcadata(j).output_evts = uint32(data_scan(stats_offset+7, :)) + ...
        uint32(bitshift(data_scan(stats_offset+8,:), 16));
end

if ~isempty(sortorder) && do_reshape
    sortorder = sortorder((FIRST_LINE-1)*px_per_line+1:LAST_LINE*px_per_line);
    if FIRST_LINE > 1 
        sortorder = sortorder - sortorder((FIRST_LINE-1)*px_per_line);
    end
    nsort = length(sortorder);
    if nsort ~= npx_expected
       fprintf('We have a problem\n'); 
    end
    for k=1:nchannels
        mcadata(k).spectra = reshape(mcadata(k).spectra(:, sortorder), MCA_channels, px_per_line, nlines);
        mcadata(k).realtime = reshape(mcadata(k).realtime(sortorder), px_per_line, nlines);
        mcadata(k).livetime = reshape(mcadata(k).livetime(sortorder), px_per_line, nlines);
        mcadata(k).triggers = reshape(mcadata(k).triggers(sortorder), px_per_line, nlines);
        mcadata(k).output_evts = reshape(mcadata(k).output_evts(sortorder), px_per_line, nlines);
    end
elseif do_reshape
    for k=1:nchannels
        mcadata(k).spectra = reshape(mcadata(k).spectra, MCA_channels, px_per_line, nlines);
        mcadata(k).realtime = reshape(mcadata(k).realtime, px_per_line, nlines);
        mcadata(k).livetime = reshape(mcadata(k).livetime, px_per_line, nlines);
        mcadata(k).triggers = reshape(mcadata(k).triggers, px_per_line, nlines);
        mcadata(k).output_evts = reshape(mcadata(k).output_evts, px_per_line, nlines);
    end
end

% calc ICR, OCR
for k=1:nchannels
    mcadata(k).icr = single(mcadata(k).triggers)./single(mcadata(k).livetime) ;
    mcadata(k).ocr = single(mcadata(k).output_evts)./single(mcadata(k).realtime);
end