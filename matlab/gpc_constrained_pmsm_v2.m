% GPC MIMO constrained - salient IPMSM (Ld != Lq) current control in the dq frame.

% Parameters from Busarello (2025), Tab. IPMSM (Case 1 / Case 2 selectable).
% Intended context: pHIL (this dq IPMSM is the plant seen by the current loop).

clear all
close all
clc

% Case selector (Busarello 2025, Tab. IPMSM)
caso = 1;    % 1 or 2

switch caso
    case 1
        Rs       = 1.3;       % stator resistance [ohm]
        Ld       = 8.9e-3;    % d-axis inductance [H]
        Lq       = 17.2e-3;   % q-axis inductance [H]
        lambda_m = 0.1819;    % PM flux linkage [Wb]
        P_poles  = 6;         % number of poles
        J        = 0.0206;    % moment of inertia [kg m^2]
        Bf       = 0.0100;    % friction coefficient [N m/(rad/s)]
    case 2
        Rs       = 1.2;
        Ld       = 5.7e-3;
        Lq       = 12.0e-3;
        lambda_m = 0.1230;
        P_poles  = 4;
        J        = 0.0005;
        Bf       = 0.0001;
end

p = P_poles/2;      % pole pairs (P is the NUMBER OF POLES in the table)

% Drive
Vdc = 500;          % DC-link voltage [V]
fsw = 10e3;         % switching frequency [Hz]

% Operating point (dq model is LPV; w_e frozen here)
n_rpm = 1000;                 % rotor speed [rpm]
w_mec = n_rpm*2*pi/60;        % mechanical speed [rad/s]
w_e   = p*w_mec;              % electrical speed [rad/s]

% Sampling
f_control_gpc = 10e3;         % GPC control frequency [Hz] (here synced to fsw)
Ts_pwm        = 1/fsw;
Ts_control    = 1/f_control_gpc;
Ts            = Ts_control;   % control/prediction sampling period [s]

%% Sistema MIMO - Modelo GPC
%
% Model note (IPMSM vs surface PMSM): because Ld ~= Lq the dq cross-coupling is
% ASYMMETRIC (w_e*Lq/Ld and w_e*Ld/Lq) and the input matrix uses 1/Ld, 1/Lq
% separately. The reluctance torque (Ld-Lq)*id*iq is nonzero, so MTPA uses id*<0.


% Note: J and Bf belong to the MECHANICAL/speed model (used by the pHIL real-time
% model to produce w_e). The current-loop plant below does not use them.

% Continuous-time salient IPMSM model in the rotor dq frame (Ld ~= Lq):
%   did/dt = -Rs/Ld*id + (w_e*Lq/Ld)*iq + (1/Ld)*vd
%   diq/dt = -(w_e*Ld/Lq)*id - Rs/Lq*iq + (1/Lq)*vq - (w_e*lambda_m/Lq)
I2  = eye(2);
Fc  = [ -Rs/Ld,        w_e*Lq/Ld;
        -w_e*Ld/Lq,   -Rs/Lq       ];   % asymmetric coupling
Gc  = [ 1/Ld,  0;
        0,     1/Lq ];                  % Ld, Lq separate
Bqc = [0; -1/Lq];                       % disturbance d = w_e*lambda_m on q-axis

disp('Continuous state matrix Fc (asymmetric dq cross-coupling):'); disp(Fc);

% Discretization (ZOH). Disturbance shares the plant dynamics Fc.
Gp_c = ss(Fc, Gc,  I2, 0);
Gq_c = ss(Fc, Bqc, I2, 0);

Gz  = c2d(tf(Gp_c), Ts, 'zoh');
Gqz = c2d(tf(Gq_c), Ts, 'zoh');

z = tf('z', Ts);
delays   = [z^-1, z^-1;  z^-1, z^-1];   % n x m
delays_q = [z^-1;  z^-1];               % n x mq
Gz  = Gz  .* delays;
Gqz = Gqz .* delays_q;

sys = minreal(ss([Gz, Gqz]));

% MIMO GPC dimensions
m  = 2;   n  = 2;   mq = 1;
A  = sys.A;
B  = sys.B(:,1:m);
Bq = sys.B(:,m+1:end);
C  = sys.C;
Cq = sys.D(:,m+1:end);

% GPC tuning (tau_q up to ~13 ms: N2 and control rate are the main knobs)
N1 = [2,2];  N2 = [20,20];  Ny = N2-N1+1;  Nu = [5,5];  Nq = 1;
delta  = [8,8]./Ny;
lambda = [2,2]./Nu;
af = 0;

Umax  = [Vdc/2, Vdc/2];   Umin  = -Umax;
dumax = [100, 100];       dumin = -dumax;
ymax  = [30, 30];         ymin  = [-30, -30];   % set to rated current
psi   = [0 0 1000 1000];

% GPC matrices (structure unchanged - generalize to any m,n,mq)
temp1 = 0; F = []; Ii = [];
for i=1:max(N2)
    temp1 = temp1 + A^i;
    F  = [F; C*temp1, -C*temp1];
    Ii = [Ii; eye(n)];
end
Fq = [C*Bq+Cq, -C*Bq];
temp1 = eye(size(A));
for i=1:max(N2)-1
    temp1 = temp1 + A^i;
    Fq = [Fq; C*temp1*Bq+Cq, -C*temp1*Bq];
end
G0 = []; temp1 = eye(size(A));
for i=1:max(N2)
    G0 = [G0; C*temp1*B];
    temp1 = temp1 + A^i;
end
G = G0;
for i=1:max(Nu)-1
    G = [G, [zeros(i*n,m); G0(1:end-i*n,:)]];
end
G0q = [Cq]; temp1 = eye(size(A));
for i=1:max(N2)-1
    G0q = [G0q; C*temp1*Bq+Cq];
    temp1 = temp1 + A^i;
end
Gq = [];
for i=0:Nq-1
    Gq = [Gq, [zeros(i*n,mq); G0q(1:end-i*n,:)]];
end
Qei = diag(delta); Qe = [];
for i=1:max(N2), Qe = blkdiag(Qe, Qei); end
Qui = diag(lambda); Qu = [];
for i=1:max(Nu), Qu = blkdiag(Qu, Qui); end
Qpsi = [];
for i=3:4, Qpsi = blkdiag(Qpsi, psi(i)); end

indc = [];
for i=1:m, indc = [indc, i:m:(Nu(i)-1)*m+i]; end
indc = sort(indc);
indcq = [];
for i=1:mq, indcq = [indcq, i:mq:(Nq(i)-1)*mq+i]; end
indcq = sort(indcq);
indl = [];
for i=1:n, indl = [indl, (N1(i)-1)*n+i:n:(N2(i)-1)*n+i]; end
indl = sort(indl);

F  = F(indl,:);  Ii = Ii(indl,:);  Fq = Fq(indl,:);  G = G(indl,indc);
if(max(Nq)>0), Gq = Gq(indl,indcq); end
Qu = Qu(indc,indc);  Qe = Qe(indl,indl);

Kmpc  = (G'*Qe*G+Qu)\(G'*Qe);   Kmpc1 = Kmpc(1:m,:);
Hqp   = 2*(G'*Qe*G+Qu);         fqp1  = -2*G'*Qe;

LB = repmat(dumin', max(Nu), 1); LB = LB(indc,:);
UB = repmat(dumax', max(Nu), 1); UB = UB(indc,:);
I = eye(m); T = [];
for i=1:max(Nu)
    T = [T; repmat(I,1,i), zeros(m, max(Nu)*m-i*m)];
end
T = T(indc,indc);
Rbar = [T; -T; G; -G];
y_rbarmax = [repelem(ymax(1),Ny(1),1); repelem(ymax(2),Ny(2),1)];
y_rbarmin = [repelem(-ymin(1),Ny(1),1); repelem(-ymin(2),Ny(2),1)];

% Simulation
nin = 10;  nit = nin + 150;
refs  = zeros(n, nit);  perts = zeros(mq, nit);
% id* = 0 baseline; for MTPA on this salient machine set id*<0 from
% Te = 1.5*p*(lambda_m*iq + (Ld-Lq)*id*iq).
refs(1, nin+10:end) = 0;
refs(2, nin+50:end) = 10;
perts(1, :) = w_e*lambda_m;              % back-EMF measured disturbance

estados  = zeros(size(A,1), nit+2);
saidas   = zeros(n, nit);
entradas = zeros(m, nit);
du       = zeros(m, nit);
rfant    = zeros(n, 1);

for k = nin+1:nit
    saidas(:,k) = C*estados(:,k);        % measure current state

    rf = af*rfant + (1-af)*refs(:,k);  rfant = rf;
    R = repmat(rf, max(N2), 1);  R = R(indl,:);

    f = Ii*saidas(:,k) + F*[estados(:,k); estados(:,k-1)] ...
        + Fq*[perts(:,k); perts(:,k-1)];      % back-EMF feedforward

    rbarmax = repmat(Umax'-entradas(:,k-1), max(Nu), 1);
    rbarmin = repmat(-Umin'+entradas(:,k-1), max(Nu), 1);
    rbar = [rbarmax(indc,:); rbarmin(indc,:); y_rbarmax - f; y_rbarmin + f];

    fqp   = fqp1*(R - f);
    duOti = quadprog(Hqp, fqp, Rbar, rbar, [], [], LB, UB);
    if isempty(duOti), du(:,k) = du(:,k-1); else, du(:,k) = duOti(1:m); end
    entradas(:,k) = du(:,k) + entradas(:,k-1);

    % OPTION A: advance ONE step with the control just computed
    estados(:,k+1) = A*estados(:,k) + B*entradas(:,k) + Bq*perts(:,k);
end

theta_now = w_e*(nit*Ts_control);
[v_abc_pwm, duty_pwm, gates_pwm, t_pwm] = ...
    applyPWM(entradas(1,nit), entradas(2,nit), theta_now, w_e, Ts_control, Ts_pwm, fsw, Vdc);

figure;
subplot(3,1,1);
plot(saidas(1,nin+1:nit)','LineWidth',2); hold on;
plot(saidas(2,nin+1:nit)','LineWidth',2);
plot(refs(:,nin+1:nit)','--','LineWidth',1.5);
ylabel('Currents [A]'); legend('i_d','i_q','refs','Location','SouthEast');
title(sprintf('GPC current control - salient IPMSM (Case %d, L_q/L_d = %.2f)', caso, Lq/Ld));
grid on;
subplot(3,1,2);
plot(entradas(1,nin+1:nit)','LineWidth',2); hold on;
plot(entradas(2,nin+1:nit)','LineWidth',2);
ylabel('Voltages [V]'); legend('v_d','v_q','Location','SouthEast'); grid on;
subplot(3,1,3);
plot(du(1,nin+1:nit)','LineWidth',2); hold on;
plot(du(2,nin+1:nit)','LineWidth',2);
ylabel('\Delta v [V]'); xlabel('control step');
legend('\Delta v_d','\Delta v_q','Location','SouthEast'); grid on;
set(gcf,'Color','white');

function [v_abc, duty, gates, t_pwm] = applyPWM(vd, vq, theta, omega, Ts_control, Ts_pwm, fsw, Vdc)
    ratio = max(round(Ts_control / Ts_pwm), 1);
    t_pwm = (0:ratio-1)*Ts_pwm;
    Kinv = [1 0; -1/2 sqrt(3)/2; -1/2 -sqrt(3)/2];
    v_abc = zeros(3, ratio);  duty = zeros(3, ratio);  gates = zeros(3, ratio);
    for j = 1:ratio
        th = theta + omega*t_pwm(j);
        v_al = cos(th)*vd - sin(th)*vq;
        v_be = sin(th)*vd + cos(th)*vq;
        vabc = Kinv * [v_al; v_be];
        v_abc(:,j) = vabc;
        d = min(max(0.5 + vabc/Vdc, 0), 1);
        duty(:,j) = d;
        carrier = 0.5 + 0.5*sawtooth(2*pi*fsw*t_pwm(j), 0.5);
        gates(:,j) = d > carrier;
    end
end