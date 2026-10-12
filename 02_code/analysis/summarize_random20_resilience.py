"""Build readable conclusions strictly from MATLAB outputs, without new rates."""
from pathlib import Path
import csv, json, statistics, math

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '06_resilience/20_trials_and_failures'
def read(name):
    with (OUT/name).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))
def write(name, rows):
    with (OUT/name).open('w', encoding='utf-8', newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
S=read('summary20.csv');V=read('trial_metrics.csv');J=json.loads((OUT/'run_metadata.json').read_text(encoding='utf-8'))
def row(name,c='28_800',g='all'):
    return next(r for r in S if r['scenario']==name and r['condition']==c and r['group']==g)
def num(r,k='p5_mean_Mbps'): return float(r[k])
def series(name,c,k='p5_Mbps'):
    return {int(r['trial']):float(r[k]) for r in V if r['scenario']==name and r['condition']==c and r['group']=='all'}
def interval(v):
    m=statistics.mean(v);h=2.0930240544*statistics.stdev(v)/math.sqrt(20);return m,m-h,m+h

# Independence unit is trial, not the spatially correlated locations.
assert len({r['seed'] for r in V})==20
keys={(r['scenario'],r['condition'],r['group']) for r in V}
assert len(V)==len(keys)*20
assert all(math.isfinite(float(r['p5_Mbps'])) and float(r['p5_Mbps'])>0 for r in V)
baseline_error=0
for c in ['3p5_100','28_100','28_800']:
    a=series('baseline9',c);b=series('off_10_11',c)
    baseline_error=max(baseline_error,max(abs(a[t]-b[t]) for t in a))
assert baseline_error<1e-9
comparisons=[]
for c1,c2,title in [('28_100','3p5_100','frequency_equal100'),('28_800','3p5_100','operating_condition'),('28_800','28_100','bandwidth_only')]:
    a=series('normal11',c1);b=series('normal11',c2);m,lo,hi=interval([a[t]-b[t] for t in a])
    comparisons.append(dict(comparison=title,left_condition=c1,right_condition=c2,paired_P5_difference_mean_Mbps=m,CI95_low=lo,CI95_high=hi))
write('paired_band_comparisons.csv',comparisons)
outage=[]
defs=read('scenario_definitions.csv');fails={r['scenario']:r['n_failed'] for r in defs if r['scenario'].startswith('off_')}
for c in ['3p5_100','28_100','28_800']:
    for k in [1,2]:
        candidates=[r for r in S if r['condition']==c and r['group']=='all' and fails.get(r['scenario'])==str(k)]
        for rank,r in enumerate(sorted(candidates,key=num),1):
            outage.append(dict(condition=c,n_failed=k,rank_worst_first=rank,scenario=r['scenario'],p5_mean_Mbps=r['p5_mean_Mbps'],p5_CI95_low_Mbps=r['p5_CI95_low_Mbps'],p5_CI95_high_Mbps=r['p5_CI95_high_Mbps']))
write('outage_ranking_by_condition.csv',outage)
fallback=read('dualband_fallback_trials.csv');fallbackSummary=[]
for name in ['normal11',J['worst_double']]:
    rows=[r for r in fallback if r['scenario']==name];m,lo,hi=interval([float(r['dualband_best_p5_Mbps']) for r in rows])
    fallbackSummary.append(dict(scenario=name,p5_mean_Mbps=m,p5_CI95_low_Mbps=lo,p5_CI95_high_Mbps=hi,below10Mbps_mean_pct=statistics.mean(float(r['dualband_below10_pct']) for r in rows),rescued_by_3p5_mean_pct=statistics.mean(float(r['rescued_by_3p5_pct']) for r in rows)))
write('dualband_fallback_summary.csv',fallbackSummary)
q=read('qos_threshold_sensitivity.csv');qs=[]
for name in ['normal11',J['worst_double']]:
    for c in [1,2,3]:
        for threshold in [1,5,10,25]:
            a=[r for r in q if r['scenario']==name and int(r['condition_index'])==c and float(r['threshold_Mbps'])==threshold]
            qs.append(dict(scenario=name,condition_index=c,threshold_Mbps=threshold,all_mean_below_pct=statistics.mean(float(r['all_below_threshold_pct']) for r in a),indoor_mean_below_pct=statistics.mean(float(r['indoor_below_threshold_pct']) for r in a)))
write('qos_threshold_summary.csv',qs)
gain=[]
for c in ['3p5_100','28_100','28_800']:
    a=series('normal11',c);b=series('baseline9',c);v=[a[t]-b[t] for t in a];m,lo,hi=interval(v)
    gain.append(dict(condition=c,paired_P5_gain_mean_Mbps=m,CI95_low=lo,CI95_high=hi,positive_gain_trials=sum(z>0 for z in v),trials=20))
write('paired_placement_validation.csv',gain)
verify=json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
verify.update(total_scenarios=len(defs),total_metric_rows=len(V),baseline9_equals_both_added_off_max_P5_error_Mbps=baseline_error,finite_positive_P5=True)
(OUT/'verification.json').write_text(json.dumps(verify,ensure_ascii=False,indent=2),encoding='utf-8')

text=['# 독립 난수 20회·기지국 장애·비이상적 상황 검증',
'', '## 결론', '',
'기존 두 추가 위치를 고정한 채 실제 MATLAB으로 독립 채널 실현 20개를 계산했다. 세 조건 모두 같은 채널 실현을 사용해 기존 9개와 추가 11개를 비교했다. 11개 단일 장애와 55개 이중 장애를 전수 비교했으며 혼잡·외부 간섭·잡음지수·링크 차폐·복합 상황과 대응도 계산했다.',
'', '정상 배치의 개선은 가정한 확률 모델에서도 확인됐다. 그러나 추가 11번 사이트 (-17.5,22.5) m가 멈추면 취약 사용자 성능이 크게 낮아진다. 정상 상태의 P5 우선 배치와 장애에 강한 배치는 다른 설계 목표다. 이번에 모든 설치 후보를 장애 기준으로 다시 최적화한 것은 아니다.',
'', '## 무엇을 무작위로 바꿨는가', '',
'- 원본 labgemini4의 고정 NLOS 평균 경로손실과 low-loss O2I를 유지하고, 수신전력에 표준편차 6 dB의 Gaussian 섀도 페이딩을 추가했다. 이는 3GPP UMa NLOS의 SF 크기를 참고한 확장 모델이다.',
'- 시행마다 새 시드로 17개 사이트 각각의 독립 공간 필드를 생성했다. 시드 2026101101~2026101120과 코드가 저장되어 있어 재현할 수 있다.',
'- 한 사이트의 3개 섹터에는 같은 필드를 적용했다. 주파수·기지국 배치·장애 비교에서는 같은 필드를 재사용해 조건 효과를 분리했다. 주파수 간 실제 페이딩이 완전히 같은 것으로 검증된 의미는 아니다.',
'- 공간 공분산은 exp(-(abs(dx)+abs(dy))/50)이다. 2.5 m 격자의 두 축에 정상 Gaussian AR(1)을 적용한 프로젝트 근사이며, 유클리드 거리 기반의 완전한 3GPP 공간 일관성 구현은 아니다. 가까운 사용자를 독립 표본 17,922개로 취급하지 않았다.',
'- 두 추가 위치는 (-127.5,260), (-17.5,22.5) m로 고정했다. 새로운 20개 필드에서 기존 선택을 검증했으며 새 난수로 다시 위치를 고르지 않았다.',
'- 열잡음 전력은 기존 B와 NF 계산을 유지한다. 잡음 파형을 임의로 더하는 대신 환경·링크 변동과 명시한 악화 조건을 변경했다.',
'', '[표준 근거: ETSI TR 138 901 V19.3.0, Table 7.4.1-1 및 7.5-6](https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/19.03.00_60/tr_138901v190300p.pdf). 가정한 공분산과 장애·부하·차폐 크기는 학교/3GPP 지정 조건이 아니다.',
'', '## 독립 20회 정상 배치 검증', '',
'각 시행의 캠퍼스 전송률 5백분위를 먼저 구하고, 그 값 20개의 평균과 95% Monte Carlo 평균 구간을 보고한다. 모든 시행·위치 데이터를 합친 분포의 P5나 하위 5% 평균과 다르다. 구간은 t(19)를 사용한 근사이며, 가정한 모델에서 평균을 추정하는 오차를 나타낸다. 실제 네트워크 성능이나 경계 오차의 95% 보장은 아니다.', '',
'| 조건 | 기존 9개 P5 평균 | 추가 11개 P5 평균 | 추가 11개 평균의 95% 구간 | 추가 효과의 paired 95% 구간 |',
'|---|---:|---:|---:|---:|']
labels={'3p5_100':'3.5 GHz / 100 MHz','28_100':'28 GHz / 100 MHz','28_800':'28 GHz / 800 MHz'}
for c in labels:
    a=row('baseline9',c);b=row('normal11',c);g=next(r for r in gain if r['condition']==c)
    text.append(f"| {labels[c]} | {num(a):.2f} | {num(b):.2f} | {num(b,'p5_CI95_low_Mbps'):.2f}~{num(b,'p5_CI95_high_Mbps'):.2f} | +{g['CI95_low']:.2f}~+{g['CI95_high']:.2f} |")
text+=['', '단위는 Mbps다. 세 조건 모두 추가 효과의 paired 구간이 0보다 크다. 결정론적 결과와 확률 모델 결과는 구분해 보관한다. 28/800과 3.5/100의 정상 P5 평균 차이는 약 +3.58 Mbps지만 paired 95% 구간은 -4.11~+11.28 Mbps로 0을 포함한다. 이번 20회만으로 두 운용 조건의 P5 우열을 확정하지 않는다.',
'', '## 기지국 한 개·두 개 장애', '',
'장애는 사이트의 3개 섹터가 모두 송신을 중단하는 경우다. 장애 사이트는 신호와 간섭에서 함께 제거하고, 남은 활성 섹터 중 가장 강한 곳에 즉시 다시 접속하는 이상적인 정상상태를 계산했다. 재접속 지연·실제 핸드오버 실패·복구 시간은 계산하지 않았다.', '',
'- 서비스 사이트 ID와 좌표는 service_sites.csv에 있다. 최악 패턴은 28 GHz·800 MHz의 20회 P5 평균이 가장 낮은 조합으로 선정했다.',
f"- 단일 최악: {J['worst_single']} — 추가 11번 (-17.5,22.5) m 중단.",
f"- 이중 최악: {J['worst_double']} — 기존 1번 (53.6,121.3) m + 추가 11번 (-17.5,22.5) m 중단.",
'- 이는 가정한 모델과 20개 실현에서의 순위다. 66개 패턴을 비교해 최악을 고른 뒤 같은 데이터에서 제시한 개별 구간에는 순위 선택·다중 비교 보정이 없다.', '',
'| 28 GHz / 800 MHz 상태 | P5의 20회 평균, Mbps | 10 Mbps 미만 위치 비율 평균 |', '|---|---:|---:|']
for a,title in [('normal11','정상'),(J['worst_single'],'최악 단일 장애'),(J['worst_double'],'최악 이중 장애'),('worst2_busy_load1','최악 이중 장애 + 부하율 1.0'),('worst2_combined_adverse','최악 이중 장애 + 복합 악화')]:
    r=row(a);text.append(f"| {title} | {num(r):.2f} | {num(r,'below10Mbps_mean_pct'):.2f}% |")
text+=['', '기존 접속 사이트가 꺼져 재접속이 필요한 위치의 평균 비율은 단일 최악 약 12.60%, 이중 최악 약 21.26%다. 재접속 후 10 Mbps 미만 비율과 구분한다. 10 Mbps는 프로젝트의 서비스 품질 비교 기준이며 실제 무선 연결 끊김 판정값은 아니다. 1/5/10/25 Mbps 기준 민감도도 저장했다.',
'', '## 별도 악화 조건과 대응', '',
'| 조건 | 가정 | 28/800 P5 평균, Mbps | 대응 방향 |','|---|---|---:|---|']
for a,title,assumption,response in [
 ('busy_load1','혼잡','부하율 0.5→1.0','간섭 조정·트래픽 분산'),
 ('external_plus6dB','외부 간섭 증가','외부 수신 간섭 전력 +6 dB','주파수·시간 자원 조정 검토'),
 ('receiver_NF10','수신기 잡음 증가','NF 7→10 dB','수신 품질 개선·커버리지 보강'),
 ('added_links_block20dB_28','추가 링크 차폐','두 추가 사이트의 모든 28 GHz 링크에 +20 dB 손실','차폐 경로 점검·3.5 GHz 대체 접속'),
 ('combined_adverse','복합 악화','위 네 조건을 동시에 적용','단일 조치보다 복구·대체 접속·간섭 조정 병행')]:
    text.append(f"| {title} | {assumption} | {num(row(a)):.2f} | {response} |")
text+=['', '20 dB 차폐는 실제 건물·사람·강우를 측정한 값이 아니라 스트레스 시험 가정이다. 모든 추가 링크에 적용한 강한 조건으로, 특정 차폐물 위치를 모델링한 결과는 아니다. 부하율은 간섭의 평균 활동도 계수이고 스케줄러 자원 할당 모델이 아니다.',
'', '최악 이중 장애에서 실제 계산한 대응:', '',
f"- 간섭 부하율 0.5→0.3으로 낮추면 P5 평균 {num(row(J['worst_double'])):.2f}→{num(row('response2_coordinate_load03')):.2f} Mbps. 전 사용자 같은 활성 송신전력을 유지한 이상적 간섭 조정이다. 조정에 필요한 시간·대역폭 비용을 차감하지 않았다."]
rep=read('repair_priority.csv')
for r in rep:
    if r['condition']=='28_800':text.append(f"- {r['restored_site']}번만 먼저 복구: {r['remaining_failed_site']}번은 계속 중단, P5 평균 {float(r['p5_mean_Mbps']):.2f} Mbps.")
f=next(r for r in fallbackSummary if r['scenario']==J['worst_double'])
text+=[f"- 3.5/100과 28/800 중 사용자별 전송률이 높은 대역을 선택할 수 있는 이상적 대체 접속: P5 평균 {f['p5_mean_Mbps']:.2f} Mbps, 10 Mbps 미만 비율 {f['below10Mbps_mean_pct']:.2f}%. 듀얼밴드 단말·동시 가용 커버리지가 필요하며 전환 지연과 부하 재분배는 반영하지 않았다. 두 대역 용량을 더한 결과가 아니다.",
'', '**복구 우선순위는 11번이다.** 28/800의 최악 이중 장애에서 11번을 복구하는 효과가 1번 복구나 이상적 간섭 조정보다 크다. 따라서 11번의 전원·전송 경로·대체 커버리지 확보가 우선 검토 대상이다. 이 물리적 조치 자체를 구현·검증한 것은 아니다.',
'', '## 그림과 파일', '',
'- trial_p5_three_cases.png: 기존 9개·추가 11개·최악 이중 장애의 시행별 P5.',
'- all_failure_patterns_p5.png: 단일/이중 장애 66패턴의 P5 평균 행렬.',
'- worst2_response_comparison.png: 최악 이중 장애에서 복구·간섭 조정·이상적 대체 대역을 비교.',
'- stress_and_response_p5.png: 스트레스·일부 대응의 P5 평균과 Monte Carlo 구간.',
'- below10_probability_maps.png: 정상/최악 이중 장애에서 20개 실현 중 10 Mbps 미만인 비율. 시간 가용률이나 실제 장애 확률이 아니다.',
'- normal_worst2_mean_cdf.png: 시행별 CDF 평균, 10 Mbps 간격 표시. 이 그림의 P5와 시행별 P5 평균을 혼용하지 않는다.',
'- summary20.csv / trial_metrics.csv: 전체·실내·실외 모든 조건의 집계/시행별 수치.',
'- repair_priority.csv / dualband_fallback_summary.csv: 복구 우선순위와 이상적 대체 대역 선택.',
'- paired_band_comparisons.csv / paired_placement_validation.csv: paired 비교 구간.',
'- scenario_definitions.csv / seeds.csv / run_metadata.json / verification.json: 설정·재현·검증.',
'- random20_results.mat: 정상/최악 이중 장애 위치별 용량과 접속 사이트·통계.',
'', '## 실행 방법', '', 'MATLAB에서 저장소 루트를 현재 폴더로 지정한다.', '', '```matlab', "addpath('02_code/matlab');", 'validate_random_trials_and_failures;', 'analyze_resilience_fallback;', '```', '',
'그 뒤 02_code/analysis/summarize_random20_resilience.py를 실행해 CSV와 이 설명을 갱신한다.',
'', '## 검증 범위와 남은 작업', '',
f"- 확률 변동이 0인 평균 링크가 이전 결정론적 세 조건 결과와 일치한다. 최대 오차 {J['deterministic_max_error_Mbps']:.3g} Mbps.",
f"- 10·11번을 모두 끈 결과와 기존 9개 배치의 시행별 P5 최대 차이 {baseline_error:.3g} Mbps. 시드 20개·표본 유일성·유한 결과·대역폭별 용량 순서 등을 확인했다.",
'- 독립 단위는 시행 20개다. 공간 상관을 가진 위치 17,922개를 독립 난수 시행으로 세지 않는다.',
'- 정밀 경계·현장 설치·LOS 상태 표본·실내 깊이·O2I의 추가 랜덤 변동·빠른 페이딩·이동·스케줄러·백홀·실제 복구 시간·장애 확률은 이번에 검증하지 않았다.',
'- 원본 평균 식을 유지했으며 2D 거리 10 m 미만 링크가 495개 있다. 표준 적용 범위 밖의 근거리 외삽을 포함하므로 완전한 3GPP 모델 준수 결과로 표현하지 않는다.',
'- A: 팀 PC 재현, 확정 채널 모델/장애 후 부하 모델 검토. B: 11번 실제 설치·전원·전송 경로·대체 커버리지 조사. C: 실내 QoS와 장애 패턴·복구 순위 검토. D: 결정론/확률 결과를 구분해 PPT 반영.',
'- 장애에 강한 배치를 선택하려면 다음 단계에서 모든 후보 조합을 최악 장애 P5 또는 실제 장애 확률 기반 지표로 다시 비교해야 한다. 기존 두 위치의 전역 최적·장애 최적을 이번 결과로 확정하지 않는다.', '']
(OUT/'README.md').write_text('\n'.join(text),encoding='utf-8')
print('Verified:',verify)
print('Fallback:',fallbackSummary)
print('Placement validation:',gain)
