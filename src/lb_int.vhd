-- CAEN @ May 26th, 2010
-- Module:          lb_int
-- Description:     Local Bus interface
-- Modification by Suerfu @ April 21, 2016

library ieee;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_arith.all;
use IEEE.Std_Logic_unsigned.all;

entity lb_int is
	port(
		-- Local Bus interface signals
		nLBRES     : in   	std_logic;
		nBLAST     : in   	std_logic;
		WnR        : in   	std_logic;
		nADS       : in   	std_logic;
		LCLK       : in   	std_logic;
		nREADY     : out 	 	std_logic;
		nINT       : out	  std_logic;
		LAD        : inout  std_logic_vector(15 DOWNTO 0);

		-- Software trigger via write access
		soft_trigger : out std_logic;
		
		-- Internal Registers
		REG_CTRL       	: buffer std_logic_vector(31 downto 0);
		REG_GATE_LEN		: buffer std_logic_vector(31 downto 0);
		REG_DEAD_TIME     : buffer std_logic_vector(31 downto 0);
		REG_TIME_BOMB		: buffer std_logic_vector(31 downto 0)
	);
end lb_int;


architecture arch_lb_int of lb_int is

	-- States of the finite state machine
	type   LBSTATE_type is (LBIDLE, LBWRITEL, LBWRITEH, LBREADL, LBREADH);
	signal LBSTATE : LBSTATE_type;
	
	-- Output Enable of the LAD bus (from User to Vme)
	signal LADoe     : std_logic;
	-- Data Output to the local bus
	signal LADout    : std_logic_vector(15 downto 0);
	-- Lower 16 bits of the 32 bit data
	signal DTL       : std_logic_vector(15 downto 0);
	-- Address latched from the LAD bus
	signal ADDR      : std_logic_vector(15 downto 0);
	
	-- Register Address Map
	constant A_REG_CTRL   		: std_logic_vector(15 downto 0) := X"1030";
	constant A_REG_GATE_LEN   	: std_logic_vector(15 downto 0) := X"1034";
	constant A_REG_DEAD_TIME   : std_logic_vector(15 downto 0) := X"1038";
	constant A_REG_TIME_BOMB   : std_logic_vector(15 downto 0) := X"100C";
	
	-- Software trigger
	constant A_REG_SOFT_TRIG	: std_logic_vector(15 downto 0) := X"1042";
	
begin
LAD	<= LADout when LADoe = '1' else (others => 'Z'); -- output tri-state
-- Local bus FSM
process(LCLK, nLBRES)
variable rreg, wreg   : std_logic_vector(31 downto 0);
begin
	if (nLBRES = '0') then
      REG_CTRL <= (others => '0'); -- default, mode 00, no retrig, no sig delay, no trig time, reset on
      REG_GATE_LEN <= (others => '0');
      REG_DEAD_TIME <= (others=>'0');
		REG_TIME_BOMB <= (others=>'0');

      nREADY      <= '1';
      LADoe       <= '0';
      ADDR        <= (others => '0');
      DTL         <= (others => '0');
      LADout      <= (others => '0');
      rreg        := (others => '0');
      wreg        := (others => '0');
      LBSTATE     <= LBIDLE;
		
		soft_trigger <= '0';
		
	elsif rising_edge(LCLK) then
      case LBSTATE is
        when LBIDLE  =>  
          LADoe   <= '0';
			 nREADY  <= '1';
          if (nADS = '0') then        -- start cycle
				ADDR <= LAD;              -- Address Sampling
            if (WnR = '1') then       -- Write Access to the registers
              nREADY   <= '0';
              LBSTATE  <= LBWRITEL;     
            else                      -- Read Access to the registers
              nREADY    <= '1';
              LBSTATE   <= LBREADL;
            end if;
          end if;

        when LBWRITEL => 
          DTL <= LAD;  -- Save the lower 16 bits of the data
          if (nBLAST = '0') then
            LBSTATE  <= LBIDLE;
            nREADY   <= '1';
          else
            LBSTATE  <= LBWRITEH;
          end if;
                         
        when LBWRITEH =>   
          wreg  := LAD & DTL;  -- Get the higher 16 bits and create the 32 bit data
          case ADDR is
            when A_REG_CTRL =>
					REG_CTRL <= wreg;
            when A_REG_GATE_LEN =>
					REG_GATE_LEN <= wreg;
            when A_REG_DEAD_TIME =>
					REG_DEAD_TIME <= wreg;
				when A_REG_TIME_BOMB =>
					REG_TIME_BOMB <= wreg and X"FFFF7FFF";
				when A_REG_SOFT_TRIG =>
					soft_trigger <= '1';
            when others =>
					null;
          end case;
			 
          nREADY   <= '1';
          LBSTATE  <= LBIDLE;

        when LBREADL =>  
          nREADY    <= '0';  -- Assuming that the register is ready for reading
          case ADDR is
            when A_REG_CTRL =>
					rreg := REG_CTRL;
            when A_REG_GATE_LEN =>
					rreg := REG_GATE_LEN;
            when A_REG_DEAD_TIME =>
					rreg := REG_DEAD_TIME;
				when A_REG_TIME_BOMB =>
					rreg := REG_TIME_BOMB;
            when others =>
					null;
          end case;
          LBSTATE  <= LBREADH;
          LADout <= rreg(15 downto 0);    -- Save the lower 16 bits of the data
          LADoe  <= '1';                  -- Enable the output on the Local Bus
          
        when LBREADH =>  
          LADout  <= rreg(31 downto 16);  -- Put the higher 16 bits
          LBSTATE <= LBIDLE;
		 end case;
	end if;
end process;

end arch_lb_int;