function  [scandata, errors] = open_id20_mda(mdafilename)
% function [scandata, errors] = open_id20_mda(mdafile)
% Parses ascii files created from *.mda data files (an EPICS-native format)
% by the mda2ascii utility.

%tic
%h = msgbox('Loading MCA data, please wait...(patiently)', 'Open', 'warn');

[mcapath, mcaname, extn] = fileparts(mdafilename);

%% Initialization
errors.code = 0;
% Initialize scandata structure and spec substructures:
spec = struct('data', [],'scann',1,'scanline', '', 'npts', [],...
    'columns', 0,'headers',{{}},'motor_names',{{}},'motor_positions', [],...
    'cttime', [],'complete',1,'ctrs',{{}},'mot1','', 'var1',[],...
    'dims', 1,'size', []);

scandata = struct('spec', spec, 'mcadata',[], 'mcaformat', 'id20_mda', 'dead', struct('key',''), ...
    'depth', [], 'channels', [], 'mcafile', [mcaname extn], 'ecal', [], 'energy', [], ...
    'specfile',[mcaname extn], 'dtcorr', [], 'dtdel', [], 'image', {{}});


mdafile = fopen(mdafilename, 'r');
if mdafile == -1
    errors = add_error(errors, 1, sprintf('Error: spec file %s not found',...
        mdafilename));
    return
end

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
    scandata.spec.scann = sscanf(nextline, '%d');
end

%---------------------------------------------%
%------------ Get scan dimensions ------------%
%---------------------------------------------%
nextline = find_id20_mdaline(mdafile, 'Overall scan dimension =');
if ischar(nextline)
    if strcmp(nextline, '2-D')
        scandata.spec.dims = 1;
    elseif strcmp(nextline, '3-D')
        scandata.spec.dims = 2;
    end
end

%---------------------------------------------%
%----- Get scan sizes in each dimension ------%
%---------------------------------------------%
nextline = find_id20_mdaline(mdafile, 'Total requested scan size =');
if ischar(nextline)
    if scandata.spec.dims == 1
        dims = sscanf(nextline, '%d x %d');
        scandata.spec.size = dims(1);
        scandata.channels = dims(2);
    else
        dims = sscanf(nextline, '%d x %d x %d');
        scandata.spec.size = dims(1:2)';
        scandata.channels = dims(3);
    end
end

%---------------------------------------------%
%-------------- Get count time ---------------%
%---------------------------------------------%
% Note: Fight arbitrary formats with non-general read routines.
nextline = find_id20_mdaline(mdafile, 'Extra PV:');
if ischar(nextline)
    nextline = find_id20_mdaline(mdafile, '');
    while ~isempty(strfind(nextline, 'Extra PV'))
        pv_info = textscan(nextline, 'Extra PV %d: %s %s %q', 'delimiter', ',');
        if strcmp(pv_info{2}{1}, '20id:scaler1.TP')
            scandata.spec.cttime = str2num(pv_info{4}{1});
            break
        end
        nextline = find_id20_mdaline(mdafile, '');
    end
end

% Parse headers

nextline = find_id20_mdaline(mdafile, 'Column Descriptions');
nextline = fgetl(mdafile); % index
nextline = find_id20_mdaline(mdafile, '');
headers = cell(1,100);
nheaders = 0;
while strcmp(nextline, {'Positioner', 'Detector'})
    nheaders = nheaders + 1;
    column_info = textscan(nextline, '%s', 'delimiter', ',]')
    headers{nheaders} = column_info{1}{2};
    nextline = find_id20_mdaline(mdafile, '');
end

scandata.spec.headers = headers(1:nheaders);


% Parse mot1, (mot2), var1, (var2), columns,





% full scandata:
%          spec: [1x1 struct]
%       mcadata: [1024x51x21 single]
%     mcaformat: 'chess1'
%          dead: [1x1 struct]
%         depth: [1x1071 double]
%      channels: [1024x1 double]
%       mcafile: 'teniers5_34.mca'
%          ecal: [-0.4681 0.0199 8.8771e-08]
%        energy: [1024x1 double]
%      specfile: 'teniers5'
%        dtcorr: [51x21 single]
%         dtdel: [51x21 single]
%         image: {1x21 cell}


% scandata.spec
% ans = 
%                data: [10x51x21 double]
%               scann: 34
%            scanline: 'smesh  scany 33.2 33.6 -0.05 0.25 50  scanz 294.3 274.3 20  2'
%                npts: 1071
%             columns: 10
%             headers: {1x10 cell}
%         motor_names: {1x58 cell}
%     motor_positions: [1x58 double]
%              cttime: 2
%            complete: 1
%                ctrs: {'sec'  'Itot'  'Iprot'  'mca'  'CESR'  'Imon'  'Idet'}
%                mot2: 'scanz'
%                mot1: 'scany'
%                var1: [51x21 double]
%                var2: [51x21 double]
%                dims: 2
%                size: [51 21]