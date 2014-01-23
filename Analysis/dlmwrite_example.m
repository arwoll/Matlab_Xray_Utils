%% dlmwrite example 

fullmtxfile = fullfile(mcapath, strrep(matfile, '.mat', '_array.txt'));
if save_choice
    f = fopen(fullmtxfile, 'wt');
    fprintf(f, '# Raw Data from Diode Array : 640 rows, one column per point in scan\n');
    fprintf(f, ['# Scan variable ' scandata.spec.mot1 ' listed below\n']);
    fprintf(f, ['# '  sprintf('%5.3f\t', scandata.spec.var1) '\n']);
    fclose(f);
    outvar = double(scandata.mcadata);
    dlmwrite(fullmtxfile,outvar, 'delimiter', '\t', 'precision', '%d', '-append');
end