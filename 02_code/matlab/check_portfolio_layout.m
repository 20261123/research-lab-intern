function check_portfolio_layout()
% Read-only layout/cache sanity check after the 2026-10-12 relocation.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
weak=fullfile(repo,'04_site_selection','01_weak_regions');
choice=fullfile(repo,'04_site_selection','02_candidate_evaluation');
fixed=fullfile(repo,'05_comparison_results','03_added11_campus');
random=fullfile(repo,'06_resilience','20_trials_and_failures');
U=readtable(fullfile(weak,'campus_positions.csv'));
B=readtable(fullfile(weak,'boundary_vertices_estimated.csv'));
K=readtable(fullfile(choice,'candidates.csv'));
J=jsondecode(fileread(fullfile(choice,'run_summary.json')));
V=readtable(fullfile(fixed,'positions_three_cases.csv'));
T=readtable(fullfile(random,'trial_metrics.csv'));
seeds=readtable(fullfile(random,'seeds.csv'));
assert(height(U)==17922 && sum(U.is_indoor)==4601);
assert(height(B)==24 && height(K)==12);
assert(isequal(J.final_recommendation.coordinates_m,[-127.5,260;-17.5,22.5]));
assert(height(V)==17922 && height(T)==14400 && height(seeds)==20);
assert(numel(unique(T.seed))==20);
% Recompute one deterministic condition without writing or resimulating trials.
serv=readtable(fullfile(fixed,'service_sites.csv'));ext=readtable(fullfile(fixed,'external_sites.csv'));
sites=[serv.x_m,serv.y_m;ext.x_m,ext.y_m];R=zeros(height(U),51);fc=28;
wall=5-10*log10(.3*10^(-(2+.2*fc)/10)+.7*10^(-(5+4*fc)/10));
for k=1:17
 d=hypot(hypot(U.x_m-sites(k,1),U.y_m-sites(k,2)),23.5);
 PL=13.54+39.08*log10(d)+20*log10(fc);
 theta=atan2d(U.y_m-sites(k,2),U.x_m-sites(k,1));
 for sec=1:3
  delta=mod(theta-120*(3-sec)+180,360)-180;
  R(:,3*(k-1)+sec)=10.^((43-PL-wall*double(U.is_indoor)-min(12*(delta/70).^2,20))/10);
 end
end
S=max(R(:,1:33),[],2);I=.5*(sum(R,2)-S);N=10^((-174+10*log10(800e6)+7)/10);
C=800*log2(1+S./(I+N));[tf,loc]=ismember([U.x_m,U.y_m],[V.x_m,V.y_m],'rows');assert(all(tf));
err=max(abs(C-V.added_capacity_28GHz_800MHz_Mbps(loc)));assert(err<1e-8);
functions={'export_labgemini4_heatmaps','plot_provisional_weak_regions','evaluate_three_placement_scenarios','run_added_sites_three_cases','validate_random_trials_and_failures','analyze_resilience_fallback'};
for k=1:numel(functions)
 assert(~isempty(which(functions{k})));
 issues=checkcode(fullfile(repo,'02_code','matlab',[functions{k},'.m']),'-id');
 if ~isempty(issues),assert(~any(strcmp({issues.id},'PARSE')));end
end
fprintf('PASS: relocated inputs, 17,922 users, 12 candidates, 20 seeds, 14,400 metrics.\n');
fprintf('PASS: deterministic 28/800 matches stored values, max error %.3g Mbps.\n',err);
end
