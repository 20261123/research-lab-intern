"""Generate nested geometric candidate sets, without assuming surveyed feasibility."""
from pathlib import Path
import csv,json
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'results/labgemini4/weak_regions_provisional'
OUT=ROOT/'results/labgemini4/three_placement_scenarios'
OUT.mkdir(parents=True,exist_ok=True)
b=np.array([[-120.7,-56.4,234.9,325.6],[-12.4,46.4,0,61.6],[51.7,102.6,109.7,187.1],[-72.3,-24.3,113.1,170.1],[-76.4,-24.7,51.8,102.2],[-55.2,16.5,368,469.1],[-20.4,38.2,339.4,398.9]])
w=np.genfromtxt(BASE/'weak_points.csv',delimiter=',',names=True,encoding='utf-8-sig')
weak=np.c_[w['x_m'],w['y_m']]
p=np.genfromtxt(BASE/'boundary_vertices_estimated.csv',delimiter=',',names=True,encoding='utf-8-sig')
poly=np.c_[p['x_m'],p['y_m']]
bs=np.array([[53.6,121.3],[75.1,143.8],[76.3,156.5],[-2.2,269.7],[-98.8,364.8],[-58.1,386.1],[36.1,418.1],[-1.4,489.8],[-126.2,521.6]])
x,y=np.meshgrid(np.arange(-175,176,2.5),np.arange(-70,616,2.5)); xy=np.c_[x.ravel(),y.ravel()]
inside=np.zeros(len(xy),bool); edge=np.full(len(xy),np.inf)
for a,z in zip(poly,np.roll(poly,-1,axis=0)):
    if a[1]!=z[1]: inside^=((a[1]>xy[:,1])!=(z[1]>xy[:,1]))&(xy[:,0]<(z[0]-a[0])*(xy[:,1]-a[1])/(z[1]-a[1])+a[0])
    v=z-a;t=np.clip(((xy-a)@v)/(v@v),0,1);edge=np.minimum(edge,np.linalg.norm(xy-(a+t[:,None]*v),axis=1))
wall=np.full(len(xy),np.inf)
for r in b:
    d=np.c_[np.maximum(np.maximum(r[0]-xy[:,0],xy[:,0]-r[1]),0),np.maximum(np.maximum(r[2]-xy[:,1],xy[:,1]-r[3]),0)]
    wall=np.minimum(wall,np.linalg.norm(d,axis=1))
old_dist=np.min(np.linalg.norm(xy[:,None,:]-bs[None,:,:],axis=2),axis=1)
valid=inside&(edge>=10)&(wall>=5)&(old_dist>=25)
selected=[];rows=[]
# Balanced ranks: first candidate from each region, then second from each, then third.
# Nested 4,8,12 sets make the effect of more geometric choices visible.
for rank in [1,2,3]:
    for region,centre in enumerate(weak,1):
        dist=np.linalg.norm(xy-centre,axis=1)
        ok=valid&(dist<=75)
        if selected:
            ok &= np.min(np.linalg.norm(xy[:,None,:]-np.array(selected)[None,:,:],axis=2),axis=1)>=25
        idx=np.flatnonzero(ok)
        order=idx[np.lexsort((xy[idx,1],xy[idx,0],dist[idx]))]
        assert len(order),f'No geometric candidate for W{region}, rank {rank}'
        k=order[0]; selected.append(xy[k]);
        rows.append([f'W{region}C{rank}',region,rank,*xy[k],25,dist[k],edge[k],wall[k],old_dist[k]])
with (OUT/'candidates.csv').open('w',encoding='utf-8-sig',newline='') as f:
    writer=csv.writer(f);writer.writerow(['id','weak_region','rank_in_region','x_m','y_m','height_m','distance_to_weak_m','boundary_clearance_m','building_clearance_m','nearest_existing_site_m']);writer.writerows(rows)
settings={'status':'PROVISIONAL_GEOMETRIC_SITES_NOT_INSTALLATION_VERIFIED',
 'candidate_sets':[{'scenario':'S1','n_candidates':4,'n_pairs':6,'objective':'maximize overall p5 capacity'},
 {'scenario':'S2','n_candidates':8,'n_pairs':28,'objective':'maximize mean log capacity ratio'},
 {'scenario':'S3','n_candidates':12,'n_pairs':66,'objective':'maximize worst weak-region p5 improvement ratio'}],
 'rules':{'weak_search_radius_m':75,'boundary_clearance_m':10,'building_clearance_m':5,'existing_site_clearance_m':25,'candidate_separation_m':25,'new_site_height_m':25},
 'candidate_selection':'closest allowed grid point to each weak centre, then closest remaining point >=25 m from already selected candidates; balanced ranks across W1-W4',
 'common_selection':'held-out overall p5 descending; then worst regional p5 improvement ratio, median capacity, smaller worsened-user fraction; no claim of global optimum',
 'training_split':'even checkerboard index parity; odd parity held out; spatially nearby deterministic samples, not independent random trials',
 'feasibility_unverified':['land ownership','access','actual mast/roof height','installation permissions','utilities','unmodeled buildings'],
 'source_boundary':'../weak_regions_provisional/boundary_vertices_estimated.csv'}
(OUT/'scenario_settings.json').write_text(json.dumps(settings,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
