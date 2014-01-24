function N = gid_spec2mat(fname, scans)
% function N = gid_spec2mat(fname, scans) 
%   sequentially reads the scan numbers in the vector "scans" and processes
%   them as done by gidview. That is, it reads the scan in and saves .mat,
%   _scan.txt, and _array.txt files for that scan.
%
%   If scans = [] (isempty(scans) = True), 
%      process scans from scan #1 until a scan is not found

N = 0;
dead_struct.key = 'no_dtcorr';
while 1
    if isempty(scans)
        scann = N+1;
    else
        if N+1 > length(scans)
            break
        end
        scann = scans(N+1);
    end
    fprintf('Processing scan %d...', scann);
    [sd, errors] = openmca(fname, 'scan', scann, 'mcaformat', 'spec', ...
        'dead', dead_struct);
    switch errors.code
        case 0
            fprintf('Done\n'); 
            N = N +1;
        case 1
            fprintf('Scan not found or other fatal error\n');
            break;
        case 2
            fprintf('Scan found but incomplete or other non-fatal error\n');
            N = N+1;
    end
end
