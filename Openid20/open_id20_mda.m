function  [mdadata, errors] = open_id20_mda(mdafilename)
% function [scandata, errors] = open_id20_mda(mdafile)
% Parses ascii files (*.asc) created from *.mda data files (an EPICS-native format)
% by the mda2ascii utility.

%tic
%h = msgbox('Loading MCA data, please wait...(patiently)', 'Open', 'warn');

[mcapath, mcaname, extn] = fileparts(mdafilename);

%% Initialization
errors.code = 0; 

mdadata = struct('mcafile', '', 'mcadata', [], 'mdascann', 1, 'dims', 1, 'size', [], 'channels', 1);

mdafile = fopen(mdafilename, 'r');
if mdafile == -1
    errors = add_error(errors, 1, sprintf('Error: spec file %s not found',...
        mdafilename));
    return
end

mdadata.mcafile = mdafilename;

%---------------------------------------------%
%---------- CHECK mda2ascii version ----------%
%---------------------------------------------%
nextline = fgetl(mdafile);
if ~strfind(nextline, 'mda2ascii')
    errors = add_error(errors,1 , 'Error: first line of file does not contain ''mda2ascii'' identifier');
    return
elseif ~strfind(nextline, '1.3.0')
    errors = add_error(errors, 2, 'Warning: mda2ascii version is not 1.3.0: results may vary');
end

%---------------------------------------------%
%-------------- Get scan number --------------%
%---------------------------------------------%
nextline = find_id20_mdaline(mdafile, 'Scan number =');
if ischar(nextline)
    mdadata.mdascann = sscanf(nextline, '%d');
end

%---------------------------------------------%
%------------ Get scan dimensions ------------%
%---------------------------------------------%
nextline = find_id20_mdaline(mdafile, 'Overall scan dimension =');
if ischar(nextline)
    if strcmp(nextline, '2-D')
        mdadata.dims = 1;
    elseif strcmp(nextline, '3-D')
        mdadata.dims = 2;
    end
end

%---------------------------------------------%
%----- Get scan sizes in each dimension ------%
%---------------------------------------------%
nextline = find_id20_mdaline(mdafile, 'Total requested scan size =');
if ischar(nextline)
    if mdadata.dims == 1
        dims = sscanf(nextline, '%d x %d');
        mdadata.size = double(dims(1));
        MCA_channels = double(dims(2));
    else
        dims = sscanf(nextline, '%d x %d x %d');
        mdadata.size = double(dims([2 1])');
        MCA_channels = double(dims(3));
    end
end

mdadata.channels = MCA_channels;

spectra = prod(mdadata.size);
mdadata.mcadata = zeros(mdadata.channels, spectra);
nextline = find_id20_mdaline(mdafile, '1-D Scan Values');
k = 0;
while ischar(nextline) && k < spectra
    k=k+1;
    foo = textscan(mdafile, '%*d%u16');
    if length(foo{1}) == mdadata.channels
        mdadata.mcadata(:,k) = foo{1};
    else
        errors = add_error(errors, 1, ...
            sprintf('Error: mdafile format error? wrong number of spectra in file %s',...
            mdafilename));
    end
    nextline = find_id20_mdaline(mdafile, '1-D Scan Values');
end

if mdadata.dims == 2
    mdadata.mcadata = reshape(mdadata.mcadata, MCA_channels, ...
        mdadata.size(1), mdadata.size(2));
end
