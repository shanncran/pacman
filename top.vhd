library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
						
entity top is port(					
	clk_in: in std_logic; 
	pin : out std_logic;				
	HSYNC_out : out std_logic; 
	VSYNC_out : out std_logic; 
	--NES
	data_in : in std_logic;
	latch : out std_logic;
	nes_clk : out std_logic;
	ctrl : out std_logic_vector(7 downto 0);
	RGB_out : out unsigned(5 downto 0)					
);
 end top;
						
architecture synth of top is
signal clk_tovga: std_logic;
signal inter_row : unsigned(9 downto 0); 
signal inter_column : unsigned(9 downto 0); 
signal inter_valid: std_logic;
signal pacxpos : unsigned(9 downto 0) := 10d"32";
signal pacypos : unsigned(9 downto 0) := 10d"224";
signal ghostypos : unsigned(9 downto 0);
signal ghostxpos : unsigned(9 downto 0);
signal ghostypos2 : unsigned(9 downto 0);
signal ghostxpos2 : unsigned(9 downto 0);
signal ghostypos3 : unsigned(9 downto 0);
signal ghostxpos3 : unsigned(9 downto 0);
signal applexpos : unsigned(9 downto 0);
signal appleypos : unsigned(9 downto 0);
signal pac_has_moved : std_logic;
signal game_over : std_logic;
signal direction : std_logic_vector(1 downto 0);

-- Controller input signals, 7 == A and 0 == Right
-- A, B, Select, Start, Up, Down, Left, Right
signal controls : std_logic_vector(7 downto 0);

component mypll is				
port(
	ref_clk_i: in std_logic; 
	rst_n_i: in std_logic; 
	outcore_o: out std_logic; 
	outglobal_o: out std_logic						
);
end component;
						
component vga is port(
	clk: in std_logic;
	r: out unsigned(9 downto 0); 
	c: out unsigned(9 downto 0); 
	HSYNC : out std_logic; 
	VSYNC : out std_logic; 
	Valid : out std_logic					
);
end component;
						
component pattern_gen is port(	
	clk_display : in std_logic;
	valid: in std_logic;
	row: in unsigned(9 downto 0); 
	column: in unsigned(9 downto 0); 
	controls : in std_logic_vector(7 downto 0);
	pacxpos : in unsigned(9 downto 0);
	pacypos : in unsigned(9 downto 0);
	ghostxpos : in unsigned(9 downto 0);
	ghostypos : in unsigned(9 downto 0);
	ghostxpos2 : in unsigned(9 downto 0);
	ghostypos2 : in unsigned(9 downto 0);
	ghostxpos3 : in unsigned(9 downto 0);
	ghostypos3 : in unsigned(9 downto 0);
	applexpos : in unsigned(9 downto 0);
	appleypos : in unsigned(9 downto 0);
	direction : in std_logic_vector(1 downto 0);
	game_over : out std_logic;
	RGB: out unsigned(5 downto 0)
	--game_clk : in std_logic
);
end component;

component nes is
port (
	  data_in : in std_logic;
	  latch : out std_logic;
	  clk : in std_logic;
	  controller_clk : out std_logic;
	  data_out : out std_logic_vector(7 downto 0)
);
end component;

component movement is
port (
		clk : in std_logic;
		reset : in std_logic;
		controls : in std_logic_vector(7 downto 0);
		valid : in std_logic;
		pacXcoord : out unsigned(9 downto 0);
		pacYcoord : out unsigned(9 downto 0);
		directionOut : out std_logic_vector(1 downto 0)
);
end component;

component ghost_movement is
	port (
		clk : in std_logic;
		valid : in std_logic;
		reset : in std_logic; -- delete later
		controls : in std_logic_vector(7 downto 0);
		ghostXcoord : out unsigned(9 downto 0);
		ghostYcoord : out unsigned(9 downto 0);
		directionOut : out std_logic_vector(1 downto 0)
	);
end component;

component ghost_movement2 is
	port (
		clk : in std_logic;
		valid : in std_logic;
		reset : in std_logic; -- delete later
		controls : in std_logic_vector(7 downto 0);
		ghostXcoord2 : out unsigned(9 downto 0);
		ghostYcoord2 : out unsigned(9 downto 0);
		directionOut : out std_logic_vector(1 downto 0)
	);
end component;

component ghost_movement3 is
	port (
		clk : in std_logic;
		valid : in std_logic;
		reset : in std_logic; -- delete later
		controls : in std_logic_vector(7 downto 0);
		ghostXcoord3 : out unsigned(9 downto 0);
		ghostYcoord3 : out unsigned(9 downto 0);
		directionOut : out std_logic_vector(1 downto 0)
	);
end component;

component apple_movement is
	port (
		clk : in std_logic;
		valid : in std_logic;
		reset : in std_logic; -- delete later
		controls : in std_logic_vector(7 downto 0);
		appleXcoord : out unsigned(9 downto 0);
		appleYcoord : out unsigned(9 downto 0);
		directionOut : out std_logic_vector(1 downto 0)
	);
end component;
								
begin
mypll_map : mypll port map (									
	ref_clk_i => clk_in,					
	rst_n_i => '1', 
	outcore_o => pin,					
	outglobal_o => clk_tovga 
);
				
my_vga : vga port map (
	HSYNC => HSYNC_out, 
	VSYNC => VSYNC_out, 
	clk => clk_tovga,
	r => inter_row,
	c => inter_column,
	Valid => inter_valid 
);
						
my_pattern_gen : pattern_gen port map (						
	row => inter_row, 
	column => inter_column, 
	RGB => RGB_out,
	valid => inter_valid,
	controls => controls,
	clk_display => clk_tovga,
	pacxpos => pacxpos,
	pacypos => pacypos,
	ghostxpos => ghostxpos,
	ghostypos => ghostypos,
	ghostxpos2 => ghostxpos2,
	ghostypos2 => ghostypos2,
	ghostxpos3 => ghostxpos3,
	ghostypos3 => ghostypos3,
	applexpos => applexpos,
	appleypos => appleypos,
	direction => direction,
	
	game_over => game_over
); 

nes1 : 
nes port map (
	  data_in => data_in,
	  latch => latch,
	  clk => clk_tovga,
	  controller_clk => nes_clk,
	  data_out => controls
);

pac_movement :
movement port map (
		clk => clk_tovga,
		reset => game_over,
		controls => controls,
		valid => inter_valid,
		pacXcoord => pacxpos,
		pacYcoord => pacypos,
		directionOut => direction
);

ghost_move : ghost_movement port map(
		clk => clk_tovga,
		reset => game_over,
		controls => controls,
		valid => inter_valid,
		ghostXcoord => ghostxpos,
		ghostYcoord => ghostypos,
		directionOut => direction
);

ghost_move2 : ghost_movement2 port map(
		clk => clk_tovga,
		reset => game_over,
		controls => controls,
		valid => inter_valid,
		ghostXcoord2 => ghostxpos2,
		ghostYcoord2 => ghostypos2,
		directionOut => direction
);
ghost_move3 : ghost_movement3 port map(
		clk => clk_tovga,
		reset => game_over,
		controls => controls,
		valid => inter_valid,
		ghostXcoord3 => ghostxpos3,
		ghostYcoord3 => ghostypos3,
		directionOut => direction
);


apple_move : apple_movement port map(
		clk => clk_tovga,
		reset => game_over,
		controls => controls,
		valid => inter_valid,
		appleXcoord => applexpos,
		appleYcoord => appleypos,
		directionOut => direction
);
end; 
