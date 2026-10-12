function run_added_sites_three_cases()
% 11 service sites / 6 external interferers, shared provisional campus users.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
out=fullfile(repo,'05_comparison_results','03_added11_campus');
if ~exist(out,'dir'),mkdir(out);end
previous=repo;
U=readtable(fullfile(previous,'04_site_selection','01_weak_regions','campus_positions.csv'));
P=readtable(fullfile(previous,'04_site_selection','01_weak_regions','boundary_vertices_estimated.csv'));
choice=jsondecode(fileread(fullfile(previous,'04_site_selection','02_candidate_evaluation','run_summary.json')));
added=choice.final_recommendation.coordinates_m;
assert(isequal(added,[-127.5,260;-17.5,22.5]));
sites=[53.6,121.3;75.1,143.8;76.3,156.5;-2.2,269.7;-98.8,364.8;-58.1,386.1;36.1,418.1;-1.4,489.8;-126.2,521.6];
external=[-101.6,81.4;-149,335.7;-151.4,370.6;-143.8,409.7;94.1,505.8;-196.7,476.9];
buildings=[-120.7,-56.4,234.9,325.6;-12.4,46.4,0,61.6;51.7,102.6,109.7,187.1;-72.3,-24.3,113.1,170.1;-76.4,-24.7,51.8,102.2;-55.2,16.5,368,469.1;-20.4,38.2,339.4,398.9];
names={'광개토관','대양홀','학생회관','군자관','집현관','율곡관/충무관','학술정보원'};
x=U.x_m;y=U.y_m;indoor=logical(U.is_indoor);n=height(U);
assert(n==17922 && sum(indoor)==4601 && size(unique([x,y],'rows'),1)==n);
assert(all(inpolygon(x,y,P.x_m,P.y_m)));
freq=[3.5,28];band=[100e6,100e6,800e6];NF=7;load=.5;
noise=10.^((-174+10*log10(band)+NF)/10);
sinr=zeros(n,3,2);cap=zeros(n,3,2);S=zeros(n,2,2);I=zeros(n,2,2);
for f=1:2
 total=zeros(n,1);strong=zeros(n,1);outer=zeros(n,1);
 for k=1:9,[a,b]=sitePower(x,y,sites(k,:),indoor,freq(f));total=total+a;strong=max(strong,b);end
 for k=1:6,[a,~]=sitePower(x,y,external(k,:),indoor,freq(f));outer=outer+a;end
 S(:,f,1)=strong;I(:,f,1)=load*(total-strong+outer);
 for k=1:2,[a,b]=sitePower(x,y,added(k,:),indoor,freq(f));total=total+a;strong=max(strong,b);end
 S(:,f,2)=strong;I(:,f,2)=load*(total-strong+outer);
end
for deployment=1:2
 for c=1:3
  f=1+(c>1);v=S(:,f,deployment)./(I(:,f,deployment)+noise(c));
  sinr(:,c,deployment)=10*log10(v);cap(:,c,deployment)=band(c)/1e6*log2(1+v);
 end
end
assert(all(isfinite(sinr(:)))&&all(isfinite(cap(:))));
assert(all(sinr(:,2,2)<=sinr(:,1,2)+1e-10));
assert(all(sinr(:,3,2)<=sinr(:,2,2)+1e-10));
assert(all(cap(:,3,2)>=cap(:,2,2)-1e-9));
old=readtable(fullfile(previous,'05_comparison_results','02_baseline9_rectangle_heatmaps','positions_sinr.csv'));
[overlap,idx]=ismember([x,y],[old.x_m,old.y_m],'rows');
error35=max(abs(sinr(overlap,1,1)-old.sinr_3p5GHz_100MHz_dB(idx(overlap))));
error28=max(abs(sinr(:,3,1)-U.sinr_dB));
chosen=readtable(fullfile(previous,'04_site_selection','02_candidate_evaluation','selected_positions.csv'));
[valid,idxChosen]=ismember([x,y],[chosen.x_m,chosen.y_m],'rows');assert(all(valid));
errorAdded=max(abs(cap(:,3,2)-chosen.selected_Mbps(idxChosen)));
assert(error35<1e-10&&error28<1e-10&&errorAdded<1e-9);
labels={'3.5 GHz / 100 MHz','28 GHz / 100 MHz','28 GHz / 800 MHz'};
files={'3p5GHz_100MHz','28GHz_100MHz','28GHz_800MHz'};
rows=cell(18,12);r=0;
for deployment=1:2
 for group=1:3
  masks={true(n,1),indoor,~indoor};groupNames={'all','indoor','outdoor'};m=masks{group};
  for c=1:3
   r=r+1;rows(r,:)={9+2*(deployment-1),6,groupNames{group},labels{c},sum(m),10*log10(noise(c)),...
    median(sinr(m,c,deployment)),quantile5(sinr(m,c,deployment)),100*mean(sinr(m,c,deployment)<0),...
    mean(cap(m,c,deployment)),median(cap(m,c,deployment)),quantile5(cap(m,c,deployment))};
  end
 end
end
summary=cell2table(rows,'VariableNames',{'service_sites','external_sites','group','condition','n_positions','noise_dBm','median_sinr_dB','p5_sinr_dB','sinr_below0_pct','mean_capacity_Mbps','median_capacity_Mbps','p5_capacity_Mbps'});
writetable(summary,fullfile(out,'summary.csv'));
V=table(x,y,indoor,'VariableNames',{'x_m','y_m','is_indoor'});
for c=1:3
 V.(['baseline_sinr_',files{c},'_dB'])=sinr(:,c,1);V.(['added_sinr_',files{c},'_dB'])=sinr(:,c,2);
 V.(['baseline_capacity_',files{c},'_Mbps'])=cap(:,c,1);V.(['added_capacity_',files{c},'_Mbps'])=cap(:,c,2);
end
writetable(V,fullfile(out,'positions_three_cases.csv'));
writetable(table((1:11)',[sites(:,1);added(:,1)],[sites(:,2);added(:,2)],[false(9,1);true(2,1)],'VariableNames',{'id','x_m','y_m','is_added'}),fullfile(out,'service_sites.csv'));
writetable(table((1:6)',external(:,1),external(:,2),'VariableNames',{'id','x_m','y_m'}),fullfile(out,'external_sites.csv'));
change=cell(3,7);
for c=1:3
 p0=quantile5(cap(:,c,1));p1=quantile5(cap(:,c,2));
 change(c,:)={labels{c},p0,p1,100*(p1/p0-1),median(cap(:,c,1)),median(cap(:,c,2)),100*mean(cap(:,c,2)<cap(:,c,1)-1e-9)};
end
writetable(cell2table(change,'VariableNames',{'condition','baseline_p5_Mbps','added_p5_Mbps','p5_improvement_pct','baseline_median_Mbps','added_median_Mbps','worsened_pct'}),fullfile(out,'placement_changes.csv'));
J=struct('status','PROVISIONAL_CAMPUS_BOUNDARY','source_model','labgemini4','MATLAB_version',version,'service_sites',11,'external_sites',6,...
 'added_coordinates_m',added,'n_locations',n,'n_indoor',sum(indoor),'n_outdoor',sum(~indoor),'grid_spacing_m',2.5,...
 'load_factor',load,'sector_power_dBm',43,'noise_figure_dB',7,'base_height_m',25,'user_height_m',1.5,'color_limits_dB',[-30,15],...
 'baseline35_original_overlap_max_error_dB',error35,'baseline28_cached_max_error_dB',error28,'added28_previous_max_error_Mbps',errorAdded,...
 'same_users_for_all_cases',true,'random_trials',0,'capacity_definition','per-position single-stream Shannon rate',...
 'p5_definition','sorted values at ceil(0.05*N)','source_geometry','../../04_site_selection/01_weak_regions/boundary_vertices_estimated.csv');
fid=fopen(fullfile(out,'run_metadata.json'),'w','n','UTF-8');fwrite(fid,jsonencode(J),'char');fclose(fid);
save(fullfile(out,'three_cases_results.mat'),'x','y','indoor','sinr','cap','S','I','summary','sites','added','external','P','band','noise');
for c=1:3
 f=figure('Visible','off','Color','w','Position',[100,100,780,1070]);ax=axes(f);map(ax,c,2,true);
 exportgraphics(f,fullfile(out,['sinr_',files{c},'.png']),'Resolution',185);close(f);
 f=figure('Visible','off','Color','w','Position',[100,100,1120,560]);layout=tiledlayout(f,1,2,'TileSpacing','compact');
 for zoom=0:1,ax=nexttile(layout);cdfPlot(ax,c,zoom);end
 title(layout,[labels{c},' | 11 service + 6 external sites']);
 exportgraphics(f,fullfile(out,['cdf_',files{c},'.png']),'Resolution',170);close(f);
end
f=figure('Visible','off','Color','w','Position',[100,100,1830,1000]);layout=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
for c=1:3,ax=nexttile(layout);map(ax,c,2,c==3);end
title(layout,'11 service + 6 external | same provisional campus users | SINR comparison');
exportgraphics(f,fullfile(out,'sinr_three_cases.png'),'Resolution',175);close(f);
f=figure('Visible','off','Color','w','Position',[100,100,1420,640]);layout=tiledlayout(f,1,2,'TileSpacing','compact');
for zoom=0:1,ax=nexttile(layout);cdfPlot(ax,1:3,zoom);end
title(layout,'11 service + 6 external | 17,922 common positions | Capacity CDF');
exportgraphics(f,fullfile(out,'cdf_three_cases.png'),'Resolution',175);close(f);
f=figure('Visible','off','Color','w','Position',[100,100,1800,1800]);layout=tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
for d=1:2,for c=1:3,ax=nexttile(layout);map(ax,c,d,c==3);end,end
title(layout,'Before (9 service) / after (11 service) | 6 external | same boundary and color scale');
exportgraphics(f,fullfile(out,'sinr_before_after_three_cases.png'),'Resolution',160);close(f);
disp(summary(strcmp(summary.group,'all'),:));

 function map(ax,c,deployment,bar)
  scatter(ax,x,y,9,sinr(:,c,deployment),'filled');hold(ax,'on');colormap(ax,jet(256));clim(ax,[-30,15]);
  plot(ax,[P.x_m;P.x_m(1)],[P.y_m;P.y_m(1)],'b-','LineWidth',1.5);
  for k=1:7
   rectangle(ax,'Position',[buildings(k,1),buildings(k,3),buildings(k,2)-buildings(k,1),buildings(k,4)-buildings(k,3)],'EdgeColor','k');
   text(ax,mean(buildings(k,1:2)),buildings(k,4)+6,names{k},'FontName','Malgun Gothic','FontSize',8,'HorizontalAlignment','center','BackgroundColor','w','Margin',1);
  end
  h1=plot(ax,sites(:,1),sites(:,2),'k^','MarkerSize',6,'MarkerFaceColor','w');
  h2=plot(ax,external(:,1),external(:,2),'kx','MarkerSize',6,'LineWidth',1.3);
  if deployment==2
   h3=plot(ax,added(:,1),added(:,2),'rp','MarkerSize',11,'MarkerFaceColor','r');
   legend(ax,[h1,h2,h3],{'Existing service (9)','External (6)','Added service (2)'},'Location','northwest','FontSize',8);
  else,legend(ax,[h1,h2],{'Existing service (9)','External (6)'},'Location','northwest','FontSize',8);end
  axis(ax,'equal');xlim(ax,[-210,160]);ylim(ax,[-45,600]);grid(ax,'on');xlabel(ax,'X (m)');ylabel(ax,'Y (m)');
  title(ax,{labels{c},sprintf('%d service sites | median SINR %.2f dB',9+2*(deployment-1),median(sinr(:,c,deployment)))},'FontSize',11);
  if bar,cb=colorbar(ax);cb.Label.String='SINR (dB)';end
 end

 function cdfPlot(ax,cases,zoom)
  colors=lines(3);hold(ax,'on');
  for c=cases
   v=sort(cap(:,c,2));F=(1:n)'/n;p=quantile5(v);
   plot(ax,v,F,'Color',colors(c,:),'LineWidth',1.7,'DisplayName',sprintf('%s | P5 %.2f Mbps',labels{c},p));
   plot(ax,p,.05,'o','Color',colors(c,:),'MarkerFaceColor',colors(c,:),'MarkerSize',7,'HandleVisibility','off');
  end
  yline(ax,.05,':','P5','HandleVisibility','off');grid(ax,'on');xlabel(ax,'Shannon capacity (Mbps)');ylabel(ax,'CDF');
  if zoom
   pmax=max(arrayfun(@(c)quantile5(cap(:,c,2)),cases));xlim(ax,[0,max(20,ceil(pmax*2/10)*10)]);ylim(ax,[0,.15]);title(ax,'Lower tail and 5th percentile');
  else,xlim(ax,[0,max(max(cap(:,cases,2)))*1.03]);ylim(ax,[0,1]);title(ax,'Full CDF');end
  legend(ax,'Location','southeast','FontSize',9);
 end
end

function [total,strong]=sitePower(x,y,site,indoor,fc)
 d=sqrt((x-site(1)).^2+(y-site(2)).^2+23.5^2);theta=atan2d(y-site(2),x-site(1));
 PL=13.54+39.08*log10(d)+20*log10(fc);
 wall=5-10*log10(.3*10^(-(2+.2*fc)/10)+.7*10^(-(5+4*fc)/10));
 rx=zeros(numel(x),3);
 for k=1:3,delta=mod(theta-120*(3-k)+180,360)-180;atten=min(12*(delta/70).^2,20);rx(:,k)=10.^((43-PL-wall*double(indoor)-atten)/10);end
 total=sum(rx,2);strong=max(rx,[],2);
end
function q=quantile5(x)
 x=sort(x);q=x(max(1,ceil(.05*numel(x))));
end
