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
--
--
-- Suerfu @ 28 March 2016
-- architecture majority_level will compute the number of active lines
-- and compares the result with the comparison parameter.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity majority_comparator is

	generic (
		Nbits_cmpr : integer := 4;
			-- holds bits of the constant to be compared
		Nbits : integer := 10
			-- line width of the input vector
	);
	port(
		D : in std_logic_vector(Nbits-1 downto 0);
		window : in std_logic_vector(Nbits_cmpr-1 downto 0);
		Q : out std_logic;
			-- D greater than or equal to window
		Qbar : out std_logic;
			-- D less than window
		count : out std_logic_vector(Nbits_cmpr-1 downto 0)
	);
end majority_comparator;


architecture arch_majority_comparator of majority_comparator is
type array_result is array(0 to Nbits-1) of unsigned(Nbits_cmpr-1 downto 0);
signal result_temp : array_result;

signal result : std_logic;
constant zero : std_logic_vector(Nbits_cmpr-2 downto 0) := (others=>'0'); -- (Nbits-2 downto 0);
begin

	result_temp(0) <= unsigned(zero & D(0));
	majority_level : for i in 1 to Nbits-1 generate
	begin
		result_temp(i) <= result_temp(i-1) + unsigned(zero & D(i));
	end generate;
	
	result <= '1' when (result_temp(Nbits-1) >= unsigned(window)) else
				 '0';
	count <= std_logic_vector(result_temp(Nbits-1));
	Q <= result;
	Qbar <= (not result);

end arch_majority_comparator;