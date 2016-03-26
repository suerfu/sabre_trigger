library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016

entity crystal_coincidence is
	generic(
		Npmt : integer := 2;
			-- number of pmt per crystal
		Nbits_window : integer := 2;
			-- coincidence window in number of clock cycles
		Ndelay : integer := 2
			-- delay in number of clock cycles
	);

	port (
		clk : in std_logic;
			-- system clock
		reset : in std_logic;
			-- global reset for the coincidence module
		crystal_input : in std_logic_vector(Npmt-1 downto 0);
			-- signal input from crystal scintillation
		coin_window : in std_logic_vector(Nbits_window-1 downto 0);
			-- register that holds coincidence window length
		coincidence : out std_logic;
			-- output of coincidence
		count : out std_logic_vector(Nbits_window-1 downto 0)
	);

end crystal_coincidence;

architecture arch_crystal_coincidence of crystal_coincidence is
signal pmt_out, temp_coin : std_logic_vector(Npmt-1 downto 0);

begin
	-- create coincidence window from each pmt
	label_coin_win: for i in 0 to Npmt-1 generate
	signal reset_ff, ff_to_ctr_en, ff_to_ctr_clr: std_logic;
	signal ctr_to_cmp : std_logic_vector(Nbits_window-1 downto 0);
	begin
		edge_det: entity work.edge_detector(arch_edge_detector)
			port map( clk => crystal_input(i),
						 reset => ( reset_ff and reset), -- reset is active low, reset_ff will use less than signal
						 Q => pmt_out(i),						-- driving Q high enables counter
						 Qbar => ff_to_ctr_clr				-- when active, Qbar is low, disabling clear
						 );
		
		ctr: entity work.binary_counter(arch_binary_counter)
			generic map(Nbits => Nbits_window)
			port map( clk => clk,
						 reset => reset,					-- global reset applies to counter directly
						 en => pmt_out(i),
						 sync_clr => ff_to_ctr_clr,
						 Q => ctr_to_cmp
						 );
						 
		cmp: entity work.comparator(arch_comparator)
			generic map(Nbits => Nbits_window)
			port map( D => ctr_to_cmp,
						 window => coin_window,
						 Qbar => reset_ff
						);
		if1: if(i=0) generate
			count <=ctr_to_cmp;
		end generate;
	end generate;
	
	-- combine output of all PMTs in the same crystal
	temp_coin(0) <= pmt_out(0);
	label_coin_gate: for i in 1 to Npmt-1 generate
	begin
		temp_coin(i) <= (temp_coin(i-1) and pmt_out(i));
	end generate;
	
	coincidence <= temp_coin(Npmt-1);
	
end arch_crystal_coincidence;