library ieee;
use ieee.std_logic_1164.all;

-- edge detector detects rising edge of the trigger signal.
-- the trigger signal is fed into the clock input of the flip flop
-- data is a constant high voltage. 

entity sabre_trigger is

	generic(
		N_nai_crystal : integer := 1;
			-- number of NaI crystals. Each crystal gets two PMTs.
		N_veto_pmt : integer := 10;
			-- number of veto PMT. Usually it is 10.
		N_nai_coin_window : integer := 10
			-- length of NaI coincidence window, measured in clock cycles.
	);
	
	port(
		nai_pmt : in std_logic_vector(2*N_nai_crystal-1 downto 0);
			-- vector holding input signal for all NaI pmt signals.
		veto_pmt : in std_logic_vector(N_veto_pmt-1 downto 0);
			-- vector holding veto input signal.
		coin_window : in std_logic_vector(N_nai_coin_window-1 downto 0);
			-- bit vector that holds number of clocl cycles for coincidence window
		reset : in std_logic;
			-- a global reset command
		clk : in std_logic;
			-- system clock.
		majority_level : in std_logic_vector(3 downto 0);
			-- majority trigger for veto coincidence
		trig_out : out std_logic
	);

end sabre_trigger;

architecture arch_sabre_trigger of sabre_trigger is

signal trigger_after_coin : std_logic_vector(N_nai_crystal-1 downto 0);
	-- pmt pair coincidence, after coincidence AND gate. To be fed to OR gate.
signal trigger_before_coin : std_logic_vector(2*N_nai_crystal-1 downto 0);
	-- pmt pair coincidence, before coincidence AND gate.
signal temp_and_gate : std_logic_vector(N_nai_crystal-1 downto 0);
begin
	-- generate coincidence window
	label_nai_coin_window : for i in 0 to 2*N_nai_crystal-1 generate
	signal w_internal_reset, w_counter_reset : std_logic;
	signal w_enable : std_logic;
		-- this wire is used to rout the reset signal from the counter
	begin
		label_nai_edge_detector: entity work.edge_triggered_dff(arch_edge_triggered_dff)
			port map(clk=>nai_pmt(i), D=>'1', reset=>w_internal_reset, Q=>w_enable);
			-- input NaI pmt signal to edge detector
			
		label_nai_counter: entity work.counter(arch_counter)
			generic map( N_window=>N_nai_coin_window )
			port map(clk=>clk, en=>w_enable, reset=>reset, window=>coin_window, status=>trigger_before_coin(i), c_over=>w_counter_reset);
			-- map output of edge detector to the enable pin of counter

		w_internal_reset <= (w_counter_reset or reset);
	end generate;
	
	label_pmt_coincidence: for i in 0 to N_nai_crystal-1 generate
	begin
		trigger_after_coin(i) <= trigger_before_coin(2*i) and trigger_before_coin(2*i+1);
	end generate;
	
	temp_and_gate(0) <= trigger_after_coin(0);
	label_or_gate: for i in 1 to (N_nai_crystal-1) generate
		temp_and_gate(i) <= (temp_and_gate(i-1) and trigger_after_coin(i));
	end generate;
	
	trig_out <= temp_and_gate(N_nai_crystal-1);
	
end arch_sabre_trigger;