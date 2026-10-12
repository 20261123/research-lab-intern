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
