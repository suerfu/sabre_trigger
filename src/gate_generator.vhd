library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016
-- Gate generator generates a gate of programmable length in clock cycle.
-- It responds to the signal edge. For every incoming edge it will reload.

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
		gate : out std_logic
			-- output gate for comparator (optional in count down mode)
--		count : out std_logic_vector(Nbits_gate-1 downto 0)
	);

end gate_generator;

architecture arch_gate_generator of gate_generator is
signal det_to_ctr, to_gate: std_logic;

begin
	sync_edge_det: entity work.sync_edge_detector(arch_sync_edge_detector)
		port map( D => en,
					 clk => clk,
					 reset => '1',
					 Q => det_to_ctr
					);

	ctr: entity work.counter(arch_count_down)
		generic map(Nbits => Nbits_gate)
		port map( clk => clk,
					 reset => reset,					-- global reset applies to counter directly
					 load => det_to_ctr,
					 en => '1',
					 up => '0',
					 sync_clr => '0',
					 load_value => gate_len,
					 min => to_gate--,
--					 Q => count
					 );

	gate <= not to_gate;
					 
end arch_gate_generator;