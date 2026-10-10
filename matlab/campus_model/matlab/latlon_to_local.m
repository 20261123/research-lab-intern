function [x_m,y_m] = latlon_to_local(lat_deg,lon_deg,origin_lat_deg,origin_lon_deg)
% Local tangent approximation for a small campus, WGS84 degrees -> metres.
% Record origin in metadata. Survey height/terrain is not modeled.
assert(all(abs(lat_deg)<=90) && all(abs(lon_deg)<=180),'Invalid latitude/longitude.');
R = 6378137;
x_m = R*cosd(origin_lat_deg)*deg2rad(lon_deg-origin_lon_deg);
y_m = R*deg2rad(lat_deg-origin_lat_deg);
end
