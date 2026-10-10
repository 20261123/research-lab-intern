clear all; close all; clc;

%% 1. 파라미터 설정
BW          = 100 * 10^6;       % 대역폭 100 MHz
fc_list     = [3.5, 28.0];      % 비교할 중심 주파수 [GHz]
NF          = 7;                % 잡음 지수 7 dB
Pt_dBm      = 43;               % 기지국 섹터당 송신 전력 43 dBm
load_factor = 0.5;              % 간섭 섹터 부하율 (1.0 = 모든 섹터 상시 송신, 최악 조건)

noise_dBm = -174 + 10*log10(BW) + NF;
noise = 10^(noise_dBm / 10);

%% 2. 기지국 배치 (m 단위 직교 좌표)
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

% 학교 외부 간섭 기지국 (6개) - (36.1 + 418.1i)는 교내 기지국과 중복이라 제거
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

%% 3. 공간 모델링 (건물 좌표: [x_min, x_max, y_min, y_max])
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

step    = 2.5;                   % 격자 간격 2.5 m
x_range = -150 : step : 150;
y_range = 0    : step : 550;     % y=521.6의 기지국까지 포함
nx = length(x_range);
ny = length(y_range);

% 실내 여부 마스크 (주파수와 무관하므로 한 번만 계산)
indoor = false(ny, nx);
for ix = 1:nx
    for iy = 1:ny
        x = x_range(ix); y = y_range(iy);
        for b = 1:num_buildings
            if x >= sejong_buildings(b,1) && x <= sejong_buildings(b,2) && ...
               y >= sejong_buildings(b,3) && y <= sejong_buildings(b,4)
                indoor(iy, ix) = true;
                break;
            end
        end
    end
end

%% 4. 주파수별 SINR 격자 계산 (행: y, 열: x)
nf = length(fc_list);
SINR_grid      = cell(1, nf);   % 부하율 적용
SINR_grid_full = cell(1, nf);   % 최악 조건(부하율 1.0)

for f = 1:nf
    fc_GHz = fc_list(f);
    Gl = zeros(ny, nx);
    Gf = zeros(ny, nx);
    for ix = 1:nx
        for iy = 1:ny
            p = x_range(ix) + 1i*y_range(iy);
            d_serv = calcDist(N, p, BS_pos);
            d_intf = calcDist(N_interference, p, BS_pos_interference);

            if indoor(iy, ix)
                rx_power  = Pr_Building(N, BS_pos, p, d_serv, Pt_dBm, fc_GHz);
                rx_interf = Pr_Building(N_interference, BS_pos_interference, p, d_intf, Pt_dBm, fc_GHz);
            else
                rx_power  = Pr(N, BS_pos, p, d_serv, Pt_dBm, fc_GHz);
                rx_interf = Pr(N_interference, BS_pos_interference, p, d_intf, Pt_dBm, fc_GHz);
            end
            Gl(iy, ix) = calcSINR(rx_power, rx_interf, noise, load_factor);
            Gf(iy, ix) = calcSINR(rx_power, rx_interf, noise, 1.0);
        end
    end
    SINR_grid{f}      = Gl;
    SINR_grid_full{f} = Gf;
end

%% 5. 채널 용량 및 통계
Cap = cell(1, nf);
fprintf('=== 시뮬레이션 결과 (BW %d MHz) ===\n', BW/10^6);
for f = 1:nf
    Cap{f} = BW * log2(1 + SINR_grid{f}(:));
    Cap_full = BW * log2(1 + SINR_grid_full{f}(:));
    s1 = calcStats(Cap{f});
    s2 = calcStats(Cap_full);
    fprintf('[%.1f GHz | 부하율 %.2f] 평균 %.2f | 중앙값 %.2f | 하위5%% 평균 %.2f Mbps\n', ...
        fc_list(f), load_factor, s1(1)/1e6, s1(2)/1e6, s1(3)/1e6);
    fprintf('[%.1f GHz | 부하율 1.00] 평균 %.2f | 중앙값 %.2f | 하위5%% 평균 %.2f Mbps\n', ...
        fc_list(f), s2(1)/1e6, s2(2)/1e6, s2(3)/1e6);
end

%% 6. 결과 출력
% --- Figure 1: 주파수별 SINR 히트맵 (격자 이미지 + 건물 외곽선) ---
figure('Name', 'Step 1: Frequency Comparison', 'NumberTitle', 'off', 'Position', [100 100 1100 650]);
for f = 1:nf
    subplot(1, nf, f);
    imagesc(x_range, y_range, 10*log10(SINR_grid{f}));   % 셀 단위로 빈틈없이 채움
    set(gca, 'YDir', 'normal');
    colormap(jet); caxis([-15 25]);                        % R2022a+ 에서는 clim([-15 25]) 가능
    cb = colorbar; cb.Label.String = 'SINR (dB)';
    hold on;
    for b = 1:num_buildings
        rectangle('Position', [sejong_buildings(b,1), sejong_buildings(b,3), ...
                               sejong_buildings(b,2)-sejong_buildings(b,1), ...
                               sejong_buildings(b,4)-sejong_buildings(b,3)], ...
                  'EdgeColor', 'k', 'LineWidth', 0.8);
    end
    h_srv = plot(real(BS_pos), imag(BS_pos), '^', 'Color', 'k', 'MarkerFaceColor', 'w', ...
                 'MarkerSize', 8, 'LineWidth', 1);
    h_int = plot(real(BS_pos_interference), imag(BS_pos_interference), 'kx', ...
                 'MarkerSize', 8, 'LineWidth', 1.5);
    xlim([-210 160]); ylim([0 550]);
    daspect([1 1 1]);
    xlabel('X (m)'); ylabel('Y (m)');
    title(sprintf('%.1f GHz / %d MHz', fc_list(f), BW/10^6));
    legend([h_srv, h_int], {'Serving BS', 'Interference BS'}, 'Location', 'northoutside');
end

% --- Figure 2: 용량 CDF ---
figure('Name', 'Step 2: Capacity CDF', 'NumberTitle', 'off');
hold on;
for f = 1:nf
    h = cdfplot(Cap{f} / 10^6);
    set(h, 'LineWidth', 1.5);
end
title('Capacity CDF');
xlabel('Shannon Capacity (Mbps)'); ylabel('Probability F(c)');
legend(arrayfun(@(v) sprintf('%.1f GHz', v), fc_list, 'UniformOutput', false), 'Location', 'southeast');
grid on;

%% ------------------- 사용자 정의 함수 ------------------- %%

function s = calcStats(C)
    A = sort(C, 'ascend');
    edge_idx = max(1, round(length(C) * 0.05));
    s = [mean(C), median(C), mean(A(1:edge_idx))];   % [평균, 중앙값, 하위5% 평균]
end

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
    Am = 20;
    P = zeros(1, 3*N);
    for x = 1:N
        theta = atan2d(imag(pos-BS_pos(x)), real(pos-BS_pos(x)));
        if dist(x) <= 1
            continue;
        end
        PL = 13.54 + 39.08*log10(dist(x)) + 20*log10(fc_GHz);
        for y = 2:-1:0
            if real(pos-BS_pos(x)) >= 0
                A_loss = -1 * min(12 * ((-theta + 120*y) / 70)^2, Am);
            else
                A_loss = -1 * min(12 * ((theta + 120*y) / 70)^2, Am);
            end
            Pr_dBm = Pt_dBm - (PL + extra_loss_dB) + A_loss;
            P(3*x-y) = 10^(Pr_dBm / 10);
        end
    end
end

function SINR_result = calcSINR(rx, interference, noise, load_factor)
    X = sort(rx, 'descend');
    own_interf = sum(X) - X(1);
    ext_interf = sum(interference);
    SINR_result = X(1) / (load_factor * (own_interf + ext_interf) + noise);
end