function [specscan, errors] = openspec(specfilename, scan_number)
% function [specscan, errors] = openspec(specfilename, scan_number)
%
% March 2010 -- openspec-1.4 : use calls to "grep" to index file. Unclear
% whether this will work on non-*NIX systems...
% 
% March 08 -- openspec-1.3 in ~woll/Matlab/woll_xrf. Add 'hklscan' type.
% Noted something peculiar: The counters seem to be counted wrong -- see
% e.g. ascan case where specscan.ctrs = headers(3:end); Shouldn't this be
% 2:end?. Also, need to add 'timescan' 
%
% July 07 - openspec-1.2 in ~woll/Matlab/woll_xrf. implement 'fastmesh' loading used
% for July 07 CXRF run.  It is a serpentine mesh scan with a variable number of
% points per line. (should also work for szoom which was not actually implemented
% when s2zoom was written.
%
% June 07 -- openspec-1.1 in ~woll/Chess/Gline/G3/PLD_Apr2007/aw_analysis.  Grab the
% point number for each comment  in scan -- to be used to index laser shots with ccd
% frames...
%
% December 06 -- replaced fgetl() & strtok() in find_line() and find_scan() with
%   textscan() for a performance gain.  Added several MCA field-types, but support
%   for multiple mca data types is not optimized. In part, this awaits a
%   well-defined, unambiguous format. There should probably be a #@MCA_FIELDS line in
%   the scan header that defines, e.g. AMCA, MCS1, MCS2, etc.
%
% NOTE: specscan.motor_names represents the most recently defined motor definitions
%       before the desired scan.
%
% specfilename  = Name of a spec file.
% 
% scan_number   = Desired scan number. 
%
% specscan      = structure containing info about the spec scan
%
% error.code = numerical indication of type
%              of error: 
%              0 = none
%              1 = spec file or scan not found
%              2 = spec scan is incomplete or other non-fatal error.
%               
% error.msg  = Error string
%
% Requires: add_error


% The following regular expression is used to capture individual motor and counter
% names as they appear in spec data files, e.g. on lines beginning #O0.  Distinct
% motor or counter labels begin with an alphanumeric character or '-' and may include
% single spaces between more such characters.  At least two spaces are required to
% separate neighboring names.  (SPEC seems to always follow this rule). The following
% regexp breaks down as follows:
%   [\w-]+ : match  1 or more alphanumeric ([a-zA-Z_0-9]) or dash
%   ( ?    : match 0 or 1 spaces within a token
%   ( ?[\w-]+)* : match 0 or more tokens, where a token is: 0 or 1 spaces
%       followed by 1 or more alphnumberic or dash characters
SPEC_LABEL_REGEXP = '[\w-]+( ?[\w-]+)*';

TIMETEST = 0;

errors.code=0;
specscan = [];

specfile = fopen(specfilename, 'r');
if specfile == -1
    errors = add_error(errors, 1, sprintf('Error: spec file %s not found',...
        specfilename));
    return
end

if TIMETEST; tic; end

% Find the correct scan and abort if not found : openspec-1.4 : fileNAME,
% not handle...
[scanline, scan_mark, motor_mark] = find_scan(specfilename, scan_number);

if TIMETEST; fprintf('Just found scan: '); toc; end
if TIMETEST; tic; end

if ~ischar(scanline)
    errors = add_error(errors, 1, sprintf('Error: scan %d not found in %s\n', ...
        scan_number, specfilename));
    return
end

if motor_mark > -1
    fseek(specfile, motor_mark, -1);
    [tok, nextline] = strtok(fgetl(specfile));
    motor_names = [];
    if ischar(nextline)
        while length(tok)>1 && strcmp(tok(1:2),'#O')
            motor_names = [motor_names regexp(nextline, SPEC_LABEL_REGEXP, 'match')];
            nextline = fgetl(specfile);
            [tok, nextline] = strtok(nextline);
        end
    end
%    motor_names = reshape(motor_names(1:10), 5,2);
end
    
fseek(specfile, scan_mark,-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in motor positions in the same fashion as the motor names
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tok = '#P0';
nextline = find_line(specfile, tok);

motor_positions = [];
if ischar(nextline)
    while length(tok)>1 && strcmp(tok(1:2),'#P')
        motor_positions = [motor_positions sscanf(nextline,'%g')'];
        %mark = ftell(specfile);
        nextline = fgetl(specfile);
        [tok, nextline] = strtok(nextline);
    end

end

if length(motor_names) ~= length(motor_positions)
        errors = add_error(errors,2, sprintf('Warning: Found %d motor names, but %d motor positions.', ...
        length(motor_names), length(motor_positions)));
end

MCA_channels = [];
channels = [];
ecal = [];
while tok(1) =='#'
    if any(strcmp(tok, '#@CHANN'))
        mcachan = textscan(nextline, '%f'); mcachan = mcachan{1};
        MCA_channels = mcachan(1);
        channels = (mcachan(2):mcachan(3))';
    elseif strcmp(tok, '#@CALIB')
        ecalcell = textscan(nextline, '%f'); 
        ecal = ecalcell{1}';
    elseif strcmp(tok, '#L')
        headers = regexp(nextline, SPEC_LABEL_REGEXP, 'match');
        ncolumns = length(headers);
    end
    data_mark = ftell(specfile);
    nextline = fgetl(specfile);
    [tok, nextline] = strtok(nextline);
    if isempty(tok)
        break
    end
end

if TIMETEST; fprintf('Done openpsec front matter:'); toc; end
if TIMETEST; tic; end

fseek(specfile, data_mark,-1);
h = msgbox('Loading Spec data, please wait...(patiently)', 'Open', 'warn');

lines = 0;
data = [];
[data_cell, stop_position] = textscan(specfile, '%f32');
if ~isempty(data_cell{1})
    data = [data' data_cell{1}']';
end

aborts = 0;
stop_position = ftell(specfile);
nextline = fgetl(specfile);
if nextline == -1
    tok = '';
else
    %stop_position = ftell(specfile);
    [tok, nextline] = strtok(nextline);
end

% while length(msgs) >= 8 && strcmp(msgs{1}, '#C')
% Note %f32 converts a float to a single-format floating-point
mcadata = [];
MCA_fields = {};
comments = [];
while any(strcmp(tok, {'#C', '@A', '@AMCA', '@B', '@AMCS1', '@AMCS2'}))
    if strcmp(tok, '#C') 
        if ~isempty(regexp(nextline, 'aborted', 'ONCE'))
            aborts = aborts + 1;
            errors = add_error(errors, 2, nextline);
        else
            comments(end+1).point = length(data);
            comments(end).text = nextline;
        end
    else
        mcadev = find(strcmp(tok(2:end), MCA_fields));
        if isempty(mcadev)
            MCA_fields{end+1} = tok(2:end);
            mcadev = length(MCA_fields);
            if length(MCA_channels)<mcadev
                MCA_channels(mcadev) = 0;
            end
            if mcadev == 1 && ncolumns ~= length(data)
                ncolumns = length(data);
                errors = add_error(errors, 2, sprintf(['Badly formed data file: #L line has %d labels, but \n' ...
                    '%d values were detected in data line'], length(headers), ncolumns));
            end
        end
        if ~MCA_channels(mcadev)
            % MCA data found but NO channel info.  Assume that the data is
            % on a single line.
            fseek(specfile, stop_position+length(tok), -1);
            textline = fgetl(specfile);
            while textline(end) == '\'
                nline = fgetl(specfile);
                if ~ischar(nline)
                    errors = add_error(errors, 1, 'Unexpected end of file...');
                    return
                else
                    textline = [textline nline];
                end
            end
            spectrum = textscan(textline, '%f32', 'whitespace', ' \b\t\\');
            mcadata.(MCA_fields{mcadev}) = spectrum{1};
            MCA_channels(mcadev) = length(mcadata.(MCA_fields{mcadev}));
        elseif ~isfield(mcadata, MCA_fields{mcadev}),
            fseek(specfile, stop_position+length(tok), -1);
            spectrum = textscan(specfile, '%f32', MCA_channels(mcadev), 'whitespace', ' \b\t\\');
            mcadata.(MCA_fields{mcadev}) = spectrum{1};
        else
            fseek(specfile, stop_position+length(tok), -1);
            spectrum = textscan(specfile, '%f32', MCA_channels(mcadev), 'whitespace', ' \b\t\\');
            mcadata.(MCA_fields{mcadev})(:,end+1) = spectrum{1};
        end
    end    
    [data_cell, stop_position] = textscan(specfile, '%f32');
    if length(data_cell{1})> 0 
        lines = lines+1;
        data = [data' data_cell{1}']';
%        if lines == 1 && ~isempty(mcadev)
%            ncolumns = length(data_cell{1});
%        end
    end
    nextline = fgetl(specfile);
    if nextline == -1
        tok = '';
    else
        [tok, nextline] = strtok(nextline);
    end
end
 
close(h);   % Close spec file load box

fclose(specfile);

for k = 1:length(comments)
    comments(k).line = comments(k).point/ncolumns;
end
lines = length(data)/ncolumns;

if ~lines
    errors = add_error(errors, 1, sprintf('No data found in scan %d of file %s\n',...
        scan_number,specfilename));
    return
end

specscan.data = reshape(data, ncolumns, lines);

if ~isempty(mcadata)
    if length(MCA_fields) > 1
        for k = 1:length(MCA_fields)
            specscan.(MCA_fields{k}) = mcadata.(MCA_fields{k});
        end
    end
    specscan.mcadata = mcadata.(MCA_fields{1});
    if isempty(channels)
        specscan.channels = (1:size(specscan.mcadata, 1))';
    else
        specscan.channels = channels;
    end
end
if ~isempty(ecal)
    specscan.ecal = ecal;
end

specscan.scann = scan_number;
specscan.scanline = scanline;
specscan.npts = lines;
specscan.columns = ncolumns;
specscan.headers = headers;
specscan.motor_names = motor_names;
specscan.motor_positions = motor_positions;

specscan.comments = comments;

scan_pars = textscan(specscan.scanline, '%s'); scan_pars = scan_pars{1};
scan_type = char(scan_pars{1});

specscan.cttime = str2double(scan_pars{end});
if specscan.cttime <= 0
    cttime_col = find(strcmp(specscan.headers, 'Seconds'),1);
    specscan.cttime = specscan.data(cttime_col,:);
end

if TIMETEST; fprintf('Done reading spec file:'); toc; end

% specscan.complete = 1: scan is complete
%                     0: scan is incomplete, but no subsequent scan is
%                       present in file
%                     -1: scan is incomplete and the file has a subsequent
%                       scan, so the scan will never complete
specscan.complete = 1;
switch scan_type
    case 'tseries'
        specscan.ctrs = headers(3:end);
        specscan.var1 = specscan.data(1,:)';
        specscan.mot1 = 'time';

        planned_pts = str2double(scan_pars{2});
        if planned_pts > 0 && planned_pts ~= specscan.npts
            specscan.complete = 0;
        end
        specscan.dims = 1;
        specscan.size = specscan.npts;
    case 'ascan'        
        specscan.ctrs = headers(3:end);
        specscan.var1 = specscan.data(1,:)';
        specscan.mot1 = scan_pars{2};
        
        planned_npts = str2double(scan_pars{5})+1;
        if planned_npts ~= specscan.npts
            specscan.complete = -1*strcmp(tok, '#S');
        end
        specscan.dims = 1;
        specscan.size = specscan.npts;
    case 'hklscan'
        specscan.ctrs = headers(4:end);
        deltah = str2num(scan_pars{3}) - str2num(scan_pars{2});
        deltak = str2num(scan_pars{5}) - str2num(scan_pars{4});
        deltal = str2num(scan_pars{7}) - str2num(scan_pars{6});
        [mval, ind] = max(abs([deltah deltak deltal]));
        scandir = ind;
        specscan.var1 = specscan.data(scandir, :)';
        specscan.mot1 = headers{scandir};

        planned_npts = str2double(scan_pars{8})+1;
        if planned_npts ~= specscan.npts
            specscan.complete = -1*strcmp(tok, '#S');
        end
        specscan.dims = 1;
        specscan.size = specscan.npts;
    case 'a2scan'
        specscan.ctrs = headers(4:end);
        specscan.var1 = specscan.data(1,:)';
        specscan.mot1 = scan_pars{2};
        
        planned_npts = str2double(scan_pars{8})+1;
        if planned_npts ~= specscan.npts
            specscan.complete = -1*strcmp(tok, '#S');
        end
        specscan.dims = 1;
        specscan.size = specscan.npts;
    case {'smesh', 'mesh', 'hklmesh'}
        specscan.ctrs = headers(4:end);
        if strcmp(scan_type, 'smesh')
            var1_n = str2double(scan_pars{7})+1;
            var2_n = str2double(scan_pars{11})+1;
            specscan.mot2 = scan_pars{8};
        else % scan type is mesh
            var1_n = str2double(scan_pars{5})+1;
            var2_n = str2double(scan_pars{9})+1;
            specscan.mot2 = scan_pars{6};
        end
        specscan.mot1 = scan_pars{2};
        planned_npts = var1_n*var2_n;

        if planned_npts ~= specscan.npts
            specscan.complete = -1*strcmp(tok, '#S');
            specscan.extra = mod(specscan.npts, var1_n);
            if specscan.extra ~= 0
                specscan.npts = specscan.npts - specscan.extra;
                %specscan.var2 = specscan.var2(1:specscan.npts);
            end 
            var2_n = specscan.npts/var1_n;
            specscan.data=reshape(specscan.data(:,1:specscan.npts), ...
                ncolumns, var1_n, var2_n);
            if ~isempty(mcadata)
                specscan.mcadata = reshape(specscan.mcadata(:,1:specscan.npts), ...
                MCA_channels, var1_n, var2_n);
            end

            if length(specscan.cttime)>1
                specscan.cttime = specscan.data(cttime_col, :, :);
            end
        else
            specscan.data=reshape(specscan.data,ncolumns, var1_n, var2_n);
            if length(specscan.cttime)>1
                specscan.cttime = reshape(specscan.cttime, var1_n, var2_n);
            end
            if ~isempty(mcadata)
                specscan.mcadata = reshape(specscan.mcadata,MCA_channels, var1_n, var2_n);
            end
        end
        specscan.var1 = squeeze(specscan.data(1,:,:)); 
        specscan.var2 = squeeze(specscan.data(2,:,:));
        specscan.dims = 2;
        specscan.size = [var1_n var2_n];
    case 's2mesh'
        specscan.ctrs = headers(5:end);
        var1_n = str2double(scan_pars{7})+1;
        var2_n = str2double(scan_pars{11})+1;
        var3_n = str2double(scan_pars{15})+1;
        
        n_fast = var2_n * var3_n; % number of fast-scan loops
        
        planned_npts = var1_n*var2_n*var3_n;
        
        specscan.mot1 = scan_pars{2};
        specscan.mot2 = scan_pars{8};
        specscan.mot3 = scan_pars{12};
        
        if planned_npts ~= specscan.npts
            % Keep only the last complete var1 (fast) loop
            specscan.complete = -1*strcmp(tok, '#S');
            specscan.extra = mod(specscan.npts, var1_n);
            if specscan.extra ~= 0
                specscan.npts = specscan.npts - specscan.extra;

            end
            n_fast = specscan.npts/var1_n;
            var3_n = ceil(n_fast/var2_n);
            if n_fast < var2_n
                var2_n = n_fast;
            end
            
            specscan.data=reshape(specscan.data(:,1:specscan.npts), ...
                ncolumns, var1_n, n_fast);  
            
            if ~isempty(mcadata)
                specscan.mcadata = reshape(specscan.mcadata(:,1:specscan.npts), ...
                    MCA_channels, var1_n, n_fast);
            end
            if length(specscan.cttime)>1
                specscan.cttime = specscan.data(cttime_col, :, :);
            end
        else
            specscan.data=reshape(specscan.data,ncolumns, var1_n, n_fast);
            if ~isempty(mcadata)
                specscan.mcadata = reshape(specscan.mcadata, MCA_channels, var1_n, n_fast);
            end
            if length(specscan.cttime)>1
                specscan.cttime = reshape(specscan.cttime, var1_n, n_fast);
            end
        end
        specscan.var1 = squeeze(specscan.data(1,:,:));
        specscan.var2 = squeeze(specscan.data(2,:,:));
        specscan.var3 = squeeze(specscan.data(3,:,:));
        % Note that specscan.npts can be less than var1_n * var2_n *
        % var3_n, since the data are truncated to the last complete fast
        % scan.  Hence specscan.npts = n_fast * var1_n = (var3_n - 1) *...
        % (var2_n*var1_n) + (n_fast- (var3_n-1)*var2_n) * var1_n
        specscan.dims = 3;
        specscan.size = [var1_n var2_n var3_n];
    case 'fastmesh'
        specscan.ctrs = headers(3:end);
        var1_n = str2double(scan_pars{5})+1;
        % Approximate increment...
        var1_inc = (str2double(scan_pars{4})-str2double(scan_pars{3}))/var1_n;
        var1_order = sign(var1_inc);
        var2_n = str2double(scan_pars{9})+1;
        var2_order = 2 * (str2double(scan_pars{8}) > str2double(scan_pars{7})) - 1;
        n_fast = var2_n;
        
        specscan.mot1 = scan_pars{2};
        specscan.mot2 = scan_pars{6};
        
        % Eliminate duplicates (only needed for earliest version of fastmesh)
        positions = specscan.data(1:2,:);
        [goodvals, unique_cols, repeated_cols] = unique(positions', 'rows');
        specscan.data = specscan.data(:, unique_cols);
        specscan.npts = length(unique_cols);
        
        % First, sort the data so that it makes a nice array, and save the order to
        % apply to the mcadata.  In sortrows, the column specification is negative or
        % positive to specify ascending or descending order.
        [sorted_data, order] = sortrows(specscan.data', [var2_order*2 var1_order*1]);
        sorted_data = sorted_data';
        specscan.order = unique_cols(order);
       
        n_fast_actual = 1;
        var1_n(1) = 1;
        slow_posn = sorted_data(2, 1);
        for k = 2:specscan.npts
            if slow_posn == sorted_data(2,k)
                var1_n(n_fast_actual) = var1_n(n_fast_actual)+1;
            else         
                n_fast_actual = n_fast_actual+1;
                var1_n(n_fast_actual) = 1;
                slow_posn = sorted_data(2, k);
            end
        end
        max_var1 = max(var1_n);
        
        % Here, we need to fill out the matrix (add elements such that var1_n is the
        % same for all columns. We also need to be able pass info about how to
        % properly reshape mcadata...
        specscan.data = ones(ncolumns,max_var1, n_fast_actual);
        start = 1;
        for k = 1:n_fast_actual
            specscan.data(:,1:var1_n(k),k) = ...
                sorted_data(:,start:start+var1_n(k)-1);
            specscan.data(1, var1_n(k)+1:max_var1, k) = ...
                specscan.data(1,var1_n(k),k) + var1_inc*(1:max_var1-var1_n(k));
            specscan.data(2, var1_n(k)+1:max_var1, k) = ...
                repmat(specscan.data(2, 1, k), 1,max_var1-var1_n(k));
            start = start+var1_n(k);
        end
        
        if n_fast_actual ~= n_fast
            specscan.complete = -1*strcmp(tok, '#S');
            var2_n = n_fast_actual;
            n_fast = n_fast_actual;
        end

        if ~isempty(mcadata)
            sorted_mcadata = specscan.mcadata(:,specscan.order);
            specscan.mcadata = zeros([MCA_channels, max_var1, n_fast]);
            start = 1;
            for k = 1:n_fast
                specscan.mcadata(:,1:var1_n(k), k) = ...
                    sorted_mcadata(:, start:start+var1_n(k)-1);
                start = start+var1_n(k);
            end
        end
        if length(specscan.cttime)>1
            specscan.cttime = specscan.data(cttime_col, :, :);
        end

        specscan.var1_n = var1_n;  % An array, necessary to re-order mcadata later...
        specscan.var1 = squeeze(specscan.data(1,:,:));
        specscan.var2 = squeeze(specscan.data(2,:,:));

        specscan.dims = 2;
        specscan.size = [max_var1 var2_n];
        
    case 's2zoom'
        specscan.ctrs = headers(5:end);
        var1_inc = str2double(scan_pars{5});
        var2_n = str2double(scan_pars{9})+1;
        var3_n = str2double(scan_pars{13})+1;
        
        % The order vars are +1 for ascending, -1 for descending
        var3_order = 2 * (str2double(scan_pars{12}) > str2double(scan_pars{11})) - 1;
        var2_order = 2 * (str2double(scan_pars{8}) > str2double(scan_pars{7})) - 1;
        n_fast = var2_n * var3_n; % number of fast-scan loops
               
        specscan.mot1 = scan_pars{2};
        specscan.mot2 = scan_pars{6};
        specscan.mot3 = scan_pars{10};
        
        % First, sort the data so that it makes a nice array, and save the order to
        % apply to the mcadata.  In sortrows, the column specification is negative or
        % positive to specify ascending or descending order.
        [sorted_data, specscan.order] = sortrows(specscan.data', ...
            [var3_order*3 var2_order*2 1]);
        sorted_data = sorted_data';
        
        n_fast_actual = 1;
        var1_n(1) = 1;
        slow_posn = sorted_data(2:3, 1);
        for k = 2:specscan.npts
            if all(slow_posn == sorted_data(2:3,k))
                var1_n(n_fast_actual) = var1_n(n_fast_actual)+1;
            else
                n_fast_actual = n_fast_actual+1;
                var1_n(n_fast_actual) = 1;
                slow_posn = sorted_data(2:3, k);
            end
        end
        max_var1 = max(var1_n);
        
        % Here, we need to fill out the matrix, or at least figure out how
        % to do so for the sake of the mcadata, or do we? We need to be
        % able pass info about how to properly reshape mcadata...
        specscan.data = ones(ncolumns,max_var1, n_fast_actual);
        start = 1;
        for k = 1:n_fast_actual
            specscan.data(:,1:var1_n(k),k) = ...
                sorted_data(:,start:start+var1_n(k)-1);
            specscan.data(1, var1_n(k)+1:max_var1, k) = ...
                specscan.data(1,var1_n(k),k) + var1_inc*(1:max_var1-var1_n(k));
            specscan.data(2:3, var1_n(k)+1:max_var1, k) = ...
                repmat(specscan.data(2:3, 1, k), 1,max_var1-var1_n(k));
            start = start+var1_n(k);
        end
        
        if n_fast_actual ~= n_fast
            specscan.complete = -1*strcmp(tok, '#S');
        end
        n_fast = n_fast_actual;
        var3_n = ceil(n_fast/var2_n);
        if n_fast < var2_n
            var2_n = n_fast;
        end
        if ~isempty(mcadata)
            sorted_mcadata = specscan.mcadata(:,specscan.order);
            specscan.mcadata = zeros([MCA_channels, max_var1, n_fast]);
            start = 1;
            for k = 1:n_fast
                specscan.mcadata(:,1:var1_n(k), k) = ...
                    sorted_mcadata(:, start:start+var1_n(k)-1);
                start = start+var1_n(k);
            end
        end
        if length(specscan.cttime)>1
            specscan.cttime = specscan.data(cttime_col, :, :);
        end

        specscan.var1_n = var1_n;  % An array, necessary to re-order mcadata later...
        specscan.var1 = squeeze(specscan.data(1,:,:));
        specscan.var2 = squeeze(specscan.data(2,:,:));
        specscan.var3 = squeeze(specscan.data(3,:,:));

        specscan.dims = 3;
        specscan.size = [max_var1 var2_n var3_n];
    otherwise
        errors=add_error(errors,1,sprintf('Error: Unrecognized scan type, scan %g in %s',...
            scan_number, specfilename));
        return
end % -------- switch -------------

function [scanline, scan_mark, motor_mark] = find_scan(specfilename, scan)
% [scanline, scan_mark, motor_mark] = find_scan(specfile, scan)
% Assumes specfile is alredy open. Makes no noise if the scan is not found, but
% returns scanline = -1.  
%
% scan_mark and motor_mark are the file position of the scan and (neareast preceding)
% motor position lines, respectively.
%
% In textscan, the format spec %[^\n] reads all characters other than newline (none
% of which are present since find_line strips them from scanline).
scanline = -1;
scan_mark = -1;
motor_mark = -1;

if ~isunix
    warndlg('Oops : this version of openspec for unix/mac only');
    return
end

% Use text scan to grab all byte offsets and scans
[st1, scanlines] = system(['grep -be "#S" "' specfilename '"']);
scan_indices = textscan(scanlines, '%d:#S %d%[^\n]%*[\n]');
% if scan_indices{2}(scan) == scan
%     scan_mark = scan_indices{1}(scan);
%     scanline = scan_indices{3}{scan};
% else
    match = find(scan_indices{2} == scan);
    if isempty(match)
        return
    elseif length(match) > 1
        warnstr = sprintf('Oops : Found %d distinct scan #%d''s. Which one?', ...
            length(match), scan);
        specscan = inputdlg(warnstr, 'Select',1,{'1'});
        specscan = sscanf(specscan{1}, '%d', 1);
        match = match(specscan);
    end
    scan_mark = scan_indices{1}(match);
    scanline = scan_indices{3}{match};
% end

[st2, motorlines] = system(['grep -be "#O0" "' specfilename '"']);
motor_indices = textscan(motorlines, '%d:%*[^\n]%*[\n]');
% motor_indices = motor_indices{1};
motor_mark = motor_indices{1}(find(motor_indices{1} < scan_mark, 1, 'last'));


