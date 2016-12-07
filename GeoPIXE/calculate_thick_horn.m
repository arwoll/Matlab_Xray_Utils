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

% f1 = double(imread('lpi04-110-Flux1.tiff'));
% fname = 'lpi04_110';
% bkr1 = f1(250:1500, 1:400);
% bkr2 = f1(2357:2760, 967:2830);

%f1 = double(imread('KeratinPellets-9657-Flux1.tiff'));
%fname = 'lpi04_110';
%bkr1 = f1(148:904, 16:147);
%bkr2 = f1(90:131, 774:1183);

% Louisa April 18 2016
f1 = double(imread('HornSections1.tiff'));
bkr1 = f1(148:904, 16:147); %
bkr2 = f1(90:131, 774:1183);



%%

imagesc(f1, [4000 7000]);
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
% keratin at 16.15 (see top): 1.3238

wtd = log(ratio)/1.3238;
%t = wtd/1.5;   % t = thickness in cm, rho = 1.5 g/cm3, sig = 0.91 cm2/g
figure(2)
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
%Calculate mean thickness of leafy part.
% lpi04
%fname = 'lpi04_110';
vt_coords = 300:700;
hz_coords = 300:500;
foo = drawrect([hz_coords(1) vt_coords(1) diff(hz_coords([1 end])) ...
    diff(vt_coords([1 end]))]);
% Thickness, in microns
%fprintf('Mean thickness in rect is %.2f nm\n', ...
   % mean(mean(t(vt_coords, hz_coords)))*1e7);
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
