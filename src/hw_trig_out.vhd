library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hw_trig_out is
	generic(
				Nbits_trigtime : integer := 3;
				Nbits_vetotime : integer := 3;
				Nbits_deadtime : integer := 3;
				Nbits_clk : integer := 28;
				Nbits_delaytime: integer := 3
	);
	port(
				clk_in : in std_logic;
				reset : in std_logic := '1';
				veto_en : in std_logic := '0';
				crystal_input : in std_logic :='0';
				veto_input : in std_logic :='0';

				output_mode : in std_logic_vector(1 downto 0);

				trig_out : out std_logic;
				reset_out : out std_logic;
				LED_crystal: out std_logic;
				LED_veto: out std_logic;
				LED_clk : out std_logic;
				LED_indep: out std_logic
	);
end hw_trig_out;

architecture arch_hw_trig_out of hw_trig_out is

constant sig_delay_time : std_logic_vector(Nbits_delaytime-1 downto 0) := std_logic_vector(to_unsigned(2, Nbits_delaytime));
constant veto_window : std_logic_vector(Nbits_vetotime-1 downto 0) := std_logic_vector(to_unsigned(2, Nbits_vetotime));
constant dead_time : std_logic_vector(Nbits_deadtime-1 downto 0) := std_logic_vector(to_unsigned(3, Nbits_deadtime));
constant trig_time : std_logic_vector(Nbits_trigtime-1 downto 0) := std_logic_vector(to_unsigned(2, Nbits_trigtime));
signal clk : std_logic;
signal reset_for_disp : std_logic;

begin

	lb_clock_div: entity work.clock_divider(arch_clock_divider)
		generic map(Nbits=>Nbits_clk)
		port map(clk_in=>clk_in, clk_out=>clk);	
	LED_clk <= clk;
	LED_crystal <= not crystal_input;
	LED_veto <= not veto_input;
	
	lb_trig_out: entity work.trigger_output(arch_trigger_output)
		generic map(Nbits_deadtime=>Nbits_deadtime,Nbits_delaytime=>Nbits_delaytime,Nbits_trigtime=>Nbits_trigtime,Nbits_vetotime=>Nbits_vetotime)
		port map( clk=>clk, reset=>reset, crystal_input=> not crystal_input, veto_input=> not veto_input, veto_en=>veto_en, sig_delay_time=>sig_delay_time,
						veto_window=>veto_window, dead_time=>dead_time, output_mode=>output_mode, trig_out=>trig_out, trig_time=>trig_time, reset_out=>reset_for_disp);
	reset_out <= not reset_for_disp;
	
	with output_mode select
	LED_indep <= (not crystal_input) or (not veto_input) when "11",
				  '0' when others;	
end arch_hw_trig_out;