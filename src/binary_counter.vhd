library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016
-- this is a simple binary counter.
-- reset is asynchronous.
-- sync_clr might be useful when we want to extend dead time.

entity binary_counter is

	generic(
		Nbits : integer := 8	-- length of coincidence window.
	);
	
	port(
		clk : in std_logic;
			-- counter clock input
		reset : in std_logic;
			-- asynchronous reset
		en	: in std_logic;
			-- enable the counter
		sync_clr : in std_logic :='0';
			-- synchronous clear
		Q : out std_logic_vector(Nbits-1 downto 0)
			-- adjustable window length
	);
	
end binary_counter;

architecture arch_binary_counter of binary_counter is
signal current_value, next_value : unsigned(Nbits-1 downto 0);

begin
		process(clk,reset)
		begin
			-- asynchronous reset takes priority. In that case, reset register output value and status
			if (reset='0') then
				current_value <= (others=>'0');
			elsif (clk'event and clk='1') then
				current_value <= next_value;
			end if;
		end process;

		next_value <= (others=>'0') when sync_clr='1' else
						  current_value+1 when en='1' else
						  current_value;
			-- next state logic.  Sync clear preceeds load preceeds counting.
		Q <= std_logic_vector(current_value);
						  
end arch_binary_counter;