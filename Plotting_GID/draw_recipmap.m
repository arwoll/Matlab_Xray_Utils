function [qpar, qperp, z] = draw_recipmap(fname, scans, Energy, i2norm, varargin)

if nargin == 5
    cra = varargin{1};
else
    cra = [12 300];
end
[qpar, qperp, z] = make_recipmap_v4(fname, scans, Energy, i2norm);

imagesc(qpar, qperp, log(z+1), log(cra));
axis equal tight xy

title_str = sprintf('%s_scans%s', fname, num2str(scans, '_%d'));
title(strrep(title_str, '_', '\_'));
xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])

%%
matfile = [title_str '.mat'];
fullmatfile = fullfile(pwd, matfile);
[matfile, matfilepath] = uiputfile('*',...
    'Save Map data to Matfile?', fullmatfile);
if ischar(matfile)
    save(fullfile(matfilepath, matfile),'qpar', 'qperp', 'z');
end
%export_png(get(gcf, 'Number'), title_str)