function output_dir = campus_main(mode, overrides)
% campus_main('demo') or campus_main('sejong')
% Actual data must be surveyed first. Demo keeps original example geometry.
if nargin<1, mode = 'demo'; end
if nargin<2, overrides = struct(); end
cfg = campus_config();
keys = fieldnames(overrides);
for k = 1:numel(keys)
 assert(isfield(cfg,keys{k}),'Unknown configuration field.'); cfg.(keys{k}) = overrides.(keys{k});
end
assert(cfg.grid_m>0 && cfg.trials>=1 && cfg.trials==fix(cfg.trials),'Invalid grid/trials.');
assert(cfg.validation_seed~=cfg.seed,'Training and validation seeds must differ.');
root = fileparts(fileparts(mfilename('fullpath')));
if strcmp(mode,'demo')
 data = campus_demo_data();
elseif strcmp(mode,'sejong')
 data = campus_load_data(fullfile(root,'input','sejong'));
else
 error('Use demo or sejong mode.');
end
geom = campus_geometry(data,cfg);
fprintf('%s: %d unique positions, %d trials\n',data.label,size(geom.xy,1),cfg.trials);
output_dir = fullfile(root,'results',[mode '_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
mkdir(output_dir);
if data.is_demo
 preliminary = campus_link_cache(data,geom,cfg,28,cfg.seed);
 b = find(data.sites.role=="baseline"); e = find(data.sites.role=="external");
 r = campus_evaluate(preliminary,b,e,800e6,cfg);
 data = campus_propose_candidates(data,geom,r,cfg); clear preliminary r;
end
writetable(data.sites,fullfile(output_dir,'sites_used.csv'));
cache = campus_link_cache(data,geom,cfg,28,cfg.seed);
[selected,ranking] = campus_optimize(cache,cfg);
writetable(ranking(:,1:5),fullfile(output_dir,'candidate_ranking.csv'));
writetable(data.sites(selected,:),fullfile(output_dir,'selected_sites.csv'));
clear cache;
% Selection uses train seed, final evidence uses an independent validation seed.
summary = table(); metrics = table();
phases = {'selection','validation'}; seeds = [cfg.seed,cfg.validation_seed];
for phase = 1:2
 res = struct(); b = find(data.sites.role=="baseline"); e = find(data.sites.role=="external");
 cache = campus_link_cache(data,geom,cfg,3.5,seeds(phase));
 res.base35 = campus_evaluate(cache,b,e,100e6,cfg);
 res.add35 = campus_evaluate(cache,[b;selected],e,100e6,cfg); clear cache;
 cache = campus_link_cache(data,geom,cfg,28,seeds(phase));
 res.base28same = campus_evaluate(cache,b,e,100e6,cfg);
 res.add28same = campus_evaluate(cache,[b;selected],e,100e6,cfg);
 res.base28wide = campus_evaluate(cache,b,e,800e6,cfg);
 res.add28wide = campus_evaluate(cache,[b;selected],e,800e6,cfg); clear cache;
 fields = fieldnames(res);
 for z = 1:numel(fields)
  summary = [summary;campus_summary(res.(fields{z}),geom,fields{z},phases{phase})]; %#ok<AGROW>
 end
 for band = [35 28]
  if band==35, before = res.base35; after = res.add35;
  else, before = res.base28wide; after = res.add28wide; end
  change = median(after.sinr_db-before.sinr_db,2);
  if band==35, carrier = 3.5; else, carrier = 28; end
  metrics = [metrics;table(string(phases{phase}),carrier, ...
   100*mean(change<0),100*mean(change>0), ...
   'VariableNames',{'phase','fc_ghz','positions_worse_pct','positions_better_pct'})]; %#ok<AGROW>
 end
 save(fullfile(output_dir,[phases{phase} '_results.mat']),'res','geom','cfg','data','selected','-v7.3');
 % Position rows use trial medians; headline summary pools positions x trials.
 t = table(geom.xy(:,1),geom.xy(:,2),geom.indoor, ...
  median(res.base35.sinr_db,2),median(res.base28same.sinr_db,2), ...
  median(res.base28wide.sinr_db,2),median(res.add28wide.sinr_db,2), ...
  median(res.base28wide.capacity_mbps,2),median(res.add28wide.capacity_mbps,2), ...
  median(res.base28wide.signal_dbm,2),median(res.base28wide.interference_dbm,2), ...
  'VariableNames',{'x_m','y_m','indoor','sinr35_db','sinr28same_db','sinr28wide_db', ...
  'sinr28added_db','capacity28_mbps','capacity28added_mbps','signal28_dbm','interference28_dbm'});
 writetable(t,fullfile(output_dir,[phases{phase} '_positions.csv']));
 if phase==2
  plotdata = data; plotdata.sites.role(selected) = "selected";
  campus_plots(plotdata,geom,res,fullfile(output_dir,'figures'),cfg,'validation');
 end
 clear res;
end
writetable(summary,fullfile(output_dir,'summary.csv'));
writetable(metrics,fullfile(output_dir,'spatial_changes.csv'));
campus_export_cdf(output_dir);
fid = fopen(fullfile(output_dir,'run_metadata.json'),'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(struct('label',data.label,'is_demo',data.is_demo, ...
 'config',cfg,'selected_ids',data.sites.id(selected),'aggregation', ...
 'CDF and summary pool equally weighted positions x trials; maps median trials', ...
 'model_scope','UMa large scale; independent SF; horizontal element pattern; full load reuse 1')));
disp(summary(summary.phase=="validation" & summary.group=="all",:));
fprintf('Results: %s\n',output_dir);
end
