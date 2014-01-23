function export_panel(fig_num, file_base, make_extras)
% function export_panel(fig_num, file_base, make_extras)
%   exports figure fig_num to an eps file, [file_base '.eps'] and,
%   optionally (if make_extras>0), also pdf and png versions as well.
% 
export_name_eps = sprintf('%s.eps',file_base);

% figure(fig_num)
% title(strrep(export_name_eps, '_', '\_'));
[export_name, save_path] = uiputfile('*.eps', 'Select Filename', export_name_eps);

if isequal(export_name, 0)
    fprintf('File not saved\n');
else
    set(fig_num, 'PaperPositionMode', 'auto');
    print(['-f' num2str(fig_num)],'-depsc2','-r300', '-painters', ...
        fullfile(save_path, export_name_eps));
     fix_lines(fullfile(save_path, export_name_eps));
    if make_extras
        print(['-f' num2str(fig_num)],'-dpdf','-r300', '-painters',...
            fullfile(save_path, [export_name_eps(1:end-4) '.pdf']));
        print(['-f' num2str(fig_num)],'-dpng','-r300', '-painters',...
            fullfile(save_path, [export_name_eps(1:end-4) '.png']));
    end
end
