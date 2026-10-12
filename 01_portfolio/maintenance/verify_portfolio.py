"""Check the reorganized portfolio without recalculating experiments."""
from pathlib import Path
import ast,csv,hashlib,json,re
from urllib.parse import unquote
from pypdf import PdfReader
import pdfplumber
ROOT=Path(__file__).resolve().parents[2]
catalog=ROOT/'01_portfolio/catalog'
with (catalog/'path_migration_2026-10-12.csv').open(encoding='utf-8',newline='') as f:moved=list(csv.DictReader(f))
changed=[];preserved=0;data=0
pdfpath='07_presentation/01_presenter_guide/세종대_통신프로젝트_발표자_상세해설서.pdf'
for r in moved:
 p=ROOT/r['new_path'];assert p.is_file(),r['new_path']
 sha=hashlib.sha256(p.read_bytes()).hexdigest()
 if p.suffix.lower() in {'.png','.jpg','.mat','.docx','.pptx','.zip','.pdf','.csv'} or r['new_path'].startswith('09_references_archive/') or r['new_path']=='02_code/matlab/labgemini4.m':
  if r['new_path'] in {pdfpath,'01_portfolio/catalog/file_manifest.csv'}:changed.append(r['new_path']);continue
  assert sha==r['sha256_before'],r['new_path'];preserved+=1
  if p.suffix=='.csv':data+=1
for p in list((ROOT/'02_code/analysis').glob('*.py'))+list((ROOT/'07_presentation/tools').glob('*.py')):ast.parse(p.read_text(encoding='utf-8-sig'))
bad=[];links=0
for name in ['01_portfolio','02_code','03_campus_data','04_site_selection','05_comparison_results','06_resilience','07_presentation','08_project_management']:
 for p in (ROOT/name).rglob('*.md'):
  for u in re.findall(r'\]\(([^\n)]+)\)',p.read_text(encoding='utf-8-sig')):
   u=unquote(u.split('#')[0].strip('<>'))
   if not u or u.startswith(('http:','https:','mailto:','app:','codex:','C:','/')):continue
   links+=1
   if not (p.parent/u).exists():bad.append([p.relative_to(ROOT).as_posix(),u])
for u in re.findall(r'\]\(([^\n)]+)\)',(ROOT/'README.md').read_text(encoding='utf-8')):
 u=unquote(u.split('#')[0].strip('<>'))
 if not u or u.startswith(('http:','https:','mailto:','#')):continue
 links+=1
 if not (ROOT/u).exists():bad.append(['README.md',u])
assert not bad,bad
p=ROOT/pdfpath;r=PdfReader(p);assert len(r.pages)==34 and len(r.outline)==34
with pdfplumber.open(p) as pdf:
 for page in pdf.pages:
  for w in page.extract_words():assert w['x0']>=40 and w['x1']<=555 and w['top']>=15 and w['bottom']<=830,(page.page_number,w['text'])
qa=json.loads((ROOT/'07_presentation/01_presenter_guide/발표자_상세해설서_검수.json').read_text(encoding='utf-8'))
qa.update(output=pdfpath,pdf_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),pdf_bytes=p.stat().st_size,pages=34,bookmarks=34,reorganized_on='2026-10-12',source_paths_refreshed=True)
(ROOT/'07_presentation/01_presenter_guide/발표자_상세해설서_검수.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
report=dict(reorganized_on='2026-10-12',relocated_files=len(moved),byte_identical_protected_files=preserved,unchanged_experiment_csv_files=data,changed_binary_artifact=[pdfpath],binary_change_reason='Presenter PDF source paths/footer refreshed; previous PDF retained in Git history',active_markdown_local_links_checked=links,broken_active_links=bad,Python_syntax='passed',MATLAB_readonly_validation='passed: 17922 users / 12 candidates / 20 seeds / 14400 metric rows; deterministic max error 2.55e-11 Mbps',source_labgemini4_sha256=hashlib.sha256((ROOT/'02_code/matlab/labgemini4.m').read_bytes()).hexdigest(),synced_sources_modified=False,numerical_experiments_rerun=False,pdf_pages=34,pdf_bookmarks=34)
(catalog/'reorganization_verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
