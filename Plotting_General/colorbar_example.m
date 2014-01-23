% making surface plots.  Use teniers5_34_surfplot.png.
bigfonts;
sq_fig = false;
%Square fig
if sq_fig
    fpos = [949   515   577   420];
    apos = [78.0000   59  355.5651  334.5500];
else
    %Rect fig
    fpos = [736   659   511   233];
    apos = [69.1924   35.1762  314.8939  172];
end
set(gcf, 'Position', fpos);
set(gca, 'Units', 'pixels');
set(gca, 'Position', apos);
fonts = 18;
interp_on = true;
logscale = true;
ele = scandata.roi(1);
x = ele.x; y = ele.y; 
z = ele.z;

XCEN = 33.39; YCEN = 286; 
x = x-XCEN; y = -(y-YCEN);

mxz = max(z(:));
mnz = 1;

if logscale 
    z = log(z+1);
end

surf(y, x, z, 'LineStyle', 'none')
axis tight; view(0, -90);
shading interp;
grid off


h = colorbar;
if logscale
    mxz = log10(mxz);
    mnz = log10(mnz);
    upper = mxz-mod(mxz, 1);
    lower = mnz-mod(mnz, 1) + 1;
    ytick = lower:upper;
    for k = 1:length(ytick)
        yticklabel{k} = sprintf('%g', 10^ytick(k));
    end
    set(h, 'ytick', log(10.^ytick));
    set(h, 'yticklabel', yticklabel, 'FontSize', fonts);
end

if sq_fig
xlabel 'Lateral Position (mm)'
ylabel 'Depth(mm)'
end
%set(gcf, 'Interpreter', 'latex');
if any(strcmp(ele.sym, {'Pb', 'Hg'}))
        leg_text = [ele.sym ' L\alpha '];
    else
        leg_text = [ele.sym ' K\alpha '];
end
h = text(0.82, 0.94, leg_text, 'Units', 'Normalized', 'FontSize', fonts);

if sq_fig
    xlabel 'Lateral Position (mm)'
    ylabel 'Depth(mm)'

    %set(h,  'Interpreter', 'latex');
    text(1.28, 0.84, 'Intensity (Integrated Counts)', 'Units', 'Normalized', ...
        'FontSize', fonts,'Rotation', -90);
end
%set(gcf, 'Interpreter', 'tex');
