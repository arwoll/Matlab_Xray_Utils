function make_txt_from_mat
matfiles = dir('*.mat');
for k = 1:length(matfiles)
    matfile = matfiles(k).name;
    vars = whos('-file', matfile);
    if length(vars) ~= 1 || ~strcmp(vars.name, 'scandata')
        continue
    end
    
    fprintf('Processing %s\n', matfile);
    load(matfile);
    
    fullmtxfile = strrep(matfile, '.mat', '_array.txt');
    if exist(fullmtxfile, 'file')
        continue
    end
    
        f = fopen(fullmtxfile, 'wt');
    fprintf(f, '# Raw Data from Diode Array : 640 rows, one column per point in scan\n');
    fprintf(f, '#S %d  %s\n', scandata.spec.scann, scandata.spec.scanline);
    fprintf(f, '# Delta CALIB A   B   C = %g %g %g\n', scandata.spec.ecal(1), ...
        scandata.spec.ecal(2), scandata.spec.ecal(3));
    fprintf(f, '# Counter I2 listed below\n');
    fprintf(f, ['# '  sprintf('%d\t', ...
        scandata.spec.data(strcmp(scandata.spec.headers, 'I2'), :))  '\n']);
    fprintf(f, ['# Scan variable ' scandata.spec.mot1 ' listed below\n']);
    fprintf(f, ['# '  sprintf('%5.3f\t', scandata.spec.var1) '\n']);
    fclose(f);
    outvar = double(scandata.mcadata);
    dlmwrite(fullmtxfile,outvar, 'delimiter', '\t', 'precision', '%d', '-append');

%   ORIGINAL
%     f = fopen(fullmtxfile, 'wt');
%     fprintf(f, '# Raw Data from Diode Array : 640 rows, one column per point in scan\n');
%     fprintf(f, ['# Scan variable ' scandata.spec.mot1 ' listed below\n']);
%     fprintf(f, ['# '  sprintf('%5.3f\t', scandata.spec.var1) '\n']);
%     fclose(f);
%     outvar = double(scandata.mcadata);
%     dlmwrite(fullmtxfile,outvar, 'delimiter', '\t', 'precision', '%d',
%     '-append');

    fullscanfile = strrep(matfile, '.mat', '_scan.txt');
    if exist(fullscanfile, 'file')
        continue
    end

    f = fopen(fullscanfile, 'wt');
    fprintf(f, '# Spec Data : Column headers on next line \n');
    fprintf(f, ['# '  sprintf( '%s\t', scandata.spec.headers{:}) '\n']);
    fclose(f);
    outvar = double(scandata.spec.data)';
    dlmwrite(fullscanfile,outvar, 'delimiter', '\t', 'precision', '%g', '-append');

%     f = fopen(fullscanfile, 'wt');
%     fprintf(f, '# Spec Data : Column headers on next line \n');
%     fprintf(f, ['# '  sprintf( '%s\t', scandata.spec.headers{:}) '\n']);
%     fclose(f);
%     outvar = double(scandata.spec.data)';
%     dlmwrite(fullscanfile,outvar, 'delimiter', '\t', 'precision', '%g', '-append'); 
end