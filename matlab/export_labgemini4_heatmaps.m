function export_labgemini4_heatmaps()
% Re-run unchanged labgemini4, then export all three SINR maps.
% Run from repository root: addpath('matlab'); export_labgemini4_heatmaps;
repoRoot = fileparts(fileparts(mfilename('fullpath')));
set(groot,'defaultFigureVisible','off');
run(fullfile(repoRoot,'matlab','labgemini4.m'));
% labgemini4 starts with clear all, so establish output paths after it runs.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(repoRoot,'results','labgemini4','heatmaps_three_cases');
if ~exist(outDir,'dir'), mkdir(outDir); end
close all;
assert(all(isfinite(SINR_dB(:))), 'Non-finite SINR.');
assert(size(unique([real(pos),imag(pos)],'rows'),1)==numUsers,'Duplicate user coordinates.');
assert(all(SINR_dB(:,3)<=SINR_dB(:,2)+1e-10),'800 MHz SINR unexpectedly exceeds 100 MHz.');
caseLabels = {'3.5 GHz / 100 MHz','28 GHz / 100 MHz','28 GHz / 800 MHz'};
caseFiles = {'sinr_3p5GHz_100MHz.png','sinr_28GHz_100MHz.png','sinr_28GHz_800MHz.png'};
for c = 1:3
    f = figure('Visible','off','Color','w','Position',[100 100 700 900]);
    ax = axes(f);
    drawMap(ax,pos,SINR_dB(:,c),sejong_buildings,BS_pos,BS_pos_interference,caseLabels{c});
    exportgraphics(f,fullfile(outDir,caseFiles{c}),'Resolution',220);
    close(f);
end
f=figure('Visible','off','Color','w','Position',[100 100 1740 900]);
layout=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
for c=1:3
    ax=nexttile(layout);
    drawMap(ax,pos,SINR_dB(:,c),sejong_buildings,BS_pos,BS_pos_interference,caseLabels{c});
end
title(layout,sprintf('labgemini4 | SINR comparison | load factor %.1f | %d locations',load_factor,numUsers),'FontSize',15);
exportgraphics(f,fullfile(outDir,'sinr_three_cases.png'),'Resolution',220);
close(f);
noise_dBm=[10*log10(noise100);10*log10(noise100);10*log10(noise800)];
median_sinr_dB=median(SINR_dB,1)';
weak_below_0dB_pct=100*mean(SINR_dB<0,1)';
mean_capacity_Mbps=mean(Capacity,1)'/1e6;
median_capacity_Mbps=median(Capacity,1)'/1e6;
sorted=sort(Capacity/1e6,1);
p5_capacity_Mbps=sorted(ceil(numUsers*.05),:)';
summary=table(string(caseLabels(:)),noise_dBm,median_sinr_dB,weak_below_0dB_pct,mean_capacity_Mbps,median_capacity_Mbps,p5_capacity_Mbps,'VariableNames',{'condition','noise_dBm','median_sinr_dB','weak_below_0dB_pct','mean_capacity_Mbps','median_capacity_Mbps','p5_capacity_Mbps'});
writetable(summary,fullfile(outDir,'summary.csv'));
positions=table(real(pos),imag(pos),isIndoor,SINR_dB(:,1),SINR_dB(:,2),SINR_dB(:,3),'VariableNames',{'x_m','y_m','is_indoor','sinr_3p5GHz_100MHz_dB','sinr_28GHz_100MHz_dB','sinr_28GHz_800MHz_dB'});
writetable(positions,fullfile(outDir,'positions_sinr.csv'));
metadata=struct('source','matlab/labgemini4.m','matlab_version',version,'generated_local',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')),'load_factor',load_factor,'sector_power_dBm',Pt_dBm,'noise_figure_dB',NF,'num_locations',numUsers,'num_indoor',sum(isIndoor),'num_outdoor',sum(~isIndoor),'grid_step_m',personX,'evaluation_x_m',[-150,150],'evaluation_y_m',[0,550],'display_x_m',[-210,160],'color_limits_dB',[-15,25],'model_changed',false);
fid=fopen(fullfile(outDir,'run_metadata.json'),'w','n','UTF-8');
assert(fid>=0); fwrite(fid,jsonencode(metadata),'char'); fclose(fid);
disp(summary);
fprintf('Exported four PNG files and verified finite/unique samples: %s\n',outDir);
end

function drawMap(ax,pos,values,buildings,serving,external,label)
scatter(ax,real(pos),imag(pos),12,values,'filled'); hold(ax,'on');
for b=1:size(buildings,1)
    rect=buildings(b,:);
    rectangle(ax,'Position',[rect(1),rect(3),rect(2)-rect(1),rect(4)-rect(3)],'EdgeColor','k','LineWidth',0.8);
end
h1=plot(ax,real(serving),imag(serving),'k^','MarkerSize',7,'MarkerFaceColor','w');
h2=plot(ax,real(external),imag(external),'kx','MarkerSize',8,'LineWidth',1.5);
colormap(ax,jet(256)); caxis(ax,[-15 25]);
cb=colorbar(ax);cb.Label.String='SINR (dB)';
title(ax,label,'FontSize',14);xlabel(ax,'X (m)');ylabel(ax,'Y (m)');
axis(ax,'equal');xlim(ax,[-210 160]);ylim(ax,[0 550]);grid(ax,'on');ax.FontSize=11;
legend(ax,[h1,h2],{'Serving BS','Interference BS'},'Location','southwest','FontSize',10);
end
