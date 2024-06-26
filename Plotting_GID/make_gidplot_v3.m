function varargout = make_gidplot_v3(matfile, E, varargin)
% function make_gidplot_v1(matfile, E, varargin) 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot
%
%  REQUIRES : open_gid_v1

graysc = 0;
cra = [];
fig_num = 1;
q_axis = [];

nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'range'
            cra = varargin{k+1};
        case 'fig'
            fig_num = varargin{k+1};
        case 'q_axis'
            q_axis = varargin{k+1};
        case 'gray'
            graysc = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

[q_par, q_perp, z] = open_gid_v1(matfile, E);

if nargout == 3
    varargout{1} = q_par;
    varargout{2} = q_perp;
    varargout{3} = z;
end

%%

if isempty(cra)
    cra = [1  max(z(:))];
end

if isempty(q_axis)
   q_axis = [q_par(1) 2 0 0.3]; 
end

fonts = 18;
logscale = 1;

new_fig = figure(fig_num);
clf;
figp = get(gcf, 'position');
set(gcf, 'Position', [figp(1) figp(2)   870 300]);

if graysc
   cm = colormap(gray);
   cm_rev = cm(end:-1:1, :);
   colormap(cm_rev);
else
    colormap(jet)
end

imagesc(q_par, q_perp,log(z+1), log(cra))
%set(gca, 'ytick', 0:.2:q_axis(4));
%axis(q_axis);
% axis([q_par(1)  2 0 0.3]);
axis xy
h = colorbar;
if logscale
    mxz = log10(cra(2));
    mnz = log10(cra(1));
    upper = mxz-mod(mxz, 1);
    lower = mnz-mod(mnz, 1) + 1;
    ytick = lower:upper;
    for k = 1:length(ytick)
        yticklabel{k} = sprintf('%g', 10^ytick(k)); %#ok<AGROW>
    end
    set(h, 'ytick', log(10.^ytick));
    set(h, 'yticklabel', yticklabel, 'FontSize', fonts);
end

xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])


title(strrep(matfile, '_', '\_'));

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