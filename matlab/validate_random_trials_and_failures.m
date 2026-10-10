function validate_random_trials_and_failures()
% Independent draws between trials; paired common fields within a trial.
% Keeps labgemini4 fixed NLOS mean loss. Spatial SF is an explicit extension.
repo=fileparts(fileparts(mfilename('fullpath')));
out=fullfile(repo,'results','labgemini4','random20_resilience');
if ~exist(out,'dir'),mkdir(out);end
old=fullfile(repo,'results','labgemini4','added11_three_cases');
U=readtable(fullfile(repo,'results','labgemini4','weak_regions_provisional','campus_positions.csv'));
BS=readtable(fullfile(old,'service_sites.csv'));EX=readtable(fullfile(old,'external_sites.csv'));
sites=[BS.x_m,BS.y_m;EX.x_m,EX.y_m];n=height(U);indoor=logical(U.is_indoor);
x=U.x_m;y=U.y_m;freq=[3.5,28];band=[100e6,100e6,800e6];labels={'3p5_100','28_100','28_800'};
ux=unique(x);uy=unique(y);[~,ix]=ismember(x,ux);[~,iy]=ismember(y,uy);
index=sub2ind([numel(uy),numel(ux)],iy,ix);
base=cell(1,2);near=zeros(n,17);
for f=1:2
 R=zeros(n,51);
 for k=1:17
  d2=hypot(x-sites(k,1),y-sites(k,2));near(:,k)=d2;d3=hypot(d2,23.5);
  theta=atan2d(y-sites(k,2),x-sites(k,1));PL=13.54+39.08*log10(d3)+20*log10(freq(f));
  wall=5-10*log10(.3*10^(-(2+.2*freq(f))/10)+.7*10^(-(5+4*freq(f))/10));
  for sec=1:3
   delta=mod(theta-120*(3-sec)+180,360)-180;
   R(:,3*(k-1)+sec)=10.^((43-PL-wall*double(indoor)-min(12*(delta/70).^2,20))/10);
  end
 end
 base{f}=R;
end
% Verify unchanged deterministic mean against the preceding validated run.
reference=readtable(fullfile(old,'positions_three_cases.csv'));[tf,loc]=ismember([x,y],[reference.x_m,reference.y_m],'rows');assert(all(tf));
refCols={'added_capacity_3p5GHz_100MHz_Mbps','added_capacity_28GHz_100MHz_Mbps','added_capacity_28GHz_800MHz_Mbps'};
deterministicError=0;
for c=1:3
 R=base{1+(c>1)};[S,~]=max(R(:,1:33),[],2);I=.5*(sum(R,2)-S);
 C=band(c)/1e6*log2(1+S./(I+10.^((-174+10*log10(band(c))+7)/10)));
 deterministicError=max(deterministicError,max(abs(C-reference.(refCols{c})(loc))));
end
assert(deterministicError<1e-8);
% Normal, all 11 single failures, all 55 two-site failures, and stresses.
sc=struct('name',{},'off',{},'load',{},'ext_dB',{},'NF',{},'block_dB',{});
sc(end+1)=scenario('baseline9',[10,11],.5,0,7,0);
sc(end+1)=scenario('normal11',[],.5,0,7,0);
for k=1:11,sc(end+1)=scenario(sprintf('off_%02d',k),k,.5,0,7,0);end
pairs=nchoosek(1:11,2);
for k=1:size(pairs,1),sc(end+1)=scenario(sprintf('off_%02d_%02d',pairs(k,:)),pairs(k,:),.5,0,7,0);end
sc(end+1)=scenario('busy_load1',[],1,0,7,0);
sc(end+1)=scenario('external_plus6dB',[],.5,6,7,0);
sc(end+1)=scenario('receiver_NF10',[],.5,0,10,0);
sc(end+1)=scenario('added_links_block20dB_28',[],.5,0,7,20);
sc(end+1)=scenario('combined_adverse',[],1,6,10,20);
seeds=(2026101101:2026101120)';
rows=cell(0,15);sample=cell(0,7);normalC=zeros(n,3,20);worstC=[];
normalID=zeros(n,3,20,'uint8');risk=zeros(n,1);masks={true(n,1),indoor,~indoor};groups={'all','indoor','outdoor'};
for t=1:20
 R=draw(t);
 for c=1:3
  [C,id]=evaluate(R,sc(2),c);normalC(:,c,t)=C;normalID(:,c,t)=uint8(ceil(id/3));
 end
 risk=risk+double(normalC(:,3,t)<10);
 for j=1:numel(sc),record(t,j,R,false);end
 fprintf('Primary independent trial %d/20 complete\n',t);
end
trials=cell2table(rows,'VariableNames',{'trial','seed','scenario','condition','group','n_positions','p5_Mbps','median_Mbps','mean_Mbps','below10Mbps_pct','below0dBSINR_pct','changed_site_pct','no_reassociation_disconnected_pct','p5_delta_normal_Mbps','p5_ratio_normal'});
summary=aggregate(trials);all28=summary(strcmp(summary.condition,'28_800')&strcmp(summary.group,'all'),:);
single=find(arrayfun(@(a)numel(a.off)==1,sc));doubleOff=find(arrayfun(@(a)numel(a.off)==2,sc));doubleOff=doubleOff(doubleOff~=1);
singleMean=arrayfun(@(k)all28.p5_mean_Mbps(strcmp(all28.scenario,sc(k).name)),single);
doubleMean=arrayfun(@(k)all28.p5_mean_Mbps(strcmp(all28.scenario,sc(k).name)),doubleOff);
[~,i1]=min(singleMean);[~,i2]=min(doubleMean);worst1=sc(single(i1));worst2=sc(doubleOff(i2));
primaryCount=numel(sc);
sc(end+1)=scenario('worst1_busy_load1',worst1.off,1,0,7,0);
sc(end+1)=scenario('worst2_busy_load1',worst2.off,1,0,7,0);
sc(end+1)=scenario('worst2_combined_adverse',worst2.off,1,6,10,20);
% Worst fixed patterns selected across primary 20 draws; not independent
% held-out evidence of the mitigation. Same fields isolate intervention.
for item=1:2
 if item==1,w=worst1;else,w=worst2;end
 sc(end+1)=scenario(['response',num2str(item),'_coordinate_load03'],w.off,.3,0,7,0);
 sc(end+1)=scenario(['response',num2str(item),'_restore_first'],w.off(2:end),.5,0,7,0);
end
worstC=zeros(n,3,20);
for t=1:20
 R=draw(t);
 for j=primaryCount+1:numel(sc),record(t,j,R,true);end
 for c=1:3
  [C,~]=evaluate(R,worst2,c);worstC(:,c,t)=C;
 end
end
trials=cell2table(rows,'VariableNames',trials.Properties.VariableNames);summary=aggregate(trials);
writetable(trials,fullfile(out,'trial_metrics.csv'));writetable(summary,fullfile(out,'summary20.csv'));
writetable(BS,fullfile(out,'service_sites.csv'));
defs=cell(numel(sc),7);
for j=1:numel(sc),defs(j,:)={sc(j).name,strjoin(string(sc(j).off),';'),sc(j).load,sc(j).ext_dB,sc(j).NF,sc(j).block_dB,numel(sc(j).off)};end
writetable(cell2table(defs,'VariableNames',{'scenario','failed_site_ids','load_factor','external_extra_dB','NF_dB','added_link_block_28_dB','n_failed'}),fullfile(out,'scenario_definitions.csv'));
writetable(table((1:20)',seeds,'VariableNames',{'trial','seed'}),fullfile(out,'seeds.csv'));
writetable(table(x,y,indoor,risk/20,mean(worstC(:,3,:)<10,3),mean(normalC(:,3,:),3),mean(worstC(:,3,:),3),...
 'VariableNames',{'x_m','y_m','is_indoor','normal_probability_below10','worst2_probability_below10','normal_mean_capacity_Mbps','worst2_mean_capacity_Mbps'}),fullfile(out,'risk_positions.csv'));
J=struct('trials',20,'seeds',seeds,'n_locations',n,'random_model','fixed NLOS labgemini4 mean + Gaussian SF sigma 6 dB',...
 'spatial_covariance','exp(-(abs(dx)+abs(dy))/50), separable project approximation, not exact 3GPP spatial consistency',...
 'same_fields_across_frequencies_and_scenarios',true,'site_sectors_share_SF',true,'sites_have_independent_fields',true,...
 'fixed_O2I',true,'fixed_placement_not_reoptimized',true,'all_single_patterns',11,'all_double_patterns',55,...
 'worst_single',worst1.name,'worst_double',worst2.name,'deterministic_max_error_Mbps',deterministicError,...
 'threshold_Mbps',10,'threshold_is_project_choice',true,'reassociation','instantaneous ideal strongest active sector, no transient time',...
 'MC_intervals','mean metric +/- t(19,.975)*sample std/sqrt(20), conditional on assumed model',...
 'not_modelled','LOS state sampling, indoor depth, fast fading, mobility, scheduling, backhaul, recovery time, true failure probabilities',...
 'MATLAB',version,'near_links_below_10m_count',sum(near(:)<10));
fid=fopen(fullfile(out,'run_metadata.json'),'w','n','UTF-8');fwrite(fid,jsonencode(J),'char');fclose(fid);
save(fullfile(out,'random20_results.mat'),'normalC','worstC','normalID','x','y','indoor','seeds','summary','trials','J','-v7');
plotResults();disp(summary(strcmp(summary.group,'all')&ismember(summary.scenario,{'baseline9','normal11',worst1.name,worst2.name,'combined_adverse'}),:));

 function R=draw(t)
  rng(seeds(t),'twister');z=zeros(n,17);rho=exp(-2.5/50);a=sqrt(1-rho^2);
  for s=1:17
   G=randn(numel(uy),numel(ux));
   for col=2:numel(ux),G(:,col)=rho*G(:,col-1)+a*G(:,col);end
   for row=2:numel(uy),G(row,:)=rho*G(row-1,:)+a*G(row,:);end
   z(:,s)=G(index);
  end
  mult=10.^(-6*repelem(z,1,3)/10);R={base{1}.*mult,base{2}.*mult};
 end
 function [C,id,sinr]=evaluate(R,a,c)
  f=1+(c>1);M=R{f};
  if a.block_dB>0&&f==2,M(:,28:33)=M(:,28:33)*10^(-a.block_dB/10);end
  for off=a.off,M(:,3*(off-1)+(1:3))=0;end
  [S,id]=max(M(:,1:33),[],2);
  I=a.load*(sum(M(:,1:33),2)-S+sum(M(:,34:51),2)*10^(a.ext_dB/10));
  noise=10.^((-174+10*log10(band(c))+a.NF)/10);sinr=S./(I+noise);
  C=band(c)/1e6*log2(1+sinr);assert(all(isfinite(C))&&all(C>0));
 end
 function record(t,j,R,isResponse)
  a=sc(j);
  for c=1:3
   [C,id,sinr]=evaluate(R,a,c);ref=normalC(:,c,t);normalSite=double(normalID(:,c,t));
   % Lower-load response cannot reduce rate versus its paired failure.
   if isResponse&&a.load==.3
    baseFail=a;baseFail.load=.5;Q=evaluate(R,baseFail,c);assert(all(C>=Q-1e-9));
   end
   for g=1:3
    m=masks{g};q=p5(C(m));qn=p5(ref(m));
    rows(end+1,:)={t,seeds(t),a.name,labels{c},groups{g},sum(m),q,median(C(m)),mean(C(m)),...
     100*mean(C(m)<10),100*mean(sinr(m)<1),100*mean(ceil(id(m)/3)~=normalSite(m)),...
     100*mean(ismember(normalSite(m),a.off)),q-qn,q/qn};
   end
  end
 end
 function plotResults()
  f=figure('Visible','off','Color','w','Position',[80,80,1450,520]);tl=tiledlayout(f,1,3);
  for c=1:3
   ax=nexttile(tl);hold(ax,'on');
   for name={'baseline9','normal11',worst2.name}
    T=trials(strcmp(trials.group,'all')&strcmp(trials.condition,labels{c})&strcmp(trials.scenario,name{1}),:);
    plot(ax,T.trial,T.p5_Mbps,'-o','DisplayName',name{1},'MarkerSize',3);
   end
   xlabel(ax,'Independent realization');ylabel(ax,'Campus P5 (Mbps)');title(ax,labels{c},'Interpreter','none');grid(ax,'on');legend(ax,'Interpreter','none');
  end
  exportgraphics(f,fullfile(out,'trial_p5_three_cases.png'),'Resolution',170);close(f);
  f=figure('Visible','off','Color','w','Position',[80,80,1250,650]);ax=axes(f);
  names={'normal11',worst1.name,worst2.name,'worst2_busy_load1','external_plus6dB','receiver_NF10','added_links_block20dB_28','combined_adverse','worst2_combined_adverse','response2_coordinate_load03','response2_restore_first'};
  T=summary(strcmp(summary.group,'all')&strcmp(summary.condition,'28_800'),:);v=zeros(numel(names),1);e=v;
  for k=1:numel(names),r=T(strcmp(T.scenario,names{k}),:);v(k)=r.p5_mean_Mbps;e(k)=r.p5_CI95_high_Mbps-v(k);end
  bar(ax,v);hold(ax,'on');errorbar(ax,1:numel(names),v,e,'.k');xticks(ax,1:numel(names));xticklabels(ax,names);xtickangle(ax,28);ax.TickLabelInterpreter='none';ylabel(ax,'Mean of trial P5 (Mbps), 95% MC interval');grid(ax,'on');
  title(ax,'28 GHz / 800 MHz | stochastic stress and ideal responses');exportgraphics(f,fullfile(out,'stress_and_response_p5.png'),'Resolution',175);close(f);
  f=figure('Visible','off','Color','w','Position',[80,80,1200,900]);tl=tiledlayout(f,1,2);
  for k=1:2
   ax=nexttile(tl);if k==1,v=risk/20;name='Normal';else,v=mean(worstC(:,3,:)<10,3);name=worst2.name;end
   scatter(ax,x,y,10,v,'filled');axis(ax,'equal');clim(ax,[0,1]);colorbar(ax);xlabel(ax,'X (m)');ylabel(ax,'Y (m)');title(ax,[name,' | fraction of 20 draws below 10 Mbps'],'Interpreter','none');
  end
  exportgraphics(f,fullfile(out,'below10_probability_maps.png'),'Resolution',165);close(f);
  f=figure('Visible','off','Color','w','Position',[80,80,1100,550]);tl=tiledlayout(f,1,2);
  for zoom=1:2
   ax=nexttile(tl);hold(ax,'on');edges=linspace(0,20000,2001);
   for k=1:2
    F=zeros(numel(edges)-1,1);
    for t=1:20
     if k==1,v=normalC(:,3,t);name='normal11';else,v=worstC(:,3,t);name=worst2.name;end
     assert(max(v)<edges(end));F=F+cumsum(histcounts(v,edges))'/n/20;
    end
    plot(ax,edges(2:end),F,'DisplayName',name,'LineWidth',1.5);
   end
   if zoom==1,xlim(ax,[0,200]);ylim(ax,[0,.3]);else,xlim(ax,[0,6000]);ylim(ax,[0,1]);end
   xlabel(ax,'Capacity (Mbps), 10 Mbps bin grid');ylabel(ax,'Mean empirical CDF over 20 draws');legend(ax,'Interpreter','none');grid(ax,'on');
  end
  exportgraphics(f,fullfile(out,'normal_worst2_mean_cdf.png'),'Resolution',165);close(f);
 end
end
function s=scenario(name,off,load,ext,NF,block)
s=struct('name',name,'off',off,'load',load,'ext_dB',ext,'NF',NF,'block_dB',block);
end
function q=p5(v)
v=sort(v);q=v(max(1,ceil(.05*numel(v))));
end
function T=aggregate(V)
names=unique(V.scenario,'stable');conditions=unique(V.condition,'stable');groups=unique(V.group,'stable');rows=cell(0,15);
for a=1:numel(names),for b=1:numel(conditions),for c=1:numel(groups)
 X=V(strcmp(V.scenario,names{a})&strcmp(V.condition,conditions{b})&strcmp(V.group,groups{c}),:);assert(height(X)==20);
 z=X.p5_Mbps;half=2.0930240544*std(z)/sqrt(20);d=X.p5_delta_normal_Mbps;dh=2.0930240544*std(d)/sqrt(20);
 rows(end+1,:)={names{a},conditions{b},groups{c},20,mean(z),std(z),mean(z)-half,mean(z)+half,min(z),max(z),...
  mean(X.median_Mbps),mean(X.below10Mbps_pct),mean(d),mean(d)-dh,mean(d)+dh};
end,end,end
T=cell2table(rows,'VariableNames',{'scenario','condition','group','trials','p5_mean_Mbps','p5_std_Mbps','p5_CI95_low_Mbps','p5_CI95_high_Mbps','p5_min_trial_Mbps','p5_max_trial_Mbps','median_mean_Mbps','below10Mbps_mean_pct','paired_p5_delta_mean_Mbps','paired_delta_CI95_low_Mbps','paired_delta_CI95_high_Mbps'});
end
