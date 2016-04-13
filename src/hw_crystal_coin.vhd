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

	generic( Nbits_gate: integer := 8 );

	port( clk : in std_logic;
			reset : in std_logic := '1';
			LED : out std_logic_vector(7 downto 0);		
			trig_in : in std_logic_vector(1 downto 0);
				--crys_out : out std_logic_vector(1 downto 0);
			mux : in std_logic
	);
			
end hw_crystal_coin;
	
architecture arch_hw_crystal_coin of hw_crystal_coin is

--signal clk : std_logic;
constant gate_len : std_logic_vector := std_logic_vector(to_unsigned(5,Nbits_gate));
signal temp : std_logic;
signal count1,count2 : std_logic_vector(7 downto 0);
signal sync_out: std_logic_vector(1 downto 0);

begin
	lb_xtal_coin: entity work.crystal_coincidence(arch_crystal_coincidence)
		generic map(Nbits_gate => Nbits_gate)
		port map( clk => clk, reset => reset, en_retrig => '0', crystal_input => trig_in(1) & trig_in(0),
					 gate_len => gate_len, crystal_trigger => temp, sync_out=>sync_out);
	
	lb_counter_input: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map( clk => sync_out(1), reset => reset, load => '0', en => '1', up => '1',
					 sync_clr => '0', load_value => (others=>'0'), Q => count1
		);

	lb_counter_trig: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map( clk => temp, reset => reset, load => '0', en => '1', up => '1',
					 sync_clr => '0', load_value => (others=>'0'), Q => count2
		);

	LED <= count1(7 downto 4) & count2(7 downto 4) when mux='1' else
			 count1(3 downto 0) & count2(3 downto 0);

end arch_hw_crystal_coin;