function y = spectrum2(e, element, y0, sig, a, b, c)

global n ele

if  ~isstruct(ele)
    fprintf 'Requires: ele, n from elam.mat';
    return
end

if element <1 || element > 98
    fprintf 'Second arg is the atomic number, must be between 1 and 98'
    return
end

kedge = ele(element).edge(1);

klines = size(kedge.lines, 2);

if klines == 0 return
end

y = zeros(size(e));

for k = 1:klines
    e0 = kedge.lines(k).e/1000;
    rel_int = kedge.lines(k).i;
    y = y + rel_int * (y0* ( exp(-((e-e0)/sig).^2/2)) + ...
        a * y0 * (e<e0) .* exp(b * (e-e0)) .* ...
        (1 - exp(-c/2*((e-e0)/sig).^2)));
end
