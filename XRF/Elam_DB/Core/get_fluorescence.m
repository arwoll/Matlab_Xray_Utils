function [line_e line_int]=get_fluorescence(Na,E0, ele)
% function [line_e line_int] = get_fluorescence(Na,E0, ele) 
%
% Using incident energy 'E0' (keV), returns fluorescence line energies and
% relative intensities from the element with atomic number 'Na' as
% calculated using data structure 'ele'
%

if Na < 3 
    % No fluorescence
    return
end

% alledges are the edges that are below the excitation energy.  Note that
% these are always in the order of decreasing energy.  

all_edges = ele(Na).edge;  % all_edges is an array of edge structures
act_edges = find([all_edges.e] < E0*1000); % act_edges is an array of the indices of excited edges

offset = act_edges(1) - 1; % Index of the lowest edge above E0

% The following converts the jump ratios for all of the excited edges to
% the probability that that edge will become vacant.  In other words, the
% vacancies created in that edge per incident photon of energy E0. If R1 is
% the jump ratio for the highest-energy edge, then this probability is
% (R1-1)/R1.  For the next lowest edge, the denominiator must be multiplied
% by the increase in photoabsortion by the edge above it: (R2-1)/(R1*R2) etc.
% The code below RELIES on the edges being ordered from high to low.

for k = 1:length(act_edges)
    vacancies_per_photon(k) = (all_edges(act_edges(k)).jump-1)/prod([all_edges(act_edges(1:k)).jump]);
%     fprintf('numerator is %f\n', (all_edges(act_edges(k)).jump-1));
%     fprintf('denominator is %f\n', prod([all_edges(act_edges(1:k)).jump]));
end

%[all_edges(act_edges(1:4)).e]
%vacancies_per_photon(1:4)

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

line_number = 0;

for edge = act_edges
    % all_edges(edge).label
    % Since the fluorescence yield per edge and the intensity of each line
    % are probabilities, line_int(1) is also the number of vacancies
    % created by fluorescence emission in the level which donates the
    % electron.
    for k = 1:length(all_edges(edge).lines)
%        [all_edges(edge).lines(k).iupac '   ' num2str(all_edges(edge).lines(k).e)]
        line_number = line_number + 1;
        line_int(line_number) = vacancies_per_photon(edge - offset) * ...
            all_edges(edge).yield * all_edges(edge).lines(k).i;
        line_e(line_number) = all_edges(edge).lines(k).e / 1000;
        vacancies_per_photon(all_edges(edge).lines(k).vac - offset) = ...
            vacancies_per_photon(all_edges(edge).lines(k).vac - offset) + line_int(line_number);
    end
%    vacancies_per_photon
    % When computing CK transitions, we use the single-event probabilities
    % rather than the totals, since the loop will enumerate all CK
    % transition routes.
    for k = 1:length(all_edges(edge).ck)
        vacancies_per_photon(all_edges(edge).ck(k).vac - offset) = ...
            vacancies_per_photon(all_edges(edge).ck(k).vac - offset) + ...
            vacancies_per_photon(edge-offset) * all_edges(edge).ck(k).prob;
    end

%    fprintf('Total Vacancies: %f\n', sum(vacancies_per_photon));
%    fprintf('Total Energy emitted: %f\n', sum([line_int .* line_e]));
%    bar(vacancies_per_photon); pause;
end

[all_edges(act_edges(1:4)).e];
vacancies_per_photon(1:4);

log_E0 = log(E0*1000);  % For the spline, we need the log of the incident energy in eV
log_sigma = splint(ele(Na).photo(:,1:3), log_E0);
sigma = exp(log_sigma);
line_int = line_int * sigma;

