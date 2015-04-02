% Executing printopt seems to get printing to work...
printopt;

afs = 18;  tfs = 18;
dafs = get(0, 'DefaultAxesFontSize'); dtfs = get(0, 'DefaulttextFontSize');
set(0, 'DefaultAxesFontSize', afs); set(0, 'DefaulttextFontSize', tfs);
set(0, 'DefaultAxesLineWidth', 1);

% Plotting notes. The above properties will not affect fonts after the
% figure has been placed. If you want to make figure 3 have font 20 axes,
% then BEFORE creating figure 3  (>> figure(3);) you have to issue, 
% e.g. set(0, 'DefaultAxesFontSize', 20) (0 is the root handle - it's 
% properties propagate to all subsequent figures)

% Now, for certain text objects on a plot, you can change properties after
% they are created. For example, after issuing >> title 'TITLE' you can
% change the fontsize of the title text by issuing:
% set(get(gca, 'Title'), 'FontSize', 14).
% To change the font of the axes numbering, you can instead issue
% set(gca, 'FontSize', 14)

% gca gets the axes handle, not to be confused with the figure handle

% Some other tidbits:
% box on/off turns the upper and right-hand axes borders on /off
% grid on/off
% alternatively:
% set(gca, 'XGrid', 'on')
% set(gca,'XAxisLocation', 'top')

% The following is a little more advanced. In the example I tried, I
% plotted four data sets together. These became the Children of the axes
% associated with the figure. (Note that the axes is one of two children of
% figure, the legend being the other). get(gca, 'Children') returns the
% vector of handles to the four data sets. Each of these handles has a
% property called Linewidth, so all four linewidths are set at the same
% time.
% set(get(gca, 'Children'), 'Linewidth', 2);
