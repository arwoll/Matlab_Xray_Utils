function mcadata = xmap_read_tiff_v2(mcafiles)
% function mcadata = xmap_read_tiff(mcafiles)
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
%

% Not sure if I need this but for the moment:
mcafiles = mcafiles{1};
nlines = length(mcafiles);

for nline = 1% :nlines
    nfiles = length(mcafiles{nline});
    npx_line = 0;
    for nfile = 1:nfiles
        a = imread(mcafiles{nline}{nfile});
        MCA_channels = a(21);
        npx_file = double(a(9));
        c = a(257:end);  % From start of first pixel buffer
        fprintf('Found %d spectra in file %s\n', npx_file , mcafiles{nline}{nfile});
        pixel_size = double(c(7)) + double(bitshift(c(8), 16));
        if nfile == 1
            npx_first = npx_file;
            data_line = zeros(pixel_size, npx_first, nfiles);
        elseif npx_file > npx_file
            fprintf(['Error in xmap_read_tiff: cannot handle case where the first file\n' ...
                '\tin a line has fewer spectra than a subsequent file on the same line\n']);
            return
        end
        data_line(:, 1:npx_file, nfile) = double(reshape(c(1:pixel_size*npx_file),pixel_size, npx_file));
        npx_line = npx_line + npx_file;
    end
    % Done with line. Now, create an array for all blocks in scan.
    if nline == 1
       % We now know how many lines and how many pixels per line, so can initialize the master arrays 
       data_scan = zeros(pixel_size, npx_line, nlines);
    end
    data_scan(:,1:npx_line, nline) = reshape(data_line, pixel_size, npx_line);
end

data_scan = reshape(data_scan, pixel_size, nlines*npx_line);

for j = 1:4
    spectrum_offset = 256+(j-1)*MCA_channels;
    mcadata(j).spectra = data_scan(spectrum_offset+1:spectrum_offset+MCA_channels,:);
    mcadata(j).realtime = data_scan(spectrum_offset+33, :) + bitshift(data_scan(spectrum_offset+34,:), 16);
    mcadata(j).livetime =data_scan(spectrum_offset+35, :) + bitshift(data_scan(spectrum_offset+36,:), 16);
    mcadata(j).triggers = data_scan(spectrum_offset+37, :) + bitshift(data_scan(spectrum_offset+38,:), 16);
    mcadata(j).output_evts = data_scan(spectrum_offset+39, :) + bitshift(data_scan(spectrum_offset+40,:), 16);
end