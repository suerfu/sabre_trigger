library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016
-- Gate generator generates a gate of programmable length in clock cycle.
-- It responds to the signal edge.
-- It will either retrigger or wait for the current gate to finish.

entity gate_generator is
	generic(	Nbits_gate : integer := 8
				-- coincidence window in number of clock cycles
	);
	port( clk : in std_logic;
			reset : in std_logic;
			en : in std_logic;
				-- one shot, enables gate generator
			enable_retrig: in std_logic :='1';
				-- retrigger the gate
			gate_len : in std_logic_vector(Nbits_gate-1 downto 0);
				-- register that holds window length
			gate : out std_logic;
			indicator : out std_logic_vector(2 downto 0);
				-- output gate for comparator (optional in count down mode)
			A : out std_logic_vector(Nbits_gate-1 downto 0)
			--sync_out : out std_logic
	);
end gate_generator;

architecture arch_gate_generator of gate_generator is
type counter_control is ( idle, trig, count, retrig, wait_end );
signal state_reg, state_next : counter_control;
signal enable_ctr, load_ctr, min, sync_clr: std_logic;

begin
	-- state register
	process(clk,reset)
	begin
		if reset='0' then
			state_reg <= idle;
		elsif (clk'event and clk='1') then
			state_reg <= state_next;
		end if;
	end process;
	-- next state logic
	process( state_reg, en, min )
	begin
		case state_reg is
			when idle => 
				if en='1' and min='1' then
					state_next <= trig;
					-- when PMT trigger comes in, and counter has finished
				else
					state_next <= state_reg;
				end if;
			when trig =>
				if en='0' and enable_retrig='1' then
					state_next <= retrig; -- prepare for re-trigger
				else
					state_next <= count;
				end if;
			when count =>
				if en='1' and min='0' then -- input high, not finished counting
					state_next <= count;
				elsif en='0' and min='0'  then -- input low, not finished counting, might retrigger
					state_next <= retrig;
				elsif en='1' and min='1' then -- input high and finished counting, 
					state_next <= wait_end;
				else
					state_next <= idle;
				end if;
			when retrig =>
				if enable_retrig='1' and en='1' then
					state_next <= trig;
				elsif min='1' and en='0' then
					state_next <= idle;
				else
					state_next <= retrig;
				end if;
			when wait_end =>
				if en='0' then
					state_next <= idle;
				else
					state_next <= wait_end;
				end if;
			when others =>
				state_next <= idle;
		end case;
	end process;
	-- Moore output
--	process(state_reg)
--	begin
--		case state_reg is
--			when idle =>
--				enable_ctr <= '0';
--				load_ctr <='0';
--				indicator <= "000";
--			when wait_end =>
--				enable_ctr <= '0';
--				load_ctr <='0';
--				indicator <= "100";
--			when trig =>
--				enable_ctr <= '1';
--				load_ctr <= '1';
--				indicator <= "001";
--			when count =>
--				enable_ctr <= '1' and (not min);
--				load_ctr <= '0';
--				indicator <= "111";
--			when retrig =>
--				enable_ctr <= '1' and (not min);
--				load_ctr <= '0';
--				indicator <= "011";
--		end case;
--	end process;
	-- Mealy output
	process(state_reg, en, min)
	begin
		case state_reg is
			when idle =>
				indicator <= "000";	
				if en='1' and min='1' then
					enable_ctr <= '1';
					load_ctr <='1';
				else
					enable_ctr <= '0';
					load_ctr <='0';
				end if;
			when trig =>
				indicator <= "001";
				load_ctr <= '0';
				enable_ctr <= (not min);
			when count =>
				load_ctr <='0';
				enable_ctr <= (not min);
				indicator <= "111";			
			when retrig =>
				if en='1' and enable_retrig='1' then
					load_ctr <= '1';
				elsif min='1' then
					enable_ctr <= '0';
				end if;
				indicator <= "011";
			when wait_end =>
				load_ctr <= '0';
				enable_ctr <= '0';
				indicator <= "101";
		end case;
		
	end process;
	lb_ctr: entity work.counter(arch_univ_counter)
		generic map( Nbits => Nbits_gate )
		port map( clk=>clk, reset=>reset, en=>enable_ctr, load_value=>gate_len,
					 load=>load_ctr, up=>'0', sync_clr=>sync_clr, min=>min, Q=>A
		);
	
	gate <= not min;
end arch_gate_generator;