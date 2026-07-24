function analise_xadc_comentado(pasta)
% =========================================================================
% ANALISE_XADC_COMENTADO
%
% Analisa CSVs exportados do ILA (Basys3 / XADC) para um ensaio de injecao
% de sinal conhecido DIRETO no pino do XADC (sem circuito de condicionamento).
%
% O QUE ESTE SCRIPT E:  verificacao funcional da cadeia de aquisicao
%                       (pino -> XADC -> DRP -> ILA -> CSV) + dimensionamento
%                       do condicionador que ainda sera projetado.
% O QUE ELE NAO E:      caracterizacao metrologica do ADC (INL/DNL/ENOB de
%                       datasheet). Ver secao "LIMITACOES" no fim do arquivo.
%
% Referencias: IEEE Std 1241 (metodos de ensaio de ADC), IEEE Std 1057
%              (registradores de forma de onda), Xilinx UG480 (XADC).
% =========================================================================

if nargin < 1, pasta = pwd; end
% ^ Se o usuario nao passar caminho, usa a pasta atual do MATLAB.
%   Decisao: evita erro bobo quando se roda direto da pasta dos CSVs.

% ================= BLOCO 1: PARAMETROS DO XADC (fixos) ===================
TS      = 50e-6;
% ^ Intervalo entre amostras ARMAZENADAS. Nao e a taxa de conversao do XADC
%   (~1 MSPS); e o periodo do strobe cap_en gerado no top.vhd (DEC_MAX=4999
%   -> 5000 ciclos de 10 ns). ATENCAO: valor ASSUMIDO, nao medido. Se voce
%   mudar DEC_MAX no VHDL, TEM que mudar aqui, senao o eixo de tempo e a
%   frequencia estimada saem errados.

NBITS   = 12;
% ^ Resolucao do XADC (UG480). Usado so para calcular CODE_FS_NBITS.

VREF    = 1.0;
% ^ Fundo de escala do XADC em modo UNIPOLAR = 1,0 V (UG480, Fig. 2-2).
%   Consequencia: 1 LSB = 1 V / 4096 = 244 uV.

CODE_FS_NBITS = 2^NBITS;
% ^ 4096 codigos. Separado de NBITS para deixar explicito nas contas.

% ================= BLOCO 2: SINAL INJETADO (o que VOCE sabe) =============
% Estes valores sao o "gabarito" do ensaio: o valor VERDADEIRO contra o qual
% o codigo lido sera comparado. Devem vir do OSCILOSCOPIO em acoplamento DC,
% nunca do display do gerador (que assume carga de 50 ohm).
SIG_AVG_V = 0.550;   % nivel medio (offset DC) do sinal injetado [V]
SIG_AMP_V = 0.900;   % amplitude [V] - ver flag abaixo
AMP_IS_PP = true;
% ^ Flag de desambiguacao. "900 mV de amplitude" e ambiguo:
%     false -> 900 mV e AMPLITUDE DE PICO  -> sinal vai de -0,350 a +1,450 V
%     true  -> 900 mV e PICO-A-PICO        -> sinal vai de +0,100 a +1,000 V
%   O primeiro caso ESTOURA a faixa 0-1 V do XADC nos dois lados; o segundo
%   cabe. Como o diagnostico muda completamente, a flag e obrigatoria.

% ================= BLOCO 3: FAIXA-ALVO apos condicionamento ==============
TGT_LOW  = 0.10;
TGT_HIGH = 0.90;
% ^ Onde queremos que o sinal caia DEPOIS do condicionador. Nao usamos
%   0,00-1,00 V de proposito: 10% de margem em cada borda absorve tolerancia
%   de resistores, deriva termica, offset do amp-op e sobressinal, evitando
%   ceifamento. Custo: perde-se ~0,3 bit de faixa. Trade-off deliberado.

% ================= BLOCO 4: OPCOES DE ANALISE ============================
FIT4P   = true;
% ^ true  = ajuste senoidal de QUATRO parametros (amplitude, fase, offset e
%           FREQUENCIA), conforme IEEE 1241/1057. Recomendado: nao assume que
%           o gerador esta exatamente em 60,000 Hz nem que TS e exato.

% Referência: <http://imeko.org/publications/wc-2000/IMEKO-WC-2000-EWADC-P633.pdf>. Acesso em 24/04/26


%   false = ajuste de tres parametros (frequencia fixada no valor nominal).
%           Mais simples, porem qualquer erro de frequencia vira "ruido" no
%           residuo e SUBESTIMA o ENOB.

% 
% A PARTIR DAQUI: processamento
% 

% --- Converte a amplitude informada para amplitude de pico ---------------
if AMP_IS_PP, sig_amp = SIG_AMP_V/2; else, sig_amp = SIG_AMP_V; end
sig_lo = SIG_AVG_V - sig_amp;   % menor tensao do sinal injetado
sig_hi = SIG_AVG_V + sig_amp;   % maior tensao do sinal injetado
% ^ Estes dois numeros governam tudo: diagnostico de saturacao e o calculo
%   do ganho/offset do condicionador.

% --- Carrega os dois grupos de ensaio ------------------------------------
d60  = carrega(pasta, '60hz',  60,  TS, FIT4P);
d300 = carrega(pasta, '300hz', 300, TS, FIT4P);
d400 = carrega(pasta, '300hz', 400, TS, FIT4P);

% ^ Decisao: agrupar por frequencia nominal permite (a) sobrepor campanhas
%   repetidas para ver repetibilidade e (b) comparar 60 vs 300 Hz para
%   detectar atenuacao da cadeia (banda).

if isempty(d60) && isempty(d300)
    error(['Nenhum CSV em "%s". Esperado ensaio_60hz_N.csv / ' ...
           'ensaio_300hz_N.csv'], pasta);
end
% ^ Falha explicita e cedo, com a causa provavel (nome de arquivo), em vez
%   de erro obscuro mais adiante.

%%  PLOT -------------

figure('Color','w','Position',[100 100 1000 760]);

ax1 = subplot(2,1,1);
plota_grupo(ax1, d60, VREF, CODE_FS_NBITS, SIG_AVG_V, sig_amp, sig_lo, sig_hi);
title(ax1, sprintf('60 Hz (%d campanhas) - medido pelo XADC', numel(d60)));

ax2 = subplot(2,1,2);
plota_grupo(ax2, d300, VREF, CODE_FS_NBITS, SIG_AVG_V, sig_amp, sig_lo, sig_hi);

title(ax2, sprintf('300 Hz (%d campanhas)', numel(d300)));
xlabel(ax2,'tempo (ms)');

% ^ Decisao de projeto do grafico: plotar em VOLTS, nao em codigo. Motivo:
%   e em volts que se enxerga se o sinal bateu no teto de 1 V do ADC. O eixo
%   em codigo esconderia isso (4095 nao "parece" um limite fisico).

sgtitle('XADC sem condicionamento - sinal conhecido injetado direto', ...
        'FontWeight','bold');
saveas(gcf, fullfile(pasta,'plot_xadc_cru.png'));
fprintf('>> Figura: %s\n', fullfile(pasta,'plot_xadc_cru.png'));

%  RELATORIO =============================================
lin = repmat('=',1,70);

fprintf('\n%s\n SINAL INJETADO (gabarito do ensaio)\n%s\n', lin, lin);
fprintf('  Media/offset : %.3f V\n', SIG_AVG_V);
fprintf('  Amplitude    : %.3f V (pico) -> de %.3f V a %.3f V\n', ...
        sig_amp, sig_lo, sig_hi);

% --- Diagnostico de faixa (feito a partir do GABARITO, nao dos dados) ----
fprintf('\n--- O sinal injetado cabe em 0-1 V do XADC? ---\n');
sat_lo = sig_lo < 0;
sat_hi = sig_hi > VREF;

% ^ Comparacao direta com os limites do UG480. Feita com o valor conhecido
%   porque, se saturou, os DADOS ja nao revelam a amplitude verdadeira -
%   o ADC ceifou a informacao. So o gabarito sabe.


if sat_lo || sat_hi
    fprintf('  NAO. ');
    if sat_lo, fprintf('Passa embaixo (%.3f V < 0). ', sig_lo); end
    if sat_hi, fprintf('Passa em cima (%.3f V > 1 V). ', sig_hi); end
    fprintf('\n  -> XADC SATURA; picos ceifados em 0 e/ou 4095.\n');
    fprintf('  -> O ensaio ja demonstra a NECESSIDADE do condicionador.\n');
else
    fprintf('  SIM (%.3f a %.3f V). ADC nao satura.\n', sig_lo, sig_hi);
end

fprintf('\n%s\n MEDIDO PELO XADC (cru)\n%s\n', lin, lin);
relatorio('60 Hz',  d60,  VREF, CODE_FS_NBITS);
relatorio('300 Hz', d300, VREF, CODE_FS_NBITS);

base = d60; if isempty(base), base = d300; end
% ^ 60 Hz e a referencia preferencial (mais amostras por ciclo -> ajuste
%   melhor condicionado). 300 Hz so e usado se nao houver dados de 60 Hz.

% --- Caracterizacao: comparar gabarito com medida ------------------------
if ~isempty(base) && ~sat_lo && ~sat_hi
    v_med  = mean([base.dc])   * VREF/CODE_FS_NBITS;   % offset medido [V]
    v_ampm = mean([base.ampfit])* VREF/CODE_FS_NBITS;  % amplitude medida [V]
    
    % ^ IMPORTANTE: usa a amplitude do AJUSTE (ampfit), nao (max-min)/2.
    %   Motivo metrologico: o pico bruto e definido por UMA amostra e por
    %   isso e sensivel a ruido e a outliers; a amplitude do ajuste usa as
    %   1024 amostras e e o estimador recomendado pela IEEE 1241.

    
    fprintf('\n--- CARACTERIZACAO (gabarito vs medida) ---\n');
    fprintf('  Offset : injetado %.3f V | medido %.3f V | erro %+.1f mV (%.1f LSB)\n', ...
            SIG_AVG_V, v_med, (v_med-SIG_AVG_V)*1e3, ...
            (v_med-SIG_AVG_V)/(VREF/CODE_FS_NBITS));
    fprintf('  Amplit : injetada %.3f V | medida %.3f V | ganho %.4f (erro %+.2f%%)\n', ...
            sig_amp, v_ampm, v_ampm/sig_amp, (v_ampm/sig_amp-1)*100);
    fprintf('  (ganho ideal 1,000; desvio = erro de escala do XADC + do gerador,\n');
    fprintf('   nao separaveis sem uma referencia de tensao independente)\n');
else
    fprintf('\n--- CARACTERIZACAO ---\n');
    fprintf('  Pulada: sinal saturou. Reduza o gerador p/ caber em 0-1 V e repita.\n');
end

% --- Ruido / ENOB e frequencia estimada ----------------------------------
if ~isempty(base)
    fprintf('\n--- DINAMICA (base: %d Hz nominal) ---\n', base(1).fnom);
    fprintf('  Freq. estimada : %.4f Hz  (nominal %.1f Hz, desvio %+.3f%%)\n', ...
            mean([base.fest]), base(1).fnom, ...
            (mean([base.fest])/base(1).fnom-1)*100);
    % ^ Este numero e um TESTE CRUZADO valioso: ele so sai certo se TS
    %   (50 us) estiver correto E o gerador estiver na frequencia dita.
    %   Desvio grande = decimacao errada no VHDL ou gerador desajustado.
    fprintf('  Residuo (rms)  : %.2f codigos (%.3f mV)\n', ...
            mean([base.rms]), mean([base.rms])*VREF/CODE_FS_NBITS*1e3);
    fprintf('  ENOB aparente  : %.2f bits  [LIMITADO PELO GERADOR - ver nota]\n', ...
            mean([base.enob]));
    fprintf('  Amostras ceifadas: %d de %d (%.1f%%)\n', ...
            sum([base.nclip]), sum([base.n]), ...
            100*sum([base.nclip])/max(1,sum([base.n])));
    % ^ Contagem direta de amostras em 0 ou 4095 nos DADOS: confirma (ou
    %   desmente) o diagnostico feito pelo gabarito. Redundancia proposital.
end

% ================= DIMENSIONAMENTO DO CONDICIONADOR ======================
K = (TGT_HIGH - TGT_LOW) / (sig_hi - sig_lo);
% ^ Ganho: razao entre a excursao desejada no ADC e a excursao do sinal.

%   K < 1 => atenuar; K > 1 => amplificar.
B = TGT_LOW - K*sig_lo;
% ^ Offset: o deslocamento DC que leva o ponto mais baixo do sinal
%   exatamente para TGT_LOW. Deduzido de V_adc = K*V_in + B com

%   V_in = sig_lo -> V_adc = TGT_LOW.
tgt_avg = (TGT_HIGH+TGT_LOW)/2;   % centro da faixa-alvo (bias do amp-op)

fprintf('\n%s\n DIMENSIONAMENTO DO CONDICIONADOR (a projetar)\n%s\n', lin, lin);
fprintf('  Meta: mapear [%.3f, %.3f] V -> XADC [%.2f, %.2f] V\n', ...
        sig_lo, sig_hi, TGT_LOW, TGT_HIGH);
fprintf('  Transferencia:  V_adc = %.4f * V_in + %.4f V\n', K, B);
if K < 1, tipo = 'ATENUAR (divisor ou amp G<1)';

else,     tipo = 'AMPLIFICAR (amp G>1)'; end

fprintf('    Ganho  K = %.4f  -> %s\n', K, tipo);
fprintf('    Offset B = %+.4f V\n', B);
fprintf('    Verificacao: %.3f V -> %.3f V | %.3f V -> %.3f V\n', ...
        sig_lo, K*sig_lo+B, sig_hi, K*sig_hi+B);
        
% ^ A verificacao recalcula as duas pontas com K e B. Se nao der TGT_LOW e
%   TGT_HIGH, ha erro de conta - autoteste barato.

fprintf('\n  Forma pratica (amp-op diferencial + bias):\n');
fprintf('    V_adc = %.4f*(V_in - %.3f) + %.3f\n', K, SIG_AVG_V, tgt_avg);
fprintf('    -> ganho diferencial %.4f, referencia (bias) = %.3f V\n', K, tgt_avg);
% ^ Reescrita algebricamente identica, porem no formato que se implementa
%   com UM amp-op: subtrai o centro do sinal, aplica ganho, soma o centro
%   da faixa-alvo. IMPORTANTE: realimentacao sempre pela entrada INVERSORA
%   (realimentacao positiva satura o amp-op - vira comparador, nao buffer).

if K < 1
    Rb = 10e3; 
    Rt = Rb*(1/K - 1);
    fprintf('\n  Se optar por divisor resistivo (atenuacao %.4f):\n', K);
    fprintf('    R_baixo = 10k -> R_topo = %.0f ohm (usar E96 mais proximo)\n', Rt);
    fprintf('    NOTA: divisor puro NAO desloca offset. Para o bias de %.3f V\n', tgt_avg);
    fprintf('    e preciso rede de 3 resistores (sinal, 3V3, GND) ou amp-op.\n');
    fprintf('    NOTA 2: a impedancia equivalente do divisor SOMA-SE ao RMUX\n');
    fprintf('    (~10 k do canal auxiliar) e aumenta o tempo de aquisicao\n');
    fprintf('    exigido: t_acq = 9*(RMUX+Rext)*3pF  (UG480 Eq. 2-4).\n');
end

lsb_v_in = (VREF/CODE_FS_NBITS)/K;
fprintf('\n--- RESOLUCAO RESULTANTE ---\n');
fprintf('  1 LSB = %.3f mV no ADC = %.3f mV referido a entrada do condicionador\n', ...
        VREF/CODE_FS_NBITS*1e3, lsb_v_in*1e3);
fprintf('  Sinal ocupara ~%.0f%% da faixa 0-1 V\n', (TGT_HIGH-TGT_LOW)/VREF*100);

fprintf('\n%s\n', lin);
fprintf(' LIMITACOES DESTE ENSAIO (declarar na dissertacao):\n');
fprintf('  1. ENOB e limitado pela pureza do gerador (THD tipica -55..-65 dBc),\n');
fprintf('     abaixo dos 74 dB exigidos por 12 bits: mede-se a FONTE, nao o ADC.\n');
fprintf('  2. 1024 amostras sao insuficientes p/ INL/DNL por histograma\n');
fprintf('     (IEEE 1241 pede muitas amostras por codigo).\n');
fprintf('  3. Ganho/offset medidos somam erros do ADC e do gerador; separa-los\n');
fprintf('     exige referencia de tensao independente (calibrador/DMM 5,5 dig).\n');
fprintf('  4. TS=%.0f us e assumido do contador do VHDL, nao medido.\n', TS*1e6);
fprintf('%s\n', lin);
end

% =========================================================================
% SUBFUNCOES
% =========================================================================

function d = carrega(pasta, tag, fnom, TS, fit4p)
% Varre a pasta procurando ensaio_<tag>_*.csv e monta um vetor de structs.
arqs = dir(fullfile(pasta, sprintf('ensaio_%s_*.csv', tag)));
d = struct('nome',{},'t',{},'codes',{},'fnom',{},'fest',{},'dc',{}, ...
           'ampfit',{},'amppk',{},'pico_pos',{},'pico_neg',{}, ...
           'rms',{},'enob',{},'n',{},'nclip',{},'fit',{});
for i = 1:numel(arqs)
    codes = ler_csv(fullfile(arqs(i).folder, arqs(i).name));
    if numel(codes) < 10, continue; end
    % ^ Descarta arquivos truncados/vazios em vez de quebrar o ajuste.
    s = metricas(codes, fnom, TS, fit4p);
    s.nome = arqs(i).name;
    s.fnom = fnom;
    d(end+1) = s; %#ok<AGROW>
end
end

function codes = ler_csv(caminho)
% Le a coluna 4 (codigo[11:0], HEX) filtrando por cap_v == 1.
fid = fopen(caminho,'r');
raw = textscan(fid, '%s %s %s %s %s', 'Delimiter',',', ...
               'HeaderLines', 2, 'CollectOutput', true);
fclose(fid);
% ^ 'HeaderLines',2 : o CSV do ILA tem DUAS linhas de cabecalho - a dos
%   nomes das colunas e a dos radices ("Radix - HEX"). Pular so uma faria
%   hex2dec falhar na segunda linha.
% ^ Le tudo como STRING (%s) de proposito: a coluna 4 esta em hexadecimal,
%   entao %d/%f leriam "A95" como NaN ou como 95 decimal - erro silencioso
%   e perigoso (o dado pareceria plausivel).

C = raw{1};
if isempty(C), codes = []; return; end

cod = hex2dec(C(:,4));
% ^ Conversao hex->decimal.


cap = strtrim(C(:,5));

mask = strcmp(cap,'1') | strcmp(cap,'01') | strcmp(cap,'0001');
% ^ cap_v tambem e exportado em hex e pode vir com zeros a esquerda,
%   dependendo da largura da probe. Aceita as tres grafias.
%   Filtrar por cap_v==1 garante que so entram amostras qualificadas pelo
%   strobe decimado - ou seja, espacadas de exatamente TS.
codes = cod(mask);
end


% -----
function s = metricas(codes, fnom, TS, fit4p)
% Ajuste senoidal por minimos quadrados + metricas derivadas.
codes = codes(:);

n = numel(codes);

t = (0:n-1)'*TS;
% ^ Eixo de tempo construido a partir do indice x TS (nao ha coluna de
%   tempo confiavel no CSV do ILA).

w = 2*pi*fnom;

% ---- Ajuste de TRES parametros (IEEE 1241): frequencia FIXA ------------
A = [sin(w*t), cos(w*t), ones(n,1)];
coef = A\codes;
% ^ Truque padrao: a senoide A*sin(wt+phi)+C e LINEAR nos coeficientes se
%   escrita como a*sin(wt)+b*cos(wt)+C. Por isso um simples "\" resolve
%   sem otimizacao nao linear. Amplitude = hypot(a,b), fase = atan2(b,a).

% ---- Refinamento de QUATRO parametros: estima tambem a frequencia ------
if fit4p
    for it = 1:12
        a = coef(1); b = coef(2);
        D = [sin(w*t), cos(w*t), ones(n,1), ...
             a*t.*cos(w*t) - b*t.*sin(w*t)];
        % ^ A quarta coluna e a derivada do modelo em relacao a w
        %   (linearizacao). Resolver da a correcao dw a aplicar.
        sol = D\codes;
        dw  = sol(4);
        w   = w + dw;
        coef = sol(1:3);
        if abs(dw) < 1e-9, break; end
        % ^ Criterio de parada: correcao desprezivel.
    end
end
% ^ POR QUE ISSO IMPORTA: com 3 parametros assume-se que o gerador esta
%   exatamente em 60,000 Hz e que TS e exatamente 50,000 us. Qualquer
%   desvio (0,1% ja basta) aparece no residuo como se fosse ruido do ADC e
%   SUBESTIMA o ENOB. O ajuste de 4 parametros absorve esse erro na
%   estimativa de frequencia - e ainda entrega a frequencia como um dado
%   util de teste cruzado. IEEE 1241/1057 preveem os dois; usa-se 3
%   parametros apenas quando a frequencia e conhecida com muita precisao.

fit   = [sin(w*t), cos(w*t), ones(n,1)]*coef;
resid = codes - fit;
amp   = hypot(coef(1), coef(2));
rms   = std(resid);

if rms > 0
    sinad = 20*log10((amp/sqrt(2))/rms);
    enob  = (sinad - 1.76)/6.02;
    % ^ Definicao classica: SINAD(dB) = 6,02*ENOB + 1,76 para senoide de
    %   fundo de escala. Como aqui o sinal NAO ocupa o fundo de escala,
    %   este ENOB e "aparente" (referido a amplitude usada), nao o ENOB
    %   de datasheet. Vale como indicador comparativo entre ensaios.
else
    enob = Inf;
end

s.t = t; s.codes = codes; s.fit = fit; s.n = n;
s.fest   = w/(2*pi);                      % frequencia estimada [Hz]
s.dc     = coef(3);                       % offset em codigos
s.ampfit = amp;                           % amplitude do AJUSTE (robusta)
s.amppk  = (max(codes)-min(codes))/2;     % amplitude por PICO (sensivel a ruido)
s.pico_pos = max(codes);
s.pico_neg = min(codes);
s.rms  = rms;
s.enob = enob;
s.nclip = sum(codes >= 4095) + sum(codes <= 0);
% ^ Contagem de amostras ceifadas: evidencia direta de saturacao nos dados.
end

function plota_grupo(ax, d, VREF, CODE_FS_NBITS, avg, amp, lo, hi)
if isempty(d), return; end
hold(ax,'on'); grid(ax,'on');
for k = 1:numel(d)
    plot(ax, d(k).t*1e3, d(k).codes*VREF/CODE_FS_NBITS, 'LineWidth',0.8);
    % ^ codigo -> volts: multiplica por VREF/CODE_FS_NBITS (244 uV por codigo).
end
% Sinal injetado ideal, alinhado em fase pelo ajuste do 1o arquivo:
t = d(1).t;
w = 2*pi*d(1).fest;
ph = atan2(d(1).fit(1)*0 + 0, 1); %#ok<NASGU>  (fase vem do ajuste abaixo)
A = [sin(w*t), cos(w*t), ones(numel(t),1)];
c = A\(d(1).codes*VREF/CODE_FS_NBITS);
inj = avg + amp*sin(w*t + atan2(c(2), c(1)));
plot(ax, t*1e3, inj, 'k--', 'LineWidth',1.3);
% ^ A referencia tracejada usa a FASE estimada dos dados (senao as curvas
%   apareceriam deslocadas e a comparacao visual seria inutil) mas a
%   AMPLITUDE e o OFFSET do gabarito. Assim, se elas nao coincidirem, a
%   diferenca e real (ganho/offset/ceifamento), nao artefato de fase.

yline(ax, 0,    ':', 'Color',[.6 .6 .6]);
yline(ax, VREF, ':', 'Color',[.85 .3 .3]);   % teto fisico do XADC
yline(ax, lo,   '--','Color',[.3 .3 .8]);
yline(ax, hi,   '--','Color',[.3 .3 .8]);
% ^ As linhas de 0 V e 1 V sao o "chao" e o "teto" do conversor; as
%   tracejadas azuis mostram onde o sinal injetado deveria estar.
ylabel(ax,'tensao (V)');
ylim(ax, [min(-0.1, lo-0.1), max(1.1, hi+0.1)]);
end

function relatorio(tag, d, VREF, CODE_FS_NBITS)
if isempty(d), return; end
fprintf('\n--- %s (%d campanhas) ---\n', tag, numel(d));
fprintf('  Offset (ajuste): %7.1f cod (%.4f V)  +/- %.1f entre campanhas\n', ...
        mean([d.dc]), mean([d.dc])*VREF/CODE_FS_NBITS, std([d.dc]));
% ^ O "+/-" entre campanhas e a REPETIBILIDADE - metrica que so existe
%   porque foram feitas varias capturas. E o dado que diz se a cadeia esta
%   estavel entre ensaios (relevante p/ comparar controladores ao longo de
%   meses).
fprintf('  Amplitude(ajus): %7.1f cod (%.4f V)  +/- %.1f\n', ...
        mean([d.ampfit]), mean([d.ampfit])*VREF/CODE_FS_NBITS, std([d.ampfit]));
pp = mean([d.pico_pos]); pn = mean([d.pico_neg]);
fprintf('  Pico + / -     : %7.1f / %-7.1f cod%s\n', pp, pn, ...
        tern(pp>=CODE_FS_NBITS-2 || pn<=1, '   <-- CEIFADO', ''));
fprintf('  Amostras ceifadas: %d\n', sum([d.nclip]));
end

function s = tern(c,a,b)
if c, s=a; else, s=b; end
end
