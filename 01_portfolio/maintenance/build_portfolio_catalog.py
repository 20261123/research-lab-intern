"""Build browsable portfolio landing pages and a complete per-topic catalog."""
from pathlib import Path
import csv, hashlib, json
ROOT=Path(__file__).resolve().parents[2]
def put(rel,text):
 p=ROOT/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text.strip()+'\n',encoding='utf-8')
groups=[
 ('01_portfolio','프로젝트 소개·전체 자료 목록','포트폴리오 요약, 읽는 순서, 파일 목록·해시·이동 이력','[사례 설명](CASE_STUDY.md) · [전체 파일 목록](catalog/FILE_INDEX.md) · [검증 기록](catalog/reorganization_verification.json)'),
 ('02_code','실행 코드·재현','현재 MATLAB, 분석 후처리, 코드 버전 안내','[재현 절차](REPRODUCE.md) · [MATLAB](matlab/) · [Python 분석](analysis/) · [버전 설명](docs/CODE_VERSIONS.md)'),
 ('03_campus_data','지도·조사 입력','지도 원본, 7영역 개념도, 조사 양식과 현황','[원본 지도](maps/originals/) · [개념도](maps/concept/) · [조사 자료](survey/)'),
 ('04_site_selection','기지국 위치 선정 과정','잠정 경계·취약점 → 후보·평가함수 → 조합 비교·좌표','[위치 선정 이야기](PLACEMENT_PROCESS.md) · [취약 구간](01_weak_regions/) · [후보·조합 평가](02_candidate_evaluation/)'),
 ('05_comparison_results','주파수·대역폭 비교 결과','원본 9개 사각 영역과 최신 11개 캠퍼스 결과를 구분','[최신 11개 캠퍼스](03_added11_campus/) · [원본 9개 결과](01_baseline9_rectangle/) · [9개 세 조건 지도](02_baseline9_rectangle_heatmaps/)'),
 ('06_resilience','독립 20회·장애·대응 검증','확률 모델, 66장애 패턴, 비이상적 상황과 대응','[20회·장애·대응 설명과 자료](20_trials_and_failures/)'),
 ('07_presentation','발표 준비 자료','발표자 상세 해설서와 읽기본, 예제 PPT를 별도 관리','[팀 발표PDF·13쪽 수정·전체 검토](02_team_deck_2026-10-14/) · [34쪽 발표자 해설서](01_presenter_guide/) · [PPT 읽는 순서](PRESENTATION_GUIDE.md) · [예제 PPT](slides/examples/)'),
 ('08_project_management','조별 진행관리','현재 체크리스트·역할별 업무·진행 기록·1일차 기록','[현재 문서](current/) · [1일차](day1/) · [역할 PDF 이력](roles/)'),
 ('09_references_archive','과제·표준·원본·이력','공식 참고자료, 원본 코드/보고서, 이전 버전·예제·로그','[과제 안내](assignment/) · [3GPP 원문](standards/) · [시작 자료](starting_materials/) · [예제 패키지](demo_package/) · [보고서 이력](reports/)'),
]
for folder,title,description,links in groups:
 note=''
 if folder=='04_site_selection':note='\n\n이 폴더는 위치를 결정한 **과정과 근거**를 보관합니다. 발표용 해설서·PPT는 [07_presentation](../07_presentation/)에서 찾습니다.'
 if folder=='05_comparison_results':note='\n\n`01/02`는 과거 26,741개 사각 격자 결과이고, `03`은 잠정 캠퍼스 경계의 17,922개 위치입니다. 다른 평가 영역의 수치를 직접 전후 비교하지 않습니다.'
 if folder=='07_presentation':note='\n\n2026-10-15에 팀의 세종대 발표 PDF 초안을 받아 13쪽을 수정하고 전체 26항목을 검토했습니다. 최신 원본/수정본/검토표는 `02_team_deck_2026-10-14`에, 배경 해설은 `01_presenter_guide`에 있습니다. `slides/examples`의 PPT 두 개는 순천향대 예제 기반 이력이며 최종 세종대 PPT가 아닙니다. 최종 PPT 작성·팀 리허설·제출 완료로 표시하지 않습니다.'
 if folder=='09_references_archive':note='\n\n원본·이력 파일은 내용 그대로 보존했습니다. 과거 문서 내부의 당시 경로·수치는 역사 기록이며 현재 결과와 구분합니다. `demo_package`의 데이터는 순천향대 예제입니다. GitHub 단일 파일 제한을 넘는 두 MAT는 기존 [비공개 Release](https://github.com/20261123/research-lab-intern/releases/tag/data-archive-2026-10-10)에 있으며 [복원 경로](../01_portfolio/catalog/LARGE_FILES.md)를 확인합니다.'
 put(folder+'/README.md',f'# {title}\n\n{description}\n\n{links}{note}\n\n[포트폴리오 첫 화면](../README.md) · [전체 파일 목록](../01_portfolio/catalog/FILE_INDEX.md)')

put('README.md','''
# 세종대 캠퍼스 통신 시뮬레이션 포트폴리오

**3.5 GHz·28 GHz 채널 비교, 취약 사용자 분석, 기지국 두 곳 선정, 독립 난수 20회와 장애 복원력 검증을 연결한 조별 프로젝트입니다.**

MATLAB · Python · 3GPP TR 38.901 참고 · GitHub 자료 관리

실험 데이터 기준 **2026-10-10**, 포트폴리오 구조 정리 **2026-10-12**. 현재 공개 범위는 기존 **비공개 저장소**입니다.

## 처음 보는 사람을 위한 읽는 순서

| 목적 | 바로 열기 |
|---|---|
| 최신 팀 발표자료와 수정할 점 | [19쪽 발표PDF·13쪽 수정본·전체 검토](07_presentation/02_team_deck_2026-10-14/) |
| 프로젝트가 무엇을 해결했는지 | [포트폴리오 사례 설명](01_portfolio/CASE_STUDY.md) |
| 두 기지국 위치를 어떻게 골랐는지 | [위치 선정 과정](04_site_selection/PLACEMENT_PROCESS.md) |
| 발표자가 자세히 이해하고 싶다면 | [34쪽 상세 해설 PDF](07_presentation/01_presenter_guide/세종대_통신프로젝트_발표자_상세해설서.pdf) · [읽기본](07_presentation/01_presenter_guide/발표자_상세해설서.md) |
| 최신 그림과 수치를 확인하려면 | [서비스 11개 세 조건](05_comparison_results/03_added11_campus/) |
| 20회 검증과 장애 대응을 확인하려면 | [확률·장애·대응](06_resilience/20_trials_and_failures/) |
| 코드를 직접 재현하려면 | [실행 순서](02_code/REPRODUCE.md) |

## 문제와 접근

높은 주파수와 넓은 대역폭의 장단점을 동일 조건에서 분리하고, 전체 평균만으로 놓치기 쉬운 실내·저성능 사용자를 보완할 두 위치를 선정했습니다. 추가 사이트의 간섭 부작용과 장애 의존성까지 확인했습니다.

```mermaid
flowchart LR
    A[단위·안테나·표본 점검] --> B[잠정 캠퍼스 경계]
    B --> C[주파수·대역폭 비교]
    C --> D[취약 구간 4곳]
    D --> E[후보·평가함수 교차 비교]
    E --> F[추가 2곳 선정]
    F --> G[동일 경계 추가 전후]
    G --> H[독립 SF 20회]
    H --> I[장애·악화·대응]
```

## 핵심 결과

**고정 채널**, 서비스 11개·외부 간섭 6개·잠정 경계 내부 17,922개 위치의 결과입니다. 단위 Mbps.

| 조건 | 전송률 중앙값 | 전송률 5백분위 |
|---|---:|---:|
| 3.5 GHz / 100 MHz | 177.29 | 65.02 |
| 28 GHz / 100 MHz | 147.68 | 32.91 |
| 28 GHz / 800 MHz | 797.61 | 51.40 |

- 같은 100 MHz에서 28 GHz는 P5가 낮았습니다. 800 MHz는 전체 중앙값을 높였지만 실내 취약성을 모두 해소하지는 못했습니다.
- 추가 좌표는 **(-127.5,260), (-17.5,22.5) m**입니다. 같은 경계의 28/800 P5가 **8.82→51.40 Mbps**로 높아졌습니다.
- **확률 확장**에서는 새 섀도 페이딩 환경 20개 모두 기존 9개 대비 P5가 개선됐습니다. 정상 11개 28/800의 시행별 P5 평균은 **58.15 Mbps**입니다.
- 28/800에서 최악 단일 장애는 추가 11번, 이중 장애는 1+11번 중단입니다. P5 평균은 각각 **25.69 / 15.98 Mbps**이며, 이중 장애 때 11번을 먼저 복구하면 **54.43 Mbps**였습니다.

고정 채널 P5와 확률 모델의 **시행별 P5 평균**은 다른 지표입니다. 근거 CSV·설정·검증을 각 결과 폴더에 보관했습니다.

![같은 배치의 세 조건 SINR](05_comparison_results/03_added11_campus/sinr_three_cases.png)

![장애 복구와 이상적 대체 대역 비교](06_resilience/20_trials_and_failures/worst2_response_comparison.png)

## 주제별 폴더

| 폴더 | 포함 자료 |
|---|---|
| [01_portfolio](01_portfolio/) | 사례 설명, 전체 목록, 해시·이동 이력·구조 검증 |
| [02_code](02_code/) | 현재 MATLAB·Python, 코드 설명과 재현 절차 |
| [03_campus_data](03_campus_data/) | 지도 원본·개념도·조사 입력 |
| [04_site_selection](04_site_selection/) | 경계·취약점·후보·평가함수·조합·선정 좌표 |
| [05_comparison_results](05_comparison_results/) | 주파수·대역폭·추가 전후 히트맵·CDF·CSV·MAT |
| [06_resilience](06_resilience/) | 독립 20회·기지국 장애·스트레스·대응 |
| [07_presentation](07_presentation/) | 발표자 PDF·읽기본·구성 안내, 예제 PPT |
| [08_project_management](08_project_management/) | 현재 체크리스트·역할·진행 기록·1일차 자료 |
| [09_references_archive](09_references_archive/) | 과제·표준·원본·이전 버전·예제·보고서·로그 |

작은 CSV·JSON·실행 로그·그림은 관련 단계의 폴더에 함께 묶고, 폴더별 README와 [전체 자료 목록](01_portfolio/catalog/FILE_INDEX.md)에서 찾도록 구성했습니다. [이전→현재 경로표](01_portfolio/catalog/path_migration_2026-10-12.csv)로 과거 링크를 추적할 수 있습니다.

## 검증 범위와 현재 상태

실제 MATLAB 실행과 단위·표본·통계·기존 수치 일치를 검증했습니다. 원본 및 이전 버전은 보존했습니다. 팀 프로젝트의 결과물이며 개별 팀원 기여를 임의로 확정하지 않았습니다.

경계·후보 설치·높이는 잠정입니다. 위치별 Shannon 전송률은 실제 다운로드 속도나 셀 총 처리량이 아닙니다. SF 확장은 완전한 LOS/NLOS·이동·빠른 페이딩 모델이 아니며, 장애 대응은 재접속 지연·부하 재분배를 제외한 이상적 조건을 포함합니다. 검토한 후보 중 최선으로, 전역·장애 최적 배치를 확정하지 않았습니다.

**완료:** 코드·계산·위치 선정 근거·확률/장애 검증·34쪽 해설서·팀 발표PDF 13쪽 수정/전체 검토·자료 정리. **남음:** 정밀 경계·현장 설치 확인·최종 모델·세종대 최종 PPT·팀 리허설·제출. [체크리스트](08_project_management/current/팀작업_체크리스트.md)
''')

put('01_portfolio/CASE_STUDY.md','''
# 학교 신호 시뮬레이션: 프로젝트 사례

## 해결하려던 문제

주파수·대역폭이 달라질 때 신호와 전송률의 변화가 섞여 해석되지 않도록 비교 조건을 분리하고, 세종대 캠퍼스의 취약 사용자 구간을 보완할 기지국 두 곳을 근거로 선정하는 프로젝트입니다. 기존 과제 코드·보고서는 출발 자료로 사용했습니다.

## 설계와 검증의 연결

1. **계산 신뢰성:** 잡음/전력/주파수 단위, 상대각, 중복 사이트, 실제 SINR 색상, 격자와 P5 정의를 점검했습니다.
2. **평가 범위:** 원본 지도와 건물 좌표로 경계를 근사하고 경계 내부 17,922개 위치를 공통 표본으로 만들었습니다.
3. **효과 분리:** 3.5/100→28/100으로 주파수, 28/100→28/800으로 대역폭 영향을 분리했습니다.
4. **위치 선정:** 하위 10%와 주변 밀도·75 m 근접 제거로 네 대표 구간을 얻었습니다. 주변의 별도 후보 4/8/12곳과 세 함수를 교차 비교했습니다.
5. **추가 효과:** 전체 P5 목표에서 8개 후보 중 (-127.5,260), (-17.5,22.5) m를 선정했습니다. 같은 경계에서 추가 전후를 재계산했습니다.
6. **비이상적 검증:** 기존 선택을 고정한 새 SF 환경 20개, 단일 11·이중 55장애 패턴, 혼잡·외부 간섭·NF·차폐 및 대응을 계산했습니다.

## 중요한 판단

- 취약 사용자점과 설치 후보는 구분했습니다. 실내의 낮은 점을 바로 사이트 위치로 사용하지 않았습니다.
- 후보 수와 평가함수를 동시에 바꾸는 비교의 한계를 보완해 3×3 교차 비교를 수행했습니다.
- 전체 중앙값과 P5·실내/실외를 함께 봤습니다. 평균이 높아도 취약 사용자는 불리할 수 있었습니다.
- 기지국 추가의 이득과 간섭으로 악화된 위치를 함께 공개했습니다.
- 고정 모델·확률 모델, 위치별 분포의 P5·시행별 P5 평균, 사이트 장애·실제 시간상 끊김을 구분했습니다.

## 결과와 배운 점

고정 28/800의 전체 P5는 8.82→51.40 Mbps, 중앙값은 652.11→797.61 Mbps였습니다. 새 SF 20개에서도 세 조건 모두 추가 P5가 높았지만 11번 장애 의존도가 드러났습니다. 정상 성능 최적화와 장애 복원력 최적화는 다른 목표이며, 실제 설치 확인과 대체 커버리지 검토가 필요합니다.

## 기술과 협업

MATLAB 링크·SINR·Shannon 계산, Python 분석·문서 생성, GitHub의 이력·폴더·해시 관리로 입력-모델-결과-발표 근거를 연결했습니다. 코드는 기존 자료와 LLM 보조를 활용했으며 실제 수식·단위·계산 결과를 검증했습니다. 역할은 코드/지도/검증/발표로 구분했고 개별 실명·개인 기여는 임의로 작성하지 않았습니다.

## 한계와 다음 단계

잠정 경계와 제한된 건물 모델, 설치 가능성·높이 미확정, 단순 NLOS 평균 및 SF 근사, 실제 스케줄러·백홀·복구 지연 미반영이라는 한계가 있습니다. 정밀 입력·최종 모델을 확정하고, 필요하면 장애 목적함수로 후보 조합을 다시 탐색해야 합니다.

[위치 선정 과정](../04_site_selection/PLACEMENT_PROCESS.md) · [최신 결과](../05_comparison_results/03_added11_campus/) · [확률/장애](../06_resilience/20_trials_and_failures/) · [발표자료](../07_presentation/) · [첫 화면](../README.md)
''')

put('04_site_selection/PLACEMENT_PROCESS.md','''
# 두 기지국 위치를 정한 과정

발표용 자료와 분리해 **판단 기준·입력·선택 근거**를 모은 문서입니다.

| 단계 | 입력·판단 | 근거 파일 |
|---|---|---|
| 1. 캠퍼스 범위 | 지도 6개 기준점, affine 맞춤, 잠정 24꼭짓점 | [경계 좌표](01_weak_regions/boundary_vertices_estimated.csv) · [가정](01_weak_regions/geometry_assumptions.json) |
| 2. 평가 사용자 | 같은 경계의 17,922개 위치 | [위치별 결과](01_weak_regions/campus_positions.csv) |
| 3. 취약 구간 | 28/800 하위 10%, 반경 25 m·최소 50표본·취약 비율 50%, 75 m 근접 제거 | [대표점 4곳](01_weak_regions/weak_points.csv) · [상세 설명](01_weak_regions/README.md) |
| 4. 설치 후보 | 구간 주변 75 m, 경계 안쪽 10 m, 건물 밖 5 m, 사이트 이격 25 m | [후보 좌표와 거리](02_candidate_evaluation/candidates.csv) |
| 5. 평가함수 | 전체 P5 / 평균 로그 비율 / 최저 지역 개선 비율 | [설정](02_candidate_evaluation/scenario_settings.json) |
| 6. 교차 비교 | 후보 4·8·12 × 함수 3개, 동일 비교 표본 P5 | [9조건 비교](02_candidate_evaluation/factorial_3x3.csv) · [66고유 조합](02_candidate_evaluation/all_66_pairs.csv) |
| 7. 선택 | 8곳+전체 P5, 12곳 같은 함수와 같은 조합 | [선택·요약](02_candidate_evaluation/run_summary.json) |
| 8. 전후·민감도 | 고정 좌표로 같은 경계, 경계 ±30 m·부하 0.5/1.0 | [민감도](02_candidate_evaluation/sensitivity.csv) · [악화](02_candidate_evaluation/degradation_analysis.json) |
| 9. 새 환경·장애 | 위치를 다시 고르지 않고 독립 SF 20회·66장애 패턴 | [검증](../06_resilience/20_trials_and_failures/) |

## 선택된 좌표

- 10번 **(-127.5,260) m**, 모델상 광개토관 서쪽.
- 11번 **(-17.5,22.5) m**, 모델상 대양홀 서쪽.

검토한 후보와 전체 P5 목적에서의 선택입니다. 실제 설치·전역 최적·장애 최적을 확정한 것이 아닙니다. 8개 후보 및 28조합은 팀의 설계이며 학교 지정값이 아닙니다.

![후보와 시나리오](02_candidate_evaluation/three_scenario_sites.png)

## 발표와 수치 해석

선택 표본(8,962개)의 P5=51.32와 전체(17,922개)의 P5=51.40을 구분합니다. 초기 S3가 세 방식 중 높았지만 9조건 교차 비교에서 8곳+F1이 더 높았습니다. 28/800 고정 채널 P5는 8.82→51.40 Mbps이며, 일부 위치에는 추가 간섭에 따른 악화가 있었습니다.

최악 장애 1+11번에서 성능 저하가 컸습니다. 따라서 후보의 정상 P5와 장애 복원력은 별도 목표입니다. 실제 설치를 정하려면 경계·높이·전원·접근성·전송 경로·대체 커버리지를 확인해야 합니다.

[발표용 해설서](../07_presentation/01_presenter_guide/) · [주파수·대역폭 결과](../05_comparison_results/) · [첫 화면](../README.md)
''')

put('07_presentation/PRESENTATION_GUIDE.md','''
# 발표자료 읽는 순서

## 최신 팀 발표 PDF

[팀 발표 원본·13쪽 수정본·전체 검토](02_team_deck_2026-10-14/)를 확인하세요. 2026-10-15 검토 항목은 원본PPT 반영과 팀 확인이 남아 있습니다.

## 상세 해설

- [34쪽 상세 해설서 PDF](01_presenter_guide/세종대_통신프로젝트_발표자_상세해설서.pdf): 원리·수정·지도·배치·비교·20회·장애·대응·한계.
- [수정 가능한 읽기본](01_presenter_guide/발표자_상세해설서.md).
- [PDF 생성 도구](tools/build_presenter_guide.py), [검수 기록](01_presenter_guide/발표자_상세해설서_검수.json).

발표자는 **28~30쪽 구성·대본 → 31~33쪽 16개 예상 질문**을 먼저 읽고, 4~7쪽 계산 원리와 13~27쪽 선정/검증 근거를 확인합니다.

## 실제 세종대 PPT의 그림을 고를 때

| 슬라이드 주제 | 사용할 자료 |
|---|---|
| 지도·입력 | [원본/개념 지도](../03_campus_data/maps/) · [경계와 취약점](../04_site_selection/01_weak_regions/) |
| 주파수·대역폭 | [11개 배치 Heatmap·CDF](../05_comparison_results/03_added11_campus/) |
| 두 위치 선정 | [과정](../04_site_selection/PLACEMENT_PROCESS.md) · [후보/함수/교차표](../04_site_selection/02_candidate_evaluation/) |
| 독립 20회 | [시행별 P5](../06_resilience/20_trials_and_failures/trial_p5_three_cases.png) |
| 장애·대응 | [장애 행렬](../06_resilience/20_trials_and_failures/all_failure_patterns_p5.png) · [대응 그림](../06_resilience/20_trials_and_failures/worst2_response_comparison.png) |

## 예제 PPT의 상태

[slides/examples](slides/examples/)의 두 PPT는 순천향대 예제 기반 초안입니다. 원본 이력을 보존한 것이며 최신 세종대 수치가 반영된 최종 PPT가 아닙니다. 팀이 검토한 세종대 최종 PPT와 리허설·제출은 남아 있습니다.

위치 선정의 상세 CSV·MAT·후보 기록은 [04_site_selection](../04_site_selection/)에 두고 발표용 문서와 분리했습니다.
''')

put('02_code/REPRODUCE.md','''
# 코드 재현과 입력-출력 관계

폴더 정리로 경로만 갱신했습니다. 기존 수치·난수·수식·좌표를 재선정하지 않았습니다. MATLAB R2025a 및 Python의 numpy/reportlab/pypdf 등을 사용했습니다. 발표 PDF 도구는 Windows 맑은 고딕 폰트 경로를 사용합니다.

## 0. 저장소 루트에서 경로/캐시 확인

```matlab
addpath('02_code/matlab');
check_portfolio_layout;
```

## 1. 원본 labgemini4 사각 격자

```matlab
run(fullfile('02_code','matlab','labgemini4.m'));
% 스크립트는 clear all/close all 수행. 원본 파일 내용 보존.
addpath('02_code/matlab');
export_labgemini4_heatmaps;
```

출력은 `05_comparison_results/02_baseline9_rectangle_heatmaps`입니다. 이 26,741개 표본과 캠퍼스 17,922개 표본을 직접 전후 비교하지 않습니다.

## 2. 경계·취약점·후보를 다시 생성하려면

```text
python 02_code/analysis/weak_regions_provisional.py --prepare
```

생성되는 `04_site_selection/01_weak_regions/labgemini4_extended_grid.m`을 MATLAB에서 실행하고, 위 Python 도구를 인자 없이 실행해 취약점·표본·민감도를 생성합니다. 저장소에는 이미 계산된 자료가 포함되어 있습니다.

```text
python 02_code/analysis/prepare_three_scenarios.py
```

```matlab
addpath('02_code/matlab');
plot_provisional_weak_regions;
evaluate_three_placement_scenarios;
```

출력: `04_site_selection/01_weak_regions` 및 `02_candidate_evaluation`. 설치 가능성이 확정되었다는 뜻은 아닙니다.

## 3. 고정 배치 세 조건 비교

```matlab
addpath('02_code/matlab');
run_added_sites_three_cases;
```

```text
python 02_code/analysis/summarize_added_sites_three_cases.py
```

출력: `05_comparison_results/03_added11_campus`.

## 4. 독립 20회·장애·대응

```matlab
addpath('02_code/matlab');
validate_random_trials_and_failures;
analyze_resilience_fallback;
```

```text
python 02_code/analysis/summarize_random20_resilience.py
```

출력: `06_resilience/20_trials_and_failures`. 기존 20개 시드와 설정으로 재현합니다.

## 5. 발표자 PDF

```text
python 07_presentation/tools/build_presenter_guide.py
```

출력: `07_presentation/01_presenter_guide`. 한국어 PDF와 수정 가능한 읽기본입니다. 팀원에게는 이 폴더를 전달합니다.

별도 예제 패키지는 `09_references_archive/demo_package` 안의 README를 따릅니다. 예제 입력·MAT를 최신 세종대 결과로 사용하지 않습니다.
''')

# Catalog all source/reference artifacts, excluding .git, local QA and ignored large files.
allfiles=[]
for folder,*_ in groups:
 for p in sorted((ROOT/folder).rglob('*')):
  if p.is_file() and '__pycache__' not in p.parts and p.suffix!='.pyc':allfiles.append(p)
index=['# 전체 자료 목록','', '주제별로 묶었습니다. 각 경로를 클릭하면 원본 파일을 열 수 있습니다. 작은 보조 자료도 관련 단계 안에 포함했습니다.', '']
for folder,title,_,_ in groups:
 index += ['## '+title,'', '| 하위 범주 | 파일 |','|---|---|']
 for p in allfiles:
  rel=p.relative_to(ROOT).as_posix()
  if not rel.startswith(folder+'/'):continue
  if p.stat().st_size>100_000_000:continue
  from_here=Path('../../')/rel
  category=p.parent.relative_to(ROOT/folder).as_posix()
  index.append(f'| {category} | [{p.name}]({from_here.as_posix()}) |')
 index.append('')
index+=['## 대용량 예제 원시 결과','', '[Release 복원 안내](LARGE_FILES.md). 기존 비공개 Release와 SHA를 유지하고 복원 위치를 새 경로로 갱신했습니다.','']
put('01_portfolio/catalog/FILE_INDEX.md','\n'.join(index))

# Refresh existing provenance rows; add new portfolio artifacts.
manifest=ROOT/'01_portfolio/catalog/file_manifest.csv'
with manifest.open(encoding='utf-8-sig',newline='') as f:r=csv.DictReader(f);cols=r.fieldnames;rows=list(r)
for p in allfiles+[ROOT/'README.md',ROOT/'AGENTS.md']:
 rel=p.relative_to(ROOT).as_posix()
 if rel.endswith('/file_manifest.csv'):continue
 hits=[v for v in rows if v['path']==rel]
 if not hits:
  v=dict(origin='generated/portfolio organization',path=rel,storage='repository',bytes='',sha256='');rows.append(v);hits=[v]
 b=p.read_bytes()
 for v in hits:v['bytes']=str(len(b));v['sha256']=hashlib.sha256(b).hexdigest()
with manifest.open('w',encoding='utf-8',newline='') as f:w=csv.DictWriter(f,fieldnames=cols);w.writeheader();w.writerows(rows)
print('Portfolio folders:',len(groups),'catalog files:',len(allfiles))
