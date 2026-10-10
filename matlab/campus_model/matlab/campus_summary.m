function t = campus_summary(result, geom, condition, phase)
groups = ["all","indoor","outdoor"];
count = zeros(3,1); p05 = nan(3,1); p50 = p05; avg = p05; tail = p05; sinr50 = p05;
for g = 1:3
 mask = true(size(geom.indoor));
 if g==2, mask = geom.indoor; elseif g==3, mask = ~geom.indoor; end
 v = result.capacity_mbps(mask,:); v = v(:); count(g) = numel(v);
 if isempty(v), continue; end
 p05(g) = campus_quantile(v,0.05); p50(g) = campus_quantile(v,0.5);
 avg(g) = mean(v); a = sort(v); tail(g) = mean(a(1:max(1,ceil(0.05*numel(a)))));
 d = result.sinr_db(mask,:); sinr50(g) = median(d(:));
end
t = table(repmat(string(phase),3,1),repmat(string(condition),3,1),groups',count, ...
 p05,p50,avg,tail,sinr50,'VariableNames', ...
 {'phase','condition','group','samples','p05_mbps','median_mbps','mean_mbps','bottom5_mean_mbps','median_sinr_db'});
end
