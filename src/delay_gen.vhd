library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 29, 2016
-- N-bit delay generator
-- with synchronous clear and asynchronous reset

entity delay_gen is

	generic( Nbits_gate : integer := 3;
				Nbits_reg : integer := 8);
					-- number of bits needed to represent delay
	port( clk : in std_logic;
				-- system clock
			reset : in std_logic;
				-- asynchronous reset
			sync_clr : in std_logic :='0';
				-- synchronous clear
			delay : in std_logic_vector(Nbits_gate-1 downto 0);
				-- amount of delay
			D : in std_logic;
				-- data input
			Q : out std_logic--;
				-- output as a single bit
			--gate_out : out std_logic_vector(Nbits_gate-1 downto 0)
	);

end delay_gen;

-- delay generator using 8-bit shift register.
architecture arch_delay_gen of delay_gen is
signal cur_reg, next_reg : std_logic_vector(6 downto 0);
	-- there is a state with no delay, so only 7 needed.
begin
	process(clk,reset)
	begin
		if(reset='0') then
			cur_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			if(sync_clr='1') then
				cur_reg <= (others=>'0');
			else
				cur_reg <= next_reg;
			end if;
		end if;
	end process;

	-- next state logic: place data in onto MSB
	next_reg <= D & cur_reg(6 downto 1);
	
	with delay select
		Q <= D when "000",
		  cur_reg(6) when "001",
		  cur_reg(5) when "010",
		  cur_reg(4) when "011",
		  cur_reg(3) when "100",
		  cur_reg(2) when "101",
		  cur_reg(1) when "110",
		  cur_reg(0) when "111";

end arch_delay_gen;
--
--architecture arch_delay_gen of delay_gen is
--signal to_edge_det, Qedge_det, Qff : std_logic;
--signal int_delay : std_logic_vector(Nbits_gate-1 downto 0);
---- signal to_gate : std_logic;
--begin
----		lb_edge_det1: entity work.sync_edge_detector(arch_sync_edge_detector)
----			port map(clk=>clk, reset=>reset, D=>D,Q=>to_gate);
--			
--		lb_gate_gen: entity work.gate_generator(arch_gate_generator)
--			generic map(Nbits_gate=>Nbits_gate)
--			port map (clk=>clk,reset=>reset,en=>D,gate_len=>int_delay,gate=>to_edge_det);--, count=>gate_out);
--			
--		lb_edge_det: entity work.sync_edge_detector(arch_sync_edge_detector_falling_edge)
--			port map(clk=>clk, reset=>reset and (not sync_clr), D=>to_edge_det,Q=>Qedge_det);
--			
--		lb_ff: entity work.dflipflop(arch_dff_reset_low)
--			port map(D=>D and sync_clr,clk=>clk,reset=>reset,Q=>Qff);
--			
--		with delay select
--		Q <= D when std_logic_vector(to_unsigned(0,Nbits_gate)),
--			  Qff when std_logic_vector(to_unsigned(1,Nbits_gate)),
--			  Qedge_det when others;
--			  
--		int_delay <= std_logic_vector(unsigned(delay) -1) when unsigned(delay)>1 else
--						 (others=>'0');
--end arch_delay_gen;