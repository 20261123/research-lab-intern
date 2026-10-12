function plot_provisional_weak_regions()
% Draw numerical coordinates only; no generated map pixels used for SINR.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
out=fullfile(repo,'04_site_selection','01_weak_regions');
T=readtable(fullfile(out,'campus_positions.csv'),'VariableNamingRule','preserve');
B=readtable(fullfile(out,'boundary_vertices_estimated.csv'));
W=readtable(fullfile(out,'weak_points.csv'),'VariableNamingRule','preserve','TextType','string');
b=[-120.7,-56.4,234.9,325.6;-12.4,46.4,0,61.6;51.7,102.6,109.7,187.1;-72.3,-24.3,113.1,170.1;-76.4,-24.7,51.8,102.2;-55.2,16.5,368,469.1;-20.4,38.2,339.4,398.9];
names={'광개토관','대양홀','학생회관','군자관','집현관','율곡관/충무관','학술정보원'};
serv=[53.6,121.3;75.1,143.8;76.3,156.5;-2.2,269.7;-98.8,364.8;-58.1,386.1;36.1,418.1;-1.4,489.8;-126.2,521.6];
ext=[-101.6,81.4;-149,335.7;-151.4,370.6;-143.8,409.7;94.1,505.8;-196.7,476.9];
for mode=1:2
 f=figure('Visible','off','Color','w','Position',[100,100,980,1160]); ax=axes(f); hold(ax,'on');
 if mode==1
   scatter(ax,T.x_m,T.y_m,11,T.sinr_dB,'filled'); colormap(ax,jet(256)); clim(ax,[-30,15]);
   cb=colorbar(ax); cb.Label.String='SINR (dB)';
 else
   scatter(ax,T.x_m,T.y_m,9,[.87,.91,.96],'filled');
   J=jsondecode(fileread(fullfile(out,'analysis_summary.json')));
   weak=T.capacity_Mbps<=J.p10_capacity_Mbps;
   scatter(ax,T.x_m(weak),T.y_m(weak),13,[.78,.16,.22],'filled');
 end
 hBoundary=plot(ax,[B.x_m;B.x_m(1)],[B.y_m;B.y_m(1)],'b-','LineWidth',2);
 for k=1:7
   rectangle(ax,'Position',[b(k,1),b(k,3),b(k,2)-b(k,1),b(k,4)-b(k,3)],'EdgeColor',[.2,.2,.2],'LineWidth',1);
   text(ax,mean(b(k,1:2)),b(k,4)+6,names{k},'FontName','Malgun Gothic','FontSize',10,'HorizontalAlignment','center','BackgroundColor','w','Margin',1);
 end
 hServ=plot(ax,serv(:,1),serv(:,2),'k^','MarkerFaceColor','w','MarkerSize',7);
 hExt=plot(ax,ext(:,1),ext(:,2),'kx','LineWidth',1.5);
 hW=plot(ax,W.x_m,W.y_m,'mo','MarkerFaceColor','y','MarkerSize',10,'LineWidth',2);
 theta=linspace(0,2*pi,160);
 for k=1:height(W)
   plot(ax,W.x_m(k)+25*cos(theta),W.y_m(k)+25*sin(theta),'m--','LineWidth',1.2);
   text(ax,W.x_m(k)+8,W.y_m(k)+12,sprintf('%s (%.1f, %.1f)',W.id(k),W.x_m(k),W.y_m(k)),...
       'Color','k','FontSize',11,'FontWeight','bold','BackgroundColor','w','Margin',2);
 end
 axis(ax,'equal'); xlim(ax,[-210,180]); ylim(ax,[-45,600]); grid(ax,'on');
 xlabel(ax,'X (m)'); ylabel(ax,'Y (m)'); ax.FontSize=11;
 title(ax,{'28 GHz / 800 MHz | labgemini4 | load 0.5','PROVISIONAL boundary | 25 m neighbourhoods | >=75 m separation'},'FontSize',13);
 legend(ax,[hBoundary,hServ,hExt,hW],{'Estimated boundary','Existing service sites (kept)','External interferers','Weak-region representative'},'Location','northwest','FontSize',9);
 if mode==1, name='weak_regions_sinr.png'; else, name='weak_regions_bottom10.png'; end
 exportgraphics(f,fullfile(out,name),'Resolution',200); close(f);
end
end
