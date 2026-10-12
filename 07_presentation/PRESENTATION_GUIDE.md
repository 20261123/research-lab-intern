# 발표자료 읽는 순서

## 최신 자료

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
