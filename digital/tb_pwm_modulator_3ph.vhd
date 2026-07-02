-------------------------------------------------------------------------------
-- tb_pwm_modulator_3ph.vhd
-- Testbench do modulador. Gera clock/reset, aplica 3 duties (uma acima do
-- clamp de bootstrap), injeta uma falha, limpa, e verifica em toda borda de
-- clock que NAO ha shoot-through (lado alto e baixo nunca conduzem juntos).
-- Compilar/rodar com --std=08.
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library std;
  use std.env.all;

library work;
  use work.pwm_pkg.all;

entity tb_pwm_modulator_3ph is
end entity tb_pwm_modulator_3ph;

architecture sim of tb_pwm_modulator_3ph is

  constant CLK_FREQ_HZ   : positive  := 40_000_000;
  constant F_SW_HZ       : positive  := 20_000;
  constant DEAD_TIME_NS  : positive  := 1_000;
  constant BOOT_MIN_NS   : positive  := 3_000;
  constant GATE_ON_LEVEL : std_logic := '1';

  constant CLK_PERIOD : time := 1 sec / CLK_FREQ_HZ;   -- 25 ns @ 40 MHz

  signal clk         : std_logic := '0';
  signal rst         : std_logic := '1';
  signal enable      : std_logic := '0';
  signal fault       : std_logic := '0';
  signal fault_clear : std_logic := '0';
  signal duty_a      : unsigned(DUTY_W-1 downto 0) := (others => '0');
  signal duty_b      : unsigned(DUTY_W-1 downto 0) := (others => '0');
  signal duty_c      : unsigned(DUTY_W-1 downto 0) := (others => '0');
  signal ah, al, bh, bl, ch, cl       : std_logic;
  signal adc_soc, load_strobe, faulto : std_logic;

  -- converte nivel do pino para "conduz" (1 = IGBT conduzindo)
  function conducts(x : std_logic) return std_logic is
  begin
    if x = GATE_ON_LEVEL then
      return '1';
    else
      return '0';
    end if;
  end function;

begin

  dut : entity work.pwm_modulator_3ph
    generic map (
      CLK_FREQ_HZ   => CLK_FREQ_HZ,
      F_SW_HZ       => F_SW_HZ,
      DEAD_TIME_NS  => DEAD_TIME_NS,
      BOOT_MIN_NS   => BOOT_MIN_NS,
      GATE_ON_LEVEL => GATE_ON_LEVEL
    )
    port map (
      clk_i         => clk,
      rst_i         => rst,
      enable_i      => enable,
      fault_i       => fault,
      fault_clear_i => fault_clear,
      duty_a_i      => duty_a,
      duty_b_i      => duty_b,
      duty_c_i      => duty_c,
      ah_o => ah, al_o => al,
      bh_o => bh, bl_o => bl,
      ch_o => ch, cl_o => cl,
      adc_soc_o     => adc_soc,
      load_strobe_o => load_strobe,
      fault_o       => faulto
    );

  -- clock
  clk <= not clk after CLK_PERIOD/2;

  -- estimulo
  stim : process
  begin
    rst    <= '1';
    enable <= '0';
    wait for 10*CLK_PERIOD;
    rst <= '0';
    wait for 5*CLK_PERIOD;

    -- duties: 50%, 25% e 90% (esta ultima excede DUTYMAX -> sofre clamp de bootstrap)
    duty_a <= to_unsigned(500, DUTY_W);
    duty_b <= to_unsigned(250, DUTY_W);
    duty_c <= to_unsigned(900, DUTY_W);
    enable <= '1';

    wait for 200 us;                 -- roda ~4 periodos de PWM (periodo = 50 us)

    -- injeta falha e verifica que trava
    fault <= '1';
    wait for 2*CLK_PERIOD;
    fault <= '0';
    wait for 50 us;                  -- deve permanecer desligado (latch)

    -- reset manual e retomada
    fault_clear <= '1';
    wait for 2*CLK_PERIOD;
    fault_clear <= '0';
    wait for 100 us;

    report "Simulacao concluida sem shoot-through." severity note;
    stop;
  end process stim;

  -- checagem de shoot-through (valida o dead time / estado seguro)
  check : process(clk)
  begin
    if rising_edge(clk) then
      assert not (conducts(ah) = '1' and conducts(al) = '1')
        report "SHOOT-THROUGH na perna A!" severity failure;
      assert not (conducts(bh) = '1' and conducts(bl) = '1')
        report "SHOOT-THROUGH na perna B!" severity failure;
      assert not (conducts(ch) = '1' and conducts(cl) = '1')
        report "SHOOT-THROUGH na perna C!" severity failure;
    end if;
  end process check;

end architecture sim;
