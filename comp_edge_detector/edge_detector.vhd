library ieee;
use ieee.std_logic_1164.all;

-- edge detector detects rising edge of the trigger signal.
-- the trigger signal is fed into the clock input of the flip flop
-- data is a constant high voltage. 

entity edge_detector is

	port(
		clk : in std_logic;
		reset : in std_logic;
		Q : out std_logic;
		Qbar : out std_logic
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