% Script to read in Elam's elemental database
% Fairly efficient -- takes ~4 seconds to load. A huge speed-up was found by
% replacing strtok with strread and textscan where possible
%

%tic

fid=fopen('ElamDB12.txt', 'rt');
datastr = fgetl(fid);
while isempty(datastr) || datastr(1)=='/'
    datastr = fgetl(fid);
end
num = 0;

[tok, rem] = strtok(datastr);
% Now assume that tok is 'Element'
while 1


    [sym num mw rho] = strread(rem, '%s%f%f%f');
    ele(num).sym = sym{1};
    ele(num).mw = mw;
    ele(num).rho = rho;
    edge = 0;

    [tok, rem] = strtok(fgetl(fid));
    while 1
        switch tok
            case 'Edge'
                % Process edge params (in this line)
                edge = edge + 1;
                [label e yield jump] = strread(rem, '%s%f%f%f');
                ele(num).edge(edge).label = label{1};  % String K, L1, etc..
                ele(num).edge(edge).e = e;
                ele(num).edge(edge).yield = yield;
                ele(num).edge(edge).jump = jump;
                [tok, rem] = strtok(fgetl(fid));
            case 'Lines'
                line = 0;
                datastr = fgetl(fid);
                [tok,rem] = strtok(datastr);
                while ~any(strcmp(tok, {'Edge', 'CK'}))
                    % 'Lines' is only present if there is at least one line
                    % is there.  So we don't have to check the first one.
                    line = line + 1;
                    ele(num).edge(edge).lines(line).iupac = tok;
                    [siegbahn e i] = strread(rem, '%s%f%f');
                    ele(num).edge(edge).lines(line).siegbahn = siegbahn{1};
                    ele(num).edge(edge).lines(line).e = e;
                    ele(num).edge(edge).lines(line).i = i;
                    datastr = fgetl(fid);
                    [tok,rem] = strtok(datastr);
                end
            case 'CK'
                [labels probs] = strread(rem, '%s%f');
                for k = 1:length(labels)
                    ele(num).edge(edge).ck(k).label = labels{k};
                    ele(num).edge(edge).ck(k).prob = probs(k);
                end
                [tok,rem] = strtok(fgetl(fid));
            case 'CKtotal'
                [labels probs] = strread(rem, '%s%f');
                for k = 1:length(labels)
                    ele(num).edge(edge).ck(k).tprob = probs(k);
                end
                [tok,rem] = strtok(fgetl(fid));
            case 'Photo'
                break
        end % ---------- end switch -----------
    end
    % Get Photo absorption x-sections;
    data = textscan(fid, '%f%f%f');
    ele(num).photo = [data{:}];
    datastr = fgetl(fid);
    if strcmp(datastr, 'Scatter')
        data = textscan(fid, '%f%f%f%f%f');
        ele(num).scatter = [data{:}];
    else
        error('Scatter line did not seem to follow Photo data');
    end
    
    % The following block (if num > 2 ... end) creates new subfields 'vac'
    % in the lines and ck subfields of each edge subfield of the most
    % recently-processed element.  I do it here so that the energy level in
    % which a vacancy is created can be identified, by index, from
    % among all of the edges defined for the element.  For example,  the
    % Ka1 line points to the L3 edge, etc.  Since the L3 edge is the 4th
    % edge in the series, ele().edge(1).lines(3).vac = 4. 
    % This increased the run time on my powerbook by about 7.5%
    if num > 2
        edges = {ele(num).edge.label};
        for k=1:length(ele(num).edge)
            for j=1:length(ele(num).edge(k).lines)
                % The following grabs, for example, the string 'M4' from the
                % string 'L2-M4,5', 'K-M4,5', or 'L2,3-M4,5'
                edge = regexp(ele(num).edge(k).lines(j).iupac, '.+-(\w+)', 'tokens');
                edge = edge{1};
                ele(num).edge(k).lines(j).vac = find(strcmp(edge, edges));
            end
            % The following makes a new field, edge, inside the field ck, which is
            % the index of the edge corresponding to the new vacancy (created by the CK transition).
            if num > 11   % All elements from au=12(Mg) have some cks
                for j = 1:length(ele(num).edge(k).ck)
                    ele(num).edge(k).ck(j).vac = ...
                        find(strcmp(ele(num).edge(k).ck(j).label, edges));
                end
            end
        end
    end
    
    datastr = fgetl(fid);   % datastr == 'EndElement'
    [tok,rem] = strtok(fgetl(fid));  % This is either 'Element' or 'End'
    if strcmp(tok, 'End')
        break
    end
end

%toc

fclose(fid);
% Easy labels!
for k=1:98 eval(['n.' ele(k).sym '= k;']); end

% Clean up
clear tok rem fid k datastr data
clear sym mw rho line num edge label e i yield jump siegbahn
