library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ April 13, 2016
-- hardware verification of veto majority trigger.
-- a second FPGA will be producing two pulses with a programmable delay.
-- each pulse will be distributed to 5 of the PMT ports.
-- user sets majority level with the DIP switch

entity hw_veto_trigger is 
	generic( Nbits_gate: integer := 8;
				Npmt : integer := 10
	);
	port( clk : in std_logic;
			reset : in std_logic := '1';
			majority_level : in std_logic_vector(2 downto 0) := (others=>'1');
			LED : out std_logic_vector(7 downto 0);		
			trig_in : in std_logic_vector(1 downto 0);
				--crys_out : out std_logic_vector(1 downto 0);
			mux : in std_logic;
			clk_out : out std_logic
	);
			
end hw_veto_trigger;
	
architecture arch_hw_veto_trig of hw_veto_trigger is
constant gate_len : std_logic_vector := std_logic_vector(to_unsigned(2,Nbits_gate));
signal temp : std_logic;
signal count1,count2 : std_logic_vector(7 downto 0);
signal sync_out : std_logic_vector(1 downto 0);
signal mask : std_logic_vector(Npmt-1 downto 0) := (others=>'1');

begin
	lb_veto_trig: entity work.veto_trigger(arch_veto_trigger)
		generic map( Nbits_gate => Nbits_gate, Npmt => Npmt, Nbits_majlev => 3 )
		port map( clk => clk, reset => reset, en_retrig => '0', mask => mask, majority_level => majority_level,
					 gate_len => gate_len, veto_input => (3 downto 0 =>trig_in(1), Npmt-1 downto 4 =>trig_in(0)),
					 veto_trigger => temp);

	sync_out <= trig_in;
	
	lb_counter_input: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map( clk => sync_out(1), reset => reset, load => '0', en => '1', up => '1',
					 sync_clr => '0', load_value => (others=>'0'), Q => count1
		);
	lb_counter_trig: entity work.counter(arch_univ_counter)
		generic map(Nbits => 8)
		port map( clk => temp, reset => reset, load => '0', en => '1', up => '1',
					 sync_clr => '0', load_value => (others=>'0'), Q => count2
		);

--	LED <= count1(7 downto 4) & count2(7 downto 4) when mux='1' else
--			 count1(3 downto 0) & count2(3 downto 0);
	LED <= count2;
	clk_out <= clk;
end arch_hw_veto_trig;