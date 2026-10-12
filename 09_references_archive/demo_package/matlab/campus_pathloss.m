function [pl_db, p_los, bp_m] = campus_pathloss(d2d_m, fc_ghz, is_los, cfg)
% TR 38.901 Table 7.4.1-1 UMa, hUT=1.5 m, hE=1 m.
assert(cfg.h_ut_m==1.5 && cfg.h_bs_m==25,'UMa implementation fixed to 25/1.5 m.');
assert(fc_ghz>0.5 && fc_ghz<100,'UMa carrier range is 0.5 < fc < 100 GHz.');
assert(all(d2d_m(:)<=cfg.max_distance_m),'A link exceeds UMa 5 km range.');
d = max(d2d_m,cfg.min_distance_m);
d3 = hypot(d,cfg.h_bs_m-cfg.h_ut_m);
% Breakpoint frequency MUST be Hz. Path-loss log frequency MUST be GHz.
bp_m = 4*(cfg.h_bs_m-1)*(cfg.h_ut_m-1)*(fc_ghz*1e9)/3e8;
los1 = 28+22*log10(d3)+20*log10(fc_ghz);
los2 = 28+40*log10(d3)+20*log10(fc_ghz) ...
       -9*log10(bp_m^2+(cfg.h_bs_m-cfg.h_ut_m)^2);
los = los1; los(d>bp_m) = los2(d>bp_m);
nlos = max(los,13.54+39.08*log10(d3)+20*log10(fc_ghz) ...
           -0.6*(cfg.h_ut_m-1.5));
pl_db = nlos; pl_db(is_los) = los(is_los);
% hUT < 13m: the UMa height correction is zero.
p_los = min(18./d,1).*(1-exp(-d/63))+exp(-d/63);
end
