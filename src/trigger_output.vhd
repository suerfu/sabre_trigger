library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 28, 2016
-- The trigger output module receives input from
-- crystals, vetos and in the future crystal majority levels
-- It delays crystal coincidence signal by a programmable amount via shift register,
-- If veto signal is received in the mean time, reset signal is send to all component
-- for veto window time, else an trig_out signal is sent and dead time is imposed.
-- There are several input modes:
-- 1) master-slave mode with crystals as master
-- 2) crystal coincidence with liquid veto (via en)
-- 3) crystal coincidence with crystal majority veto (via en)
-- 4) veto independent trigger

entity trigger_output is
	generic( Nbits_trigtime : integer := 3; -- duration of trigger pulse
				Nbits_vetotime : integer := 8; -- length of veto window
				Nbits_deadtime : integer := 8  -- duration of dead time
				--Nbits_delaytime : integer := 3	-- not needed for shift register
	);
	port( clk : in std_logic;
			reset : in std_logic;
			crystal_input : in std_logic;		-- crystal coincidence signal
			veto_input : in std_logic;			-- veto coincidence input
			sig_delay_time : in std_logic_vector(2 downto 0);
														-- amount of delay in clock cycle applied to signal
														-- during the delay, system waits for veto signal
														-- implemented with 8-bit shift register
			veto_window : in std_logic_vector(Nbits_vetotime-1 downto 0);
														-- length of veto window in number of clock cycles
			dead_time : in std_logic_vector(Nbits_deadtime-1 downto 0);
														-- dead time after trigger is output
			output_mode : in std_logic_vector(1 downto 0);
														-- output mode: 01 for NaI alone, 10 for liquid scintillator alone
														-- 00 for veto mode, 11 for either NaI or liquid scintillator
			trig_out : out std_logic;
														-- trigger output to enable DAQ
			trig_time : in std_logic_vector(Nbits_trigtime-1 downto 0);
														-- duration of trigger output
			reset_out : out std_logic
														-- reset signal to NaI and veto components when either trig out or veto in.
	);
end trigger_output;

architecture arch_trigger_output of trigger_output is
signal delayed_out, mux_out, enable_veto, indep_trigger : std_logic;
signal reset_intnl, signal_out, veto_out : std_logic;
signal sync1, sync2 : std_logic;
begin
	indep_trigger <= crystal_input or veto_input; -- fires when either crystal or LS fires
	reset_intnl <= (not signal_out) and (not veto_out); -- reset internal registers

	-- shift register / delay generator to wait for possible veto
	gate_delay: entity work.delay_gen(arch_delay_gen)
		port map( clk => clk, reset => reset and reset_intnl,
					 sync_clr => '0', delay => sig_delay_time, D => crystal_input, Q => delayed_out
		);

	-- multiplexer for choosing output mode
	with output_mode select
		mux_out <= crystal_input when "01",
					  veto_input when "10",
					  indep_trigger when "11",
					  delayed_out when others;

	-- trigger output gate generator (either gate_gen or sync edge detector)
	lb_sync_det1: entity work.sync_edge_detector(arch_sync_edge_detector)
		port map( clk => clk, reset => reset_intnl, D => mux_out, Q => sync1);
		
	lb_trig: entity work.gate_generator(arch_gate_generator_mealy)
		generic map(Nbits_gate => Nbits_trigtime)
		port map( clk => clk, reset => reset, en => sync1,
					 gate_len => trig_time, gate => trig_out
		);
	-- dead window
	lb_deadwin: entity work.gate_generator(arch_gate_generator_mealy)
		generic map(Nbits_gate => Nbits_deadtime)
		port map( clk => clk, reset => reset, en => sync1,
					 gate_len => dead_time, gate => signal_out
		);
	--veto window
	lb_sync_det2: entity work.sync_edge_detector(arch_sync_edge_detector)
		port map( clk => clk, reset => reset and reset_intnl and enable_veto,
					 D => veto_input, Q => sync2
		);
		
	gate_veto: entity work.gate_generator(arch_gate_generator_mealy)
		generic map(Nbits_gate => Nbits_vetotime)
		port map( clk => clk, reset => reset and enable_veto,
					 en => sync2, gate_len => veto_window, gate => veto_out
		);
		
	enable_veto <= '1' when output_mode="00" else
						'0';
	reset_out <= reset_intnl;
	
end arch_trigger_output;