library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity XADCTest is
    Port ( 
        clk : in STD_LOGIC;
        JA  : in STD_LOGIC_VECTOR (7 downto 0);
        led : out STD_LOGIC_VECTOR (15 downto 0)
    );
end XADCTest;

architecture Behavioral of XADCTest is

    -- Componente gerado pelo XADC Wizard (Xilinx)
    COMPONENT xadc_wiz_0
    PORT (
        di_in      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        daddr_in   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        den_in     : IN  STD_LOGIC;
        dwe_in     : IN  STD_LOGIC;
        drdy_out   : OUT STD_LOGIC;
        do_out     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dclk_in    : IN  STD_LOGIC;
        vp_in      : IN  STD_LOGIC;
        vn_in      : IN  STD_LOGIC;
        vauxp5     : IN  STD_LOGIC;
        vauxn5     : IN  STD_LOGIC;
        channel_out: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        eoc_out    : OUT STD_LOGIC;
        alarm_out  : OUT STD_LOGIC;
        eos_out    : OUT STD_LOGIC;
        busy_out   : OUT STD_LOGIC
    );
    END COMPONENT;

    -- Sinais internos
    signal channel_out : std_logic_vector(4 downto 0);
    signal daddr_in    : std_logic_vector(6 downto 0);
    signal eoc_out     : std_logic;
    signal do_out      : std_logic_vector(15 downto 0);
    signal anal_p      : std_logic;
    signal anal_n      : std_logic;

begin

    -- Instância do XADC Wizard (configurado para canal auxiliar 5)
    your_xadc: xadc_wiz_0
    PORT MAP (
        di_in      => (others => '0'),     -- Não usado (escrita)
        daddr_in   => (others => '0'),     -- Endereço fixo (leitura contínua)
        den_in     => '0',                 -- Desabilita DRP (leitura automática)
        dwe_in     => '0',                 -- Não escreve
        drdy_out   => open,                -- Não usado
        do_out     => do_out,              -- Dados lidos do XADC
        dclk_in    => clk,                 -- Clock do sistema
        vp_in      => '0',                 -- Não usado (entrada dedicada)
        vn_in      => '0',                 -- Não usado
        vauxp5     => anal_p,              -- Sinal positivo do canal auxiliar 5
        vauxn5     => anal_n,              -- Sinal negativo do canal auxiliar 5
        channel_out=> open,                -- Não usado
        eoc_out    => open,                -- Não usado
        alarm_out  => open,                -- Não usado
        eos_out    => open,                -- Não usado
        busy_out   => open                 -- Não usado
    );

    -- Conexão dos pinos do conector JA com as entradas do XADC
    -- Pino JA(4) = positivo (P) do canal auxiliar 5
    -- Pino JA(0) = negativo (N) do canal auxiliar 5
    anal_p <= JA(4);   -- JA(0) é JA1, JA(4) é JA7
    anal_n <= JA(0);

    -- Processo de exibição: mostra os 8 bits mais significativos do resultado
    process(clk)
    begin
        if rising_edge(clk) then
            -- Exibe os 8 bits superiores (bits 15 a 8) nos LEDs
            led(7 downto 0) <= do_out(15 downto 8);
            -- Os LEDs superiores (15 a 8) permanecem apagados (0)
            led(15 downto 8) <= (others => '0');
        end if;
    end process;

end Behavioral;
