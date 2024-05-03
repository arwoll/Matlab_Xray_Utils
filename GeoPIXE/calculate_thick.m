% Use Flux1 image and a guess of composition to make a thickness map
% For mc_lpi04 (run 110), energy was 11.564 keV, at which cellulouse has a
% total absorptio cross section of 2.6339 cm2/g, according to xraylib

f1 = double(imread('lpi04-110-Flux1.tiff'));
fname = 'lpi04_110';
%%
bkr1 = f1(100:900, 1:100);
bkr2 = f1(90:130, 800:1180);

% f1 = double(imread('lpi01-102-Flux1.tiff'));
% fname = 'lpi01_102';
% bkr1 = f1(500:end, 1:300);
% bkr2 = f1(1:300, 900:end);

% f1 = double(imread('lpi02-107-Flux1.tiff'));
% fname = 'lpi02_107';
% bkr1 = f1(1:400, 1:400);
% bkr2 = f1(800:end, 1280:end);

% f1 = double(imread('lpi03-120-Flux1.tiff'));
% fname = 'lpi03_120';
% bkr1 = f1(1:500, 1:500);
% bkr2 = f1(1600:end, 1600:end);

% % mc_lpi10
% f1 = double(imread('lpi10-494-Flux1.tiff'));
%fname = 'lpi10_494';
% bkr1 = f1(1:1000, 1:1000);
% bkr2 = f1(4000:end, 4000:end);

% % mc_lpi05, E = 11.564
% f1 = double(imread('lpi05-1530-Flux1.tiff'));
% fname = 'lpi05_1530';
% bkr1 = f1(1:500, 1:500);
% bkr2 = f1(2000:end, 3000:end);

% PoplarLPI06, E = 11.564
% f1 = double(imread('lpi06-1534-Flux1.tiff'));
% fname = 'lpi06_1534';
% bkr1 = f1(1:500, 1:700);
% bkr2 = f1(3000:end, 3000:end);

%f1 = double(imread('4276-Flux1.tiff'));
%fname = 'lpi04_110';
%bkr1 = f1(1:1000, 1:1000);
%bkr2 = f1(5000:end, 5000:end);
%%

imagesc(f1)
axis xy equal tight

%%
nb1 = numel(bkr1);
b1 = mean(mean(bkr1));
nb2 = numel(bkr2);
b2 = mean(mean(bkr1));
bkgd = (nb1*b1 + nb2*b2)/(nb1+nb2);
f1c = f1;
f1c(f1>=bkgd) = bkgd;
f1c(f1==0) = bkgd;
ratio = bkgd./f1c;

%%
% C5H10O5 @ 11.564, sigma = 2.634
% C5H10O5 @ 11.25, sigma = 2.85
% C5H10O5 @ 16.3, sigma = 1.041

wtd = log(ratio)/2.634;
t = wtd/1.5;   % t = thickness in cm, rho = 1.5 g/cm3, sig = 2.634 cm2/g
figure(2)
imagesc(t, [0 0.1]); axis xy equal  tight

%%
% next, remove the zeros. This probably introduces a bias but oh well.
%imagesc(tc, [0 .3]); axis xy equal  tight
% Calculate actual wt = g/pixel, using using the density and pixel size.
wt = t*1.5*400/1e8;  
sum(sum(wt))

% mc_lpi04 / 110 : E = 11.564 keV, wt = 0.0718 g
% mc_lpi01 / 102 : E = 11.564 keV, wt = 0.0116 g
% mc_lpi02 / 107 : E = 11.564 keV, wt = 0.0282 g
% mc_lpi03 / 120 : E = 11.564 keV, wt = 0.036 g
% mc_lpi10 / 494 : E = 16.3 keV, wt = 0.99 (!) 
% PoplarLPI05 / 1530 : E = 11.564, wt = 0.183 g
% PoplarLPI06 / 1534 : E = 11.564, wt = 0.259 g
% PoplarLPI07 / 4276 : E = 11.25, wt = 0.177 g (poor xmission meas)

%imwrite(tc, 'cellulose_thickness.tiff')
%imwrite(double(tc), 'cellulose_thickness.tiff')

%%
%Calculate mean thickness of leafy part.
% lpi04
%fname = 'lpi04_110';
vt_coords = 800:1100;
hz_coords = 850:1650;
foo = drawrect([hz_coords(1) vt_coords(1) diff(hz_coords([1 end])) ...
    diff(vt_coords([1 end]))]);
% Thickness, in microns
fprintf('Mean thickness in rect is %.2f nm\n', ...
    mean(mean(t(vt_coords, hz_coords)))*1e7);
% Thickness, in wt /cm2
fprintf('Meanwt conc. in rect is %.3f ug/cm2\n', ...
    1e6*mean(mean(wtd(vt_coords, hz_coords))));
%%
clear tagstruct
tagstruct.ImageLength=size(t, 1);
tagstruct.ImageWidth=size(t, 2);
tagstruct.BitsPerSample=32;
tagstruct.SamplesPerPixel=1;
tagstruct.RowsPerStrip = 1;
tagstruct.SubFileType = Tiff.SubFileType.Default;
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.Orientation = Tiff.Orientation.BottomLeft;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software='MATLAB';

ttname = [fname '_thick_nm.tiff'];
if exist(ttname, 'file')
    fprintf(['Skipping ' ttname ', already exists\n']);
else
    tt = Tiff(ttname, 'w');
    tt.setTag(tagstruct)
    t32 = uint32(1e7*t);
    tt.write(t32);
    tt.close();
end

twname = [fname '_wtconc_ugcm2.tiff'];
if exist(twname, 'file')
    fprintf(['Skipping ' twname ', already exists\n']);
else
    tw = Tiff(twname, 'w');
    tw.setTag(tagstruct)
    w32 = uint32(1e6*wtd);
    tw.write(w32);
    tw.close();
end
%% The following fails since uni16 is insufficient
%imwrite(uint16(t*1e7), [fname '_thick_nm.tiff'])
%imwrite(uint16(wtd*1e6), [fname '_wtconc_ugcm2.tiff'])
