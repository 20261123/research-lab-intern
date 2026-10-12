"""Historical one-time relocation for pre-reorganization commit 54c8cdc. Do not run on the organized tree; use build_portfolio_catalog.py for routine indexing."""
from pathlib import Path, PurePosixPath
import csv, json, hashlib, re, posixpath, os, subprocess, sys
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[2]
GIT='C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/cmd/git.exe'
PREFIX={
 'matlab/campus_model':'09_references_archive/demo_package',
 'matlab/legacy':'09_references_archive/code_versions',
 'matlab':'02_code/matlab', 'analysis':'02_code/analysis',
 'tools/report/build_presenter_guide.py':'07_presentation/tools/build_presenter_guide.py',
 'tools':'09_references_archive/generation_tools',
 'references/maps/sejong_boundary':'03_campus_data/maps/originals',
 'references/38901-j40.docx':'09_references_archive/standards/38901-j40.docx',
 'references/연구실인턴_교과목_지능형통신및네트워크_미니프로젝트_수정.pdf':'09_references_archive/assignment/연구실인턴_교과목_지능형통신및네트워크_미니프로젝트_수정.pdf',
 'references':'09_references_archive/starting_materials',
 'data/survey':'03_campus_data/survey',
 'data/file_manifest.csv':'01_portfolio/catalog/file_manifest.csv',
 'results/maps/sejong_7regions':'03_campus_data/maps/concept',
 'results/labgemini4/weak_regions_provisional':'04_site_selection/01_weak_regions',
 'results/labgemini4/three_placement_scenarios':'04_site_selection/02_candidate_evaluation',
 'results/labgemini4/added11_three_cases':'05_comparison_results/03_added11_campus',
 'results/labgemini4/heatmaps_three_cases':'05_comparison_results/02_baseline9_rectangle_heatmaps',
 'results/labgemini4/random20_resilience':'06_resilience/20_trials_and_failures',
 'results/labgemini4':'05_comparison_results/01_baseline9_rectangle',
 'results/earlier_runs':'09_references_archive/earlier_screenshots',
 'reports':'09_references_archive/reports',
 'presentations':'07_presentation/slides/examples',
 'output/pdf/세종대_통신프로젝트_발표자_상세해설서.pdf':'07_presentation/01_presenter_guide/세종대_통신프로젝트_발표자_상세해설서.pdf',
 'output/pdf/조원별_다음할일.pdf':'08_project_management/roles/조원별_다음할일.pdf',
 'docs/project/발표자_상세해설서.md':'07_presentation/01_presenter_guide/발표자_상세해설서.md',
 'docs/project/발표자_상세해설서_검수.json':'07_presentation/01_presenter_guide/발표자_상세해설서_검수.json',
 'docs/project':'08_project_management/current',
 'docs/day1':'08_project_management/day1',
 'docs/CODE_VERSIONS.md':'02_code/docs/CODE_VERSIONS.md',
 'docs/FILE_INDEX.md':'01_portfolio/catalog/FILE_INDEX.md',
 'docs/LARGE_FILES.md':'01_portfolio/catalog/LARGE_FILES.md',
 'archives/project_initial':'09_references_archive/initial_plan',
 'archives':'09_references_archive/deliverables',
 'logs':'09_references_archive/logs',
}
ordered=sorted(PREFIX,key=len,reverse=True)
def mapped(path):
 path=posixpath.normpath(str(path).replace('\\','/'))
 for old in ordered:
  if path==old or path.startswith(old+'/'):return PREFIX[old]+path[len(old):]
 return path
tracked=subprocess.check_output([GIT,'ls-files','-z'],cwd=ROOT).decode('utf-8').split('\0')
tracked=[p for p in tracked if p]
repair='--repair-text-paths' in sys.argv
# Preserve existing overview/index as history before replacing navigation.
history=ROOT/'09_references_archive/repository_history';history.mkdir(parents=True,exist_ok=True)
if not repair:
 for rel,name in [('README.md','README_before_2026-10-12.md'),('docs/FILE_INDEX.md','FILE_INDEX_before_2026-10-12.md')]:
  (history/name).write_bytes((ROOT/rel).read_bytes())
extras=[p.relative_to(ROOT).as_posix() for p in (ROOT/'matlab/campus_model').rglob('*.mat') if p.relative_to(ROOT).as_posix() not in tracked] if not repair else []
snap=[];oldbytes={}
if repair:
 with (ROOT/'01_portfolio/catalog/path_migration_2026-10-12.csv').open(encoding='utf-8',newline='') as f:snap=list(csv.DictReader(f))
 for item in snap:
  if item['old_path'] in tracked:oldbytes[item['old_path']]=subprocess.check_output([GIT,'show','HEAD:'+item['old_path']],cwd=ROOT)
for rel in tracked+extras:
 if repair:break
 src=ROOT/rel;new=mapped(rel)
 if not src.is_file():continue
 if new==rel:continue
 dst=ROOT/new
 # Final absolute source/destination must remain inside this repository.
 assert src.resolve().is_relative_to(ROOT.resolve()) and dst.resolve().is_relative_to(ROOT.resolve())
 assert '.git' not in src.relative_to(ROOT).parts and '.git' not in dst.relative_to(ROOT).parts
 assert not dst.exists(),f'Collision: {new}'
 b=src.read_bytes();oldbytes[rel]=b
 snap.append(dict(old_path=rel,new_path=new,bytes=len(b),sha256_before=hashlib.sha256(b).hexdigest()))
 dst.parent.mkdir(parents=True,exist_ok=True);src.rename(dst)

def root_strings(s):
 # Slash-separated root paths, longest prefix first; one substitution avoids cascading.
 # Match full relative roots, not identifier substrings or already-moved paths.
 choices=[re.escape(x)+(r'(?=/)' if '/' not in x else r'(?=/|[\s\x27\x22`),;]|$)') for x in ordered]
 pat=re.compile(r'(?<![A-Za-z0-9_/-])(?:'+'|'.join(choices)+')')
 for old in ordered:s=s.replace(ROOT.as_posix()+'/'+old,ROOT.as_posix()+'/'+PREFIX[old])
 return pat.sub(lambda m:PREFIX[m.group(0)],s)
def relocate_link(target,oldparent,newparent):
 if target.startswith(('https:','http:','mailto:','#','app:','codex:')):return target
 anchor='';target,sep,frag=target.partition('#')
 if sep:anchor='#'+frag
 target=unquote(target.strip('<>'))
 if target.startswith(('C:','/')):return target+anchor
 resolved=posixpath.normpath(posixpath.join(oldparent,target))
 newtarget=mapped(resolved)
 return posixpath.relpath(newtarget,newparent)+anchor
def rewrite_markdown(s,old,new):
 oldparent=posixpath.dirname(old);newparent=posixpath.dirname(new)
 pat=re.compile(r'(\]\()([^\n)]+)(\))')
 # Rewrite links before applying displayed root-path replacements.
 protected=[]
 def hold(m):
  protected.append(m.group(1)+relocate_link(m.group(2),oldparent,newparent)+m.group(3));return f'LINKTOKEN{len(protected)-1}END'
 s=pat.sub(hold,s);s=root_strings(s)
 for i,v in enumerate(protected):s=s.replace(f'LINKTOKEN{i}END',v)
 s=s.replace("addpath('matlab')","addpath('02_code/matlab')")
 return s

def matlab_paths(s):
 s=s.replace("repo=fileparts(fileparts(mfilename('fullpath')));","repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));")
 s=s.replace("repoRoot = fileparts(fileparts(mfilename('fullpath')));","repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));")
 # Aliased parent directory in the added-sites function spans multiple categories.
 s=s.replace("previous=fullfile(repo,'results','labgemini4');","previous=repo;")
 for leaf in ['weak_regions_provisional','three_placement_scenarios','heatmaps_three_cases']:
  new=mapped('results/labgemini4/'+leaf)
  s=s.replace("fullfile(previous,'"+leaf+"'","fullfile(previous,"+','.join("'"+x+"'" for x in new.split('/')))
 # All literal paths rooted at repo/repoRoot can be mapped safely.
 def ff(m):
  var=m.group(1);lits=re.findall(r"'([^']*)'",m.group(2));joined='/'.join(lits);new=mapped(joined)
  if new==joined:return m.group(0)
  return 'fullfile('+var+','+','.join("'"+v+"'" for v in new.split('/'))
 s=re.sub(r"fullfile\((repo|repoRoot),((?:\s*'[^']*'\s*,?)+)",ff,s)
 s=root_strings(s).replace("addpath('matlab')","addpath('02_code/matlab')")
 return s

for item in snap:
 old,new=item['old_path'],item['new_path'];p=ROOT/new
 # Original references/history and all binary experimental data are preserved byte-for-byte.
 if new.startswith('09_references_archive/') or p.suffix.lower() not in {'.md','.py','.m','.json'}:continue
 if new=='02_code/matlab/labgemini4.m':continue
 b=oldbytes[old];s=b.decode('utf-8-sig');crlf=b'\r\n' in b;hasbom=b.startswith(b'\xef\xbb\xbf');s=s.replace('\r\n','\n')
 if p.suffix=='.md':s=rewrite_markdown(s,old,new)
 elif p.suffix=='.m':s=matlab_paths(s)
 elif p.suffix=='.py':
  if new.startswith('02_code/analysis/'):
   s=s.replace('Path(__file__).resolve().parents[1]','Path(__file__).resolve().parents[2]')
  s=root_strings(s).replace("addpath('matlab')","addpath('02_code/matlab')")
 elif p.suffix=='.json':
  data=json.loads(s)
  def walk(v):
   if isinstance(v,dict):return {k:walk(x) for k,x in v.items()}
   if isinstance(v,list):return [walk(x) for x in v]
   if isinstance(v,str):
    if v.startswith('../'):return relocate_link(v,posixpath.dirname(old),posixpath.dirname(new))
    return root_strings(v)
   return v
  s=json.dumps(walk(data),ensure_ascii=False,indent=2)+'\n'
 if crlf:s=s.replace('\n','\r\n')
 p.write_bytes((b'\xef\xbb\xbf' if hasbom else b'')+s.encode('utf-8'))
for name in ['AGENTS.md','.gitignore']:
 p=ROOT/name;b=subprocess.check_output([GIT,'show','HEAD:'+name],cwd=ROOT) if repair else p.read_bytes();s=root_strings(b.decode('utf-8'));p.write_bytes(s.encode('utf-8'))
# Existing manifest origins are immutable provenance; relocate only stored paths.
manifest=ROOT/'01_portfolio/catalog/file_manifest.csv'
with manifest.open(encoding='utf-8-sig',newline='') as f:
 r=csv.DictReader(f);cols=r.fieldnames;rows=list(r)
for r in rows:
 r['path']=mapped(r['path']);p=ROOT/r['path']
 if p.is_file():b=p.read_bytes();r['bytes']=str(len(b));r['sha256']=hashlib.sha256(b).hexdigest()
with manifest.open('w',encoding='utf-8',newline='') as f:
 w=csv.DictWriter(f,fieldnames=cols);w.writeheader();w.writerows(rows)
catalog=ROOT/'01_portfolio/catalog';catalog.mkdir(parents=True,exist_ok=True)
with (catalog/'path_migration_2026-10-12.csv').open('w',encoding='utf-8',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(snap[0]));w.writeheader();w.writerows(snap)
# Only remove now-empty old directories, never recursive delete.
for old in ['matlab','analysis','tools','references','data','results','reports','presentations','output','docs','archives','logs']:
 p=ROOT/old
 if not p.exists():continue
 for d in sorted([x for x in p.rglob('*') if x.is_dir()],key=lambda v:len(v.parts),reverse=True)+[p]:
  assert d.resolve().is_relative_to(ROOT.resolve())
  try:d.rmdir()
  except OSError:pass
protected=[]
for item in snap:
 p=ROOT/item['new_path'];b=p.read_bytes()
 if p.suffix.lower() in {'.png','.jpg','.mat','.docx','.pptx','.zip','.pdf'} or item['new_path'].startswith('09_references_archive/') or item['new_path']=='02_code/matlab/labgemini4.m':
  assert hashlib.sha256(b).hexdigest()==item['sha256_before'],item['new_path'];protected.append(item['new_path'])
qa={'relocated_files':len(snap),'protected_files_byte_identical':len(protected),'scope':'repository only; synced sources untouched','numerical_recalculation':False}
(catalog/'reorganization_verification.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(qa,ensure_ascii=False))
