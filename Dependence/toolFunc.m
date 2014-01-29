function h = toolFunc(opt);

%ディスプレイと目との距離(m)
% Distance between eyes and display
set_length_d2e = 1.33;
%解像度(pixel)とそれに対応する実寸(m)
% pixel and the corresponding length (unit: meter)
set_kaizodo = 768.0;
set_nagasa = 0.802;

h.get_angle = @(d) (atan((d*opt.minimize_scale)*set_nagasa/set_kaizodo/set_length_d2e)*180.0/pi);
h.get_distance = @(a) ((tan(a*pi/180.0)*set_length_d2e*set_kaizodo/set_nagasa)/opt.minimize_scale);
h.gauss = @(sigma, d) (1/(sigma * sqrt(2 * pi))) * exp(-((d.^2) ./ (2*(sigma.^2))));
