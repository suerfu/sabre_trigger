library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sabre_trigger is
	generic( Ncrystal : integer := 1;
				Nbits_crystal_gate : integer := 8;	-- coincidence gate up to ~5 us.
				
				Nveto_pmt : integer := 10;
				Nbits_majlev : integer := 3;	-- 4 bits needed to enumerate up to 10, but 3 is fine.
				Nbits_veto_gate : integer := 8;	-- up to 5 us.
				
				Nbits_trigtime : integer := 8; -- up to 5 us.
				Nbits_vetotime : integer := 8;
				Nbits_deadtime : integer := 8
	);
	port( clk : in std_logic :='0';
			reset : in std_logic :='0';
			output_mode : in std_logic_vector(1 downto 0);
			
			enable_crystal_retrig : in std_logic :='0';
			crystal_gate_len : in std_logic_vector(Nbits_crystal_gate-1 downto 0) :=(others=>'0');
			crystal_input : in std_logic_vector(2*Ncrystal-1 downto 0) :=(others=>'0');
			
			enable_veto_retrig : in std_logic := '0';
			veto_mask : in std_logic_vector(Nveto_pmt-1 downto 0) :=(others=>'0');
			veto_majority_level : in std_logic_vector(Nbits_majlev-1 downto 0) :=(others=>'0');
			veto_gate_len : in std_logic_vector(Nbits_veto_gate-1 downto 0) :=(others=>'0');
			veto_input : in std_logic_vector(Nveto_pmt-1 downto 0) :=(others=>'0');

			sig_delay_time : in std_logic_vector(2 downto 0) :=(others=>'0'); -- 3 bits for signal delay time.
			veto_window : in std_logic_vector(Nbits_vetotime-1 downto 0) :=(others=>'0'); -- duration of veto
			dead_time : in std_logic_vector(Nbits_deadtime-1 downto 0) :=(others=>'0');
			trig_time : in std_logic_vector(Nbits_trigtime-1 downto 0) :=(others=>'0');
			
			trig_out : out std_logic :='0';
			reset_out : out std_logic := '0'
	);
end sabre_trigger;

architecture arch_sabre_trigger of sabre_trigger is
signal crystal_module_out, temp_coin : std_logic_vector(Ncrystal-1 downto 0);
signal trig_reset, Qxystal, Qveto : std_logic;
begin

	lb_xystal: for i in 0 to Ncrystal-1 generate
	begin
		lb_xystal_coin: entity work.crystal_coincidence(arch_crystal_coincidence)
			generic map( Npmt => 2, Nbits_gate => Nbits_crystal_gate )
			port map( clk => clk, reset => reset and trig_reset, en_retrig => enable_crystal_retrig,
						 gate_len => crystal_gate_len, crystal_input => crystal_input(2*i+1 downto 2*i),
						 crystal_trigger => temp_coin(i)
			);
	end generate;
	
	-- OR gate between different PMT modules.
	crystal_module_out(0) <= temp_coin(0);
	lb_xystal_or: for i in 1 to Ncrystal-1 generate
	begin
		crystal_module_out(i) <= (temp_coin(i) or crystal_module_out(i-1));
	end generate;
	Qxystal <= crystal_module_out(Ncrystal-1);
	
	lb_veto: entity work.veto_trigger(arch_veto_trigger)
		generic map( Npmt => Nveto_pmt, Nbits_majlev => Nbits_majlev, Nbits_gate => Nbits_veto_gate )
		port map( clk => clk, reset => reset and trig_reset, en_retrig => enable_veto_retrig, mask => veto_mask,
					 majority_level => veto_majority_level, gate_len => veto_gate_len,
					 veto_input => veto_input, veto_trigger => Qveto
		);
	
	lb_trig: entity work.trigger_output(arch_trigger_output)
		generic map( Nbits_trigtime => Nbits_trigtime, Nbits_vetotime => Nbits_vetotime, Nbits_deadtime => Nbits_deadtime )
		port map( clk=>clk, reset => reset, crystal_input => Qxystal, output_mode => output_mode,
					 veto_input => Qveto, sig_delay_time => sig_delay_time,
					 veto_window => veto_window, dead_time => dead_time, trig_time => trig_time,
					 trig_out => trig_out, reset_out => trig_reset
		);
	reset_out <= trig_reset;
end arch_sabre_trigger;