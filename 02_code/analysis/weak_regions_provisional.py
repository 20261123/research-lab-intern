"""Reproducible provisional boundary and weak-region analysis (numpy only).
Boundary is a hand-estimated screen trace, NOT surveyed geometry.
Run --prepare before MATLAB, then run without arguments after MATLAB export.
"""
from pathlib import Path
import csv, json, sys, hashlib
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '04_site_selection/01_weak_regions'
OUT.mkdir(parents=True, exist_ok=True)
BUILDINGS = np.array([[-120.7,-56.4,234.9,325.6],[-12.4,46.4,0,61.6],
 [51.7,102.6,109.7,187.1],[-72.3,-24.3,113.1,170.1],[-76.4,-24.7,51.8,102.2],
 [-55.2,16.5,368,469.1],[-20.4,38.2,339.4,398.9]])
NAMES = ['광개토관','대양홀','학생회관','군자관','집현관','율곡관/충무관','학술정보원']
# Manually estimated building footprint centres on the user's ORIGINAL 475x757 map.
# These are visual estimates, not GIS control points. Library not used (ambiguous label).
PIX = np.array([[140,434],[288,699],[391,532],[191,552],[208,643],[230,164]],float)
TARGET = np.c_[(BUILDINGS[:6,0]+BUILDINGS[:6,1])/2,
               (BUILDINGS[:6,2]+BUILDINGS[:6,3])/2]
AFFINE = np.linalg.lstsq(np.c_[PIX,np.ones(6)],TARGET,rcond=None)[0]
RESIDUAL = np.linalg.norm(np.c_[PIX,np.ones(6)]@AFFINE-TARGET,axis=1)
# Approximate perimeter on ORIGINAL screenshot canvas, using second screenshot for shape.
# North/south portions outside the first screenshot are EXTRAPOLATED estimates.
BPIX = np.array([[197,-35],[332,87],[335,148],[475,292],[480,390],[465,475],
 [345,765],[312,790],[159,790],[157,590],[148,566],[153,504],[80,475],[57,451],
 [68,396],[80,353],[85,315],[101,266],[100,244],[95,214],[58,170],[51,132],
 [72,102],[121,44]],float)
POLY = np.c_[BPIX,np.ones(len(BPIX))]@AFFINE

def write_csv(path, headers, rows):
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.writer(f); w.writerow(headers); w.writerows(rows)

def inside_and_distance(xy):
    x,y=xy.T; inside=np.zeros(len(x),bool); dist=np.full(len(x),np.inf)
    for a,b in zip(POLY,np.roll(POLY,-1,axis=0)):
        if b[1]!=a[1]:
            hit=((a[1]>y)!=(b[1]>y)) & (x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])
            inside ^= hit
        v=b-a; t=np.clip(((xy-a)@v)/(v@v),0,1)
        dist=np.minimum(dist,np.linalg.norm(xy-(a+t[:,None]*v),axis=1))
    return inside,dist

def local_aggregate(mask, values, weak, ix, iy, shape):
    count=np.zeros(shape); total=np.zeros(shape); bad=np.zeros(shape)
    M=np.zeros(shape); V=np.zeros(shape); W=np.zeros(shape)
    M[iy,ix]=mask; V[iy,ix]=values*mask; W[iy,ix]=weak & mask
    # Disk radius 25 m, 2.5 m grid. Only campus-internal samples enter sums.
    for dx in range(-10,11):
        for dy in range(-10,11):
            if dx*dx+dy*dy>100: continue
            yd=slice(max(0,dy),min(shape[0],shape[0]+dy)); ys=slice(max(0,-dy),min(shape[0],shape[0]-dy))
            xd=slice(max(0,dx),min(shape[1],shape[1]+dx)); xs=slice(max(0,-dx),min(shape[1],shape[1]-dx))
            count[yd,xd]+=M[ys,xs]; total[yd,xd]+=V[ys,xs]; bad[yd,xd]+=W[ys,xs]
    c=count[iy,ix]; mean=total[iy,ix]/np.maximum(c,1); frac=bad[iy,ix]/np.maximum(c,1)
    return c,mean,frac

def select(mask, separation=75):
    threshold=np.sort(cap[mask])[int(np.ceil(mask.sum()*.10))-1]
    weak=cap<=threshold
    count,mean,frac=local_aggregate(mask,cap,weak,ix,iy,shape)
    # Focus on broad weak patches, not isolated minima. >=50 samples =312.5 m² sampled area.
    eligible=np.flatnonzero(mask & weak & (count>=50) & (frac>=.5))
    order=eligible[np.lexsort((xy[eligible,1],xy[eligible,0],-frac[eligible],mean[eligible]))]
    chosen=[]
    for k in order:
        if all(np.linalg.norm(xy[k]-xy[j])>=separation for j in chosen): chosen.append(int(k))
    return chosen,threshold,count,mean,frac,eligible

write_csv(OUT/'boundary_vertices_estimated.csv',['vertex','x_m','y_m','source_pixel_x','source_pixel_y'],
          [[i+1,*p,*s] for i,(p,s) in enumerate(zip(POLY,BPIX))])
write_csv(OUT/'registration_anchors.csv',['building','pixel_x','pixel_y','code_centre_x_m','code_centre_y_m','fit_residual_m'],
          [[NAMES[i],*PIX[i],*TARGET[i],RESIDUAL[i]] for i in range(6)])
geometry={'status':'PROVISIONAL_NOT_SURVEYED','affine_pixel_to_m':AFFINE.tolist(),
 'rms_anchor_residual_m':float(np.sqrt(np.mean(RESIDUAL**2))), 'max_anchor_residual_m':float(RESIDUAL.max()),
 'notes':['Original screenshot visual footprint centres; not exact GIS controls.',
 'Boundary manually estimated from two user screenshots; clipped north/south parts extrapolated.',
 'West trace constrained to contain all seven provided building rectangles; not surveyed.',
 '30 m boundary sensitivity band is a working sensitivity choice, not a statistical confidence interval.'],
 'source_code_sha256':hashlib.sha256((ROOT/'02_code/matlab/labgemini4.m').read_bytes()).hexdigest()}
(OUT/'geometry_assumptions.json').write_text(json.dumps(geometry,ensure_ascii=False,indent=2),encoding='utf-8')

if '--prepare' in sys.argv:
    src=(ROOT/'02_code/matlab/labgemini4.m').read_text(encoding='utf-8-sig')
    src=src.replace('[X, Y] = meshgrid(-150:personX:150, 0:personY:550);',
                    '[X, Y] = meshgrid(-175:personX:175, -70:personY:615);')
    marker='%% ------------------- 사용자 정의 함수 ------------------- %%'
    dest=str(OUT/'extended_grid_sinr.csv').replace('\\','/')
    export="\nT=table(real(pos),imag(pos),isIndoor,SINR_dB(:,3),signal_mW(:,2),interference_mW(:,2), 'VariableNames',{'x_m','y_m','is_indoor','sinr_dB','signal_mW','interference_mW'});\nwritetable(T,'"+dest+"');\nclose all;\n"
    assert marker in src
    src=src.replace(marker,export+'\n'+marker)
    (OUT/'labgemini4_extended_grid.m').write_text(src,encoding='utf-8')
    print(json.dumps(geometry,ensure_ascii=False)); sys.exit(0)

a=np.genfromtxt(OUT/'extended_grid_sinr.csv',delimiter=',',names=True,encoding='utf-8-sig')
xy=np.c_[a['x_m'],a['y_m']]; cap=800*np.log2(1+10**(a['sinr_dB']/10))
ix=np.rint((xy[:,0]+175)/2.5).astype(int); iy=np.rint((xy[:,1]+70)/2.5).astype(int)
shape=(275,141)
mask,distance=inside_and_distance(xy)
chosen,threshold,count,mean,frac,eligible=select(mask)
names=[]; rows=[]
noise=10**((-174+10*np.log10(800e6)+7)/10)
for rank,k in enumerate(chosen,1):
    hit=np.flatnonzero((xy[k,0]>=BUILDINGS[:,0])&(xy[k,0]<=BUILDINGS[:,1])&
                       (xy[k,1]>=BUILDINGS[:,2])&(xy[k,1]<=BUILDINGS[:,3]))
    name='/'.join(NAMES[j] for j in hit) if len(hit) else '실외'
    near=(np.linalg.norm(xy-xy[k],axis=1)<=25)&mask
    rows.append([f'W{rank}',*xy[k],name,a['sinr_dB'][k],cap[k],int(count[k]),mean[k],
                 float(np.median(cap[near])),frac[k]*100,distance[k],a['interference_mW'][k]/noise,
                 10*np.log10(a['signal_mW'][k]),10*np.log10(a['interference_mW'][k])])
write_csv(OUT/'weak_points.csv',['id','x_m','y_m','location','sinr_dB','capacity_Mbps','local_samples',
 'local_mean_capacity_Mbps','local_median_capacity_Mbps','local_bottom10_pct','boundary_distance_m',
 'I_over_N','signal_dBm','interference_dBm'],rows)
write_csv(OUT/'campus_positions.csv',['x_m','y_m','is_indoor','sinr_dB','capacity_Mbps','boundary_distance_m'],
          np.c_[xy[mask],a['is_indoor'][mask],a['sinr_dB'][mask],cap[mask],distance[mask]])
sens=[]
for label,m in [('contract_30m',mask&(distance>=30)),('base',mask),('expand_30m',mask|(distance<=30))]:
    for sep in [50,75,100]:
        ch,t,*_=select(m,sep)
        sens.append({'boundary':label,'separation_m':sep,'n_positions':int(m.sum()),'n_representatives':len(ch),
                     'p10_capacity_Mbps':float(t),'points':xy[ch].tolist()})
old=np.genfromtxt(ROOT/'05_comparison_results/02_baseline9_rectangle_heatmaps/positions_sinr.csv',delimiter=',',names=True)
lookup={(float(x),float(y)):float(s) for x,y,s in zip(xy[:,0],xy[:,1],a['sinr_dB'])}
maxdiff=max(abs(lookup[(float(r['x_m']),float(r['y_m']))]-r['sinr_28GHz_800MHz_dB']) for r in old)
summary={'status':'PROVISIONAL_BOUNDARY','condition':'28 GHz / 800 MHz','load_factor':.5,
 'n_campus_positions':int(mask.sum()),'n_indoor':int(np.sum(a['is_indoor'][mask])),
 'p5_capacity_Mbps':float(np.sort(cap[mask])[int(np.ceil(mask.sum()*.05))-1]),
 'p10_capacity_Mbps':float(threshold),'median_capacity_Mbps':float(np.median(cap[mask])),
 'n_qualifying_centres':len(eligible),'n_weak_representatives':len(chosen),
 'separation_m':75,'local_radius_m':25,'min_local_samples':50,'min_bottom10_fraction':.5,
 'boundary_sensitivity_m':30,'max_difference_from_original_overlap_dB':float(maxdiff),
 'min_pair_distance_m':float(min((np.linalg.norm(xy[i]-xy[j]) for n,i in enumerate(chosen) for j in chosen[n+1:]),default=0)),
 'sensitivity':sens,'geometry':geometry}
(OUT/'analysis_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
assert np.all(np.isfinite(a['sinr_dB'])) and np.all(np.isfinite(cap))
assert len(np.unique(xy,axis=0))==len(xy)
assert np.sum(a['is_indoor'][mask])==4601, 'Provided building samples unexpectedly clipped.'
assert maxdiff<1e-10
assert all(mask[k] for k in chosen)
assert summary['min_pair_distance_m']>=75
assert all(min(np.linalg.norm(xy[k]-xy[j]) for j in chosen)<75+1e-9 for k in eligible)
verification={'finite_power_and_capacity':True,'unique_coordinates':True,
 'all_4601_original_indoor_samples_inside':True,'all_representatives_inside':True,
 'all_qualifying_centres_within_75m_of_a_selected_representative':True,
 'min_pair_distance_m':summary['min_pair_distance_m'],
 'original_overlap_max_SINR_difference_dB':maxdiff,
 'source_original_sha256':geometry['source_code_sha256'],
 'boundary_survey_verified':False,'new_base_stations_optimized':False}
(OUT/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['geometry','sensitivity']},ensure_ascii=False,indent=2))
print('POINTS',json.dumps(rows,ensure_ascii=False))
print('SENSITIVITY',json.dumps(sens,ensure_ascii=False))
