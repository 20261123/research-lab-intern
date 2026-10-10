function result = campus_evaluate(cache, service_idx, external_idx, bandwidth_hz, cfg)
assert(~isempty(service_idx),'Need at least one serving site.');
assert(isempty(intersect(service_idx,external_idx)),'Service and external sites overlap.');
assert(bandwidth_hz>0,'Bandwidth must be positive.');
S = reshape(max(cache.max_mw(:,service_idx,:),[],2),size(cache.max_mw,1),cfg.trials);
total = reshape(sum(cache.sum_mw(:,[service_idx(:);external_idx(:)],:),2),size(S));
I = max(total-S,0);
noise_dbm = -174+10*log10(bandwidth_hz)+cfg.nf_db;
noise_mw = 10^(noise_dbm/10);
result.sinr_linear = S./(I+noise_mw);
result.sinr_db = 10*log10(result.sinr_linear);
result.sir_db = 10*log10(S./max(I,realmin));
result.capacity_mbps = bandwidth_hz*log1p(result.sinr_linear)/log(2)/1e6;
result.signal_dbm = 10*log10(S);
result.interference_dbm = 10*log10(max(I,realmin));
result.noise_dbm = noise_dbm;
result.fc_ghz = cache.fc_ghz; result.bandwidth_hz = bandwidth_hz;
assert(all(isfinite(result.sinr_db(:))) && all(isfinite(result.capacity_mbps(:))), ...
 'Nonfinite simulation output.');
end
