%%
make_composite_multi('Test_data/8_4', 7:9, 10, 1e5)
%Opening Test_data/8_4 scan 7
%Opening Test_data/8_4 scan 8
%Opening Test_data/8_4 scan 9


%%
make_composite('Test_data/8_4', 7:9, 10, 1e5)
%Opening Test_data/8_4 scan 7
%Opening Test_data/8_4 scan 8
%Opening Test_data/8_4 scan 9

%%
fname = 'Test_data/130617_film_16';
scans = [4 5 6];

make_composite_multi(fname, scans, 9.849, 1e5);
%export_png(1, fname);
