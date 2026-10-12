function cache = campus_link_cache(data, geom, cfg, fc_ghz, seed)
% Store per-site sector sum/max; enough to evaluate every two-site pairing.
% Shared random draws across frequencies, bandwidths and before/after layouts.
% Adjacent-user shadow fading is independent (education simplification).
P = size(geom.xy,1); S = height(data.sites); T = cfg.trials;
cache.sum_mw = zeros(P,S,T); cache.max_mw = zeros(P,S,T);
cache.sites = data.sites;
for tr = 1:T
 user_rng = RandStream('mt19937ar','Seed',mod(seed+104729*tr,2^32-1));
 depth = min(25*rand(user_rng,P,1),25*rand(user_rng,P,1)).*geom.indoor;
 zpen = randn(user_rng,P,1);
 wall = campus_o2i(fc_ghz,depth,zpen,geom.indoor);
 for s = 1:S
  id = char(data.sites.id(s)); id_hash = 0;
  for ch = double(id), id_hash = mod(id_hash*131+ch,1000000007); end
  link_rng = RandStream('mt19937ar','Seed',mod(seed+104729*tr+id_hash,2^32-1));
  dx = geom.xy(:,1)-data.sites.x_m(s); dy = geom.xy(:,2)-data.sites.y_m(s);
  d2 = hypot(dx,dy);
  % LOS probability uses the outdoor horizontal distance for indoor UTs.
  dout = max(cfg.min_distance_m,d2-depth);
  [~,prob] = campus_pathloss(dout,fc_ghz,false(P,1),cfg);
  is_los = rand(link_rng,P,1)<prob;
  [pl,~,~] = campus_pathloss(d2,fc_ghz,is_los,cfg);
  sigma = 6*ones(P,1); sigma(is_los) = 4;
  sf = sigma.*randn(link_rng,P,1);
  bearing = atan2d(dy,dx); % east=0, north=90, counter-clockwise
  relative = mod(bearing-(data.sites.azimuth_deg(s)+(0:120:240))+180,360)-180;
  gain = cfg.element_gain_dbi-min(12*(relative/cfg.horizontal_beamwidth_deg).^2,cfg.max_attenuation_db);
  rx_dbm = cfg.tx_sector_dbm+gain-pl-sf-wall;
  rx_mw = 10.^(rx_dbm/10);
  cache.sum_mw(:,s,tr) = sum(rx_mw,2);
  cache.max_mw(:,s,tr) = max(rx_mw,[],2);
 end
end
cache.fc_ghz = fc_ghz; cache.seed = seed;
end
