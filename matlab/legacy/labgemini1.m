clear all; close all; clc;


%% 1. 파라미터 설정 (수식 및 단위 오류 수정 반영)
k = 1;
BW = 100 * 10^6;            % 대역폭 100 MHz (3.5 GHz 기준)
fc_GHz = 3.5;               % 중심 주파수 3.5 GHz (경로손실 GHz 단위 매칭)[cite: 3]
NF = 7;                     % Noise Figure 7 dB[cite: 3]
Pt_dBm = 43;                % 기지국 섹터당 총 송신 전력 43 dBm[cite: 3]

% 잡음 전력 수식 오류 수정: -174 + 10log10(B) + NF [dBm] -> 선형 값(mW) 변환[cite: 3]
noise_dBm = -174 + 10*log10(BW) + NF; 
noise = 10^(noise_dBm / 10); 

%% 2. 기지국 배치 (전파누리 기반 세종대학교 좌표로 수정 필요)
% 서비스 기지국 6개 좌표 (캠퍼스 내부 - 예시 좌표)[cite: 3]
BS_pos = [100+200i; 250+300i; 350+150i; 150+400i; 400+400i; 200+100i]; 
N = length(BS_pos);

% 외부 간섭 기지국 5개 좌표 (캠퍼스 외부 주변)[cite: 3]
BS_pos_interference = [-50+250i; 250+550i; 550+250i; 250-50i; -50-50i]; 
N_interference = length(BS_pos_interference);

%% 3. 공간 모델링 (세종대학교 건물 좌표 격자화)
% [x_min, x_max, y_min, y_max] 형식으로 입력
% ※ 지도 축척(예: 1좌표당 1m 등)에 맞게 실제 세종대 건물 위치로 값을 수정하세요.
sejong_buildings = [
    100, 150, 100, 150; % 광개토관 (예시)
    200, 240, 180, 220; % 대양홀 (예시)
    260, 300, 250, 280; % 학생회관 (예시)
    150, 190, 300, 340; % 군자관 (예시)
    320, 360, 150, 190; % 집현관 (예시)
    380, 420, 300, 350; % 율곡관/충무관 (예시)
    50,  90,  200, 250  % 학술정보원 (예시)
];
num_buildings = size(sejong_buildings, 1);

personX = 2.5;
personY = 2.5;

%% 4. 수신 전력 및 SINR 계산 (중복 격자 문제 및 실내 간섭 누락 해결)
for x = 0 : personX : 500
    for y = 0 : personY : 500
        pos(k) = x + y*1i;
        
        % 현재 좌표가 세종대학교 건물 내부(실내)인지 판별
        is_indoor = false;
        for b = 1:num_buildings
            if (x >= sejong_buildings(b,1) && x <= sejong_buildings(b,2) && ...
                y >= sejong_buildings(b,3) && y <= sejong_buildings(b,4))
                is_indoor = true;
                break;
            end
        end
        
        % 수신 전력 계산
        if is_indoor
            % 실내: 서비스 기지국과 외부 간섭 기지국 모두 O2I(투과 손실) 적용[cite: 3]
            rx_power = Pr_Building(N, BS_pos, pos(k), distance(N, pos(k), BS_pos), Pt_dBm, fc_GHz);
            rx_interf = Pr_Building(N_interference, BS_pos_interference, pos(k), distance(N_interference, pos(k), BS_pos_interference), Pt_dBm, fc_GHz);
        else
            % 실외: 기본 Pathloss 적용[cite: 3]
            rx_power = Pr(N, BS_pos, pos(k), distance(N, pos(k), BS_pos), Pt_dBm, fc_GHz);
            rx_interf = Pr(N_interference, BS_pos_interference, pos(k), distance(N_interference, pos(k), BS_pos_interference), Pt_dBm, fc_GHz);
        end
        
        % dBm 직접 합산 오류 방지 (선형 단위 합산 후 SINR 계산)[cite: 3]
        SNR(k) = SINR(rx_power, N, rx_interf, noise);
        k = k + 1;
    end
end

%% 5. Capacity 계산 및 통계 오류 수정
Capacity = BW * log2(1 + SNR);
Capacity_aver = mean(Capacity); 
BaseStation_efficiency = sum(Capacity) / N;

% 하위 5% (Edge User) 집계 논리 수정[cite: 3]
A = sort(Capacity, 'ascend');
edge_idx = round(length(Capacity) * 0.05);
Edge_user_C_array = A(1:edge_idx);
Edge_user_C_aver = mean(Edge_user_C_array);

fprintf('평균 채널 용량: %.2f Mbps\n', Capacity_aver / 10^6);
fprintf('Edge User 평균 채널 용량: %.2f Mbps\n', Edge_user_C_aver / 10^6);

%% 6. 결과 출력 (Colorbar 범위 고정 적용)
figure;
[SNRsort, ind] = sort(10*log10(SNR)); % dB 단위 변환 후 정렬
colormap(jet(length(SNRsort))); cmap = colormap;
pos_sorted = pos(ind);

scatter(real(pos_sorted), imag(pos_sorted), 10, cmap, 'filled');
colorbar; 
caxis([-15 25]); % 3.5GHz와 28GHz 비교를 위해 Colorbar 범위 통일[cite: 3]
hold on; grid on;
title('SINR Heatmap (Sejong Univ.)');

plot(BS_pos_interference, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
plot(BS_pos, 'b^', 'MarkerSize', 10, 'LineWidth', 2);
legend('Users', 'Interference BS', 'Serving BS');

figure;
cdfplot(Capacity / 10^6);
title('Capacity CDF'); xlabel('Capacity (Mbps)'); ylabel('Probability');

%% ------------------- 사용자 정의 함수 ------------------- %%

function distance_result = distance(N, pos, BS_pos)
    BaseStation_h = 25; % 기지국 높이 25m[cite: 3]
    person_h = 1.5;     % 단말 높이 1.5m[cite: 3]
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
                % TR 38.901 Pathloss (GHz 단위 적용 수정)[cite: 3]
                PL = 13.54 + 39.08*log10(dist(x)) + 20*log10(fc_GHz);
                
                if real(pos-BS_pos(x)) >= 0  
                    A_loss = -1 * min(12 * ((-theta(x) + 120*y) / 70)^2, Am);
                else  
                    A_loss = -1 * min(12 * ((theta(x) + 120*y) / 70)^2, Am);
                end
                
                Pr_dBm = Pt_dBm - PL + A_loss;
                Pr_result(3*x-y) = 10^(Pr_dBm / 10); % mW 선형 변환[cite: 3]
            end
        end
    end
end

function PrBuilding_result = Pr_Building(N, BS_pos, pos, dist, Pt_dBm, fc_GHz)
    Am = 20;
    PrBuilding_result = zeros(1, 3*N);
    
    % 실내 투과 손실(O2I) 괄호 오류 수정 (TR 38.901 Low-loss 모델)[cite: 3]
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
    I = sum(interference); % 간섭 전력 선형 스케일(mW) 합산[cite: 3]
    X = sort(x, 'descend');
    y = sum(X) - X(1); % 접속하지 않은 타 섹터의 신호도 간섭(y)으로 합산[cite: 3]
    SINR_result = X(1) / (y + I + noise); 
end