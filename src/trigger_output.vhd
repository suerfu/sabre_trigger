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
	generic( Nbits_trigtime : integer := 3;
					-- length of trigger time
				Nbits_vetotime : integer := 8;
					-- number of bits for veto window
				Nbits_deadtime : integer := 8;
					-- number of bits for dead time
				Nbits_delaytime : integer := 3
					-- number of bits needed to describe delay time
				);
	port( clk : in std_logic;
				-- system clock input
			reset : in std_logic;
				-- system global reset by user
			crystal_input : in std_logic;
				-- crystal coincidence input
			veto_input : in std_logic;
				-- veto input
			veto_en : in std_logic;
				-- veto enable / diable
			sig_delay_time : in std_logic_vector(Nbits_delaytime-1 downto 0);
				-- amount of delay in clock cycle applied to signal
				-- during the delay, system waits for veto signal
			veto_window : in std_logic_vector(Nbits_vetotime-1 downto 0);
				-- length of veto window in number of clock cycles
			dead_time : in std_logic_vector(Nbits_deadtime-1 downto 0);
				-- dead time after trigger is output
			output_mode : in std_logic_vector(1 downto 0);
				-- output mode: 00 for NaI alone as trigger, 11 as veto alone as trigger
				-- other as vetoed NaI output
			trig_out : out std_logic;
				-- trigger output to enable DAQ
			trig_time : in std_logic_vector(Nbits_trigtime-1 downto 0);
				-- duration of trigger output
			reset_out : out std_logic
				-- reset signal to NaI and veto components when either trig out or veto in.
			);
	
end trigger_output;

architecture arch_trigger_output of trigger_output is
signal delayed_out, mux_out, signal_out, veto_out, enable_veto, indep_trigger: std_logic;
begin
	indep_trigger <= crystal_input or veto_input;

	-- shift register / delay generator to wait for possible veto
	gate_delay: entity work.delay_gen(arch_delay_gen)
		generic map(Nbits_gate => Nbits_delaytime)
		port map( clk => clk,
					 reset => reset and (not signal_out) and (not veto_out),
					 sync_clr => '0',
					 delay => sig_delay_time,
					 D => crystal_input,
					 Q => delayed_out
					);
					
	-- multiplexer for choosing output mode
	with output_mode select
		mux_out <= crystal_input when "01",
					  veto_input when "10",
					  indep_trigger when "11",
					  delayed_out when others;

	-- output gate generator (either gate_gen or sync edge detector)
	gate_trig: entity work.gate_generator(arch_gate_generator)
		generic map(Nbits_gate => Nbits_trigtime)
		port map( clk => clk,
					 reset => reset,
					 en => mux_out,
					 gate_len => trig_time,
					 gate => trig_out
					);
--	gate_trig: entity work.sync_edge_detector(arch_sync_edge_detector)
--		port map( clk => clk,
--					 reset => reset,
--					 D => mux_out,
--					 Q => trig_out
--					);

	gate_deadwin: entity work.gate_generator(arch_gate_generator)
		generic map(Nbits_gate => Nbits_deadtime)
		port map( clk => clk,
					 reset => reset,
					 en => mux_out,
					 gate_len => dead_time,
					 gate => signal_out
					);
					
	gate_veto: entity work.gate_generator(arch_gate_generator)
		generic map(Nbits_gate => Nbits_vetotime)
		port map( clk => clk,
					 reset => reset and (not enable_veto),
					 en => veto_input,-- and enable_veto,
					 gate_len => veto_window,
					 gate => veto_out
					);
	enable_veto <= not veto_en when output_mode="00" else
						'1';
	
	reset_out <= (not signal_out) and (not veto_out);
	
end arch_trigger_output;