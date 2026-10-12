function output_dir = run_day1()
% Day 1: unit checks and a SMALL synthetic example, not Sejong evidence.
root = fileparts(fileparts(mfilename('fullpath')));
day = fullfile(root,'day1','2026-10-07');
if ~exist(day,'dir'), mkdir(day); end
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
logfile = fullfile(day,['MATLAB_check_' stamp '.log']);
diary(logfile);
cleanup = onCleanup(@() diary('off'));
fprintf('DAY 1 CHECK: synthetic Soonchunhyang geometry, NOT Sejong.\n');
test_campus;
output_dir = campus_main('demo',struct('grid_m',40,'trials',2));
fprintf('DAY 1 PASS. Quick check grid = 40 m, trials = 2.\n');
fprintf('Final experiments must use surveyed Sejong data, 2.5 m and 20 trials.\n');
fid = fopen(fullfile(day,['result_location_' stamp '.txt']),'w');
assert(fid>=0,'Cannot write result location.');
fprintf(fid,'%s\n',output_dir); fclose(fid);
fprintf('Log: %s\n',logfile);
end
