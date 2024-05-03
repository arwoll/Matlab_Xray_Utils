%% Example use of get_roi_spectrum.m
load imap.mat
figure(1);
imagesc(x, y, Imap_sum);            % Transpose is required since in imagesc,
                                    % the 1st INDEX is y values (row
                                    % number)
%%
y1 =  get_roi_spectrum(Imap_full);
y2 =  get_roi_spectrum(Imap_full);
y3 =  get_roi_spectrum(Imap_full);
%%
figure(2);
plot(Q, [y1 y2 y3]);