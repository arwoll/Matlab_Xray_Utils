% clc
close all
clear

%%
specfile = 'Spring10_G32';
%  scans = 23:87  ;  % Spot 1
% scans = 98:162;     % Spot 2
% scans = 173:237;     % Spot 3
scans = [248:312 316:325];     % Spot 4


y = length(scans);
s = cell(1, y);

i2_norm = 7e4;

for j = 1:y
    s{j} = openspec(specfile , scans(j));
end

%%
fits = s; 
sd = s;
clear Afit Afp  att G H
for j = 1:length(s)
    
%     s=openspec(specfile , scans(j));
    
    a = double(s{j}.var1);      % zeta
    b = double(s{j}.data(9,:)'); % apd
    c = double(s{j}.data(7,:)'); % I2
    
    b = b./c * i2_norm;
    
    G(j,1) = s{j}.motor_positions(strmatch('Mu', s{j}.motor_names));  % Mu value
    att(j,1) = s{j}.motor_positions(strmatch('Attenuator', s{j}.motor_names));
    
    d=find_peak(a,b);

    est = [d.area d.com d.fwhm a(1)];
    
    fit_opt = fitoptions('Method','NonlinearLeastSquares','StartPoint',est);

    e = fittype('(a1*0.9394/c1)*exp(-0.5*((x-b1)*2.35482/c1)^2)+d1');

    sd{j}.x = a; sd{j}.yg = b; 
    fits{j} = fit(a,b,e, fit_opt);
    
    Afit(j,1)= fits{j}.a1;
    Afp(j,1) = d.area;
end

%%
[G, order] = sort(G);
Afit = Afit(order);
Afp = Afp(order);
att = att(order);
sd = sd(order);
fits = fits(order);

%%
% for j = 1:length(s)
%    figure(2);
%    clf;
%    x = sd{j}.x; y =   sd{j}.yg; yf = fits{j}(x);
%    plot(x, y, 'b.',x, yf, 'r-');
%    pause
% end

%%

att_vals = unique(att);
att_corr = ones(size(att_vals));
att_scans = cell(size(att_vals));
for k = 1:length(att_vals)
    att_scans{k} = find(att_vals(k) == att);
end

%%
att_corr(1) = 1;
att_corr(2) = att_corr(1)*2e2;
att_corr(3) = att_corr(2)*3e1;
att_corr(4) = att_corr(3)*1e1;

Afitc = Afit;
Afpc = Afp;
hold off
for k = 1:length(att_corr)
    Afitc(att_scans{k}) = Afit(att_scans{k})*att_corr(k);
    Afpc(att_scans{k}) = Afp(att_scans{k})*att_corr(k);
    semilogy(G(att_scans{k}),[Afitc(att_scans{k})  Afpc(att_scans{k})],'.')
    hold all 
end

%%
outfile = 'Spring10_G32_spot4_reflect.txt';

f = fopen(outfile, 'wt');
fprintf(f, '# Spring10_G32  -- approximate cts/sec\n');
fprintf(f, ['# Mu    I (Gauss)  I (Findpeak) '] );
fclose(f);
outvar = [G Afitc Afpc];
dlmwrite(outfile,outvar, 'delimiter', '\t', 'precision', '%10g', '-append');


%%
f = fopen('Spring10_G32_spot4_reflect.txt');
a = textscan(f, '%f %f %f','commentstyle', '#');
s4 = [a{:}];
fclose(f);

f = fopen('Spring10_G32_spot3_reflect.txt');
a = textscan(f, '%f %f %f','commentstyle', '#');
s3 = [a{:}];
fclose(f);

f = fopen('Spring10_G32_spot2_reflect.txt');
a = textscan(f, '%f %f %f','commentstyle', '#');
s2 = [a{:}];
fclose(f);

f = fopen('Spring10_G32_spot1_reflect.txt');
a = textscan(f, '%f %f %f','commentstyle', '#');
s1 = [a{:}];
fclose(f);

clf;
 semilogy(s4(:,1), s4(:,2), s3(:,1), s3(:,2)*10, s2(:,1), s2(:,2)*100, s1(:,1), s1(:,2)*1e3, ...
     'linewidth', 1.5)
 
title 'DIP Thickness series : Reflectivity'
xlabel 'Mu'