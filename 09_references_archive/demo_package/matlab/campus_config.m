function cfg = campus_config()
% Units: coordinates m, carrier GHz, bandwidth Hz, powers dBm/mW.
cfg.grid_m = 2.5;
cfg.trials = 20;
cfg.seed = 38901;
cfg.validation_seed = 738901;
cfg.h_bs_m = 25;
cfg.h_ut_m = 1.5;
cfg.tx_sector_dbm = 43;
cfg.nf_db = 7;
cfg.element_gain_dbi = 8;
cfg.horizontal_beamwidth_deg = 65;
cfg.max_attenuation_db = 30;
cfg.min_distance_m = 10;
cfg.max_distance_m = 5000;
cfg.heatmap_limits_db = [-20 30];
cfg.candidate_separation_m = 60;
cfg.plot_visible = 'off';
end
