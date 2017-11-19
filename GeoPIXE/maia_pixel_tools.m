% Tools to analyze and map individual pixel intensies -- originally for Compton analysis
% place elastic and compton peak areas into a 2D array representing the
% detector locations...

elastic_2D = zeros(20, 20);
elastic_com_2D = elastic_2D;
compton_2D  = zeros(20, 20);
compton_pos_2D = zeros(20,20);
compton_fwhm_2D = compton_pos_2D;
detN = NaN(20, 20);
for k=1:length(col_labels)
    this_detN = col_labels(k);
    this_detN_ind = k;
    %fprintf('detN = %d\n', detN);
    det_col = str2double(det_struct(this_detN+1).Column) + 1;
    det_row = str2double(det_struct(this_detN+1).Row)    + 1;

    detN(det_col, det_row) = this_detN;
    detN_ind(det_col, det_row) = this_detN_ind;
    elastic_2D(det_col, det_row) = elastic.area(k);
    elastic_com_2D(det_col, det_row) = elastic.com(k);
    compton_2D(det_col, det_row) = compton.area(k);
    compton_pos_2D(det_col, det_row) = compton.com(k);
    compton_fwhm_2D(det_col, det_row) = compton.fwhm(k);
end

%% Refine Energy calibration for every spectrum using Mo Ka, Kb, and Elastic
moka1 = 17.479; moka2 = 17.375; moka1i = 0.551; moka2i = 0.289;
moka = (moka1*moka1i + moka2*moka2i)/(moka1i + moka2i);

%%
%plot(E_elastic, elastic_spec(:,2))

% Algorithm:
% Loop through spectra:
%    - Find channel positions for elastic, Mo Ka and Mo Kb. Either with
%      find_peak or a combination of find_peak and gauss_fit
%    - refine the energy calibration using a polyfit of centrois (channel)
%    to known energies.
E_2D_new = E_2D;
E_ranges = [16.5 18.5; 18.5 20.5; 29.5 31.5];
E_labels = {'MoKa', 'MoKb', 'E0'};
E_centers_th = [17.443 19.608 30.5]';
E_centers_m = zeros(3,1);
chan_centers = zeros(3,1);
chans = [0:4094]';
for k = 1:size(spectra,2)
    spectrum = spectra(:,k);
    E_spec = E_2D(:, k);
    for j = 1:3
        E_low = E_ranges(j,1);
        E_high = E_ranges(j,2);
        indices = E_spec > E_low & E_spec < E_high;
        offset = find(indices, 1);
        p = find_peak(E_spec(indices), spectrum(indices));
        chan_centers(j) = p.ch_com + offset - 1;
        E_centers_m(j) = p.com;
    end
%    fprintf('Spectrum %d:  Es (%.1f, %.1f, %.1f) found at chans (%.1f, %.1f, %.1f)\n', ...
%        k, E_centers_m(1), E_centers_m(2), E_centers_m(3) ...
%        , chan_centers(1), chan_centers(2), chan_centers(3));
    newcal = fit(chan_centers, E_centers_th, 'poly2');
    E_2D_new(:, k) = newcal(chans);
end
fprintf('Done -- E_2D_new is ready\n');

%% (re)-populate compton * elastic
E_ranges = [25 29.5; 29.5 31.5];
E_labels = {'Compton', 'E0'};
n_spectra = size(spectra, 2);
peak_data = struct('com', zeros(n_spectra, 1),...
    'fwhm', zeros(n_spectra, 1), 'area', zeros(n_spectra, 1));
for k = 1:n_spectra
    spectrum = spectra(:,k);
    E_spec = E_2D_new(:, k);
    for j = 1:2
        E_low = E_ranges(j,1);
        E_high = E_ranges(j,2);
        indices = E_spec > E_low & E_spec < E_high;
        offset = find(indices, 1);
        p = find_peak(E_spec(indices), spectrum(indices));
        peak_data(j).com(k) = p.com;
        peak_data(j).area(k) = p.area;
        peak_data(j).fwhm(k) = p.fwhm;
    end
%    fprintf('Spectrum %d:  Es (%.1f, %.1f, %.1f) found at chans (%.1f, %.1f, %.1f)\n', ...
%        k, E_centers_m(1), E_centers_m(2), E_centers_m(3) ...
%        , chan_centers(1), chan_centers(2), chan_centers(3));
end
elastic = peak_data(2);
compton = peak_data(1);



%% Construct E_2D
n_spectra = 4095;
n_pix = 373;
E_2D = zeros(n_spectra, n_pix);
chans = 0:(n_spectra-1);
for k = 1:373
   E_2D(:, k) = CalB(k) + chans*CalA(k); 
end

%%
% Plotting
for k=1:373
    plot(E_2D_new(:,k), spectra(:, k)) 
    axis([29.5 31.5 0 200])
    title(['Frame : ' num2str(k)])
    pause
end

%% Plotting all spectra with a surface plot
 surf(chans_2D, E_2D_new, log(spectra+1), 'LineStyle', 'none'); view(0, 90); axis([0 384 0 32])
title ('Al110 spectra: detN vs. energy')
xlabel('Detector Number')
ylabel('Energy (keV)')
%%

%imagesc(elastic_2D, [10 200]); axis equal tight; colormap(yarg); title('Elastic Integrated Intensity')
imagesc(compton_pos_2D, [27.1 28]); axis equal tight; colormap(yarg); title('Compton Peak Position')
%imagesc(compton_fwhm_2D,[.5 1.1]); axis equal tight; colormap(yarg); title('Compton FWHM')
%imagesc(compton_2D); axis equal tight; colormap(yarg); title('Integrated Compton Intensity')


%% Make and export data to a text file for Jacob
Column_labels = 'Col   Row   E (eV)   Counts   detN   width (um)   height(um)    X(um)  Y(um)';
n_chans = 4095; n_spectra = 373; n_cols = 9;
output_var = zeros(n_chans*n_spectra, n_cols);
out_row = 0;
for rown = 1:20;
    for coln = 1:20
        if isnan(detN(coln, rown))
            continue
        end
        this_detN_ind = detN_ind(coln, rown);
        for chann = 1:4095
            out_row = out_row + 1;
            output_var(out_row, :) = [coln   rown   1000*E_2D_new(chann, this_detN_ind) ...
                spectra(chann, this_detN_ind)  detN(coln, rown) 1000*str2double(det_struct(this_detN_ind).width) ...
                1000*str2double(det_struct(this_detN_ind).height) ...
                1000*det_struct(this_detN_ind).X 1000*det_struct(this_detN_ind).Y];
        end
    end
end

%%
tic
spectra_outfile = 'al110_6943_all_spectra.txt';
f = fopen(spectra_outfile, 'wt');
fprintf(f, '# Calibrated spectra from each detector pixel\n');
fprintf(f, ['#' Column_labels '\n']);
fclose(f);
dlmwrite(spectra_outfile,output_var, 'delimiter', '\t', 'precision', '%d', '-append');
toc

