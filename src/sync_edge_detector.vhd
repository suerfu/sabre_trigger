library ieee;
use ieee.std_logic_1164.all;

-- Suerfu @ 25 March, 2016
-- synchronous edge detector detects rising edge of a synchronous signal.


entity sync_edge_detector is

	port(
		clk : in std_logic;
		reset : in std_logic;
		D : in std_logic;
		Q : out std_logic
	);
	
end sync_edge_detector;

architecture arch_sync_edge_detector of sync_edge_detector is
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
	
	Q <= D and (not internal) and reset;
	
end arch_sync_edge_detector;

architecture arch_sync_edge_detector_falling_edge of sync_edge_detector is
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
	
	Q <= (not D) and internal and reset;
	
end arch_sync_edge_detector_falling_edge;