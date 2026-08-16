------------------------------------------------------------------------------
-- PURPOSE		: Generates inverter trapezoidal commands based in the duty cycle
-- and the sequencer state.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Libraries
-------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------
entity mctl_cmd_inv_trap_pwm is
	port (
		----
		-- Control
		clk_40m								: in	std_logic;								-- Motor Control clock
		rst_40m								: in	std_logic;								-- Motor Control reset at @clk_40m

		----
		-- Mode selection
		mctl_mode_inv_trap_en				: in	std_logic;								-- Motor control mode inverter trapezoidal enabled

		----
		-- PWM duty cycle
		mctl_pwm_dc							: in	integer range 0 to MCTL_PWM_DC_MAX;		-- PWM duty cycle

		----
		-- Sequencer
		mctl_inv_out						: in	std_logic_vector(2 downto 0);			-- Sequencer trapezoidal output

		----
		-- Inverter command
		mctl_inv_out_a_ina_pin				: out	std_logic;								-- Motor Control inverter trapezoidal mode - A_IN_A
		mctl_inv_out_a_inb_pin				: out	std_logic;								-- Motor Control inverter trapezoidal mode - A_IN_B
		mctl_inv_out_b_ina_pin				: out	std_logic;								-- Motor Control inverter trapezoidal mode - B_IN_A
		mctl_inv_out_b_inb_pin				: out	std_logic;								-- Motor Control inverter trapezoidal mode - B_IN_B
		mctl_inv_out_c_ina_pin				: out	std_logic;								-- Motor Control inverter trapezoidal mode - C_IN_A
		mctl_inv_out_c_inb_pin				: out	std_logic;								-- Motor Control inverter trapezoidal mode - C_IN_B

		----
		-- Verification Port
		vprobe_mctl_inv_out_a_ina_pin		: out	std_logic;								-- vprobe: mctl_inv_out_a_ina_pin
		vprobe_mctl_inv_out_a_inb_pin		: out	std_logic;								-- vprobe: mctl_inv_out_a_inb_pin
		vprobe_mctl_inv_out_b_ina_pin		: out	std_logic;								-- vprobe: mctl_inv_out_b_ina_pin
		vprobe_mctl_inv_out_b_inb_pin		: out	std_logic;								-- vprobe: mctl_inv_out_b_inb_pin
		vprobe_mctl_inv_out_c_ina_pin		: out	std_logic;								-- vprobe: mctl_inv_out_c_ina_pin
		vprobe_mctl_inv_out_c_inb_pin		: out	std_logic								-- vprobe: mctl_inv_out_c_inb_pin
		);
end entity mctl_cmd_inv_trap_pwm;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture rtl of mctl_cmd_inv_trap_pwm is
	-----------------------------------
	-- Constant Declarations
	-----------------------------------

	-----------------------------------
	-- Signal Declarations
	-----------------------------------

	-- PWM
	signal mctl_pwm_dc_reg					: integer range 0 to MCTL_PWM_DC_MAX;				-- PWM duty cycle registration
	signal mctl_pwm_dc_lt_min				: std_logic;										-- PWM duty cycle flag
	signal mctl_pwm_out_cnt					: integer range 0 to MCTL_PWM_DC_MAX - 1;			-- PWM counter
	signal mctl_pwm_out_en					: std_logic;										-- PWM output clock enable
	signal mctl_pwm_out_en_reg				: std_logic;										-- PWM output clock enable registration

	-- Switching dead time management
	signal mctl_pwm_dead_en					: std_logic;										-- PWM output dead time clock enable
	signal mctl_pwm_dead_cnt				: integer range 0 to MCTL_PWM_DEAD_TIME;			-- PWM output dead time counter after PWM toggle

	-- Command output enable
	signal mctl_inv_out_a_ina_en			: std_logic;										-- Motor Control inverter clock enable - A_IN_A
	signal mctl_inv_out_a_inb_en			: std_logic;										-- Motor Control inverter clock enable - A_IN_B
	signal mctl_inv_out_b_ina_en			: std_logic;										-- Motor Control inverter clock enable - B_IN_A
	signal mctl_inv_out_b_inb_en			: std_logic;										-- Motor Control inverter clock enable - B_IN_B
	signal mctl_inv_out_c_ina_en			: std_logic;										-- Motor Control inverter clock enable - C_IN_A
	signal mctl_inv_out_c_inb_en			: std_logic;										-- Motor Control inverter clock enable - C_IN_B

	signal mctl_inv_out_a_ina_en_reg		: std_logic;										-- Motor Control inverter clock enable registration - A_IN_A
	signal mctl_inv_out_b_ina_en_reg		: std_logic;										-- Motor Control inverter clock enable registration - B_IN_A
	signal mctl_inv_out_c_ina_en_reg		: std_logic;										-- Motor Control inverter clock enable registration - C_IN_A
	
	-- Swching sequence controller signals
	signal mctl_inv_out_a_ina_reg			: std_logic;										-- Motor Control inverter trapezoidal mode - A_IN_A
	signal mctl_inv_out_a_inb_reg			: std_logic;										-- Motor Control inverter trapezoidal mode - A_IN_B
	signal mctl_inv_out_b_ina_reg			: std_logic;										-- Motor Control inverter trapezoidal mode - B_IN_A
	signal mctl_inv_out_b_inb_reg			: std_logic;										-- Motor Control inverter trapezoidal mode - B_IN_B
	signal mctl_inv_out_c_ina_reg			: std_logic;										-- Motor Control inverter trapezoidal mode - C_IN_A
	signal mctl_inv_out_c_inb_reg			: std_logic;										-- Motor Control inverter trapezoidal mode - C_IN_B
	
begin
	
	-----------------------------------
	-- Asynchronous Assignment
	-----------------------------------
	vprobe_mctl_inv_out_a_ina_pin		<= mctl_inv_out_a_ina_reg;
	vprobe_mctl_inv_out_a_inb_pin		<= mctl_inv_out_a_inb_reg;
	vprobe_mctl_inv_out_b_ina_pin		<= mctl_inv_out_b_ina_reg;
	vprobe_mctl_inv_out_b_inb_pin		<= mctl_inv_out_b_inb_reg;
	vprobe_mctl_inv_out_c_ina_pin		<= mctl_inv_out_c_ina_reg;
	vprobe_mctl_inv_out_c_inb_pin		<= mctl_inv_out_c_inb_reg;

	-----------------------------------
	-- Processes
	-----------------------------------
	-- Command output
	seq_out_proc : process(clk_40m)
	begin
		if rising_edge(clk_40m) then
			-- Command output registration
			
			mctl_inv_out_a_ina_en_reg	<= mctl_inv_out_a_ina_en;
			mctl_inv_out_b_ina_en_reg	<= mctl_inv_out_b_ina_en;
			mctl_inv_out_c_ina_en_reg	<= mctl_inv_out_c_ina_en;

			case mctl_inv_out is
				when MCTL_INV_SEQ_STEP_UNKOWN_1 | MCTL_INV_SEQ_STEP_UNKOWN_2 =>
					-- Z
					mctl_inv_out_a_ina_en	<= DEASSERTED;
					mctl_inv_out_a_inb_en	<= DEASSERTED;

					-- Z
					mctl_inv_out_b_ina_en	<= DEASSERTED;
					mctl_inv_out_b_inb_en	<= DEASSERTED;

					-- Z
					mctl_inv_out_c_ina_en	<= DEASSERTED;
					mctl_inv_out_c_inb_en	<= DEASSERTED;

				when MCTL_INV_SEQ_STEP_1 =>
					-- H
					mctl_inv_out_a_ina_en	<= ASSERTED;
					mctl_inv_out_a_inb_en	<= DEASSERTED;

					-- L
					mctl_inv_out_b_ina_en	<= DEASSERTED;
					mctl_inv_out_b_inb_en	<= ASSERTED;

					-- Z
					mctl_inv_out_c_ina_en	<= DEASSERTED;
					mctl_inv_out_c_inb_en	<= DEASSERTED;

				when MCTL_INV_SEQ_STEP_2 =>
					-- H
					mctl_inv_out_a_ina_en	<= ASSERTED;
					mctl_inv_out_a_inb_en	<= DEASSERTED;

					-- Z
					mctl_inv_out_b_ina_en	<= DEASSERTED;
					mctl_inv_out_b_inb_en	<= DEASSERTED;

					-- L
					mctl_inv_out_c_ina_en	<= DEASSERTED;
					mctl_inv_out_c_inb_en	<= ASSERTED;

				when MCTL_INV_SEQ_STEP_3 =>
					-- Z
					mctl_inv_out_a_ina_en	<= DEASSERTED;
					mctl_inv_out_a_inb_en	<= DEASSERTED;

					-- H
					mctl_inv_out_b_ina_en	<= ASSERTED;
					mctl_inv_out_b_inb_en	<= DEASSERTED;

					-- L
					mctl_inv_out_c_ina_en	<= DEASSERTED;
					mctl_inv_out_c_inb_en	<= ASSERTED;

				when MCTL_INV_SEQ_STEP_4 =>
					-- L
					mctl_inv_out_a_ina_en	<= DEASSERTED;
					mctl_inv_out_a_inb_en	<= ASSERTED;

					-- H
					mctl_inv_out_b_ina_en	<= ASSERTED;
					mctl_inv_out_b_inb_en	<= DEASSERTED;

					-- Z
					mctl_inv_out_c_ina_en	<= DEASSERTED;
					mctl_inv_out_c_inb_en	<= DEASSERTED;

				when MCTL_INV_SEQ_STEP_5 =>
					-- L
					mctl_inv_out_a_ina_en	<= DEASSERTED;
					mctl_inv_out_a_inb_en	<= ASSERTED;

					-- Z
					mctl_inv_out_b_ina_en	<= DEASSERTED;
					mctl_inv_out_b_inb_en	<= DEASSERTED;

					-- H
					mctl_inv_out_c_ina_en	<= ASSERTED;
					mctl_inv_out_c_inb_en	<= DEASSERTED;

				when MCTL_INV_SEQ_STEP_6 =>
					-- Z
					mctl_inv_out_a_ina_en	<= DEASSERTED;
					mctl_inv_out_a_inb_en	<= DEASSERTED;

					-- L
					mctl_inv_out_b_ina_en	<= DEASSERTED;
					mctl_inv_out_b_inb_en	<= ASSERTED;

					-- H
					mctl_inv_out_c_ina_en	<= ASSERTED;
					mctl_inv_out_c_inb_en	<= DEASSERTED;

				when others =>
					-- Z
					mctl_inv_out_a_ina_en	<= DEASSERTED;
					mctl_inv_out_a_inb_en	<= DEASSERTED;

					-- Z
					mctl_inv_out_b_ina_en	<= DEASSERTED;
					mctl_inv_out_b_inb_en	<= DEASSERTED;

					-- Z
					mctl_inv_out_c_ina_en	<= DEASSERTED;
					mctl_inv_out_c_inb_en	<= DEASSERTED;
					
			end case;
			if rst_40m = ASSERTED then
				-- Z
				mctl_inv_out_a_ina_en		<= DEASSERTED;
				mctl_inv_out_a_inb_en		<= DEASSERTED;

				-- Z
				mctl_inv_out_b_ina_en		<= DEASSERTED;
				mctl_inv_out_b_inb_en		<= DEASSERTED;

				-- Z
				mctl_inv_out_c_ina_en		<= DEASSERTED;
				mctl_inv_out_c_inb_en		<= DEASSERTED;

				-- Command output registration
				mctl_inv_out_a_ina_en_reg	<= DEASSERTED;
				mctl_inv_out_b_ina_en_reg	<= DEASSERTED;
				mctl_inv_out_c_ina_en_reg	<= DEASSERTED;
			end if;
		end if;

	end process seq_out_proc;

	-- PWM duty cycle registration
	pwm_dc_proc : process(clk_40m)
	begin
		if rising_edge(clk_40m) then
			if mctl_inv_out_a_ina_en_reg /= mctl_inv_out_a_ina_en or mctl_inv_out_b_ina_en_reg /= mctl_inv_out_b_ina_en or mctl_inv_out_c_ina_en_reg /= mctl_inv_out_c_ina_en or mctl_pwm_out_cnt >= (MCTL_PWM_DC_MAX - 2) then
				mctl_pwm_dc_reg			<= mctl_pwm_dc;
			end if;

			if mctl_pwm_dc < DUTY_LT_MIN_INB then
				mctl_pwm_dc_lt_min		<= ASSERTED;
			else
				mctl_pwm_dc_lt_min		<= DEASSERTED;
			end if;

			if rst_40m = ASSERTED then
				mctl_pwm_dc_reg			<= 0;
				mctl_pwm_dc_lt_min		<= DEASSERTED;
			end if;
		end if;
	end process pwm_dc_proc;

	-- PWM output
	pwm_out_proc : process(clk_40m)
	begin
		if rising_edge(clk_40m) then
			-- PWM output clock enable registration
			mctl_pwm_out_en_reg		<= mctl_pwm_out_en;

			if mctl_mode_inv_trap_en = ASSERTED then
				-- PWM count goes from 0 to mctl_pwm_dc_reg - 1, with a total of mctl_pwm_dc_reg pulses
				if mctl_pwm_out_cnt >= (mctl_pwm_dc_reg - 1) then
					mctl_pwm_out_en		<= ASSERTED;
				else
					mctl_pwm_out_en		<= DEASSERTED;
				end if;

				if mctl_inv_out_a_ina_en_reg /= mctl_inv_out_a_ina_en or mctl_inv_out_b_ina_en_reg /= mctl_inv_out_b_ina_en or mctl_inv_out_c_ina_en_reg /= mctl_inv_out_c_ina_en or mctl_pwm_out_cnt >= (MCTL_PWM_DC_MAX - 1) then
					mctl_pwm_out_cnt	<= 0;
					if mctl_pwm_dc /= 0 then
						mctl_pwm_out_en		<= DEASSERTED;
					end if;
				else
					mctl_pwm_out_cnt	<= mctl_pwm_out_cnt + 1;
				end if;
			else
				mctl_pwm_out_cnt	<= 0;
				mctl_pwm_out_en		<= DEASSERTED;
			end if;

			if rst_40m = ASSERTED then
				mctl_pwm_out_cnt	<= 0;
				mctl_pwm_out_en		<= ASSERTED;
			end if;
		end if;
	end process pwm_out_proc;

	pwm_dead_proc : process(clk_40m)
	begin
		if rising_edge(clk_40m) then
			-- dead time control
			if mctl_inv_out_a_ina_en_reg /= mctl_inv_out_a_ina_en or mctl_inv_out_b_ina_en_reg /= mctl_inv_out_b_ina_en or mctl_inv_out_c_ina_en_reg /= mctl_inv_out_c_ina_en then
				mctl_pwm_dead_en <= ASSERTED;
			else
				if mctl_pwm_dead_cnt >= MCTL_PWM_DEAD_TIME-1 then
					mctl_pwm_dead_en <= DEASSERTED;
				else
					mctl_pwm_dead_en <= ASSERTED;
				end if;
			end if;

			-- dead cnt management
			if mctl_pwm_dead_en = ASSERTED then
				mctl_pwm_dead_cnt <= mctl_pwm_dead_cnt + 1;
			else
				if mctl_pwm_out_en = DEASSERTED and mctl_pwm_out_cnt >= (mctl_pwm_dc_reg - MCTL_PWM_DEAD_HALF_TIME - 1) then
					-- start dead time previously to PWM rising_edge
					mctl_pwm_dead_cnt	<= 0;
					-- Asserting mctl_pwm_dead_en to ensure dead counter update in the first cycle in which dead counter < MCTL_PWM_DEAD_TIME - 1
					mctl_pwm_dead_en	<= ASSERTED;
				elsif mctl_pwm_out_en = ASSERTED and mctl_pwm_out_cnt >= (MCTL_PWM_DC_MAX - MCTL_PWM_DEAD_HALF_TIME - 1) then
					-- start dead time previously to PWM falling_edge
					mctl_pwm_dead_cnt	<= 0;
					-- Asserting mctl_pwm_dead_en to ensure dead counter update in the first cycle in which dead counter < MCTL_PWM_DEAD_TIME - 1
					mctl_pwm_dead_en	<= ASSERTED;
				end if;
			end if;

			if mctl_inv_out_a_ina_en_reg /= mctl_inv_out_a_ina_en or mctl_inv_out_b_ina_en_reg /= mctl_inv_out_b_ina_en or mctl_inv_out_c_ina_en_reg /= mctl_inv_out_c_ina_en or (mctl_pwm_out_en_reg and not(mctl_pwm_out_en)) = ASSERTED then
				-- Switching sequence change. It is required to ensure dead time after PWM change 
				mctl_pwm_dead_cnt	<= MCTL_PWM_DEAD_HALF_TIME;
			end if;

			-- Disable INB pin if Inverter is disabled or if duty cycle is below 2x dead time 
			if mctl_mode_inv_trap_en = DEASSERTED OR mctl_pwm_dc_lt_min = ASSERTED then
				mctl_pwm_dead_cnt	<= MCTL_PWM_DEAD_HALF_TIME;
				mctl_pwm_dead_en	<= ASSERTED;
			end if;
		end if;
	end process pwm_dead_proc;

	-- Command Sequence
	cmd_seq_proc : process(clk_40m)
	begin
		if rising_edge(clk_40m) then
			-- Command output A
			if mctl_inv_out_a_ina_en_reg = ASSERTED then
				mctl_inv_out_a_ina_reg		<= not mctl_pwm_out_en;
				mctl_inv_out_a_inb_reg		<= mctl_pwm_dead_en;
			elsif mctl_inv_out_a_inb_en = ASSERTED then
				mctl_inv_out_a_ina_reg		<= DEASSERTED;
				mctl_inv_out_a_inb_reg		<= DEASSERTED;
			else
				mctl_inv_out_a_ina_reg		<= DEASSERTED;
				mctl_inv_out_a_inb_reg		<= ASSERTED;
			end if;

			if mctl_inv_out_b_ina_en_reg = ASSERTED then
				mctl_inv_out_b_ina_reg		<= not mctl_pwm_out_en;
				mctl_inv_out_b_inb_reg		<= mctl_pwm_dead_en;
			elsif mctl_inv_out_b_inb_en = ASSERTED then
				mctl_inv_out_b_ina_reg		<= DEASSERTED;
				mctl_inv_out_b_inb_reg		<= DEASSERTED;
			else
				mctl_inv_out_b_ina_reg		<= DEASSERTED;
				mctl_inv_out_b_inb_reg		<= ASSERTED;
			end if;

			if mctl_inv_out_c_ina_en_reg = ASSERTED then
				mctl_inv_out_c_ina_reg		<= not mctl_pwm_out_en;
				mctl_inv_out_c_inb_reg		<= mctl_pwm_dead_en;
			elsif mctl_inv_out_c_inb_en = ASSERTED then
				mctl_inv_out_c_ina_reg		<= DEASSERTED;
				mctl_inv_out_c_inb_reg		<= DEASSERTED;
			else
				mctl_inv_out_c_ina_reg		<= DEASSERTED;
				mctl_inv_out_c_inb_reg		<= ASSERTED;
			end if;

			if ((mctl_inv_out_c_ina_en_reg and mctl_inv_out_b_ina_en_reg) or (mctl_inv_out_c_ina_en_reg and mctl_inv_out_a_ina_en_reg) or (mctl_inv_out_a_ina_en_reg and mctl_inv_out_b_ina_en_reg)) = ASSERTED then
				mctl_inv_out_a_ina_reg		<= DEASSERTED;
				mctl_inv_out_a_inb_reg		<= ASSERTED;
				mctl_inv_out_b_ina_reg		<= DEASSERTED;
				mctl_inv_out_b_inb_reg		<= ASSERTED;
				mctl_inv_out_c_ina_reg		<= DEASSERTED;
				mctl_inv_out_c_inb_reg		<= ASSERTED;
			end if;

		end if;
	end process cmd_seq_proc;

	-- Command output
	cmd_out_proc : process(clk_40m, rst_40m)
	begin
		if rst_40m = ASSERTED then
			mctl_inv_out_a_ina_pin		<= DEASSERTED;
			mctl_inv_out_a_inb_pin		<= ASSERTED;
			mctl_inv_out_b_ina_pin		<= DEASSERTED;
			mctl_inv_out_b_inb_pin		<= ASSERTED;
			mctl_inv_out_c_ina_pin		<= DEASSERTED;
			mctl_inv_out_c_inb_pin		<= ASSERTED;
		else
			if rising_edge(clk_40m) then
				mctl_inv_out_a_ina_pin <= mctl_inv_out_a_ina_reg;
				mctl_inv_out_a_inb_pin <= mctl_inv_out_a_inb_reg;
				mctl_inv_out_b_ina_pin <= mctl_inv_out_b_ina_reg;
				mctl_inv_out_b_inb_pin <= mctl_inv_out_b_inb_reg;
				mctl_inv_out_c_ina_pin <= mctl_inv_out_c_ina_reg;
				mctl_inv_out_c_inb_pin <= mctl_inv_out_c_inb_reg;
			end if;
		end if;
	end process cmd_out_proc;
end architecture rtl;
