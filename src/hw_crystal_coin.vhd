library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hw_crystal_coin is 

	generic( Nbits: integer := 30);

	port( clk : in std_logic;
				-- system clock input
			reset : in std_logic := '1';
				-- external reset input
				
			trig_in : in std_logic_vector(1 downto 0);
				-- input trigger via push button
			crystal_output : out std_logic_vector(1 downto 0);	
				-- output of two gate
			trig_out : out std_logic
				-- output of coincidence trigger
			);
			
end hw_crystal_coin;
	
architecture arch_hw_crystal_coin of hw_crystal_coin is

constant input_duration : std_logic_vector(Nbits-1 downto 0) := std_logic_vector(to_unsigned(200000000,Nbits));
constant coin_window : std_logic_vector(Nbits-1 downto 0) := std_logic_vector(to_unsigned(200000000,Nbits));

begin

	lb_xtal_coin: entity work.crystal_coincidence(arch_crystal_coincidence)
		generic map(Nbits_gate => Nbits)
		port map( clk => clk, reset => reset, re_trig => '0', crystal_input => trig_in,
					 gate_len => input_duration, coincidence => trig_out, crystal_output => crystal_output);

end arch_hw_crystal_coin;
	