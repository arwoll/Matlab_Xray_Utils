function [chi, d, z] = draw_chi_d(fname, scans, Energy, i2norm, varargin)

if nargin == 5
    cra = varargin{1};
else
    cra = [12 300];
end
[d,chi, z] = make_chi_d_v1(fname, scans, Energy, i2norm);

clf;
imagesc(d, chi, log(z+1), log(cra));
axis tight xy

title_str = sprintf('%s_chi_d_scans%s', fname, num2str(scans, '_%d'));
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