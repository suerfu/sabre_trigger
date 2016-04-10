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

	generic( Nbits_gate: integer := 2;Nbits_clk:integer:=18);

	port( --clk_in : in std_logic;
				-- system clock for division
			clk : in std_logic;
				-- system clock with no division.
			reset : in std_logic := '1';
				-- external reset input

			LED : out std_logic_vector(7 downto 0);
				
			trig_in : in std_logic_vector(1 downto 0);
				-- input trigger via push button
			crystal_output : out std_logic_vector(1 downto 0);
--				-- output of two gate
--			trig_out : out std_logic;
--				-- output of coincidence trigger
--			input_duration: in std_logic_vector(Nbits_gate-1 downto 0)
--				-- use dip switches to specify gate length.
			mux : in std_logic
			);
			
end hw_crystal_coin;
	
architecture arch_hw_crystal_coin of hw_crystal_coin is

--signal clk : std_logic;
signal temp : std_logic;
signal count1,count2 : std_logic_vector(7 downto 0);
signal sync_out: std_logic_vector(1 downto 0);
signal max,clk_out : std_logic;
signal crys_out : std_logic_vector(1 downto 0);

begin
	lb_clock_div: entity work.clock_divider(arch_clock_divider)
		generic map(Nbits=>Nbits_clk)
		port map(clk_in=>clk, clk_out=>clk_out);
		
	lb_xtal_coin: entity work.crystal_coincidence(arch_crystal_coincidence)
		generic map(Nbits_gate => Nbits_gate)
		port map( --clk => clk, reset => reset, re_trig => '0', crystal_input => clk_out & clk_out,--trig_in(0) & trig_in(0),
					 clk => clk, reset => reset, re_trig => '0', crystal_input => trig_in(1) & trig_in(1),
					 gate_len => (others=>'1'), coincidence => temp, crystal_output=> crys_out, sync_out=>sync_out);
	
	lb_counter_input: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map( clk => sync_out(1),--trig_in(1),
					 reset => reset,					-- global reset applies to counter directly
					 load => '0',
					 en => '1',
					 up => '1',
					 sync_clr => '0',
					 load_value => std_logic_vector(to_unsigned(0,8)),
					 max=>max,
					 Q => count1
					 );

	lb_counter_trig: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map( clk => temp,
					 reset => reset,					-- global reset applies to counter directly
					 load => '0',
					 en => '1',
					 up => '1',
					 sync_clr => '0',
					 load_value => std_logic_vector(to_unsigned(0,8)),
					 Q => count2
					 );
--	LED <= std_logic_vector(unsigned(count1)-unsigned(count2));
--	LED <= count1;
	LED <= count1(7 downto 4) & count2(7 downto 4) when mux='1' else
			 count1(3 downto 0) & count2(3 downto 0);

end arch_hw_crystal_coin;
	