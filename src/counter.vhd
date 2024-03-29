library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016
-- this is a universal binary counter.
-- reset is asynchronous.
-- load, sync_clr are synchronous.
-- load will load specific value specified on the load_value line
-- sync_clr might be useful when we want to extend dead time.
-- up will control direction of counting.
-- max and min pin will be high when at 11..1 and 00..0 respectively.

entity counter is

	generic(
		Nbits : integer := 8	-- length of coincidence window.
	);
	
	port(
		clk : in std_logic :='0';
			-- counter clock input
		reset : in std_logic :='1';
			-- asynchronous reset
		load : in std_logic := '0';
			-- load specific value, synchronous
		load_value : in std_logic_vector(Nbits-1 downto 0) := (others=>'0');
			-- value to load
		en	: in std_logic :='1';
			-- enable the counter
		up : in std_logic :='1';
			-- count up when '1'
		sync_clr : in std_logic := '0';
			-- synchronous clear
		Q : out std_logic_vector(Nbits-1 downto 0) := (others=>'0');
			-- adjustable window length
		max : out std_logic :='0';
			-- counter at max value
		min : out std_logic :='1'
			-- counter at minimum value
	);
	
end counter;

architecture arch_univ_counter of counter is
signal current_value, next_value : unsigned(Nbits-1 downto 0);

begin
		process(clk,reset)
		begin
			-- asynchronous reset takes priority. In that case, reset register output value and status
			if (reset='0') then
				current_value <= (others=>'0');
			elsif (clk'event and clk='1') then
				if en='1' then
					current_value <= next_value;
				end if;
			end if;
		end process;

		next_value <= (others=>'0') when sync_clr='1' else
						  unsigned(load_value) when load='1' else
						  current_value+1 when (en='1' and up='1') else
						  current_value-1 when (en='1' and up='0') else
						  current_value;
			-- next state logic.  Sync clear preceeds load preceeds counting.
		Q <= std_logic_vector(current_value);
		max <= '1' when (current_value = 2**Nbits-1) else
				 '0';
		min <= '1' when (current_value = 0) else
				 '0';
						  
end arch_univ_counter;

-- Suerfu @ 27 March, 2016
-- architecture count_down specifically performs count down.
-- asserting high the load pin will load the preset value, and start count down.
-- count down will stop either when the value reaches minimum, or when enable is disabled.

architecture arch_count_down of counter is
signal current_value, next_value : unsigned(Nbits-1 downto 0);

begin
		process(clk,reset)
		begin
			-- asynchronous reset takes priority. In that case, reset register output value and status
			if (reset='0') then
				current_value <= (others=>'0');
			elsif (clk'event and clk='1') then
				if en='1' then
					current_value <= next_value;
				end if;
			end if;
		end process;

		next_value <= (others=>'0') when sync_clr='1' else
						  unsigned(load_value) when load='1' else
						  current_value when current_value=0 else
						  current_value-1;
			-- next state logic.  Sync clear preceeds load preceeds counting.
		Q <= std_logic_vector(current_value);
		max <= '1' when (current_value = unsigned(load_value)) else
				 '0';
		min <= '1' when (current_value = 0) else
				 '0';
						  
end arch_count_down;