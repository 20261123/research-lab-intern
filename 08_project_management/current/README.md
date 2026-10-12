# 세종대 캠퍼스 통신 미니프로젝트 시작 안내

이 폴더는 수정 MATLAB 코드, 실제 조사 입력 양식, 팀 체크리스트와 발표 초안을 묶은 작업 패키지입니다. 원본 Downloads 파일과 sources 자료는 수정하지 않았습니다.

**현재 상태: 계산·비교·배치 탐색 기능은 구현했습니다. 세종대 실제 건물 및 동일 사업자 4G 기지국 좌표는 아직 조사 입력이 필요합니다. 예제 결과는 순천향대 기존 코드의 영역을 사용한 검증 예제이며 세종대 결과가 아닙니다.**

## 가장 먼저 할 일

1. 조장: `팀작업_체크리스트.md`를 공유하고 A/B/C 담당자 이름을 정합니다.
2. 코드 담당 A: MATLAB에서 이 폴더를 현재 폴더로 설정합니다.
3. MATLAB 명령창에서 아래 명령을 차례로 실행합니다.

```matlab
addpath('02_code/matlab');
test_campus;
out = campus_main('demo');
```

`demo`는 코드가 작동하는지 확인하기 위한 예제입니다. 별도 툴박스는 필요하지 않습니다. MATLAB R2025a에서 검증하며, 표·문자열·tiledlayout·exportgraphics를 지원하는 MATLAB이 필요합니다.

결과는 실행별 `results/demo_날짜시간` 폴더에 생성됩니다. 전체 예제는 2.5 m 격자와 20회 시행입니다. 빠르게 확인하려면 `campus_main('demo',struct('grid_m',20,'trials',2))`를 실행합니다. 빠른 실행 결과를 최종 발표 수치로 사용하지 않습니다.

## 세종대 자료를 입력한 뒤

지도 담당 B는 `좌표조사_안내.md`에 따라 `input/sejong`의 CSV 세 개와 metadata.json을 채웁니다. 지도와 동일 사업자 기지국 위치를 검토한 다음 metadata의 status를 `surveyed`로 설정합니다.

```matlab
addpath('02_code/matlab');
out = campus_main('sejong');
```

코드는 조사 자료가 없는 상태에서 실행을 중단합니다. 가짜 세종대 좌표나 예제 좌표를 자동 대입하지 않습니다. 기존 사이트는 유지하며 candidate 두 개만 추가합니다.

## 결과를 읽는 순서

| 파일 | 확인할 내용 |
|---|---|
| summary.csv | 조건별 전체·실내·실외의 5백분위, 중앙값, 평균 |
| candidate_ranking.csv | 후보 8곳의 28개 조합, 탐색 난수에서 순위 |
| selected_sites.csv | 선택한 두 사이트 좌표 |
| validation_positions.csv | 위치별 시행 중앙값과 신호·간섭 세기 |
| spatial_changes.csv | 위치별 SINR 개선·악화 비율 |
| figures/validation_frequency_heatmap.png | 두 대역 모두 100 MHz일 때 비교 |
| figures/validation_placement_heatmap.png | 28 GHz·800 MHz 추가 전후 |
| figures/validation_placement35_heatmap.png | 3.5 GHz·100 MHz 추가 전후 |
| figures/validation_cdf_all.png | 전체 용량 CDF와 추가 전후 비교 |
| figures/validation_cdf_indoor.png | 실내 사용자 용량 CDF |
| figures/validation_sinr_change.png | 28 GHz SINR 변화, 악화 지역 확인 |
| validation_results.mat | 재현을 위한 원시 결과, 좌표, 설정 |
| run_metadata.json | 사용 조건, 난수 seed, 결과 집계 정의 |

발표에는 **validation** 결과를 사용합니다. selection 결과는 후보를 고르는 데 사용합니다. 선택에 사용하지 않은 새 난수로 최종 결과를 계산하므로, 탐색 때의 최고 성능이 검증에서도 유지되는지 확인할 수 있습니다. 검증에서 악화된다면 숨기지 않고 발표합니다.

## 계산 가정

- UMa, 높이 25/1.5 m, 섹터당 총전력 43 dBm, NF 7 dB.
- 3섹터, 수평 빔폭 65°, 최대 감쇠 30 dB, 소자 최대 이득 8 dBi. 수직 패턴·배열 빔포밍은 생략합니다. 이 변경은 원본의 70°/20 dB를 단순 버그로 간주한 것이 아니라 표준 수평 소자 패턴을 사용하는 모델 선택입니다.
- 같은 대역의 모든 섹터가 동시에 송신하는 full-load, reuse-1 모델입니다. 3.5 GHz와 28 GHz는 별도 시나리오로 계산하며 서로 간섭하지 않습니다.
- 가장 강한 서비스 후보 섹터에 접속하고 외부 사이트는 간섭만 발생시킵니다.
- LOS는 UMa 거리 확률로 결정합니다. 건물 벽을 따라 LOS를 추적하는 ray tracing은 아닙니다.
- 링크 shadow fading은 사용자·사이트별 독립 Gaussian입니다. 공간 상관·지형·실제 트래픽·스케줄링은 모델링하지 않습니다.
- O2I는 사용자별 low-loss 외벽, 실내 깊이 min(U(0,25), U(0,25)) m, 투과손실 표준편차 4.4 dB를 사용합니다. 같은 사용자에게 외부 기지국에도 적용합니다.
- O2I 기본 경로는 직선 3차원 거리로 근사합니다. 실내 깊이는 통계적으로 뽑으므로 실제 건물 폭·실제 진입점과 일치하지 않을 수 있습니다.
- UMa 적용범위 밖의 가까운 링크는 수평거리 10 m로 제한합니다. 5 km를 넘는 링크는 오류로 처리합니다.
- 위치×시행을 같은 가중치로 모아 CDF/통계를 계산합니다. Heatmap은 위치별 20회 SINR dB 중앙값입니다.
- 용량은 전체 대역폭을 쓰는 단일 스트림 Shannon 전송률입니다. 셀 처리량이나 실제 사용자 다운로드 속도가 아닙니다.

## 배치 탐색

실제 세종대 모드에서는 지도 담당자가 검토한 후보 8곳을 입력해야 합니다. 후보 28쌍을 모두 비교하고 28 GHz·800 MHz 전체 5백분위, 중앙값, 평균 순으로 선택합니다. 동일 점수라면 CSV 입력 순서가 먼저인 조합을 선택합니다. 예제 모드의 자동 후보는 약한 실외 지점에서 60 m 간격으로 뽑은 알고리즘 검증용입니다.

## 팀 공유

`deliverables`에는 발표 초안과 패키지를 둡니다. 새 좌표 조사나 설정 변경 뒤에는 코드를 다시 실행하고 발표 그래프를 교체합니다. PDF의 기존 예시 수치를 우리 조 성능으로 옮겨 적지 않습니다.
