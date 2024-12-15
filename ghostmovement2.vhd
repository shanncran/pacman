library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

entity ghost_movement2 is
	port (
		clk : in std_logic;
		reset : in std_logic; -- delete later
		valid : in std_logic;
		controls : in std_logic_vector (7 downto 0);
		ghostXcoord2 : out unsigned(9 downto 0);
		ghostYcoord2 : out unsigned(9 downto 0);
		directionOut : out std_logic_vector(1 downto 0)
	);
end ghost_movement2;


architecture synth of ghost_movement2 is
-- components
component wall_check is
  port(
    clk : in  std_logic;             
    valid : in  std_logic;                
    address_x : in  unsigned(9 downto 0);
    address_y : in  unsigned(9 downto 0); 
    wall : out std_logic      
  );
end component;
 
-- signals

	type State is (up, down, left, right);
	signal direction : State := right; 
	signal reset_button : std_logic;
	signal left_pressed : std_logic;
	signal right_pressed : std_logic;
	signal down_pressed : std_logic;
	signal up_pressed : std_logic;
	signal direction_out : std_logic_vector(1 downto 0) := "00";
	

	signal inter_ghostx : unsigned(9 downto 0);
	signal inter_ghosty : unsigned (9 downto 0);
	signal movecounter : unsigned(18 downto 0) := (others => '0');

begin
	left_pressed <= controls(1);
	right_pressed <= controls(0);
	down_pressed <= controls(2);
	up_pressed <= controls(3);
	reset_button <= controls(4);

	 --assigning signals to the respective buttons
	

process(clk) is
begin
	if rising_edge(clk) then
		movecounter <= movecounter + 1;
		if (movecounter = "1110011010110110100") then
		if (reset_button = '0') and (left_pressed = '1' and right_pressed = '1' and up_pressed = '1' and down_pressed = '1') then
		 inter_ghostx <= 10d"100";
		 inter_ghosty <= 10d"320";
		else
				if (inter_ghostx < 516 and direction = right) then 
					inter_ghostx <= inter_ghostx + 1;
					inter_ghosty <= inter_ghosty;
					direction_out <= "00";
				elsif (inter_ghostx = 100) then 
					direction <= right;
				else
					direction <= left;
					inter_ghostx <= inter_ghostx - 1;
					inter_ghosty <= inter_ghosty;
					direction_out <= "01";
				end if;
			end if;
		end if;
	--end if;
	end if;
	end process;
	
	ghostXcoord2 <= inter_ghostx;
	ghostYcoord2 <= inter_ghosty;
end;
