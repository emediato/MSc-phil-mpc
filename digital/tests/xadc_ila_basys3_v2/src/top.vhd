----------------------------------------------------------------------------------
-- top.vhd - Leitura do XADC (VAUX6 = XA1 do JXADC) com visualizacao via ILA
-- Basys3 / Artix-7 XC7A35T
--
-- Arquitetura:
--   * XADC Wizard em modo DRP, continuo, canal unico VAUX6, unipolar
--   * Laco classico eoc->den: cada fim de conversao dispara a leitura DRP
--   * Registro do codigo (bits [15:4] de do_out) validado por drdy
--   * DECIMACAO: strobe cap_en a cada 50 us (20 kSPS) -> com depth 1024,
--     a janela do ILA e de 51,2 ms (~3 ciclos de 60 Hz, ~20 de 400 Hz)
--   * ILA: probe0 = codigo (12 bits), probe1 = cap_en (qualificador)
--   * LEDs: codigo congelado a cada 50 ms (legivel a olho)
--
-- Ensaio (metodologia E2/E4):
--   Gerador: senoide 60 Hz (depois 400 Hz), High=0,9 V / Low=0,1 V, carga High-Z
--   Sinal em XA1_P (J3), retorno em XA1_N (K3) + GND (pino 5 do Pmod)
--   Codigo esperado: senoide em torno de ~2048 (0x800)
--
-- Hardware Manager:
--   Capture Setup: BASIC, qualificador cap_en == 1
--   Trigger: codigo == 0x800, posicao 512 (centro do buffer de 1024)
--   Probe codigo: Radix Unsigned Decimal + Waveform Style Analog
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    port (
        clk     : in  std_logic;                      -- 100 MHz (W5)
        vauxp6  : in  std_logic;                      -- XA1_P (J3)
        vauxn6  : in  std_logic;                      -- XA1_N (K3)
        led     : out std_logic_vector(15 downto 0)   -- codigo em binario
    );
end top;

architecture rtl of top is

    -- ================= XADC Wizard (gerado pelo create_project.tcl) ==========
    component xadc_wiz_0
        port (
            di_in       : in  std_logic_vector(15 downto 0);
            daddr_in    : in  std_logic_vector(6 downto 0);
            den_in      : in  std_logic;
            dwe_in      : in  std_logic;
            drdy_out    : out std_logic;
            do_out      : out std_logic_vector(15 downto 0);
            dclk_in     : in  std_logic;
            vauxp6      : in  std_logic;
            vauxn6      : in  std_logic;
            busy_out    : out std_logic;
            channel_out : out std_logic_vector(4 downto 0);
            eoc_out     : out std_logic;
            eos_out     : out std_logic;
            alarm_out   : out std_logic;
            vp_in       : in  std_logic;
            vn_in       : in  std_logic
        );
    end component;

    -- ================= ILA (gerado pelo create_project.tcl) ==================
    component ila_0
        port (
            clk    : in std_logic;
            probe0 : in std_logic_vector(11 downto 0);
            probe1 : in std_logic_vector(0 downto 0)
        );
    end component;

    -- ================= Constantes ============================================
    constant ADDR_VAUX6 : std_logic_vector(6 downto 0) := "0010110"; -- 0x16

    -- Decimacao: 5000 ciclos de 10 ns = 50 us -> 20 kSPS
    --   depth 1024 x 50 us = 51,2 ms de janela
    --   60 Hz  -> ~3 ciclos, ~333 amostras por ciclo
    --   400 Hz -> ~20 ciclos, ~50 amostras por ciclo
    constant DEC_MAX : integer := 4999;

    -- Tick de 50 ms para congelar os LEDs (5_000_000 ciclos)
    constant LED_MAX : integer := 4999999;

    -- ================= Sinais ================================================
    signal eoc     : std_logic;
    signal drdy    : std_logic;
    signal do_out  : std_logic_vector(15 downto 0);
    signal codigo  : std_logic_vector(11 downto 0) := (others => '0');

    signal dec_cnt : integer range 0 to DEC_MAX := 0;
    signal pend    : std_logic := '0';
    signal cap_en  : std_logic := '0';
    signal cap_v   : std_logic_vector(0 downto 0);

    signal cnt_led : integer range 0 to LED_MAX := 0;
    signal led_reg : std_logic_vector(11 downto 0) := (others => '0');

begin

    -- ================= XADC: laco de auto-leitura ============================
    -- den_in <= eoc_out : cada fim de conversao habilita a leitura DRP do
    -- resultado no endereco 0x16 (registrador de status do VAUX6).
    u_xadc : xadc_wiz_0
        port map (
            di_in       => (others => '0'),
            daddr_in    => ADDR_VAUX6,
            den_in      => eoc,
            dwe_in      => '0',
            drdy_out    => drdy,
            do_out      => do_out,
            dclk_in     => clk,
            vauxp6      => vauxp6,
            vauxn6      => vauxn6,
            busy_out    => open,
            channel_out => open,
            eoc_out     => eoc,
            eos_out     => open,
            alarm_out   => open,
            vp_in       => '0',
            vn_in       => '0'
        );

    -- ================= Registro do codigo + strobe decimado ==================
    -- O contador marca "esta na hora" (pend); a captura so e sinalizada no
    -- proximo drdy, garantindo que a amostra gravada seja sempre uma conversao
    -- fresca. Jitter maximo = 1 conversao (~1 us) = 0,02 deg a 60 Hz.
    process(clk)
    begin
        if rising_edge(clk) then
            cap_en <= '0';                      -- pulso de 1 ciclo

            if dec_cnt = DEC_MAX then
                dec_cnt <= 0;
                pend    <= '1';
            else
                dec_cnt <= dec_cnt + 1;
            end if;

            if drdy = '1' then
                codigo <= do_out(15 downto 4);  -- 12 bits validos
                if pend = '1' then
                    cap_en <= '1';
                    pend   <= '0';
                end if;
            end if;
        end if;
    end process;

    cap_v(0) <= cap_en;

    -- ================= ILA ===================================================
    -- Mesmo dominio de clock do dclk_in do XADC (obrigatorio).
    -- No Hardware Manager, qualificar a captura por cap_en == 1.
    u_ila : ila_0
        port map (
            clk    => clk,
            probe0 => codigo,
            probe1 => cap_v
        );

    -- ================= LEDs: retrato a cada 50 ms ============================
    process(clk)
    begin
        if rising_edge(clk) then
            if cnt_led = LED_MAX then
                cnt_led <= 0;
                led_reg <= codigo;
            else
                cnt_led <= cnt_led + 1;
            end if;
        end if;
    end process;

    led(15 downto 4) <= led_reg;
    led(3 downto 0)  <= (others => '0');

end rtl;
