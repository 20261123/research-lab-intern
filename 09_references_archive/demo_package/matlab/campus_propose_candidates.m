function data = campus_propose_candidates(data, geom, result, cfg)
% DEMO ONLY: weak outdoor locations, spaced 60m from current/proposed sites.
assert(data.is_demo,'Real candidates require map feasibility review.');
score = median(result.sinr_db,2); score(geom.indoor) = Inf;
[~,order] = sort(score,'ascend'); existing = [data.sites.x_m,data.sites.y_m];
chosen = zeros(0,2);
for p = order'
 if ~isfinite(score(p)), continue; end
 xy = geom.xy(p,:);
 if all(hypot(existing(:,1)-xy(1),existing(:,2)-xy(2))>=cfg.candidate_separation_m)
  chosen(end+1,:) = xy; existing(end+1,:) = xy; %#ok<AGROW>
  if size(chosen,1)==8, break; end
 end
end
assert(size(chosen,1)==8,'Cannot find eight candidates at requested separation.');
t = table("C"+string((1:8)'),repmat("candidate",8,1),chosen(:,1),chosen(:,2),zeros(8,1), ...
 'VariableNames',{'id','role','x_m','y_m','azimuth_deg'});
data.sites = [data.sites;t];
end
