function [q, chi, z] = draw_q_chi_v2(fname, scans, Energy, i2norm, varargin)

if nargin == 5
    cra = varargin{1};
else
    cra = [12 300];
end

if isstruct(fname)
    scans = fname.spec.scann;
end
[q,chi, z] = make_q_chi_v2(fname, scans, Energy, i2norm);

clf;
imagesc(q, chi, log(z+1), log(cra));
axis tight xy

title_str = sprintf('%s_chi_d_scans%s', fname.specfile, num2str(scans, '_%d'));
title(strrep(title_str, '_', '\_'));
ylabel('chi [degrees]')
xlabel(['d ' char(197)])

%%
matfile = [title_str '.mat'];
fullmatfile = fullfile(pwd, matfile);
[matfile, matfilepath] = uiputfile('*',...
    'Save Map data to Matfile?', fullmatfile);
if ischar(matfile)
    save(fullfile(matfilepath, matfile),'chi', 'd', 'z');
end
%export_png(get(gcf, 'Number'), title_str)