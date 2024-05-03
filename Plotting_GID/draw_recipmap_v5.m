function [qpar, qperp, z] = draw_recipmap_v5(fname, scans, Energy, i2norm, varargin)
%function [qpar, qperp, z] = draw_recipmap(fname, scans, Energy, i2norm, varargin)
if nargin == 5
    cra = varargin{1};
else
    cra = [20 200];
end
[qpar, qperp, z] = make_recipmap_v5_gomez(fname, scans, Energy, i2norm);



if size(scans, 1)> 1 
    % In this case, the first row is the scan numbers, the 2nd is the scale
    % factors
    scale_factors = scans(2,:);
    scans = scans(1,:);
else
    scale_factors = ones(size(scans));
end
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