library ieee;
use ieee.std_logic_1164.all;

-- edge detector detects rising edge of the trigger signal.
-- the trigger signal is fed into the clock input of the flip flop
-- data is a constant high voltage. 

entity dff is

	port(
		clk : in std_logic;
		reset : in std_logic;
		Q : out std_logic;
		Qbar : out std_logic
	);

end dff;

architecture arch_edge_detector of dff is
begin

	process(clk,reset)
	begin
		if (reset='0') then
			Q <= '0';
			Qbar <= '1';
		elsif (clk'event and clk='1') then
			Q <= '1';
			Qbar <= '0';
		end if;
	end process;
	
end arch_edge_detector;