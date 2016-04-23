library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Suerfu @ March 28, 2016
-- Veto trigger consists of 10 veto PMT inputs.
-- A majority level is imposed. When trigger number exceeds the majority level
-- a veto command is prodiced.

entity veto_trigger is
	generic( Npmt : integer := 10;
				Nbits_majlev: integer := 4;	-- number of bits to specify majority level
				Nbits_gate : integer := 3		-- num. of bits in specifying length of coincidence window
	);
	port( clk : in std_logic;
			reset : in std_logic;
			en_retrig : in std_logic;		-- retriggerabe
			mask : in std_logic_vector(Npmt-1 downto 0);
													-- veto PMT active or not
			majority_level : in std_logic_vector(Nbits_majlev-1 downto 0);
													-- majority level for triggering veto PMT
			gate_len : in std_logic_vector(Nbits_gate-1 downto 0);
													-- length of veto coincidence window
			veto_input : in std_logic_vector(Npmt-1 downto 0);
													-- veto input signal
			veto_trigger : out std_logic
													-- veto output if majority coincidence
			);
end veto_trigger;

architecture arch_veto_trigger of veto_trigger is

signal gate_out: std_logic_vector(Npmt-1 downto 0);
begin
	-- create coincidence window from each veto pmt
	lb_coin: for i in 0 to Npmt-1 generate
	signal Q, mux, loaded: std_logic;
	begin
		lb_edge_det: entity work.edge_detector(arch_edge_detector)
			port map( clk => veto_input(i),
						 reset => ( mux and reset and mask(i)),
						 Q => Q
			);
		lb_ctr: entity work.gate_generator(arch_gate_generator_moore)
			generic map(Nbits_gate => Nbits_gate)
			port map( clk => clk, reset => reset, en => Q,
						 gate_len => gate_len, gate => gate_out(i), loaded => loaded
			);		
		mux <= (not gate_out(i)) when en_retrig='0' else
				 not loaded;
	end generate;

	-- majority comparator outputs high if there is a coincidence by overlap
	-- with majority level greater than that specified.
	lb_majlev: entity work.majority_comparator(arch_majority_comparator)
		generic map(Nbits => Npmt, Nbits_cmpr => Nbits_majlev)
		port map( D => gate_out, window => majority_level, Q => veto_trigger );

end arch_veto_trigger;