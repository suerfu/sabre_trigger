library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hw_veto_trigger is 

	generic( Nbits: integer := 30; Npmt: integer := 10; Nmaj_lev : integer := 4);

	port( clk : in std_logic;
				-- system clock input
			reset : in std_logic := '1';
				-- external reset input
			
			majority_level : in std_logic_vector(Nmaj_lev-1 downto 0);
				-- bits needed for majority level
			
			trig_in : in std_logic_vector(1 downto 0);
				-- input trigger via push button
				
			trig_out : out std_logic
				-- output of coincidence trigger
			);
			
end hw_veto_trigger;
	
architecture arch_hw_veto_trigger of hw_veto_trigger is

constant input_duration : std_logic_vector(Nbits-1 downto 0) := std_logic_vector(to_unsigned(200000000,Nbits));
constant coin_window : std_logic_vector(Nbits-1 downto 0) := std_logic_vector(to_unsigned(200000000,Nbits));
signal veto_in : std_logic_vector(Npmt-1 downto 0);

begin

	veto_in <= trig_in(0)&trig_in(1)&trig_in(0)&trig_in(1)&trig_in(0)&trig_in(1)
					&trig_in(0)&trig_in(1)&trig_in(0)&trig_in(1);
	lb_veto_trig: entity work.veto_trigger(arch_veto_trigger)
		generic map(Nbits_gate=>Nbits, Nmaj_lev=>Nmaj_lev, Nveto=>Npmt)
		port map( clk => clk, reset => reset, re_trig => '0', veto_in => veto_in, mask=>(others=>'1'),
					 majority_level => majority_level, gate_len => input_duration, veto_out => trig_out);		
					 
end arch_hw_veto_trigger;
	