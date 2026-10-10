# labgemini4 세 조건 SINR 히트맵

labgemini4.m 원본을 다시 실행한 뒤, 이미 계산되는 SINR_dB의 세 열을 모두 그립니다. 기존 수식·사이트·안테나·간섭 부하율은 변경하지 않았습니다.

| 파일 | 조건 |
|---|---|
| sinr_3p5GHz_100MHz.png | 3.5 GHz / 100 MHz |
| sinr_28GHz_100MHz.png | 28 GHz / 100 MHz |
| sinr_28GHz_800MHz.png | 28 GHz / 800 MHz |
| sinr_three_cases.png | 세 조건의 가로 비교 |
| summary.csv | 조건별 SINR 중앙값, 0 dB 미만 비율, 잡음 및 전송률 통계 |
| positions_sinr.csv | 위치별 x/y, 실내 여부, 세 조건 SINR dB |
| run_metadata.json | 실행 조건과 환경 |
| verification.json | 이번 실행 결과의 수치 일치 및 표본 검증 기록 |

공통 조건은 섹터당 43 dBm, NF 7 dB, load_factor 0.5, 2.5 m 격자, 26,741개 위치입니다. 두 대역 모두 안테나 빔폭 70도와 최대 감쇠 20 dB를 사용합니다. 채널 모델은 원본의 결정론적 NLOS 형태 계산 그대로입니다.

## 그림을 읽는 방법

- 색상은 전송률이 아닌 **SINR dB**입니다. 모든 그림에서 -15~25 dB로 고정합니다.
- 범위 밖 값은 끝 색상으로 표시됩니다. 같은 짙은 파란색이라고 정확히 같은 SINR은 아닙니다.
- 삼각형은 서비스 사이트, x 표시는 외부 간섭 사이트, 사각형은 건물 영역입니다.
- 실제 평가 범위는 x -150~150 m, y 0~550 m입니다. 외부 사이트를 보이게 하려고 표시 x 범위만 -210~160 m로 넓혔으므로 왼쪽 빈 영역은 미평가 영역입니다.
- 28 GHz/800 MHz는 100 MHz와 신호·간섭을 공유하지만 총 잡음이 약 9.03 dB 더 큽니다. SINR이 낮아져도 넓은 대역폭으로 전송률은 높아질 수 있습니다.

## 다시 생성

저장소 루트를 MATLAB 현재 폴더로 두고 실행합니다.

```matlab
addpath('matlab');
export_labgemini4_heatmaps;
```

이 명령은 labgemini4의 clear all과 close all도 실행하므로 현재 변수와 열린 그림을 정리한 뒤 진행합니다. 생성 과정에서 모든 SINR의 유한값, 사용자 좌표 중복 없음, 28 GHz/800 MHz SINR이 같은 위치의 100 MHz보다 커지지 않는지 확인합니다.
