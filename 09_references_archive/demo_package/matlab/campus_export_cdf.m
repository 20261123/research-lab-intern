function campus_export_cdf(output_dir)
% Editable presentation curve points from pooled validation samples.
file = fullfile(output_dir,'validation_results.mat');
x = load(file,'res','geom');
fields = {'base35','base28wide','add35','add28wide'};
groups = {'all','indoor','outdoor'};
rows = table();
for g = 1:3
 mask = true(size(x.geom.indoor));
 if g==2, mask = x.geom.indoor; elseif g==3, mask = ~x.geom.indoor; end
 if ~any(mask), continue; end
 for k = 1:numel(fields)
  v = x.res.(fields{k}).capacity_mbps(mask,:); v = sort(v(:)); n = numel(v);
  idx = unique(round(linspace(1,n,min(n,1001)))');
  % Explicit (first capacity,0) plus full tail at probability 1.
  capacity = [v(1);v(idx)]; probability = [0;idx/n];
  rows = [rows;table(repmat(string(groups{g}),numel(capacity),1), ...
   repmat(string(fields{k}),numel(capacity),1),capacity,probability, ...
   'VariableNames',{'group','condition','capacity_mbps','probability'})]; %#ok<AGROW>
 end
end
writetable(rows,fullfile(output_dir,'cdf_curves.csv'));
end
