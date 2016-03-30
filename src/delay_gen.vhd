library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 29, 2016
-- N-bit delay generator
-- with synchronous clear and asynchronous reset

entity delay_gen is

	generic( Nbits_delay : integer := 3;
					-- number of bits needed to represent delay
				Nbits : integer := 8
					-- width of the shift register
				);
	port( clk : in std_logic;
				-- system clock
			reset : in std_logic;
				-- asynchronous reset
			sync_clr : in std_logic;
				-- synchronous clear
			index_out : in std_logic_vector(Nbits_delay-1 downto 0);
				-- it will be used to multiplex / route the output
				-- when index is 0, output is instantaneous
				-- when 1, it is delayed by the time from instantaneous to first clock edge, etc.
			D : in std_logic;
				-- data input
			Q : out std_logic;
				-- output as a single bit
			reg_out : out std_logic_vector(Nbits-1 downto 0)
			);

end delay_gen;

architecture arch_delay_gen of delay_gen is
signal reg_cur,reg_next : std_logic_vector(Nbits-1 downto 0);
begin
	process(clk,reset)
	begin
		if reset='0' then
			reg_cur <= (others=>'0');
			-- async_reset
		elsif (clk'event and clk='1') then
			if sync_clr='1' then
				-- synchronous clear
				reg_cur <= (others=>'0');
			else
				reg_cur <= reg_next;
			end if;
		end if;
	end process;
	
	reg_next <= reg_cur(Nbits-2 downto 0) & D;

	Q <= reg_next(to_integer(unsigned(index_out)));
	reg_out <= reg_next;
	
end arch_delay_gen;