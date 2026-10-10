function campus_plots(data, geom, results, out, cfg, prefix)
if ~exist(out,'dir'), mkdir(out); end
tag = data.label;
% Common actual dB range. Median across trials at each spatial location.
f = figure('Visible',cfg.plot_visible,'Position',[80 80 1200 560]);
tiledlayout(1,2);
heat(nexttile,results.base35,'3.5 GHz / 100 MHz',false);
heat(nexttile,results.base28same,'28 GHz / 100 MHz',false);
exportgraphics(f,fullfile(out,[prefix '_frequency_heatmap.png']),'Resolution',150); close(f);
f = figure('Visible',cfg.plot_visible,'Position',[80 80 1200 560]); tiledlayout(1,2);
heat(nexttile,results.base28wide,'28 GHz / 800 MHz - before',false);
heat(nexttile,results.add28wide,'28 GHz / 800 MHz - after',true);
exportgraphics(f,fullfile(out,[prefix '_placement_heatmap.png']),'Resolution',150); close(f);
f = figure('Visible',cfg.plot_visible,'Position',[80 80 1200 560]); tiledlayout(1,2);
heat(nexttile,results.base35,'3.5 GHz / 100 MHz - before',false);
heat(nexttile,results.add35,'3.5 GHz / 100 MHz - after',true);
exportgraphics(f,fullfile(out,[prefix '_placement35_heatmap.png']),'Resolution',150); close(f);
groups = {true(size(geom.indoor)),geom.indoor,~geom.indoor}; names = {'all','indoor','outdoor'};
for g = 1:3
 if ~any(groups{g}), continue; end
 f = figure('Visible',cfg.plot_visible,'Position',[80 80 1100 520]); tiledlayout(1,2);
 ax = nexttile; hold(ax,'on');
 drawcdf(ax,results.base35.capacity_mbps(groups{g},:),'3.5 GHz / 100 MHz');
 drawcdf(ax,results.base28wide.capacity_mbps(groups{g},:),'28 GHz / 800 MHz');
 title(ax,sprintf('%s | %s | bandwidth comparison',tag,names{g}),'Interpreter','none'); formatcdf(ax);
 ax = nexttile; hold(ax,'on');
 drawcdf(ax,results.base28wide.capacity_mbps(groups{g},:),'28 GHz before');
 drawcdf(ax,results.add28wide.capacity_mbps(groups{g},:),'28 GHz after');
 drawcdf(ax,results.base35.capacity_mbps(groups{g},:),'3.5 GHz before');
 drawcdf(ax,results.add35.capacity_mbps(groups{g},:),'3.5 GHz after');
 title(ax,sprintf('%s | %s | added sites',tag,names{g}),'Interpreter','none'); formatcdf(ax);
 exportgraphics(f,fullfile(out,[prefix '_cdf_' names{g} '.png']),'Resolution',150); close(f);
end
f = figure('Visible',cfg.plot_visible,'Position',[80 80 800 650]); ax = axes(f);
delta = median(results.add28wide.sinr_db-results.base28wide.sinr_db,2);
scatter(ax,geom.xy(:,1),geom.xy(:,2),8,delta,'filled'); colorbar(ax); colormap(ax,turbo);
v = max(abs(delta)); clim(ax,[-max(v,1) max(v,1)]); axis(ax,'equal'); grid(ax,'on');
title(ax,[tag ' | 28 GHz added minus baseline SINR (dB)'],'Interpreter','none');
xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); overlay(ax,true);
exportgraphics(f,fullfile(out,[prefix '_sinr_change.png']),'Resolution',150); close(f);

function heat(ax,r,name,added)
 scatter(ax,geom.xy(:,1),geom.xy(:,2),8,median(r.sinr_db,2),'filled');
 colormap(ax,turbo); clim(ax,cfg.heatmap_limits_db); cb = colorbar(ax); cb.Label.String = 'SINR (dB)';
 axis(ax,'equal'); grid(ax,'on'); xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
 title(ax,{tag,name},'Interpreter','none'); overlay(ax,added);
end
function overlay(ax,added)
 hold(ax,'on');
 for z = 1:numel(data.buildings)
  p = data.buildings{z}; plot(ax,[p(:,1);p(1,1)],[p(:,2);p(1,2)],'k-','LineWidth',0.5);
 end
 b = data.sites.role=="baseline"; e = data.sites.role=="external";
 plot(ax,data.sites.x_m(b),data.sites.y_m(b),'r^','MarkerFaceColor','r','MarkerSize',7);
 % External sites can lie beyond heatmap evaluation area; keep campus axes.
 xl = xlim(ax); yl = ylim(ax);
 plot(ax,data.sites.x_m(e),data.sites.y_m(e),'kx','MarkerSize',6);
 if added
  c = data.sites.role=="selected";
  plot(ax,data.sites.x_m(c),data.sites.y_m(c),'mp','MarkerFaceColor','m','MarkerSize',12);
 end
 xlim(ax,xl); ylim(ax,yl);
end
end

function drawcdf(ax,values,name)
v = sort(values(:)); n = numel(v);
% Decimate for rendering only. Statistics always use all samples.
idx = unique([1;round(linspace(1,n,min(n,3000)))';n]);
stairs(ax,[v(1);v(idx)],[0;idx/n],'LineWidth',1.6,'DisplayName',name);
end
function formatcdf(ax)
grid(ax,'on'); xlabel(ax,'Shannon capacity (Mbps)'); ylabel(ax,'F(c) = P(C <= c)');
ylim(ax,[0 1]); legend(ax,'Location','southeast');
end
