clear all; close all; clc;

%% 1. 파라미터 설정 (프로젝트 1단계 조건: 3.5GHz / 100MHz)
BW      = 100 * 10^6;       % 대역폭 100 MHz
NF      = 7;                % 잡음 지수 7 dB
Pt_dBm  = 43;               % 기지국 섹터당 송신 전력 43 dBm

% 간섭 섹터 부하율 (1.0 = 모든 섹터 상시 송신 = 최악 조건, 0.5 = 평균 50% 사용)
load_factor = 0.5;

%% 2. 기지국 배치 (실제 경위도를 m 단위 직교 좌표로 변환)
% 학교 내부 서비스 기지국 (9개)
BS_pos = [
     53.6 + 121.3i;
     75.1 + 143.8i;
     76.3 + 156.5i;
     -2.2 + 269.7i;
    -98.8 + 364.8i;
    -58.1 + 386.1i;
     36.1 + 418.1i;
     -1.4 + 489.8i;
   -126.2 + 521.6i
];
N = length(BS_pos);

% 학교 외부 간섭 기지국 (6개)
% (36.1 + 418.1i)는 교내 서비스 기지국과 중복이므로 제거
BS_pos_interference = [
   -101.6 +  81.4i;
   -149.0 + 335.7i;
   -151.4 + 370.6i;
   -143.8 + 409.7i;
     94.1 + 505.8i;
   -196.7 + 476.9i
];
N_interference = length(BS_pos_interference);

dup = intersect(BS_pos, BS_pos_interference);
if ~isempty(dup)
    warning('서비스/간섭 기지국 좌표가 중복되어 있습니다: %s', mat2str(dup));
end

%% 3. 공간 모델링 (세종대학교 건물 좌표)
% [x_min, x_max, y_min, y_max]
sejong_buildings = [
    -120.7, -56.4,  234.9, 325.6;  % 광개토관
     -12.4,  46.4,      0,  61.6;  % 대양홀
      51.7, 102.6,  109.7, 187.1;  % 학생회관
     -72.3, -24.3,  113.1, 170.1;  % 군자관
     -76.4, -24.7,   51.8, 102.2;  % 집현관
     -55.2,  16.5,    368, 469.1;  % 율곡관/충무관
     -20.4,  38.2,  339.4, 398.9   % 학술정보원
];
num_buildings = size(sejong_buildings, 1);

personX = 2.5;   % 2.5m 간격 배치
personY = 2.5;

%% 4. 공통 평가 격자 생성 (y 범위 0~550 m)
[X, Y] = meshgrid(-175:personX:175, -70:personY:615);
pos = X(:) + 1i*Y(:);
numUsers = numel(pos);

% 실내 여부는 주파수와 무관하므로 한 번만 계산
isIndoor = false(numUsers, 1);
for b = 1:num_buildings
    isIndoor = isIndoor | ...
        (real(pos) >= sejong_buildings(b,1) & ...
         real(pos) <= sejong_buildings(b,2) & ...
         imag(pos) >= sejong_buildings(b,3) & ...
         imag(pos) <= sejong_buildings(b,4));
end

%% 5. 주파수별 수신 신호 및 간섭 전력 계산
freqs = [3.5, 28];

signal_mW       = zeros(numUsers, 2);
interference_mW = zeros(numUsers, 2);   % load_factor 적용
interference_full_mW = zeros(numUsers, 2);   % 부하율 1.0 (최악 조건)

for f = 1:2
    fc_GHz = freqs(f);
    fprintf('%.1f GHz 계산 중...\n', fc_GHz);

    for k = 1:numUsers
        dServing  = calcDist(N, pos(k), BS_pos);
        dExternal = calcDist(N_interference, pos(k), BS_pos_interference);

        if isIndoor(k)
            rxServing  = Pr_Building(N, BS_pos, pos(k), dServing, Pt_dBm, fc_GHz);
            rxExternal = Pr_Building(N_interference, BS_pos_interference, pos(k), dExternal, Pt_dBm, fc_GHz);
        else
            rxServing  = Pr(N, BS_pos, pos(k), dServing, Pt_dBm, fc_GHz);
            rxExternal = Pr(N_interference, BS_pos_interference, pos(k), dExternal, Pt_dBm, fc_GHz);
        end

        % 가장 강한 섹터를 서빙 섹터로 선택
        signal_mW(k,f) = max(rxServing);

        % 나머지 모든 섹터를 간섭으로 처리
        I_all = sum(rxServing) - signal_mW(k,f) + sum(rxExternal);
        interference_full_mW(k,f) = I_all;
        interference_mW(k,f)      = load_factor * I_all;
    end
end

%% 6. 세 가지 시뮬레이션 조건의 SINR 계산
% 열 1: 3.5GHz / 100MHz,  열 2: 28GHz / 100MHz,  열 3: 28GHz / 800MHz
noise100 = 10^((-174 + 10*log10(100e6) + NF)/10);
noise800 = 10^((-174 + 10*log10(800e6) + NF)/10);

SINR_linear = zeros(numUsers, 3);
SINR_linear(:,1) = signal_mW(:,1) ./ (interference_mW(:,1) + noise100);
SINR_linear(:,2) = signal_mW(:,2) ./ (interference_mW(:,2) + noise100);
SINR_linear(:,3) = signal_mW(:,2) ./ (interference_mW(:,2) + noise800);

SINR_dB = 10*log10(max(SINR_linear, realmin));

%% 7. [1단계] 주파수 비교: SINR Heatmap
figure('Name', 'Step 1: Frequency Comparison', 'Position', [100 100 1200 650]);

for c = 1:2
    subplot(1,2,c);

    % 색상에 실제 SINR(dB) 값을 직접 전달 -> caxis 정상 적용
    scatter(real(pos), imag(pos), 12, SINR_dB(:,c), 'filled');
    hold on;

    % 건물 윤곽선
    for b = 1:num_buildings
        xmin = sejong_buildings(b,1);  xmax = sejong_buildings(b,2);
        ymin = sejong_buildings(b,3);  ymax = sejong_buildings(b,4);
        rectangle('Position', [xmin, ymin, xmax-xmin, ymax-ymin], ...
            'EdgeColor','k','LineWidth',0.8);
    end

    % 기지국 표시
    h1 = plot(real(BS_pos), imag(BS_pos), 'k^','MarkerSize',7,'MarkerFaceColor','w');
    h2 = plot(real(BS_pos_interference), imag(BS_pos_interference), ...
        'kx','MarkerSize',8,'LineWidth',1.5);

    colormap(jet);
    caxis([-15 25]);
    cb = colorbar;
    cb.Label.String = 'SINR (dB)';

    title(sprintf('%.1f GHz / 100 MHz', freqs(c)));
    xlabel('X (m)');
    ylabel('Y (m)');
    axis equal;
    xlim([-210 160]);
    ylim([0 550]);
    grid on;

    legend([h1,h2], {'Serving BS','Interference BS'}, 'Location','best');
end

% 0dB 미만의 취약 위치 비율
fprintf('\n=== 1단계: 주파수 비교 (부하율 %.2f) ===\n', load_factor);
for c = 1:2
    weakRatio = 100 * mean(SINR_dB(:,c) < 0);
    fprintf('%.1f GHz: SINR 0dB 미만 %.2f%%\n', freqs(c), weakRatio);
end

%% 8. [2단계] 대역폭 비교: Capacity CDF
BW_cases = [100e6, 100e6, 800e6];

Capacity = zeros(numUsers, 3);
for c = 1:3
    Capacity(:,c) = BW_cases(c) * log2(1 + SINR_linear(:,c));
end

figure('Name', 'Step 2: Capacity CDF');
hold on;

compareIdx = [1,3];
labels = {'3.5 GHz / 100 MHz', '28 GHz / 800 MHz'};

fprintf('\n=== 2단계: 전송률 비교 (부하율 %.2f) ===\n', load_factor);

for j = 1:2
    c = compareIdx(j);

    sortedC = sort(Capacity(:,c) / 1e6);   % Mbps, 오름차순
    F = (1:numUsers)' / numUsers;

    plot(sortedC, F, 'LineWidth', 2, 'DisplayName', labels{j});

    idx5 = max(1, ceil(numUsers * 0.05));
    C5   = sortedC(idx5);              % 5백분위
    C50  = median(sortedC);
    Cavg = mean(sortedC);

    fprintf('%s\n', labels{j});
    fprintf('  평균: %.2f Mbps\n', Cavg);
    fprintf('  중앙값: %.2f Mbps\n', C50);
    fprintf('  5백분위: %.2f Mbps\n\n', C5);
end

xlabel('Shannon Capacity (Mbps)');
ylabel('Cumulative Probability');
title('Capacity CDF: 3.5 GHz vs 28 GHz');
legend('Location','best');
grid on;
ylim([0 1]);


T=table(real(pos),imag(pos),isIndoor,SINR_dB(:,3),signal_mW(:,2),interference_mW(:,2), 'VariableNames',{'x_m','y_m','is_indoor','sinr_dB','signal_mW','interference_mW'});
writetable(T,'C:/Users/user/.codex/.chatgpt-projects/g-p-6ac48848a708819186677f0769430e90/research-lab-intern/04_site_selection/01_weak_regions/extended_grid_sinr.csv');
close all;

%% ------------------- 사용자 정의 함수 ------------------- %%

function d = calcDist(N, pos, BS_pos)
    BaseStation_h = 25;   % 기지국 높이 25m
    person_h = 1.5;       % 단말 높이 1.5m
    d = zeros(1, N);
    for n = 1:N
        d(n) = sqrt(real(pos-BS_pos(n))^2 + imag(pos-BS_pos(n))^2 + (BaseStation_h-person_h)^2);
    end
end

function Pr_result = Pr(N, BS_pos, pos, dist, Pt_dBm, fc_GHz)
    Pr_result = sectorPower(N, BS_pos, pos, dist, Pt_dBm, fc_GHz, 0);
end

function PrBuilding_result = Pr_Building(N, BS_pos, pos, dist, Pt_dBm, fc_GHz)
    L_glass = 2 + 0.2 * fc_GHz;
    L_concrete = 5 + 4 * fc_GHz;
    O2I_loss = 5 - 10*log10(0.3 * 10^(-L_glass/10) + 0.7 * 10^(-L_concrete/10));
    PrBuilding_result = sectorPower(N, BS_pos, pos, dist, Pt_dBm, fc_GHz, O2I_loss);
end

function P = sectorPower(N, BS_pos, pos, dist, Pt_dBm, fc_GHz, extra_loss_dB)
    % 기지국당 3개 섹터의 수신 전력(선형, mW)
    % 안테나 패턴은 각도 차를 [-180, 180]로 정규화하여 계산
    % (정규화하지 않으면 기지국 x/y 좌표를 경계로 직선 모양의 불연속이 생김)
    Am = 20;
    P = zeros(1, 3*N);
    for x = 1:N
        theta = atan2d(imag(pos-BS_pos(x)), real(pos-BS_pos(x)));
        if dist(x) <= 1
            continue;
        end
        PL = 13.54 + 39.08*log10(dist(x)) + 20*log10(fc_GHz);
        for y = 2:-1:0
            sectorAz  = 120*y;
            angleDiff = mod(theta - sectorAz + 180, 360) - 180;
            A_loss    = -min(12 * (angleDiff / 70)^2, Am);

            Pr_dBm = Pt_dBm - (PL + extra_loss_dB) + A_loss;
            P(3*x-y) = 10^(Pr_dBm / 10);
        end
    end
end