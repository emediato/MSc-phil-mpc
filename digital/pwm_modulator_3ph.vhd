-------------------------------------------------------------------------------
-- pwm_modulator_3ph.vhd
-- Modulador PWM trifasico, portadora triangular (center-aligned), para
-- inversor de 2 niveis com 6 chaves (compativel com o IPM IGCM20F60GA).
--
-- Interface pensada para o caminho GPC/CCS: o controle entrega 3 duty cycles
-- por periodo; este bloco gera os 6 comandos de gate com dead time e protecoes.
--
-- Recursos:
--   * Portadora triangular  -> f_sw = CLK_FREQ_HZ / (2*PERIOD)
--   * 3 duty cycles independentes (SPWM; para SVPWM injete a sequencia zero
--     antes deste bloco, o nucleo e o mesmo)
--   * Double buffering: duties carregados no VALE da portadora (sem glitch)
--   * Dead time por perna, em TODA borda (impede shoot-through)
--   * Clamp de duty p/ recarga do bootstrap (lado alto nunca 100%)  [DATASHEET: VBSUV]
--   * Entrada de falha com PRIORIDADE ABSOLUTA e latch (reset manual) [DATASHEET: VFO/OC/UVLO]
--   * adc_soc_o: pulso no PICO da portadora -> lado baixo conduzindo -> amostra 3-shunt
--     [DATASHEET: emissores de lado baixo NU/NV/NW acessiveis p/ medicao]
--   * load_strobe_o: pulso no VALE -> duties carregados -> use como gatilho do controle
--   * Sinais marcados p/ ILA (mark_debug)
--
-- POLARIDADE (ler com atencao):
--   GATE_ON_LEVEL e o nivel NO PINO DO FPGA que faz o IGBT CONDUZIR. A cadeia
--   FPGA -> DM74LS245 (nao inverte) -> 6N137 (INVERTE) -> IPM inverte uma vez.
--   Ajuste este generico depois de confirmar a polaridade da entrada do
--   IGCM20F60GA no datasheet. O estado seguro (tudo desligado) fica correto
--   por construcao para QUALQUER cadeia, desde que GATE_ON_LEVEL esteja certo.
--
-- Restricao de parametros: exige PERIOD_I > max(DEAD_I, BOOT_I) (senao DUTYMAX < 0).
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.pwm_pkg.all;

entity pwm_modulator_3ph is
  generic (
    CLK_FREQ_HZ   : positive  := 40_000_000;  -- clock do modulador (ex.: clk_40m)
    F_SW_HZ       : positive  := 20_000;       -- frequencia de chaveamento
    DEAD_TIME_NS  : positive  := 1_000;        -- dead time (AJUSTAR ao driver/IGBT)
    BOOT_MIN_NS   : positive  := 3_000;        -- tempo min. de lado baixo p/ bootstrap
    GATE_ON_LEVEL : std_logic := '1'           -- nivel no pino que LIGA o IGBT
  );
  port (
    clk_i         : in  std_logic;
    rst_i         : in  std_logic;             -- reset sincrono, ativo alto
    enable_i      : in  std_logic;             -- '1' habilita a modulacao
    fault_i       : in  std_logic;             -- falha do IPM (assincrona, ativo alto)
    fault_clear_i : in  std_logic;             -- limpa o latch de falha (reset manual)
    duty_a_i      : in  unsigned(DUTY_W-1 downto 0);
    duty_b_i      : in  unsigned(DUTY_W-1 downto 0);
    duty_c_i      : in  unsigned(DUTY_W-1 downto 0);
    ah_o          : out std_logic;             -- fase A, lado alto
    al_o          : out std_logic;             -- fase A, lado baixo
    bh_o          : out std_logic;             -- fase B, lado alto
    bl_o          : out std_logic;             -- fase B, lado baixo
    ch_o          : out std_logic;             -- fase C, lado alto
    cl_o          : out std_logic;             -- fase C, lado baixo
    adc_soc_o     : out std_logic;             -- pulso no pico (amostrar shunts)
    load_strobe_o : out std_logic;             -- pulso no vale (gatilho do controle)
    fault_o       : out std_logic              -- falha latchada
  );
end entity pwm_modulator_3ph;

architecture rtl of pwm_modulator_3ph is

  -- Constantes derivadas -----------------------------------------------------
  constant NS_PER_CLK : integer := 1_000_000_000 / CLK_FREQ_HZ;  -- ns por ciclo
  constant PERIOD_I   : integer := CLK_FREQ_HZ / (2*F_SW_HZ);     -- amplitude da portadora
  constant DEAD_I     : integer := DEAD_TIME_NS / NS_PER_CLK;
  constant BOOT_I     : integer := BOOT_MIN_NS  / NS_PER_CLK;
  constant DUTYMAX_I  : integer := PERIOD_I - max2(DEAD_I, BOOT_I);

  constant PERIOD   : unsigned(DUTY_W-1 downto 0) := to_unsigned(PERIOD_I,  DUTY_W);
  constant DUTYMAX  : unsigned(DUTY_W-1 downto 0) := to_unsigned(DUTYMAX_I, DUTY_W);
  constant DEAD_CNT : unsigned(DUTY_W-1 downto 0) := to_unsigned(DEAD_I,    DUTY_W);
  constant ZERO     : unsigned(DUTY_W-1 downto 0) := (others => '0');

  -- Tipos e sinais -----------------------------------------------------------
  type u_arr is array (0 to 2) of unsigned(DUTY_W-1 downto 0);

  signal cnt      : unsigned(DUTY_W-1 downto 0) := (others => '0');
  signal dir_up   : std_logic := '1';
  signal peak_s   : std_logic := '0';
  signal trough_s : std_logic := '0';

  signal duty_in  : u_arr;
  signal duty_s   : u_arr;                          -- duties "sombra" (double buffer)
  signal dt_cnt   : u_arr;
  signal rawh     : std_logic_vector(2 downto 0);
  signal rawh_d   : std_logic_vector(2 downto 0);
  signal hs_on    : std_logic_vector(2 downto 0);   -- '1' = lado alto conduz
  signal ls_on    : std_logic_vector(2 downto 0);   -- '1' = lado baixo conduz

  signal fault_sync : std_logic_vector(1 downto 0) := (others => '0');
  signal fclr_sync  : std_logic_vector(1 downto 0) := (others => '0');
  signal fault_lat  : std_logic := '0';
  signal safe       : std_logic;

  -- Debug (ILA) --------------------------------------------------------------
  attribute mark_debug : string;
  attribute mark_debug of cnt       : signal is "true";
  attribute mark_debug of hs_on     : signal is "true";
  attribute mark_debug of ls_on     : signal is "true";
  attribute mark_debug of fault_lat : signal is "true";
  attribute mark_debug of rawh      : signal is "true";

begin

  duty_in(0) <= duty_a_i;
  duty_in(1) <= duty_b_i;
  duty_in(2) <= duty_c_i;

  safe <= fault_lat or (not enable_i);

  ---------------------------------------------------------------------------
  -- Portadora triangular (sobe 0->PERIOD, desce PERIOD->0)
  ---------------------------------------------------------------------------
  carrier_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      peak_s   <= '0';
      trough_s <= '0';
      if rst_i = '1' then
        cnt    <= (others => '0');
        dir_up <= '1';
      else
        if dir_up = '1' then
          if cnt >= PERIOD then
            dir_up <= '0';
            cnt    <= cnt - 1;
            peak_s <= '1';                     -- pico -> amostra ADC
          else
            cnt <= cnt + 1;
          end if;
        else
          if cnt = ZERO then
            dir_up   <= '1';
            cnt      <= cnt + 1;
            trough_s <= '1';                   -- vale -> carrega duties / gatilho controle
          else
            cnt <= cnt - 1;
          end if;
        end if;
      end if;
    end if;
  end process carrier_proc;

  adc_soc_o     <= peak_s;
  load_strobe_o <= trough_s;

  ---------------------------------------------------------------------------
  -- Double buffering + clamp (carrega no vale da portadora)
  ---------------------------------------------------------------------------
  load_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        duty_s(0) <= (others => '0');
        duty_s(1) <= (others => '0');
        duty_s(2) <= (others => '0');
      elsif trough_s = '1' then
        for i in 0 to 2 loop
          duty_s(i) <= clamp_duty(duty_in(i), DUTYMAX);
        end loop;
      end if;
    end if;
  end process load_proc;

  ---------------------------------------------------------------------------
  -- Comparacao center-aligned: alto quando portadora < duty (pulso no vale)
  ---------------------------------------------------------------------------
  cmp_gen : for i in 0 to 2 generate
    rawh(i) <= '1' when cnt < duty_s(i) else '0';
  end generate cmp_gen;

  ---------------------------------------------------------------------------
  -- Dead time por perna + estado seguro
  ---------------------------------------------------------------------------
  dt_gen : for i in 0 to 2 generate
    dt_proc : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = '1' or safe = '1' then
          hs_on(i)  <= '0';
          ls_on(i)  <= '0';
          dt_cnt(i) <= (others => '0');
          rawh_d(i) <= rawh(i);                -- acompanha p/ nao gerar dead time falso na liberacao
        else
          rawh_d(i) <= rawh(i);
          if rawh(i) /= rawh_d(i) then         -- transicao -> abre dead time (ambos off)
            hs_on(i)  <= '0';
            ls_on(i)  <= '0';
            dt_cnt(i) <= DEAD_CNT;
          elsif dt_cnt(i) /= ZERO then         -- durante o dead time: ambos off
            hs_on(i)  <= '0';
            ls_on(i)  <= '0';
            dt_cnt(i) <= dt_cnt(i) - 1;
          else                                 -- regime: comando complementar
            hs_on(i) <= rawh(i);
            ls_on(i) <= not rawh(i);
          end if;
        end if;
      end if;
    end process dt_proc;
  end generate dt_gen;

  ---------------------------------------------------------------------------
  -- Estagio de polaridade de saida (aplica GATE_ON_LEVEL)
  ---------------------------------------------------------------------------
  ah_o <= GATE_ON_LEVEL when hs_on(0) = '1' else not GATE_ON_LEVEL;
  al_o <= GATE_ON_LEVEL when ls_on(0) = '1' else not GATE_ON_LEVEL;
  bh_o <= GATE_ON_LEVEL when hs_on(1) = '1' else not GATE_ON_LEVEL;
  bl_o <= GATE_ON_LEVEL when ls_on(1) = '1' else not GATE_ON_LEVEL;
  ch_o <= GATE_ON_LEVEL when hs_on(2) = '1' else not GATE_ON_LEVEL;
  cl_o <= GATE_ON_LEVEL when ls_on(2) = '1' else not GATE_ON_LEVEL;

  ---------------------------------------------------------------------------
  -- Sincronizador (2 FF) + latch de falha (prioridade absoluta)
  ---------------------------------------------------------------------------
  sync_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      fault_sync <= fault_sync(0) & fault_i;
      fclr_sync  <= fclr_sync(0)  & fault_clear_i;
    end if;
  end process sync_proc;

  latch_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        fault_lat <= '0';
      elsif fault_sync(1) = '1' then           -- falha detectada -> trava
        fault_lat <= '1';
      elsif fclr_sync(1) = '1' then            -- reset manual -> libera
        fault_lat <= '0';
      end if;
    end if;
  end process latch_proc;

  fault_o <= fault_lat;

end architecture rtl;
