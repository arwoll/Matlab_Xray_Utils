function varargout = make_gidplot_v2(matfile, E, varargin)
% function make_gidplot_v1(matfile, E, varargin) 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot

cra = [];
fig_num = 1;

nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'range'
            cra = varargin{k+1};
        case 'fig'
            fig_num = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end


load(matfile)
getq = @(nu) 4*pi*E/12.4 * sind(nu/2);

specd = scandata.spec;

nu = double(specd.var1);
del = double(scandata.energy);

q_par = getq(nu);
q_perp = getq(del);
z = double(scandata.mcadata);

%% clean up bad pixels
row_sums = sum(z, 2);
bad = find(row_sums == 0);
for k = 1:length(bad)
   z(bad(k), :) = 0.5 * ( z(bad(k)-1, :) + z(bad(k)+1, :));
end

%%
mxz = max(z(:));
mnz = 1;

dcal = scandata.ecal;
if dcal(3) == -1e-6
    dcal(3) = -7.5e-7;
end

% fprintf('Chan 620 = %g deg, dcal(3) = %g\n', ...
%     dcal(1) + dcal(2)*620 + dcal(3)*620^2, dcal(3));
% fprintf('Image min : max = %g : %g\n', mnz, mxz);

if isempty(cra)
    cra = [mnz mxz];
end

fonts = 18;
logscale = 1;

normcts = double(specd.data(strcmp(specd.headers, 'I2'), :));
avg_norm = mean(normcts);

norm_mat = avg_norm ./ repmat(normcts, size(z,1), 1);

z = z.* norm_mat;

% for k=1:size(z, 2)
%     z(:,k) = z(:,k) .* avg_norm./normcts(k);
% end

new_fig = figure(fig_num);
clf;
figp = get(gcf, 'position');
set(gcf, 'Position', [figp(1) figp(2)   870 300]);
imagesc(q_par, q_perp,log(z+1), log(cra))
axis([q_par(1)  2 0 0.3]);
axis xy
h = colorbar;
if logscale
    mxz = log10(mxz);
    mnz = log10(mnz);
    upper = mxz-mod(mxz, 1);
    lower = mnz-mod(mnz, 1) + 1;
    ytick = lower:upper;
    for k = 1:length(ytick)
        yticklabel{k} = sprintf('%g', 10^ytick(k));
    end
    set(h, 'ytick', log(10.^ytick));
    set(h, 'yticklabel', yticklabel, 'FontSize', fonts);
end

xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])


title(strrep(matfile, '_', '\_'));

if nargout == 3
    varargout{1} = q_par;
    varargout{2} = q_perp;
    varargout{3} = z;
end

export_plots = 0;
if export_plots
    if strcmp(scandata.mcaformat,  'spec')
        export_name_eps = sprintf('%s_q_%03d.eps',scandata.specfile, ...
            specd.scann);
    else
        fprintf('Help -- this is not the data format I was expecting\n');
        return
    end
    title(strrep(export_name_eps, '_', '\_'));
    
    [export_name, path] = uiputfile('*.eps', 'Select Filename', export_name_eps);
    
    if isequal(export_name, 0)
        fprintf('File not saved\n');
    else
        %     export_name_eps = strrep(export_name, '.png', '.eps');
        export_name_pdf = strrep(export_name_eps, '.eps', '.pdf');
        set(new_fig, 'PaperPositionMode', 'auto');
        fig_str = sprintf('-f%d',new_fig);
        %     print(fig_str,'-dpng','-r600', fullfile(path, export_name));
        print(fig_str,'-depsc2','-r600', '-painters', fullfile(path, export_name_eps));
%         print(fig_str,'-dpdf','-r600', '-painters', fullfile(path, export_name_pdf));
    end
end