function bigfonts(varargin)
% function bigfonts(varargin)
% if nargin == 0
%     fs = 20;
%  else
%     fs = varargin{1};
%  end
%
% %%%
% set(gca, 'FontSize', fs);
% set((get(gca, 'Title')), 'FontSize', fs);
% set((get(gca, 'XLabel')), 'FontSize', fs);
% set((get(gca, 'YLabel')), 'FontSize', fs);
if nargin == 0
    fs = 20;
else
    fs = varargin{1};
end

%%
set(gca, 'FontSize', fs);
set((get(gca, 'Title')), 'FontSize', fs);
set((get(gca, 'XLabel')), 'FontSize', fs);
set((get(gca, 'YLabel')), 'FontSize', fs);