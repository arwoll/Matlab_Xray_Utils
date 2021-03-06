% openspec_tests.m
%

% This script should ultimately include tests of every kind of scan and
% variant of data openspec can be used for, along with descriptions of what
% might go wrong.

% BM102913_1 : garden variety XRR a2scan's
s = openspec('Test_data/BM102913_1_cut', 13);

%%
% HKLscan
s = openspec('Test_data/LCO_STO_Spe_cut', 50);

%% "smesh" scan for dynamically tracking the surface in CXRF
% Plot shows a picture 
s = openspec('Test_data/teniers5', 34);
imagesc(squeeze(log(s.data(7,:,:)+1)))

%% Test for mca file format from Quad element data obtained at F3 -- March 2014
s = openspec('Test_data/pyro_grazing.scan7.mca1.mca', 7);

%% dependencies:
%names = dependencies.toolboxDependencyAnalysis({'openspec.m', 'find_scan.m', 'add_error.m', 'find_line.m'})
%names = 
%    'MATLAB'    'Symbolic Math Toolbox'