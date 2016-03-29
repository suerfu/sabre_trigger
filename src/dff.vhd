library ieee;
use ieee.std_logic_1164.all;

entity dflipflop is

	port(
		clk : in std_logic;
		reset : in std_logic;
		D : in std_logic;
		Q : out std_logic;
		Qbar : out std_logic
	);

end dflipflop;

architecture arch_dff_reset_low of dflipflop is
signal internal : std_logic;
begin

	process(clk,reset)
	begin
		if (reset='0') then
			internal <= '0';
		elsif (clk'event and clk='1') then
			internal <= D;
		end if;
	end process;
	
	Q <= internal;
	Qbar <= not internal;
	
end arch_dff_reset_low;


architecture arch_dff_reset_high of dflipflop is
signal internal : std_logic;
begin

	process(clk,reset)
	begin
		if (reset='0') then
			internal <= '1';
		elsif (clk'event and clk='1') then
			internal <= D;
		end if;
	end process;
	
	Q <= internal;
	Qbar <= not internal;
	
end arch_dff_reset_high;