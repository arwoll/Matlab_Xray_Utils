% Use Flux1 image and a guess of composition to make a thickness map
% For parsons-435-1, incident energy is 16.15 keV.
% keratin approximate composition:
% one reference claims eukeratins are histidine:lysine:arginine --> 1:4:12
% At 16.15 keV:
%   l-histidine  : C6H9N3O2 : 0.924
%   lysine : C6H14N2O2 : 0.896
%   arginine : C6H14N4O2 : 0.916
%
% Mina finds that keratin has sulfur too -- finds sig(16.15) = 1.3238;
% 
% total molecular formula : C102H233N59O34 : 0.9122

%f1 = double(imread('9657i-Flux1.tiff'));
%fname = 'lpi04_110'; lpi04 is the leaf example
f1 = double(imread('9657i-Flux1.tiff'));
bkr1 = f1(254:355, 52:373);
bkr2 = f1(13:57, 669:759);
%% %%

imagesc(f1, [5000 6500]);
axis xy equal tight

%% 
% plot the background region 1 

vt_coords = 254:355;
hz_coords = 52:373;
foo = drawrect([hz_coords(1) vt_coords(1) diff(hz_coords([1 end])) ...
    diff(vt_coords([1 end]))]);
%% 
% plot the background region 2
% vt_coords = 669:759;
% hz_coords = 13:57;
% foo = drawrect([hz_coords(1) vt_coords(1) diff(hz_coords([1 end])) ...
%     diff(vt_coords([1 end]))]);


%%
nb1 = numel(bkr1); % calculate the number of pixels in background 1
b1 = mean(mean(bkr1)); % Take the average of background 1 (rows & columns)
nb2 = numel(bkr2); % same as background 1
b2 = mean(mean(bkr1));
bkgd = (nb1*b1 + nb2*b2)/(nb1+nb2); % weighted average of 2 background regions
f1c = f1; % make a copy of the image
f1c(f1>=bkgd) = bkgd; %anywhere the counts are more than the average transmission in background, set value to average
f1c(f1==0) = bkgd; % anywhere you have zero transmission, set the value to the average transmission in background
ratio = bkgd./f1c; % calculate ratio incident/transmitted (I0/I1)

%%
% C5H10O5 @ 11.564, sigma = 2.634
% C5H10O5 @ 11.25, sigma = 2.85
% C5H10O5 @ 16.3, sigma = 1.041
% keratin at 16.15 (see top): 1.33488, new sigma of 4/12/16; prev= 1.3238

wtd = log(ratio)/1.33488;
% wtd= density*thickness= (ln(I0/I1))/ sigma
%t = wtd/1.5;   % t = thickness in cm, rho = 1.5 g/cm3, sig = 0.91 cm2/g
figure(2) % creates a new figure
%imagesc(t, [0 0.1]); axis xy equal  tight
imagesc(wtd, [0 0.1]); axis xy equal tight

%%
% next, remove the zeros. This probably introduces a bias but oh well.
%imagesc(tc, [0 .3]); axis xy equal  tight
% Calculate actual wt = g/pixel, using using the density and pixel size.
wt = wtd*400/1e8;  
sum(sum(wt))

% HornSections1
% total image : 118.7 mg
% Right-hand section( sum(sum(wt(100:1000, 700:1400)))) : 54.1 mg
% Left-hand section (sum(sum(wt(80:1050, 100:700))) ) : 61.2 mg
%   -- sub-total : 118.3 mg


%imwrite(tc, 'cellulose_thickness.tiff')
%imwrite(double(tc), 'cellulose_thickness.tiff')

%% 
% enter area to average aereal density

vt_coords = 90:273;
hz_coords = 791:979;
foo = drawrect([hz_coords(1) vt_coords(1) diff(hz_coords([1 end])) ...
    diff(vt_coords([1 end]))]);
% report aereal density
fprintf('Meanwt conc. in rect is %.3f ug/cm2\n', ...
    1e6*mean(mean(wtd(vt_coords, hz_coords))));

%% The following fails since uni16 is insufficient
%imwrite(uint16(t*1e7), [fname '_thick_nm.tiff'])
%imwrite(uint16(wtd*1e6), [fname '_wtconc_ugcm2.tiff'])
