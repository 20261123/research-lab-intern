import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const runtime = 'C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies';
process.env.RUNTIME_NODE_MODULES = path.join(runtime,'node/node_modules');
const skill = 'C:/Users/user/.codex/plugins/cache/openai-primary-runtime/presentations/26.1004.11800/skills/presentations';
const {Presentation,PresentationFile,FileBlob} = await import(pathToFileURL(path.join(runtime,'node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs')));
const {finalizePresentation,applyPresentationChartFont} = await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')));
const root = path.resolve('campus_project');
const build = path.join(root,'.build/slides');
const resultsRoot = path.join(root,'results');
const runs = (await fs.readdir(resultsRoot)).filter(x=>x.startsWith('demo_')).sort();
const run = process.argv[2] ? path.resolve(process.argv[2]) : path.join(resultsRoot,runs.at(-1));
function parseCSV(text){
 const rows = text.trim().split(/\r?\n/).map(x=>x.split(','));
 const h=rows.shift(); return rows.map(r=>Object.fromEntries(h.map((k,i)=>[k,r[i]])));
}
const summary = parseCSV(await fs.readFile(path.join(run,'summary.csv'),'utf8'));
const curves = parseCSV(await fs.readFile(path.join(run,'cdf_curves.csv'),'utf8'));
const ranking = parseCSV(await fs.readFile(path.join(run,'candidate_ranking.csv'),'utf8'));
const selected = parseCSV(await fs.readFile(path.join(run,'selected_sites.csv'),'utf8'));
const changes = parseCSV(await fs.readFile(path.join(run,'spatial_changes.csv'),'utf8'));
const get = (condition,group='all')=>summary.find(r=>r.phase==='validation'&&r.condition===condition&&r.group===group);
const fmt = v=>Number(v).toFixed(2);
const a=get('base28wide'),b=get('add28wide');
const gain = 100*(Number(b.p05_mbps)/Number(a.p05_mbps)-1);
const family='Malgun Gothic';
const p=Presentation.create({slideSize:{width:1280,height:720}});
const ink='#142D42', muted='#566878', blue='#126CA8', orange='#C25924';
const sourceNotes='자료: 사용자 제공 프로젝트 안내 PDF, 38901-j40.docx TR 38.901 V19.4.0, Campus_3GPP_main_v0.0.m. 계산: 이 패키지의 demo 모드와 validation 난수. 실제 세종대 성능이 아님.';
function text(s,txt,x,y,w,h,size=29,color=ink,bold=false){
 const sh=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 sh.text=txt; sh.text.style={typeface:family,fontSize:size,color,bold,autoFit:'none'}; return sh;
}
function slide(title,n){
 const s=p.slides.add(); s.background.fill='#FFFFFF';
 text(s,title,64,44,1152,80,44,ink,true);
 text(s,'검증 예제 · 순천향대 원본 영역 사용 · 세종대 실제 좌표 조사 전',64,666,1050,34,20,muted);
 text(s,String(n).padStart(2,'0'),1160,666,56,34,20,muted);
 s.speakerNotes.textFrame.setText(sourceNotes); return s;
}
function table(s,values,x,y,w,h,widths){
 const t=s.tables.add({rows:values.length,columns:values[0].length,left:x,top:y,width:w,height:h,values,columnWidths:widths});
 t.borders.assign({style:'solid',fill:'#D4DEE5',width:1});
 for(let r=0;r<values.length;r++) for(let c=0;c<values[0].length;c++){
  const cell=t.getCell(r,c); cell.fill=r===0?ink:(r%2?'#F0F5F8':'#FFFFFF');
  cell.text.style={typeface:family,fontSize:24,color:r===0?'#FFFFFF':ink,bold:r===0};
 }
 return t;
}
async function image(s,name,x,y,w,h){
 s.images.add({blob:new Uint8Array(await fs.readFile(path.join(run,'figures',name))),contentType:'image/png',alt:name,fit:'contain',position:{left:x,top:y,width:w,height:h}});
}
function cdf(s,conditions,group,x,y,w,h){
 const colors=[blue,orange,'#209B7E','#955DA9'];
 const labels={base35:'3.5 GHz / 100 MHz',base28wide:'28 GHz / 800 MHz',add35:'3.5 GHz 추가 후',add28wide:'28 GHz 추가 후'};
 const chart=s.charts.add('scatter',{
  position:{left:x,top:y,width:w,height:h},scatterOptions:{style:'line'},
  title:'전체 사용자 용량 CDF',titleTextStyle:{typeface:family,fontSize:26,fill:ink},
  series:conditions.map((c,i)=>{const rows=curves.filter(r=>r.condition===c&&r.group===group);return {name:labels[c],xValues:rows.map(r=>+r.capacity_mbps),values:rows.map(r=>+r.probability),line:{fill:colors[i],width:2.5},marker:{symbol:'none'}};}),
  hasLegend:true,legend:{position:'bottom',textStyle:{typeface:family,fontSize:20,fill:ink}},
  xAxis:{title:{text:'Shannon capacity (Mbps)',textStyle:{typeface:family,fontSize:22}},numberFormatCode:'0',min:0,textStyle:{typeface:family,fontSize:18,fill:muted},majorGridlines:{fill:'#E3EAF0',width:1}},
  yAxis:{title:{text:'F(c) = P(C ≤ c)',textStyle:{typeface:family,fontSize:22}},numberFormatCode:'0.0',min:0,max:1,majorUnit:0.2,textStyle:{typeface:family,fontSize:18,fill:muted},majorGridlines:{fill:'#E3EAF0',width:1}},
  chartFill:'#FFFFFF',plotAreaFill:'#FFFFFF',dataLabels:{showValue:false}
 });
 applyPresentationChartFont(chart,{fontFamily:family}); return chart;
}

let s=slide('캠퍼스 통신 시뮬레이션',1);
text(s,'3.5 GHz와 28 GHz 비교\n추가 기지국 두 곳의 선택',64,190,1100,170,56,ink,true);
text(s,'4인 조 실행 패키지와 계산 검증 예제',64,405,1100,60,32,blue);
text(s,'수정 코드 · 좌표 조사 양식 · 후보 탐색 · 발표 구성\n세종대 실험 결과는 실제 좌표 입력 후 생성',64,500,1100,110,28,muted);
s.speakerNotes.textFrame.setText(sourceNotes+'\n발표 첫 문장: 현재는 코드를 검증한 예제입니다. 실제 세종대 지도와 동일 사업자 4G 좌표는 다음 조사 작업입니다.');

s=slide('캠퍼스 조사와 팀 역할',2);
table(s,[['담당','책임','인계 자료'],['A MATLAB 경험자','코드 구현과 통합','수정 코드와 실행 조건'],['B 지도 담당','세종대 건물·기지국·후보 조사','좌표 CSV와 출처'],['C 분석 담당','수치 검증과 결과 비교','통계표와 그래프'],['D 조장','가정 확정과 발표 통합','위치 선정 근거와 PPT']],64,155,1152,330,[280,465,407]);
text(s,'지도와 기지국 출처',64,522,1100,42,28,ink,true);
text(s,'세종대 공식 캠퍼스맵과 전파누리 4G 무선국 목록\n동일 사업자를 확인하고 원점·축척·조사 날짜를 기록',64,574,1120,78,27,muted);
s.speakerNotes.textFrame.setText(sourceNotes+'\n공식 지도: https://www.sejong.ac.kr/kor/intro/campus-map.do?type=BUILDING\n전파누리: https://spectrummap.kr/gis/mobile_service.do?menuNo=300480\n전파누리 목록 접근은 확인했으나 내보내기와 동일 사업자 좌표 확정은 미완료.');

s=slide('모델과 공정한 비교 조건',3);
table(s,[['항목','공통 조건'],['채널과 높이','UMa, 기지국 25 m / 단말 1.5 m'],['송신과 잡음','43 dBm / 섹터, NF 7 dB'],['안테나와 실내','3섹터 수평 소자 패턴, low-loss O2I'],['표본과 난수','2.5 m 격자, 20회 시행, 조건별 공통 난수'],['비교 조건','3.5/100, 28/100, 28/800 (GHz/MHz)']],64,150,1152,366,[320,832]);
text(s,'SINR = S / (I + N)     C = B log₂(1 + SINR)',64,550,1140,60,34,blue,true);
text(s,'CDF는 위치×시행 전체 표본, 지도는 위치별 시행 중앙값',64,612,1140,42,25,muted);

s=slide('수식과 단위 오류 수정',4);
table(s,[['원본 문제','수정과 확인'],['잡음 −174×1000','−174 + 10log₁₀(BHz) + NF, 총전력 통일'],['GHz 항에 Hz 대입','경로손실 GHz / breakpoint Hz 분리'],['실내 손실 괄호·적용','재료 항을 로그 안에 합산, 외부 간섭에도 적용'],['중복 표본·하위 5%','좌표 중복 제거, 5백분위와 하위 5% 평균 구분'],['지도 색과 섹터 각도','실제 SINR dB 범례, 각도 ±180°로 정리']],64,155,1152,370,[340,812]);
text(s,'수치 검증: −87 dBm / −77.97 dBm, SINR=1이면 100 Mbps',64,558,1140,80,28,blue,true);
s.speakerNotes.textFrame.setText(sourceNotes+'\n원본 외부 간섭 합산은 이미 선형 전력이었습니다. 오류는 실내 외부 링크의 O2I 누락입니다. 5백분위와 하위 5% 평균은 서로 다른 값입니다.');

s=slide('동일 대역폭에서 주파수 비교',5);
await image(s,'validation_frequency_heatmap.png',40,143,1200,448);
const low=get('base35'),high=get('base28same');
text(s,`전체 SINR 중앙값   3.5 GHz ${fmt(low.median_sinr_db)} dB   /   28 GHz ${fmt(high.median_sinr_db)} dB`,64,601,1152,48,27,blue,true);
s.speakerNotes.textFrame.setText(sourceNotes+'\n두 조건 모두 100 MHz입니다. 양쪽 색 범위를 -20~30 dB로 통일했습니다. 검은 윤곽은 건물, 빨간 삼각형은 기존 서비스 사이트입니다.');

s=slide('대역폭 비교와 Capacity CDF',6);
cdf(s,['base35','base28wide'],'all',58,150,720,455);
table(s,[['Mbps','3.5 GHz','28 GHz'],['5백분위',fmt(get('base35').p05_mbps),fmt(a.p05_mbps)],['중앙값',fmt(get('base35').median_mbps),fmt(a.median_mbps)],['실내\n5백분위',fmt(get('base35','indoor').p05_mbps),fmt(get('base28wide','indoor').p05_mbps)]],802,200,414,255,[154,130,130]);
text(s,'100 MHz 대 800 MHz\n총 잡음전력 +9.03 dB',810,500,398,94,27,blue,true);
text(s,'아래 5%와 중앙값을 함께 비교',64,616,1120,36,25,muted);
s.speakerNotes.textFrame.setText(sourceNotes+'\n표는 전체 표본으로 계산한 값입니다. 편집 가능한 CDF 차트는 약 1001개 점을 추려 표시한 근사 곡선이며 원시 경험적 CDF는 결과 PNG와 MAT에 있습니다.');

s=slide('추가 기지국 두 곳의 후보 비교',7);
table(s,[['후보 조합','5백분위 Mbps','중앙값 Mbps'],...ranking.slice(0,5).map(r=>[`${r.candidate1} + ${r.candidate2}`,fmt(r.p05_mbps),fmt(r.median_mbps)])],64,158,1152,325,[430,361,361]);
text(s,`선정 좌표   ${selected.map(r=>`${r.id} (${r.x_m}, ${r.y_m}) m`).join('   /   ')}`,64,520,1152,58,29,blue,true);
text(s,'28개 조합 중 전체 5백분위 최대, 동률은 중앙값·평균 순\n예제 후보는 약한 실외 지점에서 자동 생성, 실제 후보는 지도 검토 필요',64,588,1152,66,25,muted);
s.speakerNotes.textFrame.setText(sourceNotes+'\n후보 순위는 selection 난수 결과입니다. 실제 배치는 후보 8곳의 설치 가정을 먼저 검토해야 합니다. 전역 최적 위치라는 주장을 하지 않습니다.');

s=slide('별도 난수로 추가 전후 검증',8);
await image(s,'validation_placement_heatmap.png',40,141,1200,365);
const spatial=changes.find(r=>r.phase==='validation'&&r.fc_ghz==='28');
table(s,[['28 GHz / 800 MHz','추가 전','추가 후'],['5백분위 Mbps',fmt(a.p05_mbps),fmt(b.p05_mbps)],['중앙값 Mbps',fmt(a.median_mbps),fmt(b.median_mbps)]],64,518,730,126,[300,215,215]);
text(s,`5백분위 변화 ${gain>=0?'+':''}${gain.toFixed(1)}%\nSINR 악화 위치 ${fmt(spatial.positions_worse_pct)}%`,830,543,386,100,27,blue,true);
s.speakerNotes.textFrame.setText(sourceNotes+'\n탐색 seed 38901, 검증 seed 738901. 새 난수에서도 개선되는지 확인합니다. 3.5 GHz 추가 전후와 실내/실외 CDF는 결과 폴더에서 함께 확인합니다.');

s=slide('결론과 다음 작업',9);
text(s,'구현과 검증을 마친 내용',64,164,1136,52,34,ink,true);
text(s,'수식·단위 수정과 재현 가능한 세 조건 비교\n후보 28쌍 탐색과 독립 난수 검증',64,236,1136,108,32,blue);
text(s,'조에서 다음으로 할 일',64,390,1136,52,34,ink,true);
text(s,'세종대 건물과 동일 사업자 4G 위치 조사\n후보 8곳 검토 후 재실행하고 실제 결과로 발표 교체',64,462,1136,106,32,ink);
text(s,'모델 한계: 독립 shadow fading, 수평 안테나, 지형·스케줄링 생략\n용량은 단일 스트림 Shannon 전송률이며 실제 다운로드 속도와 구분',64,591,1136,64,24,muted);

await fs.mkdir(build,{recursive:true});
const candidate=path.join(build,'candidate.pptx');
await (await PresentationFile.exportPptx(p)).save(candidate);
const finalPath=path.join(root,'deliverables','캠퍼스통신_발표초안_예제_v3.pptx');
const finalized=await finalizePresentation({
 workspaceDir:root,candidatePath:candidate,finalPath,
 pythonExecutable:path.join(runtime,'python/python.exe'),
 integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
 layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit',
 ...[2,3,4,6,7,8].flatMap(n=>['--require-native-table-slide',String(n)])],
 explicitTotalSlideCount:9,requiredNativeTableOwnerSlides:[2,3,4,6,7,8],requiredNativeChartOwnerSlides:[6],
 fontPolicy:{basis:'design',families:[family]},verifyArtifactToolImport:true,
 materializeLiteralChartWorkbooks:true,
 receiptPath:path.join(build,'validation_v3.json')
});
console.log(JSON.stringify(finalized));
const finalDeck=await PresentationFile.importPptx(await FileBlob.load(finalPath));
for(let i=0;i<finalDeck.slides.items.length;i++){
 const blob=await finalDeck.export({slide:finalDeck.slides.items[i],format:'png',scale:1});
 await fs.writeFile(path.join(build,`slide-${i+1}.png`),new Uint8Array(await blob.arrayBuffer()));
}
console.log('Rendered nine slides.');
