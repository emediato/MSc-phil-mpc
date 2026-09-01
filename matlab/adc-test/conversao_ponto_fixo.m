%% ========================================================================
%  conversao_ponto_fixo.m
%  Conversao de sinais double -> ponto fixo, metodologia completa
%  Requer: Fixed-Point Designer (fi, numerictype, fimath)
%
%  Sequencia:
%    1) Definir os sinais em double (faixas reais do teu pipeline)
%    2) Calcular bits inteiros necessarios de forma automatica (evita o
%       erro de off-by-one: 3 bits unsigned vao de 0 a 7, nao de 0 a 8)
%    3) Converter para ponto fixo (unsigned p/ ADC bruto, signed p/ id,iq)
%    4) Demonstrar crescimento de bits em multiplicacao (Ad11 * id)
%    5) Comparar erro de quantizacao double vs. ponto fixo
%    6) Gerar tabela-resumo dos tipos de dado escolhidos
% =========================================================================
clear; clc;

%% ——————————————————————
%  0) Funcao auxiliar: bits inteiros necessarios a partir do valor maximo
%     Evita o erro comum de off-by-one (3 bits vao de 0 a 7, nao 0 a 8)
% ——————————————————————
int_bits_needed = @(maxVal) max(1, floor(log2(max(abs(maxVal), 1e-12))) + 1);

fprintf(‘Teste da funcao auxiliar (confirma a correcao do off-by-one):\n’);
fprintf(’  int_bits_needed(5) = %d  (3 bits: 0 a 7, cobre o 5)\n’, int_bits_needed(5));
fprintf(’  int_bits_needed(8) = %d  (precisa de 4 bits pra representar o 8 em si)\n\n’, int_bits_needed(8));

%% ——————————————————————
%  1) SINAIS EM DOUBLE – faixas reais do pipeline
%     (ADC bruto -> Clarke/Park -> coeficiente Ad11 do modelo de estado)
% ——————————————————————
adc_max = 5;                              % ADC bruto: 0 a 5V (unsigned)
t = linspace(0, 0.02, 2000);
adc_signal = 2.5 + 0.6*sin(2*pi*50*t);    % simula Vout do LESR (2.5V +/- swing)

id_max = 20; iq_max = 20;                 % margem operacional de corrente (A)
id_signal = 10*sin(2*pi*50*t);
iq_signal = 15*cos(2*pi*50*t);

fprintf(’=== Faixas dos sinais (double) ===\n’);
fprintf(‘ADC bruto:  [%.3f, %.3f] V\n’, min(adc_signal), max(adc_signal));
fprintf(‘id:         [%.3f, %.3f] A\n’, min(id_signal), max(id_signal));
fprintf(‘iq:         [%.3f, %.3f] A\n\n’, min(iq_signal), max(iq_signal));

%% ——————————————————————
%  2) BITS INTEIROS NECESSARIOS (automatizado)
% ——————————————————————
WORD_LENGTH = 16;   % convencao de projeto (bate com o frame UART de 16 bits)

IB_adc = int_bits_needed(adc_max);         % unsigned: so magnitude
IB_id  = int_bits_needed(id_max) + 1;      % +1 = bit de sinal (signed)
IB_iq  = int_bits_needed(iq_max) + 1;

FB_adc = WORD_LENGTH - IB_adc;
FB_id  = WORD_LENGTH - IB_id;
FB_iq  = WORD_LENGTH - IB_iq;

fprintf(’=== Alocacao de bits (word length fixo em %d) ===\n’, WORD_LENGTH);
fprintf(‘ADC bruto (unsigned): %d bits inteiros + %d fracionarios\n’, IB_adc, FB_adc);
fprintf(‘id (signed):          %d bits inteiros(c/ sinal) + %d fracionarios\n’, IB_id, FB_id);
fprintf(‘iq (signed):          %d bits inteiros(c/ sinal) + %d fracionarios\n\n’, IB_iq, FB_iq);

%% ——————————————————————
%  3) CONVERSAO PARA PONTO FIXO (numerictype + fi)
% ——————————————————————
T_adc = numerictype(0, WORD_LENGTH, FB_adc);   % 0 = unsigned
T_id  = numerictype(1, WORD_LENGTH, FB_id);    % 1 = signed
T_iq  = numerictype(1, WORD_LENGTH, FB_iq);

fm = fimath(‘RoundingMethod’, ‘Nearest’, ‘OverflowAction’, ‘Saturate’);

adc_fi = fi(adc_signal, T_adc, fm);
id_fi  = fi(id_signal,  T_id,  fm);
iq_fi  = fi(iq_signal,  T_iq,  fm);

fprintf(’=== Resolucao (LSB) resultante ===\n’);
fprintf(‘ADC bruto: %.6f V/LSB\n’, 2^(-FB_adc));
fprintf(‘id:        %.6f A/LSB\n’, 2^(-FB_id));
fprintf(‘iq:        %.6f A/LSB\n\n’, 2^(-FB_iq));

%% ——————————————————————
%  4) CRESCIMENTO DE BITS EM MULTIPLICACAO – exemplo com Ad11 * id
%     (A(1,1) = -Rs/Ld, do modelo de estado ja derivado - Eq. 2.43 Gabbi)
% ——————————————————————
Rs = 2.875; Ld = 8.925e-3;
Ad11 = -Rs/Ld;   % coeficiente da matriz de estado discreta

IB_Ad = int_bits_needed(abs(Ad11)) + 1;   % +1 = sinal
FB_Ad = WORD_LENGTH - IB_Ad;
T_Ad  = numerictype(1, WORD_LENGTH, FB_Ad);
Ad11_fi = fi(Ad11, T_Ad, fm);

% Multiplicacao SEM cuidado (trunca de volta pro mesmo tipo de id – ingenuo)
prod_naive = fi(Ad11_fi * id_fi, T_id, fm);

% Multiplicacao CORRETA: deixa o produto crescer naturalmente primeiro
prod_full = Ad11_fi * id_fi;

fprintf(’=== Crescimento de bits na multiplicacao Ad11 x id ===\n’);
fprintf(‘Tipo de Ad11 (coef.):  WordLength=%d, FractionLength=%d\n’, T_Ad.WordLength, T_Ad.FractionLength);
fprintf(‘Tipo de id:            WordLength=%d, FractionLength=%d\n’, T_id.WordLength, T_id.FractionLength);
fprintf(‘Tipo do produto pleno: WordLength=%d, FractionLength=%d (cresceu automaticamente)\n’, …
prod_full.WordLength, prod_full.FractionLength);
fprintf(‘Erro max (double vs. truncado ingenuo p/ 16 bits): %.6e\n’, max(abs(double(prod_naive) - Ad11*id_signal)));
fprintf(‘Erro max (double vs. produto pleno, sem truncar):  %.6e\n\n’, max(abs(double(prod_full)  - Ad11*id_signal)));

fprintf(‘ATENCAO: Ad11 = %.2f tem magnitude grande -> consome %d dos %d bits\n’, Ad11, IB_Ad, WORD_LENGTH);
fprintf(‘so pra parte inteira, sobrando so %d bits fracionarios (resolucao %.4f).\n’, FB_Ad, 2^(-FB_Ad));
fprintf(‘Se essa resolucao for insuficiente, considere: (a) largura maior so\n’);
fprintf(‘pra esse coeficiente, ou (b) normalizar o modelo em por-unidade antes\n’);
fprintf(‘de converter, tecnica classica em DSP de ponto fixo.\n\n’);

%% ——————————————————————
%  5) COMPARACAO DE ERRO DE QUANTIZACAO (double vs ponto fixo)
% ——————————————————————
err_adc = adc_signal - double(adc_fi);
err_id  = id_signal  - double(id_fi);
err_iq  = iq_signal  - double(iq_fi);

fprintf(’=== Erro de quantizacao (RMS / maximo) ===\n’);
fprintf(‘ADC bruto: RMS=%.2e V | max=%.2e V\n’, sqrt(mean(err_adc.^2)), max(abs(err_adc)));
fprintf(‘id:        RMS=%.2e A | max=%.2e A\n’, sqrt(mean(err_id.^2)),  max(abs(err_id)));
fprintf(‘iq:        RMS=%.2e A | max=%.2e A\n\n’, sqrt(mean(err_iq.^2)),  max(abs(err_iq)));

%% ——————————————————————
%  6) TABELA-RESUMO (documentacao para o capitulo de metodologia)
% ——————————————————————
Sinal      = {‘ADC bruto (V)’; ‘id (A)’; ‘iq (A)’; ‘Ad11 (coef.)’};
Sinal_num  = {‘unsigned’; ‘signed’; ‘signed’; ‘signed’};
WL         = [WORD_LENGTH; WORD_LENGTH; WORD_LENGTH; WORD_LENGTH];
IB         = [IB_adc; IB_id; IB_iq; IB_Ad];
FB         = [FB_adc; FB_id; FB_iq; FB_Ad];
Resolucao  = [2^(-FB_adc); 2^(-FB_id); 2^(-FB_iq); 2^(-FB_Ad)];

T = table(Sinal, Sinal_num, WL, IB, FB, Resolucao, …
‘VariableNames’, {‘Sinal’,‘Tipo’,‘WordLength’,‘BitsInteiros’,‘BitsFracionarios’,‘Resolucao_LSB’});
disp(T);

% writetable(T, ‘tabela_ponto_fixo.csv’);   % descomente pra exportar