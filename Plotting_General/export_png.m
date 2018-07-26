function export_png(fig_num, file_base)
% function export_panel(fig_num, file_base, make_extras)
%   exports figure fig_num to an eps file, [file_base '.eps'] and,
%   optionally (if make_extras>0), also pdf and png versions as well.
% 
export_name_eps = sprintf('%s.png',file_base);

[export_name, path] = uiputfile('*.png', 'Select Filename', export_name_eps);

if isequal(export_name, 0)
    fprintf('File not saved\n');
else
    %export_name = fullfile(path, export_name);
    set(fig_num, 'PaperPositionMode', 'auto');
    if ~strfind(version, 'R2014b')
        print(['-f' num2str(fig_num)],'-dpng','-r300', '-painters',...
            fullfile(path, export_name));
    else
        print(['-f' num2str(fig_num)],'-dpng','-r300', '-painters',...
            fullfile(path, export_name));
    end
end
