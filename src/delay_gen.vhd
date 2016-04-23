library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 29, 2016
-- N-bit delay generator
-- with synchronous clear and asynchronous reset

entity delay_gen is

	generic( Nbits_gate : integer := 3;
				Nbits_reg : integer := 8);
					-- number of bits needed to represent delay
	port( clk : in std_logic := '0';
			reset : in std_logic := '0';
			sync_clr : in std_logic := '0';
			delay : in std_logic_vector(Nbits_gate-1 downto 0) := (others=>'0');
			D : in std_logic;
			Q : out std_logic := '0'
	);

end delay_gen;

-- delay generator using 8-bit shift register.
architecture arch_delay_gen of delay_gen is
signal cur_reg, next_reg : std_logic_vector(6 downto 0);
	-- there is a state with no delay, so only 7 needed.
begin
	process(clk,reset)
	begin
		if(reset='0') then
			cur_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			if(sync_clr='1') then
				cur_reg <= (others=>'0');
			else
				cur_reg <= next_reg;
			end if;
		end if;
	end process;

	-- next state logic: place data in onto MSB
	next_reg <= D & cur_reg(6 downto 1);
	
	with delay select
		Q <= D when "000",
		  cur_reg(6) when "001",
		  cur_reg(5) when "010",
		  cur_reg(4) when "011",
		  cur_reg(3) when "100",
		  cur_reg(2) when "101",
		  cur_reg(1) when "110",
		  cur_reg(0) when "111";

end arch_delay_gen;