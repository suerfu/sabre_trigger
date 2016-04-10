library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ April 3, 2016
-- clock divider for hardware.
-- it takes in 50 MHz clock, and outputs 10 second clock period.

entity clock_divider is
	generic (Nbits:integer:=5);
	port(
		clk_in : in std_logic;
		clk_out: out std_logic
	);
end clock_divider;

architecture arch_clock_divider of clock_divider is
signal ctr_out: std_logic_vector(Nbits-1 downto 0);
constant cmp: std_logic_vector(Nbits-1 downto 0) :=std_logic_vector(to_unsigned(1,Nbits));
begin
	lb_ctr: entity work.counter(arch_univ_counter)
		generic map(Nbits=>Nbits)
		port map(clk=>clk_in,reset=>'1',load=>'0',load_value=>(others=>'0'),en=>'1',up=>'1',sync_clr=>'0',Q=>ctr_out);
	lb_cmp: entity work.comparator(arch_comparator)
		generic map(Nbits=>Nbits)
		port map(window=>cmp, D=> ctr_out, Q=>clk_out);
end arch_clock_divider;