library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ April 1, 2016
-- hardware verification of NaI coincidence module.
-- user will use two push button on the DE0-nano board as crystal PMT input
-- user will specify input gate length by the first three dip switches.
-- the last dip switch will be reserved as reset.
-- first and third LED indicate two gate.
-- fifth LED is the coincidence trigger, and 7th clock after division.

entity hw_crystal_coin is 

	generic( Nbits_gate: integer := 3; Nbits_clk: integer := 28);

	port( clk_in : in std_logic;
				-- system clock input
			reset : in std_logic := '1';
				-- external reset input
			LED_clock: out std_logic;
				-- LED indicating clock after division.
				
			trig_in : in std_logic_vector(1 downto 0);
				-- input trigger via push button
			crystal_output : out std_logic_vector(1 downto 0);	
				-- output of two gate
			trig_out : out std_logic;
				-- output of coincidence trigger
			input_duration: in std_logic_vector(Nbits_gate-1 downto 0)
				-- use dip switches to specify gate length.
			);
			
end hw_crystal_coin;
	
architecture arch_hw_crystal_coin of hw_crystal_coin is

signal clk : std_logic;

begin
	lb_clock_div: entity work.clock_divider(arch_clock_divider)
		generic map(Nbits=>Nbits_clk)
		port map(clk_in=>clk_in, clk_out=>clk);
	lb_xtal_coin: entity work.crystal_coincidence(arch_crystal_coincidence)
		generic map(Nbits_gate => Nbits_gate)
		port map( clk => clk, reset => reset, re_trig => '0', crystal_input => trig_in,
					 gate_len => input_duration, coincidence => trig_out, crystal_output => crystal_output);
	
	LED_clock <= clk;
end arch_hw_crystal_coin;
	