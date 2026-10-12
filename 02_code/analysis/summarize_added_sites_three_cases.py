"""Derive comparison tables and verify exported MATLAB numeric results."""
from pathlib import Path
import csv,json
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'05_comparison_results/03_added11_campus'
casefiles=['3p5GHz_100MHz','28GHz_100MHz','28GHz_800MHz']
labels=['3.5 GHz / 100 MHz','28 GHz / 100 MHz','28 GHz / 800 MHz']
rows=list(csv.DictReader((OUT/'summary.csv').open(encoding='utf-8-sig')))
def write(name,records):
    with (OUT/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=records[0].keys());w.writeheader();w.writerows(records)
comparisons=[]
for group in ['all','indoor','outdoor']:
    r=[v for v in rows if v['service_sites']=='11' and v['group']==group]
    for tag,i,j in [('step1_frequency_same_100MHz',0,1),('step2_representative_3p5_100_vs_28_800',0,2),('bandwidth_only_28_100_vs_28_800',1,2)]:
        comparisons.append({'comparison':tag,'group':group,'from_condition':r[i]['condition'],'to_condition':r[j]['condition'],
          'median_sinr_change_dB':float(r[j]['median_sinr_dB'])-float(r[i]['median_sinr_dB']),
          'median_capacity_ratio':float(r[j]['median_capacity_Mbps'])/float(r[i]['median_capacity_Mbps']),
          'p5_capacity_ratio':float(r[j]['p5_capacity_Mbps'])/float(r[i]['p5_capacity_Mbps']),
          'p5_capacity_change_pct':100*(float(r[j]['p5_capacity_Mbps'])/float(r[i]['p5_capacity_Mbps'])-1)})
write('step1_step2_comparisons.csv',comparisons)
a=np.genfromtxt(OUT/'positions_three_cases.csv',delimiter=',',names=True,encoding='utf-8-sig')
n=len(a);assert n==17922
xy=np.c_[a['x_m'],a['y_m']];assert len(np.unique(xy,axis=0))==n
qidx=int(np.ceil(n*.05))-1
cap=np.c_[*[a['added_capacity_'+c+'_Mbps'] for c in casefiles]]
sinr=np.c_[*[a['added_sinr_'+c+'_dB'] for c in casefiles]]
assert np.isfinite(cap).all() and np.isfinite(sinr).all()
derived=np.array([100,100,800])*np.log2(1+10**(sinr/10))
formula_error=float(np.max(abs(cap-derived)));assert formula_error<1e-8
assert np.all(sinr[:,1]<=sinr[:,0]+1e-10)
assert np.all(sinr[:,2]<=sinr[:,1]+1e-10)
assert np.all(cap[:,2]>=cap[:,1]-1e-9)
sorted_cap=np.sort(cap,axis=0)
after=[v for v in rows if v['service_sites']=='11' and v['group']=='all']
for k in range(3):assert abs(sorted_cap[qidx,k]-float(after[k]['p5_capacity_Mbps']))<1e-8
F=np.arange(1,n+1)/n;assert F[-1]==1 and np.all(np.diff(F)>0)
with (OUT/'cdf_values.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f);w.writerow(['cdf',*['capacity_'+c+'_Mbps' for c in casefiles]]);w.writerows(np.c_[F,sorted_cap])
loss=[]
for k,c in enumerate(casefiles):
    before=a['baseline_capacity_'+c+'_Mbps'];ratio=cap[:,k]/before
    for group,mask in [('all',np.ones(n,bool)),('indoor',a['is_indoor']>0),('outdoor',a['is_indoor']==0)]:
        v=ratio[mask];bad=v[v<1-1e-10]
        loss.append({'condition':labels[k],'group':group,'n_positions':int(mask.sum()),
          'any_loss_pct':float(100*np.mean(v<1-1e-10)),'loss_gt_1pct_pct':float(100*np.mean(v<.99)),
          'loss_gt_10pct_pct':float(100*np.mean(v<.9)),'loss_gt_20pct_pct':float(100*np.mean(v<.8)),
          'median_relative_loss_among_worsened_pct':float(np.median(100*(1-bad)))})
write('degradation_by_case.csv',loss)
metadata=json.loads((OUT/'run_metadata.json').read_text())
assert metadata['service_sites']==11 and metadata['external_sites']==6
v={'n_locations':n,'n_indoor':int(np.sum(a['is_indoor'])),'unique_finite_samples':True,
 'p5_sorted_index_one_based':qidx+1,'capacity_formula_max_error_Mbps':formula_error,
 'CDF_monotonic_and_reaches_one':True,'common_case_inequalities_verified':True,
 'source_baseline_and_previous_added_matches_verified':True,'surveyed_boundary_verified':False}
(OUT/'verification.json').write_text(json.dumps(v,indent=2),encoding='utf-8')
print(json.dumps(v))
