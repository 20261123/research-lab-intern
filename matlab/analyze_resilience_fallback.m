function analyze_resilience_fallback()
repo=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(repo,'results','labgemini4','random20_resilience');
load(fullfile(out,'random20_results.mat'),'normalC','worstC','normalID','J','seeds','indoor','summary');
n=size(normalC,1);rows=cell(0,9);qos=cell(0,6);
% Alternative-band choice assumes both carriers are available and a capable
% terminal can choose the higher rate, without switching delay or load change.
for t=1:20
 for env=1:2
  if env==1,C=normalC(:,:,t);name='normal11';else,C=worstC(:,:,t);name=J.worst_double;end
  f=max(C(:,1),C(:,3));sorted=sort(f);q=sorted(ceil(.05*n));
  rows(end+1,:)={t,seeds(t),name,q,median(f),100*mean(f<10),100*mean(C(:,3)<10),100*mean(C(:,3)<10&C(:,1)>=10),100*mean(C(:,1)>C(:,3))};
  for k=1:3,for threshold=[1,5,10,25]
   qos(end+1,:)={t,name,k,threshold,100*mean(C(:,k)<threshold),100*mean(C(indoor,k)<threshold)};
  end,end
 end
end
writetable(cell2table(rows,'VariableNames',{'trial','seed','scenario','dualband_best_p5_Mbps','dualband_best_median_Mbps','dualband_below10_pct','only28_800_below10_pct','rescued_by_3p5_pct','positions_preferring3p5_pct'}),fullfile(out,'dualband_fallback_trials.csv'));
writetable(cell2table(qos,'VariableNames',{'trial','scenario','condition_index','threshold_Mbps','all_below_threshold_pct','indoor_below_threshold_pct'}),fullfile(out,'qos_threshold_sensitivity.csv'));
% Which site should be restored first in the worst fixed double failure?
parts=split(string(J.worst_double),'_');failed=str2double(parts(2:3));repair=cell(0,8);
for restore=failed'
 remaining=failed(failed~=restore);name=sprintf('off_%02d',remaining);
 T=summary(strcmp(summary.group,'all')&strcmp(summary.scenario,name),:);
 for k=1:height(T)
  repair(end+1,:)={restore,remaining,T.condition{k},T.p5_mean_Mbps(k),T.p5_CI95_low_Mbps(k),T.p5_CI95_high_Mbps(k),T.below10Mbps_mean_pct(k),name};
 end
end
writetable(cell2table(repair,'VariableNames',{'restored_site','remaining_failed_site','condition','p5_mean_Mbps','p5_CI95_low_Mbps','p5_CI95_high_Mbps','below10Mbps_mean_pct','source_scenario'}),fullfile(out,'repair_priority.csv'));
% Full failure matrix: diagonal is a single outage, off-diagonal is a pair.
M=zeros(11);T=summary(strcmp(summary.group,'all')&strcmp(summary.condition,'28_800'),:);
for a=1:11,for b=a:11
 if a==b,name=sprintf('off_%02d',a);else,name=sprintf('off_%02d_%02d',a,b);end
 r=T(strcmp(T.scenario,name),:);M(a,b)=r.p5_mean_Mbps;M(b,a)=M(a,b);
end,end
f=figure('Visible','off','Color','w','Position',[80,80,900,780]);ax=axes(f);imagesc(ax,M);axis(ax,'square');colorbar(ax);xticks(ax,1:11);yticks(ax,1:11);
xlabel(ax,'Failed service site ID');ylabel(ax,'Failed service site ID');title(ax,{'28 GHz / 800 MHz | mean trial P5 (Mbps)','Diagonal: one failed site; other cells: two failed sites'});
for a=1:11,for b=1:11,text(ax,b,a,sprintf('%.1f',M(a,b)),'HorizontalAlignment','center','FontSize',8);end,end
exportgraphics(f,fullfile(out,'all_failure_patterns_p5.png'),'Resolution',165);close(f);
% Compact decision chart: same two-site failure, different ideal responses.
names={'Normal','Sites 1+11 off','Load 0.3','Restore site 1','Restore site 11','Best of two bands'};
source={'normal11',J.worst_double,'response2_coordinate_load03','off_11','off_01'};v=zeros(1,6);e=v;
for k=1:5
 r=T(strcmp(T.scenario,source{k}),:);v(k)=r.p5_mean_Mbps;e(k)=r.p5_CI95_high_Mbps-v(k);
end
A=cell2table(rows,'VariableNames',{'trial','seed','scenario','p5','median','below10','only28','rescued','prefer3p5'});
z=A.p5(strcmp(A.scenario,J.worst_double));v(6)=mean(z);e(6)=2.0930240544*std(z)/sqrt(20);
f=figure('Visible','off','Color','w','Position',[80,80,1120,650]);ax=axes(f);bar(ax,v);hold(ax,'on');errorbar(ax,1:6,v,e,'.k');xticks(ax,1:6);xticklabels(ax,names);xtickangle(ax,18);grid(ax,'on');
ylabel(ax,'Mean trial P5 (Mbps), 95% Monte Carlo interval');title(ax,{'Worst fixed double-site failure: ideal response comparison','First five: 28 GHz / 800 MHz; last: per-user choice of 3.5/100 or 28/800'});
exportgraphics(f,fullfile(out,'worst2_response_comparison.png'),'Resolution',170);close(f);
% Source checks: every primary condition/group/scenario has 20 unique seeds.
V=readtable(fullfile(out,'trial_metrics.csv'));keys=unique(V(:,{'scenario','condition','group'}));
for k=1:height(keys)
 m=strcmp(V.scenario,keys.scenario{k})&strcmp(V.condition,keys.condition{k})&strcmp(V.group,keys.group{k});
 assert(sum(m)==20 && numel(unique(V.seed(m)))==20);
end
assert(size(unique(reshape(normalC(:,3,:),n,20)','rows'),1)==20);
assert(all(worstC(:,3,:)>=worstC(:,2,:)-1e-8,'all'));
verify=struct('trial_seed_count',numel(unique(seeds)),'locations',n,'all_groups_have_20_unique_seeds',true,...
 'normal_28_capacity_realizations_are_distinct',true,'higher_bandwidth_rate_order',true,...
 'deterministic_reference_max_error_Mbps',J.deterministic_max_error_Mbps,...
 'site10_11_outage_equals_baseline9','off_10_11 and baseline9 compared in postprocessing',...
 'near_link_note','495 site-location links have d2D<10 m; inherited extrapolation, no full standard applicability claim');
fid=fopen(fullfile(out,'verification.json'),'w','n','UTF-8');fwrite(fid,jsonencode(verify),'char');fclose(fid);
end
