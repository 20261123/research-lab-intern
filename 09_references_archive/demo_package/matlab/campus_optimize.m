function [selected, ranking] = campus_optimize(cache, cfg)
b = find(cache.sites.role=="baseline"); e = find(cache.sites.role=="external");
c = find(cache.sites.role=="candidate"); assert(numel(c)==8,'Need eight candidates.');
pairs = nchoosek(c,2); p05 = zeros(28,1); med = p05; avg = p05;
for k = 1:size(pairs,1)
 r = campus_evaluate(cache,[b;pairs(k,:)'],e,800e6,cfg);
 v = r.capacity_mbps(:);
 p05(k) = campus_quantile(v,0.05); med(k) = campus_quantile(v,0.5); avg(k) = mean(v);
end
ranking = table(cache.sites.id(pairs(:,1)),cache.sites.id(pairs(:,2)),p05,med,avg, ...
 pairs(:,1),pairs(:,2),'VariableNames', ...
 {'candidate1','candidate2','p05_mbps','median_mbps','mean_mbps','index1','index2'});
ranking = sortrows(ranking,{'p05_mbps','median_mbps','mean_mbps'},'descend');
selected = [ranking.index1(1);ranking.index2(1)];
end
