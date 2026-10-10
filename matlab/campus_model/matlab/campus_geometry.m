function geom = campus_geometry(data, cfg)
% Generate polygon grids separately, then remove overlap at boundaries.
xy = zeros(0,2);
for k = 1:numel(data.regions)
 p = data.regions{k};
 [x,y] = meshgrid(min(p(:,1)):cfg.grid_m:max(p(:,1)), ...
                  min(p(:,2)):cfg.grid_m:max(p(:,2)));
 in = inpolygon(x,y,p(:,1),p(:,2)); xy = [xy; x(in),y(in)]; %#ok<AGROW>
end
geom.xy = unique(xy,'rows','sorted');
geom.indoor = false(size(geom.xy,1),1);
for k = 1:numel(data.buildings)
 p = data.buildings{k};
 geom.indoor = geom.indoor | inpolygon(geom.xy(:,1),geom.xy(:,2),p(:,1),p(:,2));
end
assert(~isempty(geom.xy),'No evaluation positions inside region polygons.');
end
