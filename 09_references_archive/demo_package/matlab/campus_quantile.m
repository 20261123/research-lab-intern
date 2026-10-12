function q = campus_quantile(values, p)
% Linear interpolation on empirical CDF plotting positions (i-0.5)/n.
% No Statistics Toolbox dependency. Matches MATLAB quantile convention.
v = sort(values(:)); n = numel(v);
if n==0, q = NaN(size(p)); return; end
assert(all(isfinite(v)) && all(p>=0 & p<=1),'Invalid quantile input.');
index = min(max(n*p+0.5,1),n);
lo = floor(index); hi = ceil(index);
q = reshape(v(lo),size(p)).*(hi-index)+reshape(v(hi),size(p)).*(index-lo);
same = lo==hi; q(same) = v(lo(same));
end
