%% ========================================================================
%  MODELO DINÂMICO DO PMSM — Implementação do Capítulo 2
%  Referência: GABBI, Thieli Smidt. "Controle por Modos Deslizantes e
%  Observador de Distúrbios Aplicados ao Motor Síncrono de Ímãs
%  Permanentes". Dissertação de Mestrado, PPGEE/UFSM, Santa Maria, 2015.
%
%  Sequência do script = sequência do capítulo:
%    1) Modelo em coordenadas abc          (Eq. 2.1 – 2.8,  p.44-45)
%    2) Transformada de Clarke (αβ)        (Eq. 2.9 – 2.19, p.46-48)
%    3) Transformada de Park (dq)          (Eq. 2.20 – 2.35, p.49-50)
%    4) Equação mecânica / conjugado       (Eq. 2.36 – 2.42, p.51-52)
%    5) Modelo de corrente para controle   (Eq. 2.43, p.52) -> Espaço de
%       Estados contínuo A(wm), B, Ed
%    6) Discretização (ZOH exato x Euler)
%    7) Validação em malha aberta
% =========================================================================
clear; clc; close all;

%%  
%  0) PARÂMETROS DO MOTOR
%  ATENÇÃO: valores ABAIXO SÃO ILUSTRATIVOS (ordem de grandeza típica
%  de um PMSM de pequeno/médio porte). SUBSTITUA pelos parâmetros reais
%  identificados/de datasheet do teu motor antes de usar os resultados
%  numéricos em qualquer análise da dissertação.
%  
Rs      = 2.875;     % [Ohm]   Resistência estatórica de fase           (Eq. 2.1)
Ls      = 8.5e-3;    % [H]     Indutância própria média (componente Ls) (Eq. 2.3)
Lm      = 0.6e-3;    % [H]     Componente de saliência (Lm=0 -> polos não salientes)
phi_srm = 0.175;     % [Wb]    Fluxo concatenado máximo dos ímãs        (Eq. 2.4)
Np      = 4;         % [-]     Número de pares de polos                 (Eq. 2.39)
Jm      = 0.8e-3;    % [kg.m^2] Momento de inércia do rotor              (Eq. 2.42)
Bv      = 1.0e-4;    % [N.m.s]  Coeficiente de atrito viscoso            (Eq. 2.42)

% Indutâncias síncronas dq a partir de Ls, Lm  (Eq. 2.30)
Ld = 1.5*(Ls - Lm);
Lq = 1.5*(Ls + Lm);
fprintf('Ld = %.6f H | Lq = %.6f H  (Ld=Lq => máquina de polos não salientes se Lm=0)\n', Ld, Lq);

%%  
%  1) MODELO EM COORDENADAS abc  (Eq. 2.1 - 2.8)
%  
% Matriz de resistências (Eq. 2.8)
Rabc = Rs*eye(3);

% Indutâncias próprias e mútuas em função do ângulo elétrico theta_e
% (Eq. 2.3). Ls/Lm entram como definidos acima; a defasagem de 2*pi/3
% entre fases segue a convenção clássica de Krause/Wasynczuk/Sudhoff
% (2002), citada no texto para máquinas de polos salientes.
%   -> Confira o sinal/defasagem exata contra a Eq. (2.3), p.46 do PDF,
%      caso o teu motor use uma convenção de eixo d diferente.
La_fun  = @(te) Ls + Lm*cos(2*te);
Lb_fun  = @(te) Ls + Lm*cos(2*te - 2*pi/3);
Lc_fun  = @(te) Ls + Lm*cos(2*te + 2*pi/3);
Mab_fun = @(te) -0.5*Ls - Lm*cos(2*te - 2*pi/3);
Mbc_fun = @(te) -0.5*Ls - Lm*cos(2*te);
Mac_fun = @(te) -0.5*Ls - Lm*cos(2*te + 2*pi/3);

Labc_fun = @(te) [La_fun(te)   Mab_fun(te)  Mac_fun(te);
                  Mab_fun(te)  Lb_fun(te)   Mbc_fun(te);
                  Mac_fun(te)  Mbc_fun(te)  Lc_fun(te)];

% Fluxo concatenado do rotor nas fases abc (Eq. 2.4)
phi_rabc_fun = @(te) phi_srm*[cos(te); cos(te - 2*pi/3); cos(te + 2*pi/3)];

% --- Demonstração: as indutâncias abc variam com a posição do rotor ---
% (este é o motivo estrutural, discutido na Seção 2.2.1, para migrar
%  do referencial abc para o referencial síncrono dq)
theta_vec = linspace(0, 2*pi, 500);
La_v = arrayfun(La_fun, theta_vec);
Lb_v = arrayfun(Lb_fun, theta_vec);
Lc_v = arrayfun(Lc_fun, theta_vec);

figure('Name','Indutancias abc (tempo-variantes)');
plot(theta_vec, La_v, 'LineWidth', 1.5); hold on;
plot(theta_vec, Lb_v, 'LineWidth', 1.5);
plot(theta_vec, Lc_v, 'LineWidth', 1.5); grid on;
xlabel('\theta_e [rad elétrico]'); ylabel('Indutância [H]');
legend('L_a(\theta_e)','L_b(\theta_e)','L_c(\theta_e)');
title('Eq. (2.3) — Indutâncias próprias abc em função de \theta_e');

%%  
%  2) TRANSFORMADA DE CLARKE (coordenadas estacionárias alpha-beta)
%     Eq. 2.9, 2.11, 2.15, 2.16, 2.18
%  
% Matriz de Clarke (Eq. 2.9) — inclui a linha de sequência zero, que é
% descartada a seguir pois o sistema é considerado equilibrado a 3 fios
% (Eq. 2.10: ia+ib+ic=0 => i0=0)
Kab = (2/3)*[1        -1/2         -1/2;
             0         sqrt(3)/2   -sqrt(3)/2;
             1/2       1/2          1/2];

% Indutância no referencial alpha-beta (Eq. 2.15) — ainda depende de
% theta_e para máquina de polos salientes (Lm ~= 0)
Lab_fun = @(te) 1.5*[Ls - Lm*cos(2*te), -Lm*sin(2*te);
                     -Lm*sin(2*te),      Ls + Lm*cos(2*te)];

% Fluxo do rotor em alpha-beta (Eq. 2.16) e f.e.m. induzida (Eq. 2.18)
phi_rab_fun = @(te) phi_srm*[cos(te); sin(te)];
e_ab_fun    = @(te, we) phi_srm*we*[-sin(te); cos(te)];

%%  
%  3) TRANSFORMADA DE PARK (coordenadas síncronas dq)
%     Eq. 2.20, 2.21, 2.28, 2.30
%  
Kdq_fun = @(te) [cos(te)  sin(te);
                 -sin(te) cos(te)];

% --- Demonstração: Ldq é CONSTANTE, independente de theta_e ---
% (este é o "ganho pedagógico" da transformada de Park: elimina a
%  dependência temporal das indutâncias, Seção 2.2.4)
fprintf('\nVerificação numérica de que Ldq = Kdq * Lab * Kdq^{-1} é constante:\n');
for te_test = [0, pi/6, pi/3, pi/2, 1.7]
    Kdq_t = Kdq_fun(te_test);
    Ldq_t = Kdq_t * Lab_fun(te_test) * Kdq_t';   % Kdq é ortogonal: Kdq^-1 = Kdq'
    fprintf('  theta_e = %5.2f rad -> Ldq = [%.6f %.6f; %.6f %.6f]\n', ...
        te_test, Ldq_t(1,1), Ldq_t(1,2), Ldq_t(2,1), Ldq_t(2,2));
end
fprintf('  (Ld, Lq calculados diretamente pela Eq. 2.30: Ld=%.6f, Lq=%.6f)\n', Ld, Lq);

% Matrizes auxiliares do modelo de tensão dq (Eq. 2.27 - 2.29)
J   = [0 -1; 1  0];
Ldq = diag([Ld, Lq]);
Rdq = Rs*eye(2);

%%  
%  4) EQUAÇÃO MECÂNICA E CONJUGADO ELETROMAGNÉTICO (Eq. 2.36 - 2.42)
%  
% Conjugado eletromagnético geral (polos salientes), Eq. 2.40:
Te_fun = @(id, iq) Np*((Ld - Lq)*id + phi_srm)*iq;
% Caso de polos não salientes (Ld = Lq), Eq. 2.41 -> relação linear com iq:
Te_naosaliente_fun = @(iq) Np*phi_srm*iq;

% Equação mecânica de movimento (Eq. 2.42):  Jm*dwm/dt = Te - Tc - Bv*wm
% (subsistema mecânico — mais lento que a dinâmica elétrica; entra no
%  modelo de corrente como parâmetro/perturbação, ver Seção "Formulação
%  de Controle" no texto de acompanhamento)

%%  
%  5) MODELO DE CORRENTE dq PARA CONTROLE — ESPAÇO DE ESTADOS CONTÍNUO
%     Eq. 2.43 (equivalente a 2.35 com we = Np*wm substituído)
%
%     Estado:   x = [id; iq]
%     Entrada:  u = [vd; vq]              (variável manipulada)
%     Parâmetro/perturbação: wm (velocidade mecânica, medida)
%
%     dx/dt = A(wm)*x + B*u + Ed*wm
%  
A_fun = @(wm) [ -Rs/Ld,            Np*wm*Lq/Ld;
                -Np*wm*Ld/Lq,      -Rs/Lq       ];

B  = [1/Ld,  0;
      0,     1/Lq];              % não depende de wm

Ed = [0;
      -Np*phi_srm/Lq];           % acoplamento da f.c.e.m. (termo de perturbação aditiva)

C = eye(2);        % saída = estados medidos diretamente (id, iq)
D = zeros(2,3);     % [vd vq wm] -> nenhuma transmissão direta

%%  
%  6) LINEARIZAÇÃO EM UM PONTO DE OPERAÇÃO E DISCRETIZAÇÃO
%  
wm0 = 100;          % [rad/s] ponto de operação nominal p/ congelar A(wm)
                     % (ajuste para a velocidade de interesse do teu ensaio)
Ts  = 100e-6;        % [s] período de amostragem (ex.: 10 kHz - ajuste ao
                     % período real do teu laço de corrente na FPGA)

A0 = A_fun(wm0);
Bu = [B, Ed];        % entrada aumentada: colunas [vd, vq, wm]

sys_c = ss(A0, Bu, C, D, ...
    'StateName', {'id','iq'}, ...
    'InputName', {'vd','vq','wm'}, ...
    'OutputName', {'id','iq'});

% --- Discretização EXATA (Zero-Order Hold) ---
sys_d_zoh = c2d(sys_c, Ts, 'zoh');
Ad_zoh = sys_d_zoh.A;
Bd_zoh = sys_d_zoh.B;

% --- Discretização por EULER (aproximação de 1a ordem) ---
% Ad = I + Ts*A ; Bd = Ts*B   (forma comumente usada em implementação
% embarcada por simplicidade computacional em FPGA/DSP)
Ad_euler = eye(2) + Ts*A0;
Bd_euler = Ts*Bu;

fprintf('\n--- Comparação de discretização (Ts = %.1f us, wm0 = %d rad/s) ---\n', Ts*1e6, wm0);
disp('Ad (ZOH exato):');   disp(Ad_zoh);
disp('Ad (Euler):');       disp(Ad_euler);
disp('Autovalores continuo (polos de A0):'); disp(eig(A0));
disp('Autovalores discreto ZOH:');           disp(eig(Ad_zoh));
disp('Autovalores discreto Euler:');         disp(eig(Ad_euler));


%  7) VALIDAÇÃO EM MALHA ABERTA — resposta ao degrau de vq
%  
t_final = 0.02;
t_c = 0:1e-6:t_final;                 % base de tempo fina p/ modelo contínuo
u_c = [zeros(1,length(t_c));          % vd = 0
       12*ones(1,length(t_c));        % vq = degrau de 12 V
       wm0*ones(1,length(t_c))];      % wm constante (congelado no ponto de operação)

y_c = lsim(sys_c, u_c', t_c);

N = floor(t_final/Ts);
t_d = (0:N-1)*Ts;
x_d = zeros(2, N);
u_d = [0; 12; wm0];
for k = 1:N-1
    x_d(:,k+1) = Ad_zoh*x_d(:,k) + Bd_zoh*u_d;
end

figure('Name','Validacao malha aberta - degrau em vq');
subplot(2,1,1);
plot(t_c*1e3, y_c(:,1), 'b-', 'LineWidth', 1.3); hold on;
stairs(t_d*1e3, x_d(1,:), 'r--', 'LineWidth', 1.1); grid on;
ylabel('i_d [A]'); legend('Continuo','Discreto (ZOH)');
title('Resposta ao degrau de v_q (Eq. 2.43) — v_d=0, v_q=12V, \omega_m=100 rad/s');

subplot(2,1,2);
plot(t_c*1e3, y_c(:,2), 'b-', 'LineWidth', 1.3); hold on;
stairs(t_d*1e3, x_d(2,:), 'r--', 'LineWidth', 1.1); grid on;
xlabel('tempo [ms]'); ylabel('i_q [A]'); legend('Continuo','Discreto (ZOH)');

fprintf('\nScript concluido. Substitua os parametros da Secao 0 pelos valores reais do motor.\n');
