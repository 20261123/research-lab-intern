function data = campus_load_data(folder)
% Read surveyed local-metre polygons and site positions. Refuse blank templates.
meta = jsondecode(fileread(fullfile(folder,'metadata.json')));
assert(strcmp(meta.status,'surveyed'),'Campus:SurveyMissing', ...
 'Sejong survey missing. Fill input/sejong CSVs and metadata first; use demo for verification.');
assert(~isempty(meta.operator) && ~isempty(meta.origin_description), ...
 'Operator and local-coordinate origin are required.');
data.label = 'Sejong - virtual 5G at surveyed 4G sites';
data.is_demo = false; data.metadata = meta;
data.regions = read_polygons(fullfile(folder,'regions.csv'));
data.buildings = read_polygons(fullfile(folder,'buildings.csv'));
t = readtable(fullfile(folder,'sites.csv'),'TextType','string');
req = {'id','role','x_m','y_m','azimuth_deg','operator','source_url','survey_date','location_basis'};
assert(all(ismember(req,t.Properties.VariableNames)),'sites.csv column names do not match template.');
assert(all(ismember(t.role,["baseline","external","candidate"])),'Unknown site role.');
assert(numel(unique(t.id)) == height(t),'Site IDs must be unique.');
assert(size(unique([t.x_m,t.y_m],'rows'),1) == height(t),'Duplicate site coordinates.');
assert(all(isfinite([t.x_m;t.y_m;t.azimuth_deg])),'Site coordinates/angles must be finite.');
assert(all(t.operator == string(meta.operator)),'Use one operator for all site rows.');
assert(all(~ismissing(t.source_url) & ~ismissing(t.survey_date) & ~ismissing(t.location_basis)), ...
 'Every site needs source, survey date, and location basis.');
assert(nnz(t.role=="baseline")>=1 && nnz(t.role=="external")>=1,'Need baseline and external sites.');
assert(nnz(t.role=="candidate")==8,'Exactly eight reviewed candidate locations are required.');
data.sites = t(:,{'id','role','x_m','y_m','azimuth_deg'});
% Candidate locations must be inside the evaluation region. Rooftops allowed.
c = t(t.role=="candidate",:); inside = false(height(c),1);
for k = 1:numel(data.regions)
 p = data.regions{k}; inside = inside | inpolygon(c.x_m,c.y_m,p(:,1),p(:,2));
end
assert(all(inside),'Candidate sites must be within the campus evaluation region.');
end

function polys = read_polygons(file)
t = readtable(file,'TextType','string');
assert(all(ismember({'polygon_id','vertex_order','x_m','y_m'},t.Properties.VariableNames)), ...
 'Polygon CSV columns do not match template.');
ids = unique(t.polygon_id,'stable'); polys = cell(numel(ids),1);
for k = 1:numel(ids)
 r = sortrows(t(t.polygon_id==ids(k),:),'vertex_order');
 p = [r.x_m,r.y_m];
 assert(size(unique(p,'rows'),1)>=3 && all(isfinite(p(:))),'Invalid polygon.');
 assert(numel(unique(r.vertex_order))==height(r),'Duplicate vertex order.');
 shape = polyshape(p(:,1),p(:,2),'Simplify',false);
 assert(area(shape)>0,'Polygon area must be positive.');
 polys{k} = p;
end
assert(~isempty(polys),'Polygon CSV has no data.');
end
