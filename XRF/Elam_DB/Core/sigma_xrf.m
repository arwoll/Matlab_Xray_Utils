function lines = sigma_xrf(element, E0, elamdb, varargin)
% function lines = sigma_xrf(element, E0, elamdb, [Ka | Kb | La | Lb | Ma])
%
% given an element (either the string symbol or atomic number), and
% incident energy E0 (keV), sigma_xrf returns a structure, lines, with fields:
%       e : the energies of all of the excited emission lines
%       sigma : the total cross section of each particular line. That is,
%               the total number of fluorescent photons in that line per
%               incident photon per (g/cm2) of material.
%       iupac : a cell array of the iupac IDs of each line
%       siegbahn : a cell array of the siegbahn IDs of each line
%       varargin : if present, this argument should be a string used to
%       select a subset of lines, e.g. 'Ka', 'La', 
%       
% calculated using data tabulated in the Elam database
%
% Examples:
%
% >>l = sigma_xrf('Cu', 12, elamdb)
% l = 
%        sigma: [0.0158 15.1405 29.6929 2.2390 4.3224 0.0406 0.0014 0.0020 0.0076 0.1078 0.0355 0.0488 0.4435]
%            e: [7.8823 8.0267 8.0463 8.9017 8.9039 8.9740 1.0194 1.0216 0.8298 0.9473 0.8102 0.9277 0.9277]
%        iupac: {1x13 cell}
%     siegbahn: {'Ka3'  'Ka2'  'Ka1'  'Kb3'  'Kb1'  'Kb5'  'Lb4'  'Lb3'  'Ln'  'Lb1'  'Ll'  'La2'  'La1'}
% 
%
% >>

if nargin > 3 && (ischar(varargin{1}) || iscell(varargin))
    subset = varargin{1};
    if ischar(subset)
        subset = {subset};
    end
else
    subset = [];
end

lines = [];

n = elamdb.n;
ele = elamdb.ele;

if ischar(element)
    try 
        Na = n.(element);
    catch
        fprintf('Error in sigma_xrf: Element symbol %s not recognized\n', element);
        return
    end
elseif element < 3 || element > 98
    % No fluorescence
    fprintf('Error in sigma_xrf: element must be between 3 and 98 inclusive\n');
    return
else
    Na = element;
end

% edges(active_edge_indices) are the edges that are below the excitation energy.  Note that
% edge energies are pre-sorted in order of decreasing energy.  

edges = ele(Na).edge;  % all_edges is an array of edge structures
active_edge_indices = find([edges.e] < E0*1000); % act_edges is an array of the indices of excited edges
n_active = length(active_edge_indices);

offset = active_edge_indices(1) - 1; % Index of the lowest edge above E0

% The following converts the jump ratios for all of the excited edges to
% the probability that that edge will become vacant.  In other words, the
% vacancies created in that edge per incident photon of energy E0. If R1 is
% the jump ratio for the highest-energy edge, then this probability is
% (R1-1)/R1.  For the next lowest edge, the denominiator must be multiplied
% by the increase in photoabsortion by the edge above it: (R2-1)/(R1*R2) etc.
% The code below RELIES on the edges being ordered from high to low.

vacancies_per_photon = zeros(n_active, 1);
for k = 1:n_active
    vacancies_per_photon(k) = (edges(active_edge_indices(k)).jump-1)/ ...
        prod([edges(active_edge_indices(1:k)).jump]);
end

% Next, we calculate the fluorescence from each line, from the deepest to
% most shallow vacancy (highest energy to lowest energy edge).  At the same
% time, we use the fluorescence intensities / probabilities and CK
% transition probabilities to correct the vacancy distribution in
% lower-energy shells and subshells.  The algorithm is: compute K
% fluorescence line yields (Edge yield * fractional intensity of line *
% fraction of vacancies), while at the same time adding to the L, M, N,
% etc. vacancies. (This will increaese the sum of all vacancy probabilities
% above 1). Next, compute CK's for the subshell transitions in the L shell.
% Next compute the L fluorescence, followed by the M CK,s and the M
% fluorescence, followed by the N CK's, then the N fluorescence, etc... At
% the end, all of the fluorescence intensities are multiplied by the
% phot-absorption x-section.  

line_index = 0;
n_lines = length([edges(active_edge_indices).lines]);
e = zeros(1, n_lines);
sigma = e;
iupac = cell(size(e));
siegbahn = iupac;

for edge = active_edge_indices
    % Since the fluorescence yield per edge and the intensity of each line
    % are probabilities, sigma_xrf(1) is also the number of vacancies
    % created by fluorescence emission in the level which donates the
    % electron. NOTE: the algorithm below neglects the Auger contribution
    % to the vacancy cascade. Specifically we could imagine a third term in
    % the vacancies_per_photon line below, proportional to
    % (1-yield)*line.auger.i, where line.auger.i is the probability of an
    % Auger electron leaving the same level as the state that would
    % otherwise be supplying the radiative-transition. 
    for line = edges(edge).lines
        line_index = line_index + 1;
        sigma(line_index) = vacancies_per_photon(edge - offset) * ...
            edges(edge).yield * line.i;
        e(line_index) = line.e / 1000;
        iupac{line_index} = line.iupac;
        siegbahn{line_index} = line.siegbahn;
        vacancies_per_photon(line.vac - offset) = ...
            vacancies_per_photon(line.vac - offset) + sigma(line_index);
    end
    % vacancies_per_photon
    % When computing CK transitions, we use the single-event probabilities
    % rather than the totals, since the loop will enumerate all CK
    % transition routes.
% The following code is simpler -- test for identical results with below
%     for ck = edges(edge).ck
%         vacancies_per_photon(ck.vac - offset) = ...
%             vacancies_per_photon(ck.vac - offset) + ...
%             vacancies_per_photon(edge-offset) * ck.prob;
%     end
    for k = 1:length(edges(edge).ck)
        vacancies_per_photon(edges(edge).ck(k).vac - offset) = ...
            vacancies_per_photon(edges(edge).ck(k).vac - offset) + ...
            vacancies_per_photon(edge-offset) * edges(edge).ck(k).prob;
    end

%    fprintf('Total Vacancies: %f\n', sum(vacancies_per_photon));
%    fprintf('Total Energy emitted: %f\n', sum([line_int .* line_e]));
%    bar(vacancies_per_photon); pause;
end

log_E0 = log(E0*1000);  % For the spline, we need the log of the incident energy in eV
log_sigma_photo = splint(ele(Na).photo(:,1:3), log_E0);
sigma_photo = exp(log_sigma_photo);
lines.sigma = sigma * sigma_photo;
lines.e = e;
lines.iupac = iupac;
lines.siegbahn = siegbahn;

if isempty(subset)
    return
end

selection = false(1, length(lines.siegbahn));
for m = 1:length(subset)
    matches = strfind(lines.siegbahn, subset{m});
    for k = 1:length(matches)
        if ~isempty(matches{k})
            selection(k) = true;
        end
    end
end
subset = lines;

subset.sigma = sum(lines.sigma(selection));
subset.e = sum(lines.e(selection) .* lines.sigma(selection))/subset.sigma;
subset.iupac = lines.iupac(selection);
subset.siegbahn = lines.siegbahn(selection);

lines = subset;

