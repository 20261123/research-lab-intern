clear all; close all; clc; %e is shorthan2,kd for *10^.
k = 1;
noise_dB=-174*1000;
noise=db2pow(noise_dB);
BW = 5*10^6;
BS_pos_interference=[-120-150*i;-170+340*i;-220+720*i;220+800*i;380+70*i];N_interference=length(BS_pos_interference);


%발표용 EdgeUser최대
% BS_pos=[60+300*i;90+602.5*i;200+230*i;185+42.5*i;200+400*i;530+400*i;370+490*i;380+320*i;65+115*i;97.5-57.5*i;97.5+470*i;240+575*i]; N=length(BS_pos);
%포스터
% BS_pos=[60+300*i;125+602.5*i;230+205*i;185+42.5*i;200+400*i;530+400*i;370+490*i;380+320*i;65+115*i;97.5-57.5*i]; N=length(BS_pos);
%표준
% BS_pos=[60+280*i;150+602.5*i;230+205*i;185+42.5*i;230+340*i;552.5+440*i]; N=length(BS_pos);
%표준개선
BS_pos=[60+280*i;150+602.5*i;115+42.5*i;230+340*i;390+500*i;450+300*i]; N=length(BS_pos);



personX=2.5;
personY=2.5;
for x = 0 : personX : 200
    
    for y = 0 : personY : 680
        pos(k) = (x) +(y)*j;
        SNR(k) = SINR(Pr(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
        if x>=170%대학본부            
            if x<=200
                
                if y>=20                    
                    if y<=65
                        
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=140 %자연과학관
            if x<=160
                if y>=135
                    if y<=270
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=30 %실내체육관
            if x<=90
                if y>=260
                    if y<=300
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=50%의료과학관
            if x<=110
                if y>=440
                    if y<=455
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=140%학생회관
            if x<=175
                if y>=300
                    if y<=360
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=130 %공자 아카데미
            if x<=170
                if y>=435
                    if y<=455
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=140 %우체국
            if x<=160
                if y>=475
                    if y<=515
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=125 %한마루
            if x<=165
                if y>=540
                    if y<=565
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=130 %학성사 3관
            if x<=170
                if y>=595
                    if y<=610
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=65 %생활관 2관
            if x<=115
                if y>=575
                    if y<=590
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=10 %학성사 1관
            if x<=60
                if y>=585
                    if y<=600
                        SNR(k) = SINR(Pr_Building(N,BS_pos,pos(k),distance(N,pos(k),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k),distance(N_interference,pos(k),BS_pos_interference)),noise);
                    end
                end
            end
        end
                                
        k = k + 1;
        
    end
    
end
k2=k+1;
for y = 240:2.5:570
    
    for x=200:2.5:560
        
        pos(k2) = (x) +(y)*j;
        
        SNR(k2) = SINR(Pr(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
        

        
        if x>=230 %공학관 
            if x<=285
                if y>=295
                    if y<=385
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=295 %향설생활관 1
            if x<=355
                if y>=275
                    if y<=330
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=420 %향설생활관2
            if x<=475
                if y>=315
                    if y<=410
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=505 %글로벌빌리지         
            if x<=560
                if y>=295
                    if y<=375
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=500 %향설생활관 3
            if x<=535
                if y>=400
                    if y<=490
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=295 %유니토피아관
            if x<=350
                if y>=400
                    if y<=465
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=365 %앙뜨레프레너관
            if x<=410
                if y>=450
                    if y<=470
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=230 %산학협력관
            if x<=255
                if y>=440
                    if y<=495
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=235 %지역혁신관
            if x<=265
                if y>=520
                    if y<=560
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=285 %학예관
            if x<=360
                if y>=495
                    if y<=530
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        
        if x>=375 %멀티미디어관
            if x<=430
                if y>=505
                    if y<=535
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end
        if x>=30
            if x<=90
                if y>=260
                    if y<=300
                        SNR(k2) = SINR(Pr_Building(N,BS_pos,pos(k2),distance(N,pos(k2),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k2),distance(N_interference,pos(k2),BS_pos_interference)),noise);
                    end
                end
            end
        end



k2 = k2 + 1;
    end
    
end

k3=1+k2;
for y = 0:-2.5:-100%인문과학관
    
    for x=40:2.5:160
        
        pos(k3) = (x) +(y)*j;
        SNR(k3) = SINR(Pr(N,BS_pos,pos(k3),distance(N,pos(k3),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k3),distance(N_interference,pos(k3),BS_pos_interference)),noise);
        if x>=65
            if x<=135
                if y>=-85
                    if y<=-30
                        
        
        SNR(k3) = SINR(Pr_Building(N,BS_pos,pos(k3),distance(N,pos(k3),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k3),distance(N_interference,pos(k3),BS_pos_interference)),noise);
                    end
                end
            end
        end
        k3 = k3 + 1;
    end
    
end
k4=k3+1;
for y = 190:2.5:240%도서관
    
    for x=200:2.5:260
        
        pos(k4) = (x) +(y)*j;
        
        SNR(k4) = SINR(Pr_Building(N,BS_pos,pos(k4),distance(N,pos(k4),BS_pos)),N,Pr(N_interference,BS_pos_interference,pos(k4),distance(N_interference,pos(k4),BS_pos_interference)),noise);
        
        k4 = k4 + 1;
    end
    
end


% Capacity 계산부분
Capacity=(BW*log2(1+SNR));
Capacity_aver=sum(Capacity)./length(SNR)
BaseStation_efficiency=sum(Capacity)./N

A=sort(Capacity,'ascend');
for xx=1:1:round(length(Capacity)*0.05)
    
   Edge_user_C=A(xx);
   
end

Edge_user_C_aver=sum(Edge_user_C)./round(length(Capacity)*0.05)

figure();
cdfplot(Capacity)



%%%그림 출력%%%%%%%%%%%
figure;

[SNRsort, ind] = sort(SNR);

colormap(jet(length(SNRsort)));cmap = colormap;

pos = pos(ind);

scatter(real(pos),imag(pos),10,cmap,'filled')
hold on; grid on;

plot(BS_pos_interference,'rx');
plot(BS_pos(1:N),'bx');



function BS_pos1=BaseStation1(N)%구역 1 기지국 위치함수
k=1;
N1=250./(N+1);
N2=630./(2*(N)+1);
if N==0
    BS_pos1=100000000;
else
    for x=1:1:N
        for y=1:1:2*N
            BS_pos1(k)=(x*N1)+(y*N2)*i;
            k=k+1;
        end
    end
end

end

function BS_pos2=BaseStation2(N)%구역2 기지국 위치함수
k=1;
if N==1
    BS_pos2=[280+340*i];
elseif N==2
    BS_pos=[100+340*i;380+355*i];

else
    N2=345./(sqrt(N)+1);
    
    for x=1:1:sqrt(N)
        for y=1:1:sqrt(N)
            BS_pos2(k)=(x*N2+200)+(y*N2+240)*i;
            k=k+1;
        end
    end
    
end
end

function BS_pos=BaseStation(BS_pos1,BS_pos2) %1구역 2구역 기지국 합성
BS_pos=BS_pos1;
for x=length(BS_pos1)+1:1:length(BS_pos)+length(BS_pos2)
    BS_pos(x)=BS_pos2(x-length(BS_pos1));
end
end

function distance_result=distance(N,pos,BS_pos)
BaseStation=20;
person=1.5;

for n=1:1:N
    distance_result(n)=(real(pos-BS_pos(n)))^2+(imag(pos-BS_pos(n)))^2+(BaseStation-person)^2;
end

distance_result=sqrt(distance_result);


end

function PrBuilding_result=Pr_Building(N,BS_pos,pos,distance)
%거리를 받아서 거리가 1이하인 경우 결과값은 0
Pt_dB_Hz=-24;
fc=4*10^9;%중심주파수
c=3*10^8;
Am=20;
f=4;

for x=1:1:N
    theta(x)=atan2d(real(pos-BS_pos(x)),imag(pos-BS_pos(x)));%pos는 사용자 BS_pos는 기지국
    if distance(x)<=1
        PrBuilding_result(3*x)=0;
        PrBuilding_result(3*x-1)=0;
        PrBuilding_result(3*x-2)=0;
    else
        
        if real(pos-BS_pos(x))>=0  %1,4사분면
            for y=2:-1:0
                PrBuilding_result(3*x-y)=Pt_dB_Hz-(13.54+39.08*log10(distance(x))+20*log10(fc)+5-10*log10(0.3*10.^((-2-0.2*f)./10))+0.7*10.^((-5-4*f)./10));
                A(3*x-y)=-1*min(12*((-theta(x)+120*y)/70).^2,Am);
                PrBuilding_result(3*x-y)=PrBuilding_result(3*x-y)+A(3*x-y);
                PrBuilding_result(3*x-y)=10.^(PrBuilding_result(3*x-y)./10);
            end
            
        else  %2,3분면
            for y=2:-1:0
                PrBuilding_result(3*x-y)=Pt_dB_Hz-(13.54+39.08*log10(distance(x))+20*log10(fc)+5-10*log10(0.3*10.^((-2-0.2*f)./10))+0.7*10.^((-5-4*f)./10));
                A(3*x-y)=-1*min(12*((theta(x)+120*y)/70).^2,Am);
                PrBuilding_result(3*x-y)=PrBuilding_result(3*x-y)+A(3*x-y);
                PrBuilding_result(3*x-y)=10.^(PrBuilding_result(3*x-y)./10);
            end
            
        end
        
    end
    
end

end

function Pr_result=Pr(N,BS_pos,pos,distance)
%거리를 받아서 거리가 1이하인 경우 결과값은 0
Pt_dB_Hz=-24;
fc=4*10^9;%중심주파수
c=3*10^8;
Am=20;


for x=1:1:N
    theta(x)=atan2d(real(pos-BS_pos(x)),imag(pos-BS_pos(x)));%pos는 사용자 BS_pos는 기지국
    if distance(x)<=1
        Pr_result(3*x)=0;
        Pr_result(3*x-1)=0;
        Pr_result(3*x-2)=0;
    else
        
        if real(pos-BS_pos(x))>=0  %1,4사분면
            for y=2:-1:0
                Pr_result(3*x-y)=Pt_dB_Hz-(13.54+39.08*log10(distance(x))+20*log10(fc));
                A(3*x-y)=-1*min(12*((-theta(x)+120*y)/70).^2,Am);
                Pr_result(3*x-y)=Pr_result(3*x-y)+A(3*x-y);
                Pr_result(3*x-y)=10.^(Pr_result(3*x-y)./10);
            end
            
        else  %2,3분면
            for y=2:-1:0
                Pr_result(3*x-y)=Pt_dB_Hz-(13.54+39.08*log10(distance(x))+20*log10(fc));
                A(3*x-y)=-1*min(12*((theta(x)+120*y)/70).^2,Am);
                Pr_result(3*x-y)=Pr_result(3*x-y)+A(3*x-y);
                Pr_result(3*x-y)=10.^(Pr_result(3*x-y)./10);
            end
            
        end
        
    end
    
end

end

function SINR_result=SINR(x,N,interference,noise)
%Pr의 크기를 내림차순으로 정리해서 가장 큰 값은 분자로 나머지 요소들은
%합해서 분모로보낸다

I=sum(interference);
X=sort(x,'descend');

y=sum(X)-X(1);

SINR_result=X(1)./(y+I+noise);


end