library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_sig_quality is
	generic ( Nbits : integer :=7 ;
				 length1 : integer := 3
	);
	port(	clk : in std_logic;
			reset: in std_logic;
			
			cout : out std_logic;
			cin : in std_logic;
			mux : in std_logic;
			LED: out std_logic_vector(7 downto 0)
	);
	
end test_sig_quality;

architecture arch_test_trigger of test_sig_quality is
constant t1 : std_logic_vector(Nbits-1 downto 0):= std_logic_vector(to_unsigned(length1, Nbits));

signal to_next, out1, max : std_logic;
signal Q : std_logic_vector(Nbits-1 downto 0);
signal LED_temp : std_logic_vector(7 downto 0);

begin
	-- counter with maximum 2**Nbits - 1 period
	ctr1: entity work.counter(arch_univ_counter)
		generic map(Nbits => Nbits)
		port map(clk=>clk, reset=>reset,load=>'0',load_value=>(others=>'0'),
					en=> not max,up=>'1',sync_clr=>'0',Q=>Q
		);
	
	--counter output high duration
	cmp1_1: entity work.comparator(arch_comparator)
		generic map(Nbits=>Nbits)
		port map(D=>Q,Qbar=>out1,window=>t1);

	-- counter for displaying LED
	ctr2: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map(clk=>cin, reset=>reset,load=>'0',load_value=>(others=>'0'),
					en=> '1',up=>'1',sync_clr=>'0',Q=>LED_temp
		);
		
	cout <= out1;
	LED <= LED_temp when mux = '0' else
			 (0=>'0',2=>'0',4=>'0',6=>'0',others=>max);
	ctr3: entity work.counter(arch_univ_counter)
		generic map (Nbits=>27)
		port map(clk=>out1, reset=>reset,load=>'0',load_value=>(others=>'0'),en=>reset,up=>'1',sync_clr=>'0',max=>max);
	
end arch_test_trigger;