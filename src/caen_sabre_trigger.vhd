-- Suerfu @ April 21, 2016
-- SABRE trigger that incorporates CAEN front panel and VME interface.

library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.std_Logic_arith.all;
use IEEE.std_Logic_unsigned.all;


entity caen_sabre_trigger is
	port(
		-- Front Panel Ports
		A        : in     std_logic_vector (31 downto 0);  -- In A (32 x LVDS/ECL)
		B        : in     std_logic_vector (31 downto 0);  -- In B (32 x LVDS/ECL)

		-- output trigger through port G
		GOUT     : out    std_logic_vector ( 1 downto 0);   -- Out G - LEMO (2 x NIM/TTL)
	 
		-- Output Enable Port G
		nOEG     : out    std_logic;

		-- Port Level Select (0=NIM, 1=TTL)
		SELG     : out    std_logic;                       -- Output Level Select Port G

		-- LED drivers
		nLEDG    : out    std_logic;                       -- Green (active low)
		nLEDR    : out    std_logic;                       -- Red (active low)

		-- Local Bus interface
		nLBRES     : in     std_logic;
		nBLAST     : in     std_logic;
		WnR        : in     std_logic;
		nADS       : in     std_logic;
		LCLK       : in     std_logic;
		nREADY     : out    std_logic;
		nINT       : out    std_logic;
		LAD        : inout  std_logic_vector (15 DOWNTO 0)
	);
end caen_sabre_trigger;


architecture arch_caen_sabre_trigger of caen_sabre_trigger is

	signal REG_CTRL		: std_logic_vector(31 downto 0);
	signal REG_GATE_LEN	: std_logic_vector(31 downto 0);
	signal REG_DEAD_TIME	: std_logic_vector(31 downto 0);
	signal REG_TIME_BOMB	: std_logic_vector(31 downto 0) := X"F00D0ADC"; -- bit 15 must be 0
	signal REG_SOFT_TRIG : std_logic_vector(31 downto 0) := (others=>'0');
	
	-- alias signals for control register
	alias go : std_logic is REG_CTRL(0);
	alias reset : std_logic is REG_CTRL(1);
	alias output_mode : std_logic_vector(1 downto 0) is REG_CTRL(3 downto 2);
	alias enable_crystal_retrig : std_logic is REG_CTRL(4);
	alias enable_veto_retrig : std_logic is REG_CTRL(5);
	alias veto_mask : std_logic_vector(9 downto 0) is REG_CTRL(15 downto 6);
	alias veto_majority_level : std_logic_vector(3 downto 0) is REG_CTRL(19 downto 16);
	alias sig_delay_time : std_logic_vector(2 downto 0) is REG_CTRL(22 downto 20);
	alias trig_time : std_logic_vector(7 downto 0) is REG_CTRL(30 downto 23);
	
	-- alias for gate length register
	alias crystal_gate_len : std_logic_vector(15 downto 0) is REG_GATE_LEN(15 downto 0);
	alias veto_gate_len : std_logic_vector(15 downto 0) is REG_GATE_LEN(31 downto 16);
	
	-- alias for veto time and dead time
	alias dead_time : std_logic_vector(15 downto 0) is REG_DEAD_TIME( 15 downto 0);
	alias veto_window : std_logic_vector(15 downto 0) is REG_DEAD_TIME( 31 downto 16);
	
	signal G_trig_out : std_logic;
	alias crystal_input : std_logic_vector is B(11 downto 10);
	alias veto_input : std_logic_vector is B(9 downto 0);
	
	signal soft_trigger : std_logic := '0';
begin

	nOEG  <=  '1';
	SELG  <=  '1';  -- 1 for TTL, can also derive it from VME communication

	--nLEDR <= not G_trig_out;	-- when trigger, redlight for busy
	nLEDR <= not soft_trigger;
	--nLEDG <= not (go and (not G_trig_out) );	-- when board ready and no trigger, green light
	nLEDG <= not (go and (not soft_trigger) );	-- when board ready and no trigger, green light

	--soft_trigger <= REG_SOFT_TRIG(0);
	
	sabre: entity work.sabre_trigger(arch_sabre_trigger)
		generic map( Ncrystal => 1, Nbits_crystal_gate => 16,
						 Nveto_pmt => 10, Nbits_majlev => 4, Nbits_veto_gate => 16,
						 Nbits_trigtime => 8, Nbits_vetotime => 16, Nbits_deadtime => 16
		)
		port map( clk => LCLK, reset => (go and reset), output_mode => output_mode,
					 enable_crystal_retrig => enable_crystal_retrig,
					 crystal_gate_len => crystal_gate_len,
					 crystal_input => crystal_input,
					 enable_veto_retrig => enable_veto_retrig,
					 veto_gate_len => veto_gate_len,
					 veto_mask => veto_mask,
					 veto_majority_level => veto_majority_level,
					 veto_input => veto_input,
					 sig_delay_time => sig_delay_time,
					 veto_window => veto_window,
					 dead_time => dead_time,
					 trig_time => trig_time,
					 force_trigger => soft_trigger,
					 trig_out => G_trig_out
		);

  lb_int: entity work.lb_int
		port map (
			-- Local Bus in/out signals
			nLBRES      => nLBRES,
			nBLAST      => nBLAST,   
			WnR         => WnR,      
			nADS        => nADS,     
			LCLK        => LCLK,     
			nREADY      => nREADY,   
			nINT        => nINT,     
			LAD         => LAD,

			-- Internal Registers
			REG_CTRL => REG_CTRL,
			REG_DEAD_TIME => REG_DEAD_TIME,
			REG_GATE_LEN => REG_GATE_LEN,
			REG_TIME_BOMB => REG_TIME_BOMB,
			REG_SOFT_TRIG => REG_SOFT_TRIG,
			soft_trigger => soft_trigger
		);
		
	GOUT <= (others=>G_trig_out);

end arch_caen_sabre_trigger;