function scandata = update_id20(filename)
% function scan = openid20(filename)
% re-processes a matlab variable or binary file filename, output by 
% openid20. Specifically, update_id20 grabs the ion chamber information
% from the fileheader if the "ion_chamber" field is not already present in
% the variable.

if isstruct(filename)
    scandata = filename;
elseif ischar(filename) && exist(filename, 'file')==2 
    s = whos('-file', filename);
    if ~isempty(s) && strcmp(s(1).name, 'scandata')
        load(filename);
    else
        fprintf('update_id20: unrecognized input file or variable\n');
    end
end

if isfield(scandata, 'ion_chambers')
    fprintf('update_id20: this file already has ion chamber info\n');
    return
end

fileheader = scandata.spec.fileheader;
ion_chambers = struct('name', {}, 'sensitivity', {}, ...
    'V0', {}', 'V1', {}); % Sensitivity in A/V


[nextline, pos] = textscan(fileheader, '%s\n', 'whitespace', '\n'); 
fileheader = fileheader(pos+1:end);
nextline = nextline{1}{1};
[tok, partline] = strtok(nextline);

while tok(1) =='#'
    if ~isempty(strfind(partline, 'Sensitivities'))
        [nextline, pos] = textscan(fileheader, '%s\n', 'whitespace', '\n');
        fileheader = fileheader(pos+1:end);
        nextline = nextline{1}{1};
        [tok, partline] = strtok(nextline);
        foo = textscan(partline, '%s: %f %s', 'whitespace', ' \b\t:');
        for k = 1:length(foo)
           ion_chambers(k).name = foo{1}{k};
           ion_chambers(k).sensitivity = foo{2}(k);
           switch foo{3}{k}
               case 'nA/V'
                   ion_chambers(k).sensitivity = ion_chambers(k).sensitivity * 1e-9;
               case 'pA/V'
                   ion_chambers(k).sensitivity = ion_chambers(k).sensitivity * 1e-12;
           end
        end
    elseif ~isempty(strfind(partline, 'Analog Input Voltages'))
        ic_names = {ion_chambers.name};
        [nextline, pos] = textscan(fileheader, '%s\n', 'whitespace', '\n');
        fileheader = fileheader(pos+1:end);
        nextline = nextline{1}{1};
        [tok, partline] = strtok(nextline);
        foo = textscan(partline, '%s %f %f', 'whitespace', ' \b\t:/');
        for k = 1:length(foo{1})
           this_ic = strcmp(foo{1}{k}, ic_names);
           if any(this_ic)
               ion_chambers(this_ic).V0 = foo{2}(k);
               ion_chambers(this_ic).V1 = foo{3}(k);
           end
        end
    elseif ~isempty(strfind(partline, 'XIA Filters'))
        [nextline, pos] = textscan(fileheader, '%s\n', 'whitespace', '\n');
        fileheader = fileheader(pos+1:end);
        nextline = nextline{1}{1};
        [tok, partline] = strtok(nextline);
        foo = textscan(partline, '%s %s', 'whitespace', ' \b\t:');
        inouts = strcmp(foo{2},'IN');
        vals = [1 2 4 8];
        filters = vals * inouts;       
    end
    if isempty(fileheader)
        break
    end
    [nextline, pos] = textscan(fileheader, '%s\n', 'whitespace', '\n');
    fileheader = fileheader(pos+1:end);
    nextline = nextline{1}{1};
    [tok, partline] = strtok(nextline);
    if isempty(tok) % This 'if' takes care of blank lines, which SHOULDn't be there
        tok = '#';
    end
end

if isempty(ion_chambers)
    fprintf('update_id20: Error while trying to process ion chamber settings\n');
else
    scandata.spec.ion_chambers = ion_chambers;
    scandata.spec.filters = filters;
end

