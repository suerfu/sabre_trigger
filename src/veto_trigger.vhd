library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 28, 2016
-- Veto trigger consists of 10 veto PMT inputs.
-- A majority level is imposed. When trigger number exceeds the majority level
-- a veto command is prodiced.

entity veto_trigger is

	generic( 
				Nveto : integer := 10;
					-- number of veto PMT
				Nmaj_lev: integer := 4;
					-- number of bits in the majority level specified.
					-- 2**Nmaj_lev must be greater than Nveto
				Nbits_gate : integer := 3
					-- coincidence window of veto signal
				);
	port( 
			clk : in std_logic;
				-- system clock
			reset : in std_logic;
				-- system reset
			re_trig : in std_logic;
				-- retriggerability
			mask : in std_logic_vector(Nveto-1 downto 0);
				-- if mask is 0, will keep reset channel low
			majority_level : in std_logic_vector(Nmaj_lev-1 downto 0);
				-- majority level input
			veto_in : in std_logic_vector(Nveto-1 downto 0);
				-- veto PMT signal in
			gate_len : in std_logic_vector(Nbits_gate-1 downto 0);
				-- length of veto coincidence window
			veto_out : out std_logic
			);
end veto_trigger;

architecture arch_veto_trigger of veto_trigger is

signal gate_out: std_logic_vector(Nveto-1 downto 0);
begin
	-- create coincidence window from each veto pmt
	coin_win: for i in 0 to Nveto-1 generate
	signal signal_after_ff, gate_output, oneshot_to_mux, reset_after_mux, sig_for_retrig: std_logic;
	
	begin
		edge_det: entity work.edge_detector(arch_edge_detector)
			port map( clk => veto_in(i),
						 reset => ( reset_after_mux and reset and mask(i)), -- reset is active low, reset_ff will use less than signal
						 Q => signal_after_ff					    -- driving Q high enables counter
						 );
		
		ctr: entity work.gate_generator(arch_gate_generator)
			generic map(Nbits_gate => Nbits_gate)
			port map( clk => clk,
						 reset => reset,					-- global reset applies to counter directly
						 en => signal_after_ff,
						 gate_len => gate_len,
						 gate => gate_out(i)
						 );
		flpflp: entity work.dflipflop(arch_dff_reset_low)
			port map( clk => clk,
						 D => signal_after_ff,
						 reset => reset,
						 Q => sig_for_retrig
						);
		
		oneshot: entity work.sync_edge_detector(arch_sync_edge_detector)
			port map( D => sig_for_retrig,
						 clk => clk,
						 reset => reset,
						 Q => oneshot_to_mux
						);
						
		reset_after_mux <= not oneshot_to_mux when re_trig='1' else
								 not gate_out(i);

	end generate;
	
	-- combine output of all veto PMTs and compare with majority level

	majority_lev: entity work.majority_comparator(arch_majority_comparator)
		generic map(Nbits => Nveto,
						Nbits_cmpr => Nmaj_lev)
		port map( D => gate_out,
					 window => majority_level,
					 Q => veto_out
					);

end arch_veto_trigger;