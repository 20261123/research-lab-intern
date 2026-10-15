"""Replace only PDF physical page 13 and deliver a page-by-page review."""
from pathlib import Path
from io import BytesIO
import csv,json,hashlib,shutil,html
from pypdf import PdfReader,PdfWriter
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.colors import HexColor,white
from reportlab.platypus import SimpleDocTemplate,Paragraph,Table,TableStyle,Spacer,PageBreak
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'07_presentation/02_team_deck_2026-10-14';OUT.mkdir(parents=True,exist_ok=True)
SRC=Path('C:/Users/user/Desktop/2026-2/연구실인턴 10_14 (1)-1.pdf')
ORIGINAL=OUT/'original/연구실인턴_10_14_원본.pdf';ORIGINAL.parent.mkdir(exist_ok=True)
shutil.copyfile(SRC,ORIGINAL)
pdfmetrics.registerFont(TTFont('MG','C:/Windows/Fonts/malgun.ttf'));pdfmetrics.registerFont(TTFont('MGB','C:/Windows/Fonts/malgunbd.ttf'))
pdfmetrics.registerFontFamily('MG',normal='MG',bold='MGB',italic='MG',boldItalic='MGB')
NAVY=HexColor('#24364E');GREEN=HexColor('#80958D');BG=HexColor('#F8F7F5');GRAY=HexColor('#526476');PALE=HexColor('#EEF2F5')
def read(rel):
 with (ROOT/rel).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
cross=read('04_site_selection/02_candidate_evaluation/factorial_3x3.csv')
# Direct, selectable vector typography and fraction rules, no upscaled screenshot.
b=BytesIO();c=canvas.Canvas(b,pagesize=(1440,810))
def txt(x,y,s,size=20,font='MG',color=NAVY):
 c.setFillColor(color);c.setFont(font,size);c.drawString(x,y,s)
def box(x,y,w,h,color):c.setFillColor(color);c.roundRect(x,y,w,h,8,stroke=0,fill=1)
def m(x,y,s,size=32):txt(x,y,s,size,'Times-Roman')
def cs(x,y,sub,size=26):
 txt(x,y,'C',size,'Times-Italic');m(x+size*.67,y-6,sub,size*.58)
def q(x,y,sub,region=False):
 txt(x,y,'Q',26,'Times-Italic');m(x+20,y-6,'0.05',15);m(x+52,y,'(',26)
 cs(x+64,y,sub)
 if region:
  m(x+103,y,'|',26);txt(x+120,y,'R',26,'Times-Italic');m(x+138,y-6,'k',15);m(x+151,y,')',26)
 else:m(x+101,y,')',26)
c.setFillColor(BG);c.rect(0,0,1440,810,stroke=0,fill=1)
c.setFillColor(GREEN);c.rect(54,726,6,45,stroke=0,fill=1)
txt(75,735,'설치 후보와 평가함수 비교',38,'MGB');txt(1350,740,'13',16)
c.setStrokeColor(GREEN);c.line(55,711,1385,711)
txt(55,672,'취약 사용자 위치와 설치 후보는 구분하고, 같은 기준으로 선택 결과를 비교했습니다.',22)
box(54,564,1330,83,HexColor('#E9EFEC'))
txt(70,616,'기하적 후보 가정',21,'MGB')
txt(70,585,'취약점 75 m 이내 · 경계 안쪽 10 m · 건물 밖 5 m · 기존/후보 사이트와 25 m 이상 이격',19)
txt(945,616,'신규 높이 25 m / 3섹터',18)
txt(945,588,'실제 설치 가능성은 미확인',18)
txt(55,530,'세 시나리오의 목적함수 - 모두 최대화',22,'MGB')
for y in [415,300,185]:box(54,y,660,100,white)
txt(70,488,'S1 · 4개 후보 / 6조합 · 전체 저성능 사용자 우선',18,'MGB')
m(78,445,'F',32);m(97,438,'1',18);m(110,445,'(p) =',32);q(203,445,'p')
txt(438,446,'전체 전송률 5백분위',18)
txt(70,373,'S2 · 8개 후보 / 28조합 · 상대적 개선의 균형',18,'MGB')
m(78,329,'F',32);m(97,322,'2',18);m(110,329,'(p) =',32)
m(213,346,'1',22);m(207,314,'N',22);c.setStrokeColor(NAVY);c.line(201,337,237,337)
c.setStrokeColor(NAVY);c.setLineWidth(2.3)
summation=c.beginPath();summation.moveTo(279,351);summation.lineTo(251,351);summation.lineTo(267,335);summation.lineTo(251,319);summation.lineTo(279,319);c.drawPath(summation,stroke=1,fill=0)
m(263,359,'N',13);m(246,304,'i = 1',13)
m(302,329,'ln',31);m(344,329,'(',37);cs(367,347,'p,i',24);cs(367,315,'0,i',24);c.line(358,337,436,337);m(442,329,')',37)
txt(505,332,'전송률 비율의',16);txt(505,310,'로그 평균',16)
txt(70,258,'S3 · 12개 후보 / 66조합 · 취약 구간의 최소 개선 비율',18,'MGB')
m(78,214,'F',32);m(97,207,'3',18);m(110,214,'(p) =',32);m(204,214,'min',29);m(193,192,'k = 1,...,4',13)
m(280,214,'[',38);q(310,230,'p',True);q(310,198,'0',True);c.line(303,221,500,221);m(509,214,']',38)

txt(752,530,'선택된 배치의 동일 비교 표본 P5 (Mbps)',21,'MGB')
xs=[750,864,1037,1210,1384];ys=[507,458,409,360,311]
headers=['후보 수','F1로 선택','F2로 선택','F3로 선택']
for row in range(4):
 for col in range(4):
  c.setFillColor(NAVY if row==0 else (white if row%2 else PALE));c.rect(xs[col],ys[row+1],xs[col+1]-xs[col],49,stroke=0,fill=1)
  if row==0:v=headers[col]
  elif col==0:v=str([4,8,12][row-1])
  else:v=f"{float(next(r for r in cross if int(r['n_candidates'])==[4,8,12][row-1] and int(r['objective_number'])==col)['held_p5_Mbps']):.2f}"
  txt(xs[col]+15,ys[row+1]+17,v,20,'MGB' if row==0 else 'MG',white if row==0 else NAVY)
txt(752,283,'표는 F1·F2·F3 점수 자체를 비교한 것이 아닙니다.',17)
txt(752,251,'8곳+F1과 12곳+F1은 같은 두 위치를 선택했습니다.',17)
box(750,185,634,49,HexColor('#E9EFEC'));txt(765,201,'권장: 같은 성능을 더 적은 후보로 얻는 8곳 + F1',19,'MGB')
box(54,52,1330,112,HexColor('#EAEFF3'))
txt(70,137,'기호와 표본',18,'MGB')
txt(70,110,'p: 추가 두 사이트 조합  |  C_p: 추가 후 전송률  |  C_0: 추가 전 전송률  |  Q_0.05: nearest-rank 5백분위',17)
txt(70,83,'목적함수는 탐색 8,960개 위치에서 계산. 오른쪽 표는 별도 비교 8,962개 위치의 전체 P5.',17)
txt(70,59,'N: 탐색 위치 수  |  R_k: 기존 취약 대표점 반경 25 m의 고정 구간  |  검토한 후보·목적함수 내 선택이며 전역 최적은 아님',15)
c.showPage();c.save();b.seek(0)
replacement=PdfReader(b).pages[0];source=PdfReader(ORIGINAL);writer=PdfWriter()
for i,page in enumerate(source.pages):writer.add_page(replacement if i==12 else page)
writer.add_metadata({'/Title':'연구실인턴 발표자료 - 13쪽 수식 가독성 수정','/Subject':'Only physical PDF page 13 replaced; all other pages retained.','/Creator':'2026-10-15 presentation review'})
CORRECTED=OUT/'연구실인턴_10_14_13쪽수정본.pdf'
with CORRECTED.open('wb') as f:writer.write(f)

findings=[]
def issue(pages,priority,title,observation,fix,basis='PDF 시각 검토 및 기존 코드/결과 대조'):
 findings.append(dict(id=f'R{len(findings)+1:02d}',pages=pages,priority=priority,title=title,observation=observation,recommendation=fix,basis=basis))
issue('5','필수','위도 환산 계수가 설명보다 10배 작음','본문은 위도 1도≈111 km라 쓰지만 Y식은 ×11000. 111 km는 111000 m이며 110000을 근사로 쓸 수는 있어도 11000은 맞지 않음.','Y≈(위도-원점위도)×111000으로 식을 바로잡기. 다만 기존 y좌표를 일괄 10배 하지 말 것. 계산에 실제 사용한 원점·십진도·변환 절차를 확인해 설명 오타인지 입력 오류인지 구분. 입력이 틀렸다면 전체 결과 재계산 필요.')
issue('4~5','필수 확인','좌표를 실측·확정값으로 읽히게 하는 설명','대양홀 서쪽 남단 원점 및 실제 경위도 변환을 주장하지만 원점 경위도, 사이트 원시 위경도·출처·사업자 근거가 없음. 기존 조사 기록도 사업자/좌표를 미확정으로 구분.','확인 전에는 제공된 m좌표 기반 캠퍼스 근사 모델로 명시. 확인 가능한 원점 WGS84 위경도, 동/북 축, 단위·출처·날짜를 추가. 건물의 지도 거리 측정과 사이트 경위도 변환, 잠정 경계 affine 추정을 분리.')
issue('7~9','필수','기지국 추가 전/후 조건이 흐름상 섞임','그래프 상단이 11 service + 6 external이며 표의 177.29/147.68/797.61, P5 65.02/32.91/51.40도 추가 후 11개 결과. 그러나 위치 선정은 뒤에서 설명됨.','현재 그림을 유지하면 모든 제목에 추가 후 11개 서비스·6개 외부·고정 채널이라고 표시하고 최종 배치 결과를 먼저 비교한다고 안내. 선정 전 비교를 의도했다면 동일 경계의 기존 9개 결과로 그림/표 모두 교체. 과거 26741 사각 표본은 사용하지 않기.')
issue('9','필수','간섭 모델인데 용량식이 S/N으로 표시됨','계산은 SINR=S/(I+N)인데 슬라이드는 C=B log2(1+S/N), SINR(S/N)으로 표기.','C=B log2(1+S/(I+N))로 수정. S/N은 SNR이며 I≈0일 때만 근사. C[bit/s], B[Hz], S/I/N 동일 선형 전력 단위, Mbps 표시 시 10^6으로 나눔을 명시.')
issue('9','필수','대역폭 8배면 전송률도 비례한다는 설명','현재 모델은 총 출력 고정이고 N이 B에 비례해 SINR도 바뀜.','같은 SINR을 가정할 때만 C가 B에 비례. 현재 28 GHz에서 100→800 MHz: 잡음 +9.03 dB, 중앙값 147.68→797.61 Mbps(5.40배), P5 32.91→51.40 Mbps(+56.2%)라고 수정. 저 SINR·잡음 지배에서는 C≈S/(n0 ln2)로 증가가 제한됨.')
issue('10','필수','전력 증대로 해결 불가·실내 기지국 필수라는 단정','전력을 늘리면 잡음 지배 위치의 SINR은 개선될 수 있음. 또한 실제 추가한 모델은 실내 소형셀이 아니라 건물 밖 높이 25 m 3섹터임.','전력 조정만으로 모든 취약 구간 개선을 보장하기 어렵고, 배치·안테나·실내 보완·대체 대역을 비교할 필요가 있다고 완화. 이번에 시험한 대응과 미시험 대안을 구분.')
issue('10','보완','SIR·잡음 단위 및 적용 범위','모든 S와 I가 똑같이 감쇠한다는 설명은 현재 수신점 공통 O2I의 단순화에 해당. N=-174+10logB+NF는 dBm인데 SINR 분모 N은 선형 전력.','현재 공통 O2I 모델에서는 SIR이 유지될 수 있다고 조건부 표현. N_dBm=-174+10log10(B_Hz)+NF_dB, N_mW=10^(N_dBm/10)로 분리. N은 B와 NF가 정해지면 고정이며 대역폭을 바꾸면 달라짐.')
issue('9~10','보완','SINR이 0에 수렴한다는 표현이 모호함','선형 SINR=0은 극저성능이지만 0 dB는 선형 1이며 같은 뜻이 아님. 모든 실내 링크가 S,I<<N 또는 0 Mbps인 것도 아님.','선형 SINR이 매우 작아지는 잡음 지배 위치에서 용량 이득이 제한된다고 표현. 0 Mbps 주장은 실제 최소값/정의 확인 전 사용하지 않기. 단위와 실제 실내 P5를 제시.')
issue('4·7 이후','필수 보완','공통 시뮬레이션 조건표가 없음','서비스 수·실내/실외·17922·높이·출력·부하·안테나·모델 정의가 여러 그림에 흩어져 있음.','17,922(실내4,601/실외13,321), 격자2.5m, BS/UT25/1.5m, 섹터43dBm, NF7dB, 3섹터, load0.5, low-loss O2I, 고정 NLOS 형태 식을 한 조건표로 추가. 7개는 건물 모델 영역이며 율곡·충무는 통합.')
issue('6','보완','43 dBm의 상용망 단정과 모델 범위','43 dBm≈19.95 W는 맞지만 모든 상용 5G 섹터의 보편 값이라고 할 근거는 없음. -24는 전력밀도이므로 단순 수치 교체와 다름.','섹터당 총전력 43 dBm(약20 W)을 비교 가정으로 통일이라고 수정. Pt_dBm/MHz/Hz 혼합 금지. 경로손실 주파수 항은 GHz, 일반 breakpoint에는 Hz이나 현재 구현은 breakpoint 없는 NLOS 식이라고 구분.')
issue('6','보완','수정 이력과 표 가독성','O2I 괄호와 잡음식은 코드와 맞지만 표를 이미지로 넣어 코드가 작음. 실제 lab4의 상대각·RGB·중복·격자/P5 수정은 빠져 있음.','표를 2장 또는 핵심 4항목 텍스트로 재작성. 나머지는 부록에 정리. 잡음 100MHz -87 / 800MHz -77.97 dBm과 상대각 정규화·중복 외부 제거·실제 SINR 색상·nearest-rank P5를 설명. 기존 외부 간섭 선형 합산이 없었다고 주장하지 않기.')
issue('11','보완','기존 서비스와 설치 후보 용어 혼동','캠퍼스 내 기지국 9개(28/800) 후보군에서라고 쓰여 기존 9개가 설치 후보로 읽힘.','기존 서비스 사이트 9개를 유지한 28/800 환경에서 취약 사용자 구간을 찾고, 주변의 별도 설치 후보를 도출했다고 수정.')
issue('11~14','보완','취약 대표점 수·근접 기준·경계 오차의 범위','75m 등은 프로젝트 선택이며 W1은 추정 경계까지2.18m. 지도 개념도와 계산 경계, 기준점 최대 적합 오차29.21m가 구분되지 않으면 실측으로 오해.','4곳은 현재 규칙의 결과(근접 기준50/75/100m이면5/4/3곳)라고 명시. 잠정24꼭짓점·6기준점 affine·RMS16.65m·최대적합29.21m를 보조자료에, W1/후보10의 위치 불확실성을 본문 짧게 추가. 적합 오차를 신뢰구간으로 부르지 않기.')
issue('13','이번 수정','하단 수식과 표가 작고 행이 붙어 있음','수식은 텍스트 이미지로 축소되어 Q0.05, Σ, min의 인덱스·분수가 흐릿하고 S3의12/66이 왼쪽에 붙음.','13쪽을 벡터 수식·분수와 넓은 카드로 재작성. C_p/C_0/N/R_k와 탐색8,960/비교8,962를 정의. 목적함수는 최대화한다고 표시. 이번 수정본에 반영.')
issue('13','이번 수정','교차표가 함수 점수로 읽히는 문제','F2/F3 열도 44.56/48.57처럼 Mbps 결과인데 단위·비교표본 명시가 없어 로그 점수나 배율로 오해 가능.','표 제목을 선택된 배치의 동일 비교 표본 전체 P5(Mbps)로 변경. 세 함수 자체 점수를 비교하지 않는다고 명시. 8곳+F1과12곳+F1은 동일 조합·동일 성능이므로 적은 후보를 권장한다고 한정. 이번 수정본 반영.')
issue('13~14','이번 수정/보완','실제로 설치 가능한 지점이라는 과장','기하적 이격만 검토했고 토지·높이·전원·접근·허가를 확인하지 않음. 실내에는 안테나를 넣을 수 없다는 일반화도 부정확(실내 설비는 가능).','현재 25m 옥외 사이트 가정에서는 실내 사용자점 대신 건물 밖 기하적 후보를 둔다고 표현. 실제 설치 가능성 미확인으로 명시. 13쪽 반영,14쪽 개념도는 위치예시 주석 유지.')
issue('13','보완','후보 4/8/12와 두 표본의 관계 설명 부족','왜 해당 후보 개수인지, 후보2개/구간의 생성 순서, 훈련/비교 구분이 없음.','구간별 C1/C2/C3 대안을 만들어4/8/12 중첩 집합 구성, 8C2=28은 팀 설계라고 설명. 탐색8,960/비교8,962는 가까운 격자 분리로 독립 통계검증 아님. 표51.32와 전체51.40의 표본 차이를 명시.')
issue('15','보완','구간별 P5와 단일 대표점 전송률의 구분','12쪽의 대표점 값과15쪽 반경25m 구간P5는 다른 통계. W1은 반올림값1.51이 같아 혼동할 수 있음.','표를 28/800·고정 모델·경계 내부 반경25m 구간의 P5로 표기. W2의1.7배는 최저 지역 개선으로 남음을 설명. 인접 효과로 폭등보다는 공동 배치와 서빙 재선택·간섭 반영 결과로 개선이라고 표현.')
issue('15','필수 보완','추가 전후의 그림과 악화 정보가 빠짐','전후 P5와 개선율은 기존 CSV와 일치하지만 표만 있으며, 일부 위치의 추가 간섭 악화가 없음. 마지막 핵심 의미 셀도 빈칸.','같은 경계/색 범위 전후 Heatmap과 CDF를 추가. 고정28/800에서 소폭 포함79.20% 감소, 악화자의 감소율 중앙값0.68%, 전체 중10%초과 감소5.08%를 함께 설명. 마지막 셀은 저성능 경계 개선 또는 삭제.')
issue('16','필수 보완','무엇을 난수화했는지 설명 없음','20회는 단순 반복이 아니라 SF6dB의 사이트별 공간 필드. 기존 PDF의 고정 결과와 숫자가 달라지는 이유를 설명하지 않음.','고정 NLOS+SF표준편차6dB, 공간상관50m 분리형 근사, 같은 시행은 대역/배치/장애에 공통 필드, 시행끼리 독립 시드, O2I고정·LOS/빠른페이딩 미반영을 짧게 추가. 독립 단위20, 위치17922는 공간상관 존재.')
issue('16','보완','범례·축·평균 통계의 의미','baseline9/normal11/off_01_11 범례가 설명되지 않고 시간곡선으로 보임. 표의95%구간 제목은 어떤 평균인지 불명확하며 단위도 생략.','범례를 기존9개/정상11개/1·11번중단으로 번역. x축 독립 시행번호(시간 아님), y축 시행별전체P5(Mbps). 표는 시행별P5의20회평균 및 그 평균의95% Monte Carlo구간으로 표기.')
issue('17','필수 정밀화','운용 조건 간 우열 미확정을 너무 넓게 서술','0을 포함하는 구간은 28/800 - 3.5/100의 P5 평균차. 세 조건의 모든 비교가 불확실한 것은 아님.','해당 두 운용조건의 P5차만 우열 미확정이라고 한정. 28/100 - 3.5/100은-25.33[-28.47,-22.18], 28/800 - 28/100은+28.91[22.83,34.99] Mbps. 유의하지 않음은 동등함의 증명이 아님.')
issue('17','보완','신뢰구간의 정의를 한 문장 보충','현재 표와 개선 구간/지도오차 불포함 설명은 대체로 정확함. 다만20개 시행별P5의 평균, paired 차이, t근사라는 정의가 없음.','각 시행P5를 먼저 구하고 평균±t19×s/√20을 사용. 개선은 동일 시행의11개P5-9개P5 차이로 계산. 사용자95%범위·현장성능보장과 구분.')
issue('18~19','필수','장애 분석 결론에 대응하는 부록이 빈 페이지','18쪽은 장애 시나리오 분석을 했다고 쓰지만19쪽은 제목만 있고 결과/조건이 없음.','19쪽에 단일11패턴·이중55패턴, 전체사이트3섹터중단, 즉시재접속 가정, 28/800 정상58.15/11중단25.69/1+11중단15.98/11우선복구54.43 Mbps(시행별P5평균)를 넣기. 비어 두려면18쪽 장애 결론과 부록 제목을 삭제.')
issue('19','필수 보완','사이트 중단·재접속·실제 끊김을 구분해야 함','모델에는 장애와 정상상태 재접속만 있고 실제 장애 확률·중단 시간·복구 지연이 없음.','실제 끊김 시간은 계산하지 않았다고 명시. 10Mbps미만은 프로젝트QoS 기준, 실제 무선단절 판정 아님. 재접속 필요 비율과 재접속 후 저전송률을 구분. 대역선택60.88은 지연/부하 재분배 제외 이상적 조건임을 표시.')
issue('전체','보완','페이지 번호·서식·출처·모델 한계','우상단 번호03/04/05/06/07이 순서와 다르게 반복됨. 일부 페이지는 제목/번호가 없고 표·그림 출처 및 주요 가정이 생략. PDF는19쪽 모두 이미지 기반이라 검색/편집과 확대 가독성에 한계.','PDF 물리페이지1~19와 발표쪽수를 통일,6/9/13/15쪽의 작은 표/수식은 원본PPT의 텍스트·수식으로 작성 후PDF 직접 내보내기. 각 그래프의 고정/확률,9/11개,영역·표본·단위를 통일. 잠정경계·원본NLOS식·근거리495링크<10m·Shannon이론값·실제설치미검증을 마지막 한계/출처에 추가.')

# Text review is the editable master and includes replacement-ready wording.
intro='''# 발표자료 전체 검토 및 수정 제안 - 2026-10-15

대상: PDF 물리페이지 1~19. 우상단의 반복되는 05 등은 페이지 기준으로 사용하지 않았다.

## 이번에 실제 수정한 범위

원본은 보존했다. 수정 PDF는 **13쪽만 교체**했고 나머지18쪽은 원본 페이지를 그대로 보관한다. 13쪽 수식·분수·정의·비교표를 텍스트/벡터로 재작성하고, 설치 가능성 미확인·교차표의 단위/표본·후보 내 권장 범위를 명시했다. 나머지 제안은 자동 반영하지 않았으며 검토 후 원본 PPT에 반영할 내용이다. 입력 PDF는 전 페이지 이미지 기반이므로 원본 PPT의 개별 객체를 직접 수정한 것은 아니다.

## 우선 수정할 다섯 가지

1. 5쪽 위도 환산계수: 11000과111 km 설명이10배 불일치. 좌표 입력의 오류인지 설명 오타인지 먼저 확인.
2. 7~9쪽: 추가 후11개 결과를 추가 전 단계처럼 읽히지 않게 조건 표시.
3. 9~10쪽: C=B log2(1+S/(I+N)), 대역폭 증가 시 잡음 증가, 전력증대 불가/실내기지국 필수라는 단정 완화.
4. 16~17쪽: SF 모델과 시행별P5 평균/paired 구간, 대역간 비교 범위 명확화.
5. 19쪽: 빈 장애 부록을 실제 결과로 채우거나 관련 결론을 제거.

## 확인한 수치 중 일치하는 부분

- 9쪽 중앙값177.29/147.68/797.61 및P5 65.02/32.91/51.40은 고정 채널 **추가 후11개** 통계와 일치.
- 12쪽 대표점과13쪽 교차표,14쪽 추가좌표,15쪽 전후P5 및 개선율은 보관 자료와 일치.
- 16쪽20회P5평균·구간,17쪽paired 개선 및28/800-3.5/100 구간은 CSV와 일치.
- 수치가 일치한다고 실측 좌표·설치 가능성·완전한3GPP 모델·실제속도가 확인된 것은 아니다.

## 9개 조건으로 앞부분을 다시 구성할 경우의 기준값

같은 잠정 경계의17,922개 위치에서, 기존9개 사이트 기준(단위Mbps):

| 조건 | 중앙값 | P5 |
|---|---:|---:|
|3.5 GHz /100 MHz|151.88|40.83|
|28 GHz /100 MHz|126.38|7.54|
|28 GHz /800 MHz|652.11|8.82|

위 표를 선택하면7~9쪽 그림과 표 전체를 같은 기준으로 교체해야 한다. 현재11개 결과를 유지하고 배치완료 후비교라고 명시하는 방법도 가능하다. 두 방법을 섞지 않는다.
'''
md=[intro,'\n## 페이지별 검토 항목\n']
for v in findings:md.extend([f"### {v['id']} | {v['pages']}쪽 | {v['priority']} | {v['title']}",f"관찰: {v['observation']}",f"수정 제안: {v['recommendation']}",''])
md.extend(['## 발표문 교체 예시','',
'9쪽: “간섭을 포함한 Shannon 전송률은 C=B log2(1+S/(I+N))입니다. 총 출력이 같은 상태에서 대역폭을 넓히면 잡음도 증가하므로 전송률이8배로 늘지는 않습니다. 이번28GHz의 중앙값은 약5.40배 증가했습니다.”','',
'10쪽: “현재 공통O2I 모델에서는 신호와 간섭이 함께 감소해 SIR은 비슷할 수 있지만, 잡음은 벽 손실로 함께 감소하지 않습니다. 잡음 지배 위치에서는 SINR이 낮아져 넓은 대역폭의 용량 이득이 제한됩니다. 개선 대안은 배치·전력·안테나·대체 대역 등을 조건별로 평가해야 합니다.”','',
'13쪽: “네 취약 구간의 주변에서 설치 조건을 가정한 후보를 만들었습니다. 후보 수와 목적함수를 교차 비교한 뒤 공통비교표본의 전체P5로 평가했습니다. 8곳+F1과12곳+F1이 동일한 조합을 골라 후보가 적은8곳+F1을 권장했습니다.”','',
'16쪽: “고정NLOS 평균 식에6dB 섀도 페이딩과 공간상관 근사를 추가해 새 환경20개를 만들었습니다. 같은 시행에는 대역·배치·장애에 같은 필드를 사용했습니다. 표는 각 시행의P5를 구한 뒤20개를 평균한 값입니다.”','',
'19쪽: “기지국 한 사이트의3섹터가 모두 중단되는 단일11·이중55패턴을 계산했습니다. 즉시 재접속한 뒤의P5 평균은28/800에서 정상58.15,11번중단25.69,1+11번중단15.98Mbps였습니다. 이중 장애에서11번 먼저 복구하면54.43Mbps로 회복했습니다. 실제 끊김 시간은 모델링하지 않았습니다.”','',
'## 근거 경로','',
'- 05_comparison_results/03_added11_campus/summary.csv 및 run_metadata.json','- 04_site_selection/02_candidate_evaluation/factorial_3x3.csv, degradation_analysis.json','- 04_site_selection/01_weak_regions/analysis_summary.json 및 geometry_assumptions.json','- 06_resilience/20_trials_and_failures/summary20.csv, paired_band_comparisons.csv, paired_placement_validation.csv','- 02_code/matlab/labgemini4.m, run_added_sites_three_cases.m, validate_random_trials_and_failures.m','- 03_campus_data/survey/세종대_온라인조사_현황.md는 독립 관측 참고자료이며 기존9개 좌표를확정한 원시자료가 아님',''])
(OUT/'전체검토_수정제안.md').write_text('\n'.join(md),encoding='utf-8')
(OUT/'review_findings.json').write_text(json.dumps(findings,ensure_ascii=False,indent=2),encoding='utf-8')
with (OUT/'수정항목.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(findings[0]));w.writeheader();w.writerows(findings)

# Printable review companion: 8 focused pages, no opaque screenshot tables.
body=ParagraphStyle('B',fontName='MG',fontSize=10,leading=16,wordWrap='CJK',textColor=NAVY,spaceAfter=7)
title=ParagraphStyle('H',parent=body,fontName='MGB',fontSize=21,leading=28,spaceAfter=14)
sub=ParagraphStyle('S',parent=body,fontName='MGB',fontSize=11,leading=17,textColor=HexColor('#286E76'),spaceBefore=8,spaceAfter=6)
small=ParagraphStyle('SM',parent=body,fontSize=8.6,leading=13)
def pp(s,style=body):return Paragraph(html.escape(s).replace('\n','<br/>'),style)
story=[]
sections=[('검토 결과와 수정 범위',None),('좌표·실험 조건', ['R01','R02','R03','R09']),('수식·단위·물리 해석',['R04','R05','R06','R07','R08']),('코드 수정과 취약 구간',['R10','R11','R12','R13']),('13쪽과 위치 선정',['R14','R15','R16','R17','R18']),('전후 비교·독립 난수',['R19','R20','R21']),('통계·장애 부록·서식',['R22','R23','R24','R25','R26']),('그대로 사용할 교체 문장과 근거',None)]
for pageidx,(heading,ids) in enumerate(sections):
 if pageidx:story.append(PageBreak())
 story+=[pp('발표자료 검토 | 2026-10-15',small),pp(heading,title)]
 if ids:
  for fid in ids:
   v=next(x for x in findings if x['id']==fid);story+=[pp(f"{fid} · {v['pages']}쪽 · {v['priority']} · {v['title']}",sub),pp('관찰: '+v['observation']),pp('수정: '+v['recommendation'])]
 elif pageidx==0:
  for s in ['검토 대상은 물리페이지1~19입니다. 반복되는 우상단05 등은 검토 페이지 번호로 쓰지 않았습니다.','실제 수정본은13쪽만 바꿨습니다. 아래쪽 수식·분수와 표를 벡터/텍스트로 다시 작성하고, 기호·탐색/비교 표본·단위·기하적 설치 가정을 명시했습니다. 다른18쪽은 원본 그대로입니다.','원본 PDF는 전 페이지 이미지입니다. PPT 원본의 개별 객체를 직접 고친 것은 아니며, 수정13쪽은 새로 작성해 교체했습니다.','다른 오류는 검토 제안이며 자동 반영하지 않았습니다. 특히5쪽 환산식은 좌표 입력 문제인지 설명 오타인지 먼저 확인해야 하므로 기존 좌표를 임의로10배하거나 새 결과를 만들지 않았습니다.','우선순위: ①5쪽 환산계수/좌표근거 ②7~9쪽11개조건 ③9~10쪽SINR/대역폭/단정 ④16~17쪽확률정의 ⑤19쪽빈부록.','수치 대조 결과: 9·12~17쪽에 인용한 핵심 통계는 보관CSV와 일치했습니다. 핵심 문제는 주로 모델·표본·수식·의미의 표기입니다.','원본·수정본·Markdown검토표·CSV항목표를 같은 폴더에 보관합니다. 총26개 검토 항목을 필수/확인/보완/이번수정으로 구분했으며, 모든 항목이 수치 오류라는 뜻은 아닙니다.']:story.append(pp(s))
  story.append(pp('목차',sub));story.extend(pp(f'{i+1}. {v[0]}') for i,v in enumerate(sections))
 else:
  for s in md[md.index('## 발표문 교체 예시')+2:]:
   if s:story.append(pp(s[3:],sub) if s.startswith('## ') else pp(s,small if s.startswith('- ') else body))
def footer(c,doc):
 c.setFillColor(GRAY);c.setFont('MG',8);c.drawString(43,25,'발표자료 검토 | 입력/실험 데이터는 변경하지 않음');c.drawRightString(552,25,str(doc.page))
REVIEW=OUT/'발표자료_전체검토_수정제안.pdf'
doc=SimpleDocTemplate(str(REVIEW),pagesize=(595.276,841.89),leftMargin=43,rightMargin=43,topMargin=43,bottomMargin=47)
doc.build(story,onFirstPage=footer,onLaterPages=footer)
check=PdfReader(CORRECTED);assert len(check.pages)==19
for i in range(19):
 if i!=12:assert check.pages[i].get_contents().get_data()==source.pages[i].get_contents().get_data(),i+1
assert len(check.pages[12].extract_text())>600
qa={'date':'2026-10-15','source_sha256':hashlib.sha256(SRC.read_bytes()).hexdigest(),'original_copy_identical':SRC.read_bytes()==ORIGINAL.read_bytes(),'corrected_pages':19,'replaced_physical_page':13,'other_18_page_content_streams_identical':True,'page13_vector_text':True,'review_findings':len(findings),'review_pdf_pages':len(PdfReader(REVIEW).pages),'simulation_results_changed':False}
(OUT/'verification.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(qa,ensure_ascii=False));print(CORRECTED);print(REVIEW)
