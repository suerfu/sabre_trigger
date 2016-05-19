library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Suerfu @ March 25, 2016
--comparator compares input data with the preloaded window length value.
--output Q will be high when input is greater or equal to the window length.
--output Q bar will be the opposite of Q.
--
entity comparator is

	generic( Nbits : integer := 8
	);
	port( D : in std_logic_vector(Nbits-1 downto 0);
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
		Q : buffer std_logic;
			-- D greater than or equal to window
		Qbar : buffer std_logic;
			-- D less than window
		count : out std_logic_vector(Nbits_cmpr-1 downto 0)
	);
end majority_comparator;

-- following implementation is a general cascade adder
-- Suerfu @ May 18, 2016
architecture arch_majority_comparator of majority_comparator is

signal P0,P1 : std_logic_vector(1 downto 0);
signal Q0,Q1 : std_logic_vector(2 downto 0);
signal sum : std_logic_vector(3 downto 0);

begin
	
	ad1: entity work.adder(arch_adder)
		generic map( Nbits_in=>1, Nbits_out=>2 )
		port map( A(0)=>D(0), B(0)=>D(1), Cin=>D(2), S=>P0 );

	ad2: entity work.adder(arch_adder)
		generic map( Nbits_in=>1, Nbits_out=>2 )
		port map( A(0)=>D(3), B(0)=>D(4), Cin=>D(5), S=>P1 );
		
	ad3: entity work.adder(arch_adder)
		generic map( Nbits_in=>2, Nbits_out=>3 )
		port map( A=>P0, B=>P1, Cin=>D(6), S => Q0 );

	ad4: entity work.adder(arch_adder)
		generic map( Nbits_in=>1, Nbits_out=>3 )
		port map( A(0)=>D(7), B(0)=>D(8), Cin=>D(9), S=>Q1 );

	ad5: entity work.adder(arch_adder)
		generic map( Nbits_in=>3, Nbits_out=>4 )
		port map( A=>Q0, B=>Q1, Cin=>'0', S=>sum );
		
	Q <= '0' when unsigned(window) > unsigned(sum) else
		  '1';
	Qbar <= not Q;
	
	count <= sum;
	
end arch_majority_comparator;