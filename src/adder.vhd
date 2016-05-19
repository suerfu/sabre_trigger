library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ May 18, 2016
-- full_adder will add three numbers to produce a two bit numbers
-- effectively the count of ones in the input

entity full_adder is
	port(	A : in std_logic_vector(2 downto 0);
			S : out std_logic_vector(1 downto 0)	
	);
end full_adder;

architecture arch_full_adder of full_adder is
begin
	with A select
		S <=	"00" when "000",
				"11" when "111",
				"10" when "110",
				"10" when "011",
				"10" when "101",
				"01" when others;
end arch_full_adder;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
	generic( Nbits_in : integer := 4;
					-- number of bits of the input vector
				Nbits_out : integer := 5
					-- number of bits of the output vector
					-- must be greater than Nbits_in by 1
					-- the mismatched part will be set to '0'
	);
	
	port( A : in std_logic_vector(Nbits_in-1 downto 0) := (others=>'0');
			B : in std_logic_vector(Nbits_in-1 downto 0) := (others=>'0');
			Cin : in std_logic_vector(0 downto 0) := "0";
			S : out std_logic_vector(Nbits_out-1 downto 0) := (others=>'0')
	);
end adder;

architecture arch_adder of adder is
signal tmp : std_logic_vector(Nbits_in-1 downto 0);
signal tmp2 : std_logic_vector(Nbits_out-1 downto Nbits_in-2) := (others=>'0');
begin
	tmp <= std_logic_vector(unsigned(A) + unsigned(B) + unsigned(Cin));
	S <= tmp2 & tmp;
		-- convert vector to unsigned to do addition, then convert back.
end arch_adder;