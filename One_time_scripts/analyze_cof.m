function [cen, fwhm] = analyze_cof(fname)
% function [cen, fwhm] = analyze_cof(fname) analyze a PXRD scan of COF5
% powder and find the fwhm of the 100 peak using find_peak (or,
% alternatively, a gaussian peak) but implmenting background subtraction
%
% This version looks at mat files, and based on a prior version locaed in 
% Dichtel/Writing/2_hour_control_JWC-1-272
% 
cen = -1; fwhm = 0;

pxra = 598:607;
lh_bk_pix = 1;
rh_bk_pix = 5;

a =  whos('-file', fname);
if ~strcmp(a.name, 'scandata')
    fprintf('Cannot process %s\n...skipping\n', fname);
    return
end

load(fname);

if ~strcmp(scandata.spec.mot1, 'nu')
    fprintf('%s\n... is not a nu scan ... skipping\n', fname);
    return
end

im = scandata.mcadata;
y_raw = double(sum(im(pxra, :), 1)');
th_raw = double(scandata.spec.var1);

roi = th_raw<3.5;
th = th_raw(roi);
y = y_raw(roi);

rh_bk = length(y)-rh_bk_pix:length(y);
bk = [1:lh_bk_pix rh_bk];

pd = find_peak(th, y, 'mode', 'lin', 'back', bk);

h = figure(20); clf;
plot(th, y, 'b.-', th, pd.bkgd, 'r-', 'linewidth', 1.5);
ann_str = sprintf('%s\nFWHM = %.2f', fname, pd.fwhm);
ann_str = strrep(ann_str, '_', '\_');
text(.45, .9, ann_str, 'units', 'normalized');
cen = pd.com; fwhm = pd.fwhm;

user_ent = input('Accept (n or N to reject)? ', 's');
if any(strcmp(user_ent, {'n', 'N'}))
    cen=-1;
    return
end

if 1
    [p, n, e] = fileparts(fname);
    outname = strrep(fname, e, '.eps');
    set(h, 'PaperPositionMode', 'auto');
    fig_str = sprintf('-f%d',h);
    if ~exist(outname, 'file')
        print(fig_str,'-depsc2','-r300', '-painters', ...
            fullfile(outname));
    end
    
end
