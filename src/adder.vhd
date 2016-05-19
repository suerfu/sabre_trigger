library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
			Cin : in std_logic := '0';
			S : out std_logic_vector(Nbits_out-1 downto 0) := (others=>'0')
	);
end adder;

architecture arch_adder of adder is

begin
--	fulladd: if (Nbits_in = 1) and (Nbits_out = 2) generate
--	signal sel : std_logic_vector(2 downto 0);
--	begin
--		sel <= A(0) & B(0) & Cin;
--		with  sel select
--		S <=	"00" when "000",
--				"11" when "111",
--				"10" when "110",
--				"10" when "011",
--				"10" when "101",
--				"01" when others;
--	end generate;
	
	general: if (Nbits_in >= 1) generate
	signal Cvec : std_logic_vector(0 downto 0);
	signal Stmp : std_logic_vector(Nbits_in downto 0);
	begin
		Cvec(0) <= Cin;
		Stmp <= std_logic_vector(unsigned('0'& A) + unsigned('0'& B) + unsigned(Cvec));

		noincr: if Nbits_out - Nbits_in = 1 generate
		begin
			S <= Stmp;
		end generate;
		
		incr: if Nbits_out - Nbits_in >1 generate
		constant zero : std_logic_vector(Nbits_out - Nbits_in -2 downto 0) := (others=>'0');
		begin
			S <= zero & Stmp;
		end generate;
	end generate;

end arch_adder;

--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

-- Suerfu @ May 20, 2016
-- Cascade adder will count ones in the input vector of size 2**(n+1)-1
-- General case is fairly hard to implement. Will postpone, and implement case n=10
-- hard-coded.
--
--entity cascade_adder is
--	generic( N : integer := 2;
--				Nbits_cmpr : integer := N+1
--					-- for n layers, total number of ones are 2**(n+1)-1
--					-- needs n+1 numbers to represent in binary form
--	);
--	port( A : in std_logic_vector(2**Nbits_cmpr-2 downto 0) := (others=>'0');
--			S : out std_logic_vector(Nbits_cmpr-1 downto 0) := (others=>'0')
--	);
--end cascade_adder;
--
--architecture arch_cascade_adder of cascade_adder is
--
--signal carry_out : std_logic_vector(2**N-1 downto 0);
--
--begin
--	FA: for j in 1 to 2**(N-1) generate
--	begin
--		
--	end generate;
--	
--	for i in N downto 1 generate
--	begin
--		for j in 
--	end generate;
--
--end arch_cascade_adder;