function loss_db = campus_o2i(fc_ghz, depth_m, z_penetration, indoor)
% Low-loss O2I: user-specific depth and Gaussian wall variability.
glass_db = 2+0.2*fc_ghz; concrete_db = 5+4*fc_ghz;
wall_db = 5-10*log10(0.3*10^(-glass_db/10)+0.7*10^(-concrete_db/10));
loss_db = (wall_db+0.5*depth_m+4.4*z_penetration).*indoor;
end
