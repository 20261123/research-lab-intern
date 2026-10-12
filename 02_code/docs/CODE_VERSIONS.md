# 코드와 실험 버전 안내

| 경로 | 목적 | 해석 |
|---|---|---|
| `02_code/matlab/labgemini4.m` | 현재 세종대 좌표 기반 주파수·대역폭 비교 | 결정론적 NLOS 형태 모델, 부하율 0.5 |
| `09_references_archive/code_versions/labgemini1.m` ~ `labgemini3.m` | 변경 이력 보존 | 최종 발표 수치 계산에 사용하지 않음 |
| `09_references_archive/code_versions/campus_project.m` | 사용자 기존 작업본 | 원본 그대로 보존 |
| `09_references_archive/demo_package` | 별도 확률 채널·기지국 배치 탐색 구현 | demo 결과는 세종대 결과가 아님 |
| `09_references_archive/starting_materials/Campus_3GPP_main_v0.0.m` | 과제의 원본 초안 | 수정 대상 원본 |

## labgemini2에서 labgemini4로 바뀐 점

1. RGB 배열 대신 실제 SINR dB 값을 scatter의 색상 데이터로 전달하고 두 그림에 −15~25 dB 범위를 적용합니다.
2. (36.1, 418.1) m의 외부 목록 중복을 제거했습니다. 목록 간 중복 검사에는 경고만 있고 자동 삭제 기능은 없습니다.
3. y 평가 상한을 500에서 550 m로 넓히고 세 조건에 공통인 meshgrid를 사용합니다.
4. `load_factor = 0.5`로 합산 간섭 전력을 줄입니다. 이는 실제 스케줄러가 아닌 모델 가정이며, 1.0으로 바꾸면 전체 간섭 전력을 사용합니다.
5. 섹터 상대각을 `mod(theta-sectorAz+180,360)-180`으로 정규화합니다.
6. 하위 5% 평균 대신 nearest-rank 5백분위를 출력합니다.

## 별도 campus_model 실행

MATLAB에서 `09_references_archive/demo_package`을 현재 폴더로 지정합니다. 원래 패키지의 상대 경로와 입력 구조를 보존했습니다.

```matlab
addpath('02_code/matlab');
test_campus;
out = campus_main('demo', struct('grid_m',20,'trials',2));
```

전체 예제는 `campus_main('demo')`로 실행합니다. 실제 세종대 입력 모드는 조사 양식을 완성하고 검토한 뒤 실행해야 합니다. 현재 양식의 빈 값을 가상 좌표로 채워 실측 결과처럼 사용하지 않습니다.

`tools`의 생성 스크립트는 당시 로컬 경로와 문서 라이브러리 설정을 포함한 이력 자료입니다. 재사용할 때 경로와 의존성을 조정해야 합니다.
