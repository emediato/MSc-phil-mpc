-------------------------------------------------------------------------------
-- pwm_pkg.vhd
-- Pacote de apoio para o modulador PWM trifasico center-aligned.
-- Funcoes auxiliares e constante de largura dos barramentos de duty cycle.
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package pwm_pkg is

  -- Largura dos barramentos de duty cycle. 16 bits cobrem qualquer PERIOD
  -- realista (ex.: 40 MHz / (2*500 Hz) = 40000 < 65535).
  constant DUTY_W : positive := 16;

  -- clog2: numero de bits para representar 0..n-1
  function clog2(n : positive) return natural;

  -- maximo de dois inteiros
  function max2(a, b : integer) return integer;

  -- satura d no intervalo [0, dmax]
  function clamp_duty(d : unsigned; dmax : unsigned) return unsigned;

end package pwm_pkg;

package body pwm_pkg is

  function clog2(n : positive) return natural is
    variable r : natural  := 0;
    variable v : positive := 1;
  begin
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  function max2(a, b : integer) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;

  function clamp_duty(d : unsigned; dmax : unsigned) return unsigned is
  begin
    if d > dmax then
      return dmax;
    else
      return resize(d, dmax'length);
    end if;
  end function;

end package body pwm_pkg;
