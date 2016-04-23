library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016
-- crystal coincidence unit takes two input from PMT and generates
-- a gate of programmable length. When there is coincidence by overlap
-- output goes high.
-- the gate can be programmed to be retriggerable (re-generate gate at new signal)

entity crystal_coincidence is
	generic(	Npmt : integer := 2;			-- number of pmt per crystal
				Nbits_gate : integer := 2	-- coincidence window in number of clock cycles
	);
	port ( clk : in std_logic :='0';
			 reset : in std_logic :='1';
			 en_retrig : in std_logic :='1';		-- enable/disable re-trigger
			 gate_len : in std_logic_vector(Nbits_gate-1 downto 0) :=(others=>'0');
															-- holds coincidence window length
			 crystal_input : in std_logic_vector(Npmt-1 downto 0) :="00";
															-- signal input from crystal scintillation
			 crystal_trigger : out std_logic := '0'
															-- output of coincidence
			 --crystal_output : out std_logic_vector(Npmt-1 downto 0) :=(others=>'0');
				-- optional, the window produced by two gates
			 --sync_out : out std_logic_vector(Npmt-1 downto 0) :=(others=>'0')
				-- debug purpose, to count input signals that made into the board
	);

end crystal_coincidence;

architecture arch_crystal_coincidence of crystal_coincidence is
signal gate_out : std_logic_vector(Npmt-1 downto 0);
--signal temp_coin : std_logic_vector(Npmt-1 downto 0);	-- if Npmt > 2
begin
	-- create coincidence window from each pmt
	lb_coin: for i in 0 to Npmt-1 generate
	signal Q, loaded, mux: std_logic;
	begin
		-- edge detector latches high at incoming signal edge and stay high until reset
		-- reset comes from either a load signal from counter (re-trigger), or
		-- from output gate
		lb_edge: entity work.edge_detector(arch_edge_detector)
			port map( clk => crystal_input(i),
						 reset =>  mux and reset,
						 Q => Q
			);
		-- Moore architecture needs to be used for reliable operation
		lb_ctr: entity work.gate_generator(arch_gate_generator_moore)
			generic map(Nbits_gate => Nbits_gate)
			port map( clk => clk, reset => reset, en => Q,
						 gate_len => gate_len, gate => gate_out(i),
						 loaded => loaded
			);
		-- signal mux is used to clear the incoming latch
		mux <= (not gate_out(i)) when en_retrig='0' else
				 not loaded;
		--sync_out(i) <= loaded;
			-- debug purpose
	end generate;

	crystal_trigger <= gate_out(0) and gate_out(1);
	
	-- combine output of all/both PMTs -- if Npmt > 2
--	temp_coin(0) <= gate_out(0);
--	label_coin_gate: for i in 1 to Npmt-1 generate
--	begin
--		temp_coin(i) <= (temp_coin(i-1) and gate_out(i));
--	end generate;
--	crystal_trigger <= temp_coin(Npmt-1);
	
end arch_crystal_coincidence;