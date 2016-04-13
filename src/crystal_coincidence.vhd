library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 25, 2016

entity crystal_coincidence is
	generic(	Npmt : integer := 2;
					-- number of pmt per crystal
				Nbits_gate : integer := 2
					-- coincidence window in number of clock cycles
	);

	port ( clk : in std_logic :='0';
			 reset : in std_logic :='1';
			 en_retrig : in std_logic :='1';
				-- enable/disable re-trigger (extend or ignore current trigger)
			 gate_len : in std_logic_vector(Nbits_gate-1 downto 0) :=(others=>'0');
				-- register that holds coincidence window length
				
			 crystal_input : in std_logic_vector(Npmt-1 downto 0) :="00";
				-- signal input from crystal scintillation
			 crystal_trigger : out std_logic := '0';
				-- output of coincidence
			 --crystal_output : out std_logic_vector(Npmt-1 downto 0) :=(others=>'0');
				-- optional, the window produced by two gates
			 sync_out : out std_logic_vector(Npmt-1 downto 0) :=(others=>'0')
	);

end crystal_coincidence;

architecture arch_crystal_coincidence of crystal_coincidence is
signal gate_out, temp_coin : std_logic_vector(Npmt-1 downto 0);
begin
	-- create coincidence window from each pmt
	lb_coin: for i in 0 to Npmt-1 generate
	signal Q, loaded, mux: std_logic;
	
	begin
		lb_edge: entity work.edge_detector(arch_edge_detector)
			port map( clk => crystal_input(i),
						 reset =>  mux and reset,
						 Q => Q -- will stay high until reset
			);
		lb_ctr: entity work.gate_generator(arch_gate_generator_moore)
			generic map(Nbits_gate => Nbits_gate)
			port map( clk => clk, reset => reset, en => Q,
						 gate_len => gate_len, gate => gate_out(i),
						 loaded => loaded
			);
		mux <= (not gate_out(i)) when en_retrig='0' else
				 not loaded;	-- this option is disabled in the Mealy output.
		sync_out(i) <= loaded;
	end generate;

	-- combine output of all/both PMTs
	-- crystal_output <= gate_out;
	temp_coin(0) <= gate_out(0);
	label_coin_gate: for i in 1 to Npmt-1 generate
	begin
		temp_coin(i) <= (temp_coin(i-1) and gate_out(i));
	end generate;
	
	crystal_trigger <= temp_coin(Npmt-1);
	
end arch_crystal_coincidence;