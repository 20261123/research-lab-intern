function evaluate_three_placement_scenarios()
% Actual deterministic MATLAB evaluation, cached links identical to labgemini4.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
base=fullfile(repo,'04_site_selection','01_weak_regions');
out=fullfile(repo,'04_site_selection','02_candidate_evaluation');
T=readtable(fullfile(base,'extended_grid_sinr.csv'));
P=readtable(fullfile(base,'boundary_vertices_estimated.csv'));
W=readtable(fullfile(base,'weak_points.csv'));
K=readtable(fullfile(out,'candidates.csv'),'TextType','string');
x=T.x_m; y=T.y_m; n=height(T);
inside=inpolygon(x,y,P.x_m,P.y_m);
edge=inf(n,1);
for k=1:height(P)
 j=mod(k,height(P))+1; a=[P.x_m(k),P.y_m(k)]; v=[P.x_m(j),P.y_m(j)]-a;
 z=max(0,min(1,([x,y]-a)*v'/(v*v')));
 edge=min(edge,hypot(x-a(1)-z*v(1),y-a(2)-z*v(2)));
end
parity=mod(round((x+175)/2.5)+round((y+70)/2.5),2);
train=inside & parity==0; held=inside & parity==1;
R=false(n,4);
for k=1:4, R(:,k)=hypot(x-W.x_m(k),y-W.y_m(k))<=25; end
noise=10^((-174+10*log10(800e6)+7)/10);
oldS=T.signal_mW; oldFullI=T.interference_mW/.5;
baseline=800*log2(1+oldS./(.5*oldFullI+noise));
assert(max(abs(10*log10(oldS./(.5*oldFullI+noise))-T.sinr_dB))<1e-10);
serv=[53.6,121.3;75.1,143.8;76.3,156.5;-2.2,269.7;-98.8,364.8;-58.1,386.1;36.1,418.1;-1.4,489.8;-126.2,521.6];
ext=[-101.6,81.4;-149,335.7;-151.4,370.6;-143.8,409.7;94.1,505.8;-196.7,476.9];
ss=zeros(n,1); sm=zeros(n,1); ex=zeros(n,1);
for k=1:size(serv,1), [total,strong]=link(x,y,serv(k,:),T.is_indoor); ss=ss+total;sm=max(sm,strong);end
for k=1:size(ext,1), [total,~]=link(x,y,ext(k,:),T.is_indoor);ex=ex+total;end
relS=max(abs(sm-oldS)./max(oldS,realmin));
relI=max(abs(ss-sm+ex-oldFullI)./max(oldFullI,realmin));
assert(relS<1e-11 && relI<1e-11,'Cached baseline does not match original model.');
newSum=zeros(n,12);newMax=zeros(n,12);
for k=1:12, [newSum(:,k),newMax(:,k)]=link(x,y,[K.x_m(k),K.y_m(k)],T.is_indoor);end
pairs=nchoosek(1:12,2);np=size(pairs,1);
Mtrain=zeros(np,10);Mheld=zeros(np,10);Mall=zeros(np,10);
for p=1:np
 c=capacity(pairs(p,:),.5);
 Mtrain(p,:)=metrics(c,baseline,train,R);
 Mheld(p,:)=metrics(c,baseline,held,R);
 Mall(p,:)=metrics(c,baseline,inside,R);
end
metricNames={'p5_Mbps','median_Mbps','mean_Mbps','worsened_pct','worst_region_p5_ratio','mean_log_capacity_ratio','W1_p5_Mbps','W2_p5_Mbps','W3_p5_Mbps','W4_p5_Mbps'};
pairTable=table(K.id(pairs(:,1)),K.id(pairs(:,2)),'VariableNames',{'site1','site2'});
for k=1:10
 pairTable.(['train_',metricNames{k}])=Mtrain(:,k);
 pairTable.(['held_',metricNames{k}])=Mheld(:,k);
 pairTable.(['all_',metricNames{k}])=Mall(:,k);
end
writetable(pairTable,fullfile(out,'all_66_pairs.csv'));
objCols=[1,6,5]; selected=zeros(3,3);crossRows=cell(9,9);r=0;
for budget=1:3
 allowed=find(all(K.rank_in_region(pairs)<=budget,2));
 for objective=1:3
  % Same training tie-breakers, no held-out values used in pair selection.
  keys=[-Mtrain(allowed,objCols(objective)),-Mtrain(allowed,1),-Mtrain(allowed,2),pairs(allowed,:)];
  [~,order]=sortrows(keys);chosen=allowed(order(1));selected(budget,objective)=chosen;
  r=r+1;crossRows(r,:)={4*budget,objective,K.id(pairs(chosen,1)),K.id(pairs(chosen,2)),Mtrain(chosen,objCols(objective)),Mheld(chosen,1),Mheld(chosen,2),Mheld(chosen,5),Mheld(chosen,4)};
 end
end
writetable(cell2table(crossRows,'VariableNames',{'n_candidates','objective_number','site1','site2','training_objective_value','held_p5_Mbps','held_median_Mbps','held_worst_region_ratio','held_worsened_pct'}),fullfile(out,'factorial_3x3.csv'));
diagonal=diag(selected); names={'S1: P5 / 4 sites','S2: log utility / 8 sites','S3: regional fairness / 12 sites'};
summary=table(string(names(:)),K.id(pairs(diagonal,1)),K.id(pairs(diagonal,2)),K.x_m(pairs(diagonal,1)),K.y_m(pairs(diagonal,1)),K.x_m(pairs(diagonal,2)),K.y_m(pairs(diagonal,2)), 'VariableNames',{'scenario','site1','site2','site1_x_m','site1_y_m','site2_x_m','site2_y_m'});
for k=1:10,summary.(['held_',metricNames{k}])=Mheld(diagonal,k);summary.(['all_',metricNames{k}])=Mall(diagonal,k);end
baseTrain=metrics(baseline,baseline,train,R);baseHeld=metrics(baseline,baseline,held,R);baseAll=metrics(baseline,baseline,inside,R);
summary.held_p5_improvement_pct=100*(summary.held_p5_Mbps/baseHeld(1)-1);
summary.all_p5_improvement_pct=100*(summary.all_p5_Mbps/baseAll(1)-1);
writetable(summary,fullfile(out,'scenario_comparison.csv'));
keys=[-summary.held_p5_Mbps,-summary.held_worst_region_p5_ratio,-summary.held_median_Mbps,summary.held_worsened_pct,(1:3)'];
[~,order]=sortrows(keys);winner=order(1);bestPair=pairs(diagonal(winner),:);
% Refine after factorial comparison; identical winning pairs favor fewer candidates.
crossIndices=selected(:);crossBudgets=repmat((1:3)',3,1)*4;
crossObjectives=repelem((1:3)',3);
crossKeys=[-Mheld(crossIndices,1),-Mheld(crossIndices,5),-Mheld(crossIndices,2),Mheld(crossIndices,4),crossBudgets,crossObjectives];
[~,crossOrder]=sortrows(crossKeys);bestCross=crossOrder(1);recommendedIndex=crossIndices(bestCross);
bestPair=pairs(recommendedIndex,:);
recommended=struct('candidate_count',crossBudgets(bestCross),'objective_number',crossObjectives(bestCross),...
 'site_ids',K.id(bestPair),'coordinates_m',[K.x_m(bestPair),K.y_m(bestPair)],...
 'held_metrics',Mheld(recommendedIndex,:),'all_metrics',Mall(recommendedIndex,:));
evaluationIndices=[diagonal;recommendedIndex];
sensRows=cell(24,8);r=0; masks={inside & edge>=30,inside,inside | edge<=30}; labels={'contract_30m','base','expand_30m'};
for s=1:4
 for load=[.5,1]
  baseC=800*log2(1+oldS./(load*oldFullI+noise));
  for boundary=1:3
   r=r+1;c=capacity(pairs(evaluationIndices(s),:),load);m=metrics(c,baseC,masks{boundary},R);bm=metrics(baseC,baseC,masks{boundary},R);
   sensRows(r,:)={s,load,labels{boundary},m(1),bm(1),100*(m(1)/bm(1)-1),m(2),m(4)};
  end
 end
end
writetable(cell2table(sensRows,'VariableNames',{'scenario','load_factor','boundary','p5_Mbps','baseline_p5_Mbps','p5_improvement_pct','median_Mbps','worsened_pct'}),fullfile(out,'sensitivity.csv'));
bestC=capacity(bestPair,.5);
final=table(x(inside),y(inside),T.is_indoor(inside),baseline(inside),bestC(inside),10*log10(oldS(inside)./(.5*oldFullI(inside)+noise)),...
 10*log10(2.^(bestC(inside)/800)-1),'VariableNames',{'x_m','y_m','is_indoor','baseline_Mbps','selected_Mbps','baseline_sinr_dB','selected_sinr_dB'});
writetable(final,fullfile(out,'selected_positions.csv'));
ratio=bestC(inside)./baseline(inside);
loss=struct('any_loss_pct',100*mean(ratio<1-1e-10),'loss_gt_1pct_of_users',100*mean(ratio<.99),...
 'loss_gt_10pct_of_users',100*mean(ratio<.9),'loss_gt_20pct_of_users',100*mean(ratio<.8),...
 'loss_gt_50pct_of_users',100*mean(ratio<.5),'median_relative_loss_among_worsened_pct',median(100*(1-ratio(ratio<1))),...
 'all_p5_improvement_pct',100*(recommended.all_metrics(1)/baseAll(1)-1));
fid=fopen(fullfile(out,'degradation_analysis.json'),'w','n','UTF-8');fwrite(fid,jsonencode(loss),'char');fclose(fid);
J=struct('status','PROVISIONAL_MODEL_PLACEMENT','source','labgemini4','condition','28 GHz / 800 MHz','MATLAB_version',version,...
 'n_train',sum(train),'n_held',sum(held),'n_all',sum(inside),'baseline_train_metrics',baseTrain,'baseline_held_metrics',baseHeld,'baseline_all_metrics',baseAll,...
 'metric_order',{metricNames},'winner_among_primary_three',winner,'final_recommendation',recommended,'source_link_max_relative_error_S',relS,'source_link_max_relative_error_I',relI,...
 'pair_count_unique',np,'scenario_pair_counts',[6,28,66],'all_sites_height_m',25,'new_sector_power_dBm',43,'load_factor',.5,...
 'independent_random_validation',false,'surveyed_feasibility',false,'global_optimality_proven',false);
fid=fopen(fullfile(out,'run_summary.json'),'w','n','UTF-8');fwrite(fid,jsonencode(J),'char');fclose(fid);
save(fullfile(out,'scenario_results.mat'),'pairs','Mtrain','Mheld','Mall','selected','summary','winner','bestPair','recommended','baseAll','baseHeld','baseTrain');
disp(summary);fprintf('Winner under common held-out P5 rule: S%d\n',winner);
fprintf('Refined recommendation: %d candidates, objective %d, %s + %s; held P5 %.3f Mbps\n',recommended.candidate_count,recommended.objective_number,K.id(bestPair(1)),K.id(bestPair(2)),recommended.held_metrics(1));
drawFigures();

 function c=capacity(pair,load)
  S=max([oldS,newMax(:,pair)],[],2);
  I=oldFullI+oldS+sum(newSum(:,pair),2)-S;
  assert(all(I>=-1e-15));c=800*log2(1+S./(load*max(I,0)+noise));
 end

 function drawFigures()
  f=figure('Visible','off','Color','w','Position',[100 100 1500 930]);t=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
  for s=1:3
   ax=nexttile(t);hold(ax,'on');scatter(ax,x(inside),y(inside),5,[.9,.93,.96],'filled');
   plot(ax,[P.x_m;P.x_m(1)],[P.y_m;P.y_m(1)],'b-','LineWidth',1.3);
   buildings=[-120.7,-56.4,234.9,325.6;-12.4,46.4,0,61.6;51.7,102.6,109.7,187.1;-72.3,-24.3,113.1,170.1;-76.4,-24.7,51.8,102.2;-55.2,16.5,368,469.1;-20.4,38.2,339.4,398.9];
   for z=1:7,rectangle(ax,'Position',[buildings(z,1),buildings(z,3),buildings(z,2)-buildings(z,1),buildings(z,4)-buildings(z,3)],'EdgeColor',[.5,.5,.5]);end
   plot(ax,W.x_m,W.y_m,'mo','MarkerSize',7,'LineWidth',1.5);
   allowed=K.rank_in_region<=s;plot(ax,K.x_m(allowed),K.y_m(allowed),'ko','MarkerSize',5,'MarkerFaceColor','w');
   for z=find(allowed)',text(ax,K.x_m(z)+3,K.y_m(z)+4,K.id(z),'FontSize',8);end
   q=pairs(diagonal(s),:);plot(ax,K.x_m(q),K.y_m(q),'rp','MarkerSize',14,'MarkerFaceColor','r');
   axis(ax,'equal');xlim(ax,[-160,160]);ylim(ax,[-45,600]);grid(ax,'on');xlabel(ax,'X (m)');ylabel(ax,'Y (m)');
   title(ax,{names{s},sprintf('Held-out P5: %.2f Mbps',summary.held_p5_Mbps(s))},'FontSize',11);
  end
  title(t,'Provisional sites | circles: candidates | red stars: selected pair | magenta: weak centres');
  exportgraphics(f,fullfile(out,'three_scenario_sites.png'),'Resolution',170);close(f);
  f=figure('Visible','off','Color','w','Position',[100 100 1000 700]);ax=axes(f);hold(ax,'on');
  v=sort(baseline(held));plot(ax,v,(1:numel(v))/numel(v),'k--','LineWidth',1.7,'DisplayName','Baseline');
  for s=1:3,c=capacity(pairs(diagonal(s),:),.5);v=sort(c(held));plot(ax,v,(1:numel(v))/numel(v),'LineWidth',1.7,'DisplayName',sprintf('S%d',s));end
  c=capacity(bestPair,.5);v=sort(c(held));plot(ax,v,(1:numel(v))/numel(v),'m-','LineWidth',2,'DisplayName','Refined: 8 sites / P5');
  yline(ax,.05,':','P5','HandleVisibility','off');xlim(ax,[0,200]);ylim(ax,[0,.25]);grid(ax,'on');legend(ax,'Location','southeast');
  xlabel(ax,'Shannon capacity (Mbps)');ylabel(ax,'CDF (held-out positions)');title(ax,'28 GHz / 800 MHz | lower-capacity CDF');
  exportgraphics(f,fullfile(out,'heldout_cdf_lower_tail.png'),'Resolution',180);close(f);
  f=figure('Visible','off','Color','w','Position',[100 100 1100 1050]);t=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
  for mode=1:2
   ax=nexttile(t);hold(ax,'on');
   if mode==1,v=10*log10(oldS./(.5*oldFullI+noise));label='Before';else,v=10*log10(2.^(bestC/800)-1);label='After: refined 8-site P5 selection';end
   scatter(ax,x(inside),y(inside),8,v(inside),'filled');colormap(ax,jet(256));clim(ax,[-30 15]);
   plot(ax,[P.x_m;P.x_m(1)],[P.y_m;P.y_m(1)],'b-','LineWidth',1.5);
   for z=1:7,rectangle(ax,'Position',[buildings(z,1),buildings(z,3),buildings(z,2)-buildings(z,1),buildings(z,4)-buildings(z,3)],'EdgeColor','k');end
   plot(ax,serv(:,1),serv(:,2),'k^','MarkerSize',5,'MarkerFaceColor','w');
   if mode==2
    plot(ax,K.x_m(bestPair),K.y_m(bestPair),'rp','MarkerSize',13,'MarkerFaceColor','r');
    for z=bestPair,text(ax,K.x_m(z)+5,K.y_m(z)+12,sprintf('%s\n(%.1f, %.1f)',K.id(z),K.x_m(z),K.y_m(z)),'FontSize',9,'BackgroundColor','w');end
   end
   axis(ax,'equal');xlim(ax,[-150 150]);ylim(ax,[-45 600]);grid(ax,'on');xlabel(ax,'X (m)');ylabel(ax,'Y (m)');title(ax,label,'FontSize',11);
  end
  cb=colorbar(ax);cb.Label.String='SINR (dB)';title(t,'28 GHz / 800 MHz | provisional boundary | common color scale');
  exportgraphics(f,fullfile(out,'recommended_before_after.png'),'Resolution',175);close(f);
 end
end

function [total,strong]=link(x,y,site,indoor)
 d=sqrt((x-site(1)).^2+(y-site(2)).^2+23.5^2);
 theta=atan2d(y-site(2),x-site(1)); PL=13.54+39.08*log10(d)+20*log10(28);
 wall=5-10*log10(.3*10^(-(2+.2*28)/10)+.7*10^(-(5+4*28)/10));
 extra=wall*double(indoor); rx=zeros(numel(x),3);
 for k=1:3,az=120*(3-k);delta=mod(theta-az+180,360)-180;loss=min(12*(delta/70).^2,20);rx(:,k)=10.^((43-PL-extra-loss)/10);end
 total=sum(rx,2);strong=max(rx,[],2);
end

function m=metrics(c,base,mask,regions)
 v=c(mask); b=base(mask);rp=zeros(1,4);brp=zeros(1,4);
 for k=1:4
  r=mask & regions(:,k);
  if any(r),rp(k)=q5(c(r));brp(k)=q5(base(r));else,rp(k)=NaN;brp(k)=NaN;end
 end
 m=[q5(v),median(v),mean(v),100*mean(v<b-1e-9),min(rp./brp,[],'omitnan'),mean(log(max(v,1e-12)./max(b,1e-12))),rp];
end
function v=q5(x)
 x=sort(x);assert(~isempty(x));v=x(max(1,ceil(.05*numel(x))));
end
