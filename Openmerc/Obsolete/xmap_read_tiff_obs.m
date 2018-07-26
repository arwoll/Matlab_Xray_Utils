function mcadata = xmap_read_tiff(mcafiles, varargin)
% function mcadata = xmap_read_tiff(mcafiles, varargin)
% Read a group of mcafiles assumed to be associated with a particular scan
% line, and stuff the data into a structure array mcadata, where:
%     mcadata(n) has fields spectra, realtime, livetime, triggers, and
%     output_evts, each with dimensions MCA_channels x npixels, where npixels is
%     envisioned as the number of spectra/points per line
%
% OK: make arrays for each file and concatenate them afterwords.
%
% for testing, construct an input cell structure like so:
% testf{1} = {'deg70111-2_eveXMAP_007_158_000.tiff', 'deg70111-2_eveXMAP_007_158_001.tiff'}
% The following line was for testing with a test cell array above 
% mcafiles = mcafiles{1};
%
% ToDo:
%    * Add optional "order" and reshape arguments to perform ordering and
%      reshaping here. (reshaping should probably default to yes.
%    * Calculate & store ICR (triggers*realtime?) and OCR (output_evts*livetime?).
%    * edit openxmap to reflect changes here...
%    * check ICR/OCR calc & add dead time line.
%
%    * Note that realtime appears to be based on about a 322 ns / 3.11 MHz
%    clock. I might have seen a note stating that this is the decimation
%    time, the sampling interval times the samples / digital measurement.

nvarargin = nargin -1;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to xmap_read_tiff must come in variable/value pairs');
    return
end

mcapath = '';
sortorder = [];
do_reshape = 1;

% Also considering an order parameter, so that ordering (and reshaping!)
% could happen here. 
for k = 1:2:nvarargin
    switch varargin{k}
        case 'path'
            mcapath = varargin{k+1};
        case 'order'
            sortorder = varargin{k+1};
        case 'reshape'
            do_reshape = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end   

MAX_NLINES = 200;
nlines = length(mcafiles);
if nlines > MAX_NLINES
    nlines = MAX_NLINES;
end
for nline = 1:nlines
    if mod(nline,10) == 0
        fprintf('Starting line %d of %d\n', nline, nlines);
    end
    nfiles = length(mcafiles{nline});
    npx_this_line = 0;
    for nfile = 1:nfiles
        a = imread(fullfile(mcapath, mcafiles{nline}{nfile}));
        MCA_channels = a(21);
        npx_this_file = double(a(9));
        c = a(257:end);  % From start of first pixel buffer
        %fprintf('Found %d spectra in file %s\n', npx_this_file , mcafiles{nline}{nfile});
        pixel_size = double(c(7)) + double(bitshift(c(8), 16));
        if nfile == 1
            px_per_file = npx_this_file;
            data_line = zeros(pixel_size, px_per_file, nfiles, 'uint16');
        elseif npx_this_file > px_per_file
            fprintf(['Error in xmap_read_tiff: cannot handle case where the first file\n' ...
                '\tin a line has fewer spectra than a subsequent file on the same line\n']);
            return
        end
        data_line(:, 1:npx_this_file, nfile) = double(reshape(c(1:pixel_size*npx_this_file),pixel_size, npx_this_file));
        npx_this_line = npx_this_line + npx_this_file;
    end
    % Done with line. Now, create an array for all blocks in scan.
    if nline == 1
        px_per_line = npx_this_line;
       % We now know how many lines and how many pixels per line, so can initialize the master arrays 
       data_scan = zeros(pixel_size, px_per_line, nlines, 'uint16');
    end
    data_line = reshape(data_line, pixel_size, px_per_file*nfiles);
    data_scan(:,1:npx_this_line, nline) = data_line(:, 1:npx_this_line);
end

clear data_line;
nspectra = nlines*px_per_line;
data_scan = reshape(data_scan, pixel_size, nspectra);

% make a temporary matfile to access as a file
% mfilename = 'tmp.mat';
% fprintf('Saving mcadata as matfile %s to access on disk\n', mfilename);
% tic
% save(mfilename, 'data_scan');
% fprintf('save file: %g seconds\n', toc);
% clear data_scan
% data_scan = matfile(mfilename, 'Writeable', 'False');

for j = 1:4
    spectrum_offset = 256+(j-1)*MCA_channels;
    mcadata(j).spectra = data_scan(spectrum_offset+1:spectrum_offset+MCA_channels,:);
    stats_offset = (j-1)*8+32;
    mcadata(j).realtime = uint32(data_scan(stats_offset+1, :)) + uint32(bitshift(data_scan(stats_offset+2,:), 16));
    mcadata(j).livetime = uint32(data_scan(stats_offset+3, :)) + uint32(bitshift(data_scan(stats_offset+4,:), 16));
    mcadata(j).triggers = uint32(data_scan(stats_offset+5, :)) + uint32(bitshift(data_scan(stats_offset+6,:), 16));
    mcadata(j).output_evts = uint32(data_scan(stats_offset+7, :)) + uint32(bitshift(data_scan(stats_offset+8,:), 16));
end

if ~isempty(sortorder) && do_reshape
    if length(sortorder) > nspectra
        sortorder = sortorder(1:nspectra);
    end
    for k=1:4
        mcadata(k).spectra = reshape(mcadata(k).spectra(:, sortorder), MCA_channels, px_per_line, nlines);
        mcadata(k).realtime = reshape(mcadata(k).realtime(sortorder), px_per_line, nlines);
        mcadata(k).livetime = reshape(mcadata(k).livetime(sortorder), px_per_line, nlines);
        mcadata(k).triggers = reshape(mcadata(k).triggers(sortorder), px_per_line, nlines);
        mcadata(k).output_evts = reshape(mcadata(k).output_evts(sortorder), px_per_line, nlines);
    end
elseif do_reshape
    for k=1:4
        mcadata(k).spectra = reshape(mcadata(k).spectra, MCA_channels, px_per_line, nlines);
        mcadata(k).realtime = reshape(mcadata(k).realtime, px_per_line, nlines);
        mcadata(k).livetime = reshape(mcadata(k).livetime, px_per_line, nlines);
        mcadata(k).triggers = reshape(mcadata(k).triggers, px_per_line, nlines);
        mcadata(k).output_evts = reshape(mcadata(k).output_evts, px_per_line, nlines);
    end
end

% calc ICR, OCR
for k=1:4
    mcadata(k).icr = single(mcadata(k).triggers)./single(mcadata(k).livetime) ;
    mcadata(k).ocr = single(mcadata(k).output_evts)./single(mcadata(k).realtime);
end