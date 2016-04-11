library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016

entity crystal_coincidence is
	generic(	Npmt : integer := 2;
					-- number of pmt per crystal
				Nbits_gate : integer := 2--;
					-- coincidence window in number of clock cycles
				--Nbits_sync : integer := 2
					-- delay in number of clock cycles
	);

	port ( clk : in std_logic;
			 reset : in std_logic;
			 re_trig : in std_logic;
				-- enable/disable re-trigger (extend or ignore current trigger)
			 crystal_input : in std_logic_vector(Npmt-1 downto 0);
				-- signal input from crystal scintillation
			 gate_len : in std_logic_vector(Nbits_gate-1 downto 0);
				-- register that holds coincidence window length
			 coincidence : out std_logic;
				-- output of coincidence
			 crystal_output : out std_logic_vector(Npmt-1 downto 0);
				-- optional, the window produced by two gates
			 sync_out : out std_logic_vector(Npmt-1 downto 0)
	);

end crystal_coincidence;

architecture arch_crystal_coincidence of crystal_coincidence is
signal gate_out, temp_coin : std_logic_vector(Npmt-1 downto 0);
begin
	-- create coincidence window from each pmt
	coin_win: for i in 0 to Npmt-1 generate
	signal signal_after_ff, gate_output, oneshot_to_mux, reset_after_mux, sig_for_retrig: std_logic;
	
	begin
		edge_det: entity work.edge_detector(arch_edge_detector)
			port map( clk => crystal_input(i),
						 reset =>  reset_after_mux and reset ,--and (not sig_for_retrig), -- reset is active low, reset_ff will use less than signal
						 Q => signal_after_ff					    -- driving Q high enables counter
						 );
		sync_out(i) <= signal_after_ff;
		
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
						 reset => not sig_for_retrig,
						 Q => oneshot_to_mux
						);
						
		reset_after_mux <= not oneshot_to_mux when re_trig='1' else
								 not gate_out(i);
--		count(i) <= reset_after_mux;
--		col_q(i) <= signal_after_ff;
	end generate;
	
	-- combine output of all PMTs in the same crystal
	crystal_output <= gate_out;
	
	temp_coin(0) <= gate_out(0);
	label_coin_gate: for i in 1 to Npmt-1 generate
	begin
		temp_coin(i) <= (temp_coin(i-1) and gate_out(i));
	end generate;
	
	coincidence <= temp_coin(Npmt-1);
	
end arch_crystal_coincidence;