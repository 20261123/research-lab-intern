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
