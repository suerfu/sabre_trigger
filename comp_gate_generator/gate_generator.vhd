library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016

entity gate_generator is
	generic(
		Nbits_gate : integer := 2
			-- coincidence window in number of clock cycles
	);

	port (
		clk : in std_logic;
			-- system clock
		reset : in std_logic;
			-- global reset
		en : in std_logic;
			-- one shot, enables gate generator
		gate_len : in std_logic_vector(Nbits_gate-1 downto 0);
		-- register that holds window length
		gate : out std_logic;
			-- output gate
		count : out std_logic_vector(Nbits_gate-1 downto 0)
	);

end gate_generator;

architecture arch_gate_generator of gate_generator is
signal Q_ff, Qbar_ctr: std_logic;
signal ctr_to_cmp: std_logic_vector(Nbits_gate-1 downto 0); 

begin		
	ctr: entity work.binary_counter(arch_binary_counter)
		generic map(Nbits => Nbits_gate)
		port map( clk => clk,
					 reset => Q_ff and reset,					-- global reset applies to counter directly
					 en => Qbar_ctr or en,
					 sync_clr => '0',
					 Q => ctr_to_cmp
					 );
						 
	cmp: entity work.comparator(arch_comparator)
		generic map(Nbits => Nbits_gate)
		port map( D => ctr_to_cmp,
					 window => gate_len,
					 Qbar => Qbar_ctr
					);

	label_dff: entity work.dflipflop(arch_dff_reset_high)
		port map( D => Qbar_ctr,
					 clk => clk,
					 reset => reset,
					 Q => Q_ff,
					 Qbar => gate
				   );
 
	count <= ctr_to_cmp;
end arch_gate_generator;