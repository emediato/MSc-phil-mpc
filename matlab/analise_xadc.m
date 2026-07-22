function analise_xadc(pasta)
% ANALISE_XADC  Analisa CSVs do ILA (Basys3 XADC) SEM circuito de
% condicionamento: compara o sinal conhecido injetado direto no XADC com o
% que foi medido, caracteriza o ADC cru e DIMENSIONA o condicionador
% necessario (ganho, offset e resolucao resultante).
%
% Formato do CSV (2 linhas de cabecalho, codigo em HEX, cap_v em HEX):
%   Sample in Buffer, Sample in Window, TRIGGER, codigo[11:0], cap_v
%
% Uso:
%   analise_xadc                 % pasta atual
%   analise_xadc('caminho')
%
% Preencha o bloco SINAL INJETADO com o que voce sabe do gerador.

if nargin < 1, pasta = pwd; end

% ================= XADC (fixo) =========================================
TS      = 50e-6;      % intervalo entre amostras (s) = decimacao do top.vhd
NBITS   = 12;
VREF    = 1.0;        % fundo de escala do XADC unipolar (V) -> 4096 codigos
CODE_FS = 2^NBITS;

% ================= SINAL INJETADO (o que voce SABE do gerador) =========
% Valores lidos no OSCILOSCOPIO (nao no display do gerador).
SIG_AVG_V = 0.550;   % nivel medio / offset do sinal injetado (V)
SIG_AMP_V = 0.900;   % amplitude (V)
AMP_IS_PP = false;   % false = amplitude (pico); true = pico-a-pico

% ================= FAIXA-ALVO do XADC apos condicionamento =============
TGT_LOW  = 0.10;     % V (borda inferior desejada; margem contra saturacao)
TGT_HIGH = 0.90;     % V (borda superior desejada)
% =======================================================================

if AMP_IS_PP, sig_amp = SIG_AMP_V/2; else, sig_amp = SIG_AMP_V; end
sig_lo = SIG_AVG_V - sig_amp;
sig_hi = SIG_AVG_V + sig_amp;

d60  = carrega(pasta, '60hz',  60,  TS);
d300 = carrega(pasta, '300hz', 300, TS);
if isempty(d60) && isempty(d300)
    error(['Nenhum CSV em "%s". Esperado ensaio_60hz_N.csv / ' ...
           'ensaio_300hz_N.csv'], pasta);
end

% ---------------- PLOT: medido (codigo->V) + limites do XADC ------------
figure('Color','w','Position',[100 100 1000 760]);
ax1 = subplot(2,1,1);
plota_grupo(ax1, d60, 60, VREF, CODE_FS, SIG_AVG_V, sig_amp, sig_lo, sig_hi);
title(ax1, sprintf('60 Hz (%d campanhas) - medido pelo XADC vs injetado', numel(d60)));
ax2 = subplot(2,1,2);
plota_grupo(ax2, d300, 300, VREF, CODE_FS, SIG_AVG_V, sig_amp, sig_lo, sig_hi);
title(ax2, sprintf('300 Hz (%d campanhas)', numel(d300)));
xlabel(ax2,'tempo (ms)');
sgtitle('XADC sem condicionamento - sinal conhecido injetado direto', ...
        'FontWeight','bold');
saveas(gcf, fullfile(pasta,'plot_xadc_cru.png'));
fprintf('>> Figura: %s\n', fullfile(pasta,'plot_xadc_cru.png'));

% ---------------- RELATORIO --------------------------------------------
lin = repmat('=',1,70);
fprintf('\n%s\n SINAL INJETADO (conhecido)\n%s\n', lin, lin);
fprintf('  Media/offset : %.3f V\n', SIG_AVG_V);
fprintf('  Amplitude    : %.3f V (pico) -> de %.3f V a %.3f V\n', ...
        sig_amp, sig_lo, sig_hi);

fprintf('\n--- O sinal injetado cabe em 0-1 V do XADC? ---\n');
sat_lo = sig_lo < 0;  sat_hi = sig_hi > VREF;
if sat_lo || sat_hi
    fprintf('  NAO. ');
    if sat_lo, fprintf('Passa embaixo (%.3f V < 0). ', sig_lo); end
    if sat_hi, fprintf('Passa em cima (%.3f V > 1 V). ', sig_hi); end
    fprintf('\n  -> O XADC SATURA; picos medidos ceifados em 0 e/ou 4095.\n');
    fprintf('  -> Este ensaio ja demonstra a NECESSIDADE do condicionador.\n');
else
    fprintf('  SIM (%.3f a %.3f V). ADC nao satura; dados validos p/ linearidade.\n', ...
            sig_lo, sig_hi);
end

fprintf('\n%s\n MEDIDO PELO XADC (cru)\n%s\n', lin, lin);
relatorio('60 Hz',  d60,  VREF, CODE_FS);
relatorio('300 Hz', d300, VREF, CODE_FS);

base = d60; if isempty(base), base = d300; end

if ~isempty(base) && ~sat_lo && ~sat_hi
    v_med_meas = mean([base.media])*VREF/CODE_FS;
    v_amp_meas = mean([base.amp_code])*VREF/CODE_FS;
    fprintf('\n--- CARACTERIZACAO DO XADC (injetado vs medido) ---\n');
    fprintf('  Offset : injetado %.3f V | medido %.3f V | erro %+.1f mV\n', ...
            SIG_AVG_V, v_med_meas, (v_med_meas-SIG_AVG_V)*1e3);
    fprintf('  Amplit : injetada %.3f V | medida %.3f V | ganho %.4f\n', ...
            sig_amp, v_amp_meas, v_amp_meas/sig_amp);
    fprintf('  (ganho ideal = 1,000; desvio = erro de escala XADC/gerador)\n');
else
    fprintf('\n--- CARACTERIZACAO ---\n');
    fprintf('  Pulada: sinal saturou (picos ceifados). Para caracterizar o ganho\n');
    fprintf('  do XADC, reduza o sinal p/ caber em 0-1 V e repita. O dimensionamento\n');
    fprintf('  do condicionador abaixo independe disso.\n');
end

if ~isempty(base)
    fprintf('\n--- RUIDO DO XADC (base: %d Hz) ---\n', base(1).fnom);
    fprintf('  Ruido rms : %.2f codigos (%.3f mV)\n', ...
            mean([base.rms]), mean([base.rms])*VREF/CODE_FS*1e3);
    fprintf('  ENOB est. : %.2f bits\n', mean([base.enob]));
end

% ---------------- DIMENSIONAMENTO DO CONDICIONADOR ---------------------
K = (TGT_HIGH - TGT_LOW) / (sig_hi - sig_lo);
B = TGT_LOW - K*sig_lo;
tgt_avg = (TGT_HIGH+TGT_LOW)/2;

fprintf('\n%s\n DIMENSIONAMENTO DO CONDICIONADOR (a projetar)\n%s\n', lin, lin);
fprintf('  Meta: mapear [%.3f, %.3f] V -> XADC [%.2f, %.2f] V\n', ...
        sig_lo, sig_hi, TGT_LOW, TGT_HIGH);
fprintf('  Transferencia:  V_adc = %.4f * V_in + %.4f V\n', K, B);
if K < 1, tipo = 'ATENUAR (divisor ou amp G<1)';
else,     tipo = 'AMPLIFICAR (amp G>1)'; end
fprintf('    Ganho  K = %.4f   -> %s\n', K, tipo);
fprintf('    Offset B = %+.4f V  (nivel DC a somar)\n', B);
fprintf('    Verif.: %.3f V -> %.3f V  |  %.3f V -> %.3f V\n', ...
        sig_lo, K*sig_lo+B, sig_hi, K*sig_hi+B);
fprintf('\n  Forma pratica (amp-op diferencial + bias):\n');
fprintf('    V_adc = %.4f*(V_in - %.3f) + %.3f\n', K, SIG_AVG_V, tgt_avg);
fprintf('    -> ganho diferencial %.4f, referencia (bias) = %.3f V\n', K, tgt_avg);

% Exemplo de resistores para divisor (se K<1, caso mais comum)
if K < 1
    fprintf('\n  Se optar por DIVISOR resistivo simples (atenuacao %.4f):\n', K);
    fprintf('    Ex.: R_topo/R_baixo tal que R_baixo/(R_topo+R_baixo)=%.4f\n', K);
    Rb = 10e3; Rt = Rb*(1/K - 1);
    fprintf('    Ex. pratico: R_baixo=10k -> R_topo=%.0f ohm (E96 mais proximo)\n', Rt);
    fprintf('    (lembre: divisor puro nao desloca offset; para o bias %.3f V\n', tgt_avg);
    fprintf('     ainda e preciso somar tensao - use rede de 3 resistores ou amp-op)\n');
end

lsb_v_in = (VREF/CODE_FS)/K;
fprintf('\n--- RESOLUCAO RESULTANTE (apos condicionador) ---\n');
fprintf('  1 LSB = %.3f mV no ADC = %.3f mV do sinal de entrada\n', ...
        VREF/CODE_FS*1e3, lsb_v_in*1e3);
fprintf('  Sinal ocupara ~%.0f%% da faixa 0-1 V do XADC\n', ...
        (TGT_HIGH-TGT_LOW)/VREF*100);

fprintf('\n%s\n Ajuste SINAL INJETADO e FAIXA-ALVO no topo do arquivo.\n%s\n', ...
        lin, lin);
end

% ======================================================================
function plota_grupo(ax, d, fnom, VREF, CODE_FS, avg, amp, lo, hi)
hold(ax,'on'); grid(ax,'on');
for k = 1:numel(d)
    plot(ax, d(k).t*1e3, d(k).codes*VREF/CODE_FS, 'LineWidth',0.8);
end
if ~isempty(d)
    t = d(1).t;
    w = 2*pi*fnom; A = [sin(w*t), cos(w*t), ones(numel(t),1)];
    c = A\(d(1).codes*VREF/CODE_FS); ph = atan2(c(2), c(1));
    inj = avg + amp*sin(w*t + ph);
    plot(ax, t*1e3, inj, 'k--', 'LineWidth',1.3);
end
yline(ax, 0,    ':', 'Color',[.6 .6 .6]);
yline(ax, VREF, ':', 'Color',[.85 .3 .3]);   % teto do XADC (1 V)
yline(ax, lo,   '--','Color',[.3 .3 .8]);
yline(ax, hi,   '--','Color',[.3 .3 .8]);
ylabel(ax,'tensao (V)');
ylim(ax, [min(-0.1, lo-0.1), max(1.1, hi+0.1)]);
end

function d = carrega(pasta, tag, fnom, TS)
arqs = dir(fullfile(pasta, sprintf('ensaio_%s_*.csv', tag)));
d = struct('nome',{},'t',{},'codes',{},'fnom',{},'media',{}, ...
           'amp_code',{},'pico_pos',{},'pico_neg',{},'rms',{},'enob',{});
for i = 1:numel(arqs)
    codes = ler_csv(fullfile(arqs(i).folder, arqs(i).name));
    if numel(codes) < 10, continue; end
    s = metricas(codes, fnom, TS);
    s.nome = arqs(i).name; s.fnom = fnom;
    d(end+1) = s; %#ok<AGROW>
end
end

function codes = ler_csv(caminho)
fid = fopen(caminho,'r');
raw = textscan(fid, '%s %s %s %s %s', 'Delimiter',',', ...
               'HeaderLines', 2, 'CollectOutput', true);
fclose(fid);
C = raw{1};
if isempty(C), codes = []; return; end
cod = hex2dec(C(:,4));
cap = strtrim(C(:,5));
mask = strcmp(cap,'1') | strcmp(cap,'01') | strcmp(cap,'0001');
codes = cod(mask);
end

function s = metricas(codes, fnom, TS)
codes = codes(:); n = numel(codes); t = (0:n-1)'*TS;
w = 2*pi*fnom; A = [sin(w*t), cos(w*t), ones(n,1)];
coef = A\codes; fit = A*coef; resid = codes - fit;
amp = hypot(coef(1),coef(2)); rms = std(resid);
if rms > 0, enob = (20*log10((amp/sqrt(2))/rms)-1.76)/6.02;
else, enob = Inf; end
s.t=t; s.codes=codes; s.media=mean(codes);
s.amp_code=(max(codes)-min(codes))/2;
s.pico_pos=max(codes); s.pico_neg=min(codes); s.rms=rms; s.enob=enob;
end

function relatorio(tag, d, VREF, CODE_FS)
if isempty(d), return; end
fprintf('\n--- %s (%d campanhas) ---\n', tag, numel(d));
fprintf('  Media    : %7.1f codigos (%.4f V)\n', ...
        mean([d.media]), mean([d.media])*VREF/CODE_FS);
pp = mean([d.pico_pos]); pn = mean([d.pico_neg]);
fprintf('  Pico +   : %7.1f codigos (%.4f V)%s\n', pp, pp*VREF/CODE_FS, ...
        tern(pp>=CODE_FS-2,'  <-- SATUROU',''));
fprintf('  Pico -   : %7.1f codigos (%.4f V)%s\n', pn, pn*VREF/CODE_FS, ...
        tern(pn<=1,'  <-- SATUROU',''));
fprintf('  Amplitude: %7.1f codigos (%.4f V)\n', ...
        mean([d.amp_code]), mean([d.amp_code])*VREF/CODE_FS);
end

function s = tern(c,a,b)
if c, s=a; else, s=b; end
end
