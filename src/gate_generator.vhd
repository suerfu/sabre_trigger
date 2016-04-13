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
			gate_len : in std_logic_vector(Nbits_gate-1 downto 0);
				-- register that holds window length
			gate : out std_logic;
			loaded : out std_logic
				-- signal is used for reset the edge detector
	);
end gate_generator;

architecture arch_gate_generator_moore of gate_generator is
type counter_control is ( idle, trig, count );
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
				if en='1' then
					state_next <= trig; -- trigger in
				else
					state_next <= state_reg;
				end if;
			when trig =>
					state_next <= count;
			when count =>
				if en='1' then -- input high, not finished counting
					state_next <= trig;
				elsif min='1' then -- input high and finished counting, 
					state_next <= idle;
				else
					state_next <= state_reg;
				end if;
		end case;
	end process;

	-- Moore output
	process(state_reg)
	begin
		case state_reg is
			when idle =>
				enable_ctr <= '0';
				load_ctr <='0';
			when trig =>
				enable_ctr <= '1';
				load_ctr <= '1';
			when count =>
				enable_ctr <= (not min);
				load_ctr <= '0';
		end case;
	end process;

	lb_ctr: entity work.counter(arch_univ_counter)
		generic map( Nbits => Nbits_gate )
		port map( clk=>clk, reset=>reset, en=>enable_ctr, load_value=>gate_len,
					 load=>load_ctr, up=>'0', sync_clr=>'0', min=>min
		);

	loaded <= load_ctr;	
	gate <= not min;
end arch_gate_generator_moore;

architecture arch_gate_generator_mealy of gate_generator is
type counter_control is ( idle, trig, count );
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
				if en='1' then
					state_next <= trig; -- trigger in
				else
					state_next <= state_reg;
				end if;
			when trig =>
					state_next <= count;
			when count =>
				if en='1' then -- input high, not finished counting
					state_next <= trig;
				elsif min='1' then -- input high and finished counting, 
					state_next <= idle;
				else
					state_next <= state_reg;
				end if;
		end case;
	end process;

	-- Mealy output
	process(state_reg, en, min)
	begin
		case state_reg is
			when idle =>
				if en='1' then
					enable_ctr <= '1';
					load_ctr <='1';
				else
					enable_ctr <= '0';
					load_ctr <='0';
				end if;
			when trig =>
				load_ctr <= '0';
				enable_ctr <= (not min);
			when count =>
				if en='1' then
					load_ctr <= '1';
					enable_ctr <= '1';
				else
					load_ctr <= '0';
					enable_ctr <= (not min);
				end if;
		end case;
	end process;

	lb_ctr: entity work.counter(arch_univ_counter)
		generic map( Nbits => Nbits_gate )
		port map( clk=>clk, reset=>reset, en=>enable_ctr, load_value=>gate_len,
					 load=>load_ctr, up=>'0', sync_clr=>'0', min=>min
		);
	lb_buff: entity work.dflipflop(arch_dff_reset_low)
		port map(D=>load_ctr, Q=>loaded, clk=>clk, reset=>reset);
		-- use one stage buffer to avoid instantaneous reset.
	--loaded <= load_ctr;
	
	gate <= not min;
end arch_gate_generator_mealy;