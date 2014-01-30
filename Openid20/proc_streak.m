function proc_streak(imfile, specfile, scann)
% function proc_streak(imfile, specfile, scann)
%   Developing function to open streak-camera data from the April 2007 PLD @ G3 run,
%   Gokhkan Arikan, John Ferguson, and Arthur Woll.  
%
%   For these data, the "LSYN" signal from the Gruner 1K controller was used to
%   directly control the shutter, so that the CCD data was good regardless of whether
%   SPEC could keep up with the CCD. However, SPEC controlled when the laser fired,
%   and sometimes missed frames, so we want an algorithm to automatically find the
%   correspondence between CCD frame number and laser pulse.  Note too that if the
%   shutter is perfectly sync'd with LSYN, then the first illuminated frame is frame
%   number 4 (4th  column of the image as loaded using imread).  If the spec missed
%   points at the very beginning (rare, and never more than one that I recall), then
%   the first illuminated frame is frame 5. 
%
%   Other nice features:
%      Calculate the growth rate  in pulses/ML.
%      Make some plots in real units (q, time), marking laser pulses
%      Optionally create plots such as average signal between pulses, or evolution of
%      signal between particular pulses.
%      Peak finding (guassian fitting?) for the diffuse peak location % width.
%      List where SPEC "mistakes" occurred.
%
%    Eventually, we should incorporate intensity & distortion correction

MIN_LIVE = 50000;
sample_to_detector = 829.79-84;
halfML_frames = 94:129;

plottitle = [sprintf('%s Scan %d', strrep(specfile, '_', '\_'), scann)];

ccd=double(imread(imfile));
first_live_frame = find(sum(ccd(1:10,:), 2)>MIN_LIVE, 1)

npts = size(ccd,1);     % number of streak frames
delpts = size(ccd,2);   % number of pixels in q_parallel (=1024/hbin)

b = openspec(specfile, scann);
% For reference:
% b = 
%                data: [13x1960 single]
%               scann: 47
%            scanline: 'tseries 1964 0.24'
%                npts: 1960
%             columns: 13
%             headers: {1x13 cell}
%         motor_names: {1x40 cell}
%     motor_positions: [1x40 double]
%              cttime: 0.2400
%            complete: 0
%                ctrs: {1x11 cell}
%                var1: [1960x1 single]
%                mot1: 'time'
%                dims: 1
%                size: 1960

delta_t = mean(b.data(1,(first_live_frame+1):end)-b.data(1,first_live_frame:end-1));  % Time between CCD frames
t = b.data(1,2:end);      % The first time point is WAY early, and should be extra. Also, all the points 
t(1) = t(2)-delta_t;      % 
t=t-t(1);                 % total offset for points >=3 is  t = t -b.data(3)+deltat  

if length(t) < npts
   needpts = npts - length(t); 
   t( [(length(t)+1):npts]) = t(end) + delta_t*[1:needpts];
end

%%
% Approximate sample-to-detector is G[12] - D(gamT axis to CCD face 84 mm)
% Approximate pixel size is 0.05 mm * 4 (4 is hbin)
pk = find_peak([1:delpts]', sum(ccd(4:6,:),1)');
qrange = [1:delpts];
pixel_size = 0.05*(1024/delpts);
q = 4*pi/1.24*sin(atan((qrange-pk.com)*pixel_size/sample_to_detector)/2);
  

logra = [6.5 8];
figure(4)
imagesc(log(ccd(:,qrange)+1)', logra)

figure(1)

%imagesc(t,q(qrange),ccd', [400 2000])
imagesc(t,q(qrange),log(ccd(:,qrange)+1)', logra)


axis fill

xlabel 'Time (sec)' 
ylabel 'Q (inv. angstroms)'
title(plottitle);
bigfonts

figure(2)
plot(q, mean(ccd(halfML_frames, :),1))
%plot(q, mean(ccd(trange0, :),1), q, mean(ccd(trange1, :), 1), q, mean(ccd(trange2, :), 1), ...
%    q, mean(ccd(trange3, :), 1), 'Linewidth', 1.0)
set(gca, 'XTick', -.12:.02:.2);
set(gca, 'XMinorTick', 'on')
set(gca, 'XGrid', 'on')
axis([-.12 .2 700 1.3e3])
xlabel 'Q (inv. angstroms)'
title([plottitle ', 0.5 ML'])
bigfonts

figure(3)
specchans = pk.wl:pk.wr;
plot(sum(ccd(:, specchans), 2), 'bo')
%axis([3.2 400 13192 45000])

%%
% export_base = sprintf('%s_scan%d', specfile, scann);
% figure(1)
% set(gcf, 'PaperPositionMode', 'auto')
% print('-dpng',  [export_base '_rgb'])
% 
% figure(2)
% set(gcf, 'PaperPositionMode', 'auto')
% print('-dpng', [export_base '_halfML'])

