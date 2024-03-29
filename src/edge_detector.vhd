library ieee;
use ieee.std_logic_1164.all;

-- Suerfu @ 25 March, 2016
-- edge detector detects rising edge of the trigger signal.
-- the trigger signal is fed into the clock input of the flip flop
-- data is a constant high voltage. 

entity edge_detector is

	port(
		clk : in std_logic := '0';
		reset : in std_logic := '1';
		Q : out std_logic :='0';
		Qbar : out std_logic := '1'
	);

end edge_detector;

architecture arch_edge_detector of edge_detector is
signal internal : std_logic;
begin

	process(clk,reset)
	begin
		if (reset='0') then
			internal <= '0';
		elsif (clk'event and clk='1') then
			internal <= '1';
		end if;
	end process;
	
	Q <= internal;
	Qbar <= not internal;
	
end arch_edge_detector;