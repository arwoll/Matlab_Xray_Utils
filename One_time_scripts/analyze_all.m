txtfiles = dir('*.mat');
write_sum = 1;
if write_sum
    fid = fopen('FWHM_Summary.txt', 'wt');
else
    fid = 1;
end
fprintf(fid, 'Filename   :   FWHM\n');
for k = 1:length(txtfiles)
    [c, f] = analyze_cof(txtfiles(k).name);
    if c<0
        continue
    end
    fprintf(fid, '%s : %.2f\n', txtfiles(k).name, f);
    %pause
end

if write_sum
    fclose(fid);
end

%%
txtfiles(63).name