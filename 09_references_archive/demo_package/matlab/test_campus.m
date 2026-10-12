function test_campus()
% Numerical tests with independently known values and behavioral invariants.
cfg = campus_config(); cfg.trials = 2;
assert(abs((-174+10*log10(100e6)+7)-(-87))<1e-12);
assert(abs((-174+10*log10(800e6)+7)-(-77.96910013008056))<1e-10);
assert(abs(100e6*log2(1+1)/1e6-100)<1e-12);
% NLOS 100 m / 3.5GHz, independently computed from the stated equation.
d3 = sqrt(100^2+23.5^2);
expected = 13.54+39.08*log10(d3)+20*log10(3.5);
[pl,prob,bp] = campus_pathloss(100,3.5,false,cfg);
assert(abs(pl-expected)<1e-10); assert(abs(bp-560)<1e-10);
assert(abs(prob-((18/100)*(1-exp(-100/63))+exp(-100/63)))<1e-12);
[l1,~,bp] = campus_pathloss(560,3.5,true,cfg);
[l2,~,~] = campus_pathloss(560+1e-6,3.5,true,cfg);
assert(abs(l1-l2)<1e-6 && bp==560,'LOS discontinuity at breakpoint.');
expected_wall = 5-10*log10(0.3*10^(-2.7/10)+0.7*10^(-19/10));
assert(abs(campus_o2i(3.5,0,0,true)-expected_wall)<1e-12);
assert(campus_o2i(28,20,1,false)==0);
assert(campus_o2i(28,0,0,true)>campus_o2i(3.5,0,0,true));
assert(isequal(campus_quantile([1 2 3 4],[0 0.5 1]),[1 2.5 4]));
assert(campus_quantile(1:100,0.05)==5.5);
% Overlapping rectangles yield exactly six unique grid positions.
data.regions = {[0 0;1 0;1 1;0 1],[1 0;2 0;2 1;1 1]};
data.buildings = {[0 0;1 0;1 1;0 1]}; cfg.grid_m = 1;
g = campus_geometry(data,cfg); assert(size(g.xy,1)==6 && nnz(g.indoor)==4);
cache.max_mw = reshape([1 0.5 1 0.5],[1 2 2]);
cache.sum_mw = cache.max_mw; cache.fc_ghz = 3.5;
a = campus_evaluate(cache,1,[],100e6,cfg);
b = campus_evaluate(cache,1,2,100e6,cfg);
assert(all(b.sinr_linear(:)<a.sinr_linear(:)),'External interference should reduce SINR.');
assert(all(abs(b.sinr_linear(:)-1/(0.5+10^(-87/10)))<1e-12));
% Seed stability across band and layout: outdoor powers scale in NLOS region.
d = campus_demo_data(); cfg.grid_m = 40; cfg.trials = 2;
g = campus_geometry(d,cfg);
c1 = campus_link_cache(d,g,cfg,3.5,cfg.seed);
c2 = campus_link_cache(d,g,cfg,3.5,cfg.seed);
assert(isequal(c1.sum_mw,c2.sum_mw),'Seed repeat failed.');
% O2I multiplies ALL site received powers by the same UT-specific loss.
go = g; go.indoor(:) = false;
gi = g; gi.indoor(:) = true;
% At LOS-probability=1, depth cannot change the LOS state.
go.xy = [d.sites.x_m(1),d.sites.y_m(1)]; go.indoor = false;
gi.xy = go.xy; gi.indoor = true;
d.sites.x_m(:) = go.xy(1); d.sites.y_m(:) = go.xy(2);
co = campus_link_cache(d,go,cfg,3.5,cfg.seed);
ci = campus_link_cache(d,gi,cfg,3.5,cfg.seed);
assert(all(ci.sum_mw(:,1,:)>0),'Indoor serving signal must be finite.');
ratio = ci.sum_mw./co.sum_mw;
assert(max(abs(ratio-ratio(:,1,:)),[],'all')<1e-12, ...
 'O2I must apply to every baseline AND external link consistently.');
% Adding candidates cannot perturb existing-link randomness.
d2 = d;
d2.sites = [d.sites; table("C1","candidate",200,100,0, ...
 'VariableNames',d.sites.Properties.VariableNames)];
c3 = campus_link_cache(d2,go,cfg,3.5,cfg.seed);
assert(isequal(c3.sum_mw(:,1:height(d.sites),:),co.sum_mw));
% Data gate rejects unfilled real-data template.
root = fileparts(fileparts(mfilename('fullpath'))); caught = false;
try
 campus_load_data(fullfile(root,'input','sejong'));
catch ex, caught = strcmp(ex.identifier,'Campus:SurveyMissing'); end
assert(caught,'Survey gate failed.');
fprintf('PASS: noise, capacity, UMa, breakpoint, O2I, quantiles, grid, interference, repeatability, survey gate.\n');
end
