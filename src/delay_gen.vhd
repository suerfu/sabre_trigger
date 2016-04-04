library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 29, 2016
-- N-bit delay generator
-- with synchronous clear and asynchronous reset

entity delay_gen is

	generic( Nbits_gate : integer := 3);
					-- number of bits needed to represent delay
	port( clk : in std_logic;
				-- system clock
			reset : in std_logic;
				-- asynchronous reset
			sync_clr : in std_logic;
				-- synchronous clear
			delay : in std_logic_vector(Nbits_gate-1 downto 0);
				-- amount of delay
			D : in std_logic;
				-- data input
			Q : out std_logic--;
				-- output as a single bit
			--gate_out : out std_logic_vector(Nbits_gate-1 downto 0)
	);

end delay_gen;

architecture arch_delay_gen of delay_gen is
signal to_edge_det : std_logic;
-- signal to_gate : std_logic;
begin
--		lb_edge_det1: entity work.sync_edge_detector(arch_sync_edge_detector)
--			port map(clk=>clk, reset=>reset, D=>D,Q=>to_gate);
			
		lb_gate_gen: entity work.gate_generator(arch_gate_generator)
			generic map(Nbits_gate=>Nbits_gate)
			port map (clk=>clk,reset=>reset,en=>D,gate_len=>delay,gate=>to_edge_det);--, count=>gate_out);
			
		lb_edge_det: entity work.sync_edge_detector(arch_sync_edge_detector_falling_edge)
			port map(clk=>clk, reset=>reset and (not sync_clr), D=>to_edge_det,Q=>Q);
end arch_delay_gen;