clear all; close all; clc;

%% 1. 파라미터 설정 (프로젝트 1단계 조건: 3.5GHz / 100MHz)
k = 1;
BW = 100 * 10^6;            % 대역폭 100 MHz
fc_GHz = 3.5;               % 중심 주파수 3.5 GHz
NF = 7;                     % 잡음 지수 (Noise Figure) 7 dB[cite: 7]
Pt_dBm = 43;                % 기지국 섹터당 총 송신 전력 43 dBm[cite: 5, 7]

% 잡음 전력 수식 수정 (-174 + 10log10(B) + NF) 및 선형 값 변환[cite: 7]
noise_dBm = -174 + 10*log10(BW) + NF; 
noise = 10^(noise_dBm / 10); 

%% 2. 기지국 배치 (추후 전파누리 스펙트럼맵 기준으로 좌표 수정 필요)
%% 2. 기지국 배치 (실제 경위도를 m 단위 직교 좌표로 변환 완료)
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

% 학교 외부 간섭 기지국 (7개)
BS_pos_interference = [
  -101.6 + 81.4i;
  -149.0 + 335.7i;
  -151.4 + 370.6i;
  -143.8 + 409.7i;
    36.1 + 418.1i;
    94.1 + 505.8i;
  -196.7 + 476.9i
]; 
N_interference = length(BS_pos_interference);

%% 3. 공간 모델링 (직접 측정한 세종대학교 건물 좌표 입력)
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

personX = 2.5; % 2.5m 간격 배치[cite: 5]
personY = 2.5;

%% 4. 수신 전력 및 SINR 계산 (실내 간섭 누락 및 중복 격자 해결)[cite: 7]
% x축 탐색 범위를 표의 최소값(-120.7)을 덮을 수 있도록 -150부터 시작
for x = -150 : personX : 150
    for y = 0 : personY : 500
        pos(k) = x + y*1i;
        
        % 현재 좌표가 세종대학교 실내인지 판별
        is_indoor = false;
        for b = 1:num_buildings
            if (x >= sejong_buildings(b,1) && x <= sejong_buildings(b,2) && ...
                y >= sejong_buildings(b,3) && y <= sejong_buildings(b,4))
                is_indoor = true;
                break;
            end
        end
        
        % 수신 전력 계산 (실내일 경우 간섭 기지국에도 O2I 투과손실 일관성 적용)[cite: 7]
        if is_indoor
            rx_power = Pr_Building(N, BS_pos, pos(k), distance(N, pos(k), BS_pos), Pt_dBm, fc_GHz);
            rx_interf = Pr_Building(N_interference, BS_pos_interference, pos(k), distance(N_interference, pos(k), BS_pos_interference), Pt_dBm, fc_GHz);
        else
            rx_power = Pr(N, BS_pos, pos(k), distance(N, pos(k), BS_pos), Pt_dBm, fc_GHz);
            rx_interf = Pr(N_interference, BS_pos_interference, pos(k), distance(N_interference, pos(k), BS_pos_interference), Pt_dBm, fc_GHz);
        end
        
        % dBm 직접 합산 불가 규칙 적용: 선형 단위(mW)로 합산 후 SINR 계산[cite: 7]
        SNR(k) = SINR(rx_power, N, rx_interf, noise);
        k = k + 1;
    end
end

%% 5. 채널 용량(Capacity) 및 통계 계산
Capacity = BW * log2(1 + SNR); % C = B*log2(1+SINR)[cite: 7]

Capacity_median = median(Capacity); % 중앙값(50%) 전송률[cite: 7]
Capacity_aver = mean(Capacity);

% 하위 5% (Edge User) 집계 오류 수정[cite: 7]
A = sort(Capacity, 'ascend');
edge_idx = round(length(Capacity) * 0.05);
Edge_user_C_array = A(1:edge_idx);
Edge_user_C_aver = mean(Edge_user_C_array);

fprintf('=== 시뮬레이션 결과 (%.1f GHz / %d MHz) ===\n', fc_GHz, BW/(10^6));
fprintf('평균 전송률: %.2f Mbps\n', Capacity_aver / 10^6);
fprintf('중앙값(50%%) 전송률: %.2f Mbps\n', Capacity_median / 10^6);
fprintf('하위 5%%(Edge User) 평균 전송률: %.2f Mbps\n', Edge_user_C_aver / 10^6);

%% 6. 결과 출력: SINR Heatmap 및 Capacity CDF[cite: 7]
figure;
[SNRsort, ind] = sort(10*log10(SNR)); % 선형값을 dB 단위로 변환 후 시각화
colormap(jet(length(SNRsort))); cmap = colormap;
pos_sorted = pos(ind);

scatter(real(pos_sorted), imag(pos_sorted), 15, cmap, 'filled');
cb = colorbar; 
cb.Label.String = 'SINR (dB)';
caxis([-15 25]); % 3.5GHz와 28GHz 공정 비교를 위해 색상 범례 고정[cite: 7]
hold on; grid on;
title(sprintf('SINR Heatmap (Sejong Univ. - %.1f GHz)', fc_GHz));

plot(BS_pos_interference, 'kx', 'MarkerSize', 10, 'LineWidth', 2);
plot(BS_pos, 'b^', 'MarkerSize', 10, 'LineWidth', 2);
legend('Users', 'Interference BS', 'Serving BS', 'Location', 'bestout');

figure;
cdfplot(Capacity / 10^6);
title(sprintf('Capacity CDF (%.1f GHz)', fc_GHz)); 
xlabel('Shannon Capacity (Mbps)'); ylabel('Probability F(c)');
grid on;

%% ------------------- 사용자 정의 함수 ------------------- %%

function distance_result = distance(N, pos, BS_pos)
    BaseStation_h = 25; % 기지국 높이 25m[cite: 5]
    person_h = 1.5;     % 단말 높이 1.5m[cite: 5]
    for n=1:N
        distance_result(n) = (real(pos-BS_pos(n)))^2 + (imag(pos-BS_pos(n)))^2 + (BaseStation_h-person_h)^2;
    end
    distance_result = sqrt(distance_result);
end

function Pr_result = Pr(N, BS_pos, pos, dist, Pt_dBm, fc_GHz)
    Am = 20;
    Pr_result = zeros(1, 3*N);
    for x=1:N
        theta(x) = atan2d(imag(pos-BS_pos(x)), real(pos-BS_pos(x)));
        if dist(x) <= 1
            Pr_result(3*x-2:3*x) = 0;
        else
            for y=2:-1:0
                % Pathloss (GHz 단위 적용)[cite: 7]
                PL = 13.54 + 39.08*log10(dist(x)) + 20*log10(fc_GHz);
                
                if real(pos-BS_pos(x)) >= 0  
                    A_loss = -1 * min(12 * ((-theta(x) + 120*y) / 70)^2, Am);
                else  
                    A_loss = -1 * min(12 * ((theta(x) + 120*y) / 70)^2, Am);
                end
                
                Pr_dBm = Pt_dBm - PL + A_loss;
                Pr_result(3*x-y) = 10^(Pr_dBm / 10); % 선형 스케일(mW) 변환[cite: 7]
            end
        end
    end
end

function PrBuilding_result = Pr_Building(N, BS_pos, pos, dist, Pt_dBm, fc_GHz)
    Am = 20;
    PrBuilding_result = zeros(1, 3*N);
    
    % 실외 -> 실내 투과손실(O2I) 괄호 오류 수정[cite: 7]
    L_glass = 2 + 0.2 * fc_GHz;
    L_concrete = 5 + 4 * fc_GHz;
    O2I_loss = 5 - 10*log10(0.3 * 10^(-L_glass/10) + 0.7 * 10^(-L_concrete/10));

    for x=1:N
        theta(x) = atan2d(imag(pos-BS_pos(x)), real(pos-BS_pos(x)));
        if dist(x) <= 1
            PrBuilding_result(3*x-2:3*x) = 0;
        else
            for y=2:-1:0
                PL = 13.54 + 39.08*log10(dist(x)) + 20*log10(fc_GHz);
                
                if real(pos-BS_pos(x)) >= 0  
                    A_loss = -1 * min(12 * ((-theta(x) + 120*y) / 70)^2, Am);
                else  
                    A_loss = -1 * min(12 * ((theta(x) + 120*y) / 70)^2, Am);
                end
                
                Pr_dBm = Pt_dBm - (PL + O2I_loss) + A_loss;
                PrBuilding_result(3*x-y) = 10^(Pr_dBm / 10);
            end
        end
    end
end

function SINR_result = SINR(x, N, interference, noise)
    I = sum(interference); % 외부 간섭섹터 선형 전력 합산[cite: 7]
    X = sort(x, 'descend');
    y = sum(X) - X(1); % 접속하지 않은 자국 섹터의 신호도 간섭으로 처리[cite: 5, 7]
    SINR_result = X(1) / (y + I + noise); 
end