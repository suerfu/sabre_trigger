library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Suerfu @ March 25, 2016
--comparator compares input data with the preloaded window length value.
--output Q will be high when input is greater or equal to the window length.
--output Q bar will be the opposite of Q.

entity comparator is

	generic (
		Nbits : integer := 8
	);
	port(
		D : in std_logic_vector(Nbits-1 downto 0);
		window : in std_logic_vector(Nbits-1 downto 0);
		Q : out std_logic;
			-- D greater than or equal to window
		Qbar : out std_logic
			-- D less than window
	);
end comparator;

architecture arch_comparator of comparator is
signal result : std_logic;

begin

	result <= '1' when unsigned(D)>=unsigned(window) else
		  '0';
	Q <= result;
	Qbar <= (not result);

end arch_comparator;