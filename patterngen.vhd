library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
						
entity pattern_gen is 
generic (
	WORD_SIZE : natural := 20; -- Bits per word (read/write block size)
	N_WORDS : natural := 15; -- Number of words in the memory
	ADDR_WIDTH : natural := 4 -- This should be log2 of N_WORDS; see the Big Guide to Memory for a way to eliminate this manual calculation
);
port(					
    clk_display : in std_logic;	
	--clk_coins : in std_logic;
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
	RGB: out unsigned(5 downto 0);
	game_over : out std_logic
);
end pattern_gen;

-- rom should be a submodule for pattern gen, rom gives back a value to pattern gen (RGB <= whatever)
						
architecture synth of pattern_gen is 
--components
component wall_check is
  port(
    clk : in  std_logic;             
    valid : in  std_logic;                
    address_x : in  unsigned(9 downto 0);
    address_y : in  unsigned(9 downto 0); 
    wall : out std_logic      
  );
 end component;
 
component eating1_rom is
   port (
       row_address : in std_logic_vector(4 downto 0);
       row_data : out std_logic_vector(20 downto 0)
   );
end component;
component eating2_rom is
   port (
       row_address : in std_logic_vector(4 downto 0);
       row_data : out std_logic_vector(20 downto 0)
   );
end component;

component eating3_rom is
   port (
       row_address : in std_logic_vector(4 downto 0);
       row_data : out std_logic_vector(20 downto 0)
   );
end component;

component eating1updown is
   port (
       row_address : in std_logic_vector(4 downto 0);
       row_data : out std_logic_vector(20 downto 0)
   );
end component;

component eating2updown is
   port (
       row_address : in std_logic_vector(4 downto 0);
       row_data : out std_logic_vector(20 downto 0)
   );
end component;

component eating1down is
  Port (
      row_address : in std_logic_vector(4 downto 0);
      row_data : out std_logic_vector(20 downto 0)
  );
end component;

component eating2down is
  Port (
      row_address : in std_logic_vector(4 downto 0);
      row_data : out std_logic_vector(20 downto 0)
  );
end component;


component ghost_rom is
   port (
       row_address : in std_logic_vector(4 downto 0);
       row_data : out std_logic_vector(20 downto 0)
   );
end component;

component ghost_rom2 is
   port (
       row_address2 : in std_logic_vector(4 downto 0);
       row_data2: out std_logic_vector(20 downto 0)
   );
end component;

 component ghost_rom3 is
   port (
       row_address3 : in std_logic_vector(4 downto 0);
       row_data3: out std_logic_vector(20 downto 0)
   );
end component;

 component apple_rom is
   port (
       applerow_address : in std_logic_vector(4 downto 0);
       applerow_data: out std_logic_vector(20 downto 0)
   );
end component;

component gameover_rom is
   Port (
       x_coord : in std_logic_vector(6 downto 0);
	   y_coord : in std_logic_vector(5 downto 0);
       rgb : out std_logic_vector(5 downto 0)
   );
end component;

--component start_rom is
   --Port (
       --x_coord : in std_logic_vector(6 downto 0);
	   --y_coord : in std_logic_vector(5 downto 0);
       --rgb : out std_logic_vector(5 downto 0)
   --);
--end component;

component winner_rom is
   Port (
       x_coord : in std_logic_vector(6 downto 0);
	   y_coord : in std_logic_vector(5 downto 0);
       rgb : out std_logic_vector(5 downto 0)
   );
end component;
 
--signals
signal row_addr : unsigned (3 downto 0); 
signal wall_here : std_logic;
signal pac1 : std_logic_vector(20 downto 0);
signal pac2 : std_logic_vector(20 downto 0);
signal pac3 : std_logic_vector(20 downto 0);

signal pacdisplay : std_logic_vector(20 downto 0);
signal pacdisplay1 : std_logic_vector(20 downto 0);
signal pacdisplay2 : std_logic_vector(20 downto 0);
signal pacdisplay3 : std_logic_vector(20 downto 0);
signal pacdisplay4 : std_logic_vector(20 downto 0);
signal pacdisplay5 : std_logic_vector(20 downto 0);
signal pacdisplay6 : std_logic_vector(20 downto 0);
signal pacdisplay7 : std_logic_vector(20 downto 0);


signal start_screen : std_logic_vector(5 downto 0);
signal winscreen : std_logic_vector(5 downto 0);

signal reset_button : std_logic := '1';
signal leftp : std_logic := '1';
signal rightp : std_logic := '1';
signal downp : std_logic := '1';
signal upp : std_logic := '1';
signal select_button : std_logic := '1';
signal a_button : std_logic := '1';
signal b_button : std_logic := '1';


signal animation : unsigned(22 downto 0) := 23d"0";

signal ghostdisplay : std_logic_vector(20 downto 0);
signal ghostdisplay2 : std_logic_vector(20 downto 0);
signal ghostdisplay3 : std_logic_vector(20 downto 0);
signal appledisplay : std_logic_vector(20 downto 0);


signal pacx : unsigned(9 downto 0);-- := 10d"32";
signal pacy : unsigned(9 downto 0);-- := 10d"224";
signal pacaddry : std_logic_vector(9 downto 0) := 10d"32";
signal pacaddrx : std_logic_vector(9 downto 0) := 10d"32";

signal ghostx : unsigned(9 downto 0);-- := 10d"32";
signal ghosty : unsigned(9 downto 0);-- := 10d"224";
signal ghostaddry : std_logic_vector(9 downto 0) := 10d"32";
signal ghostaddrx : std_logic_vector(9 downto 0) := 10d"32";

signal ghostx2: unsigned(9 downto 0) := 10d"160";
signal ghosty2 : unsigned(9 downto 0) := 10d"224";
signal ghostaddry2 : std_logic_vector(9 downto 0);
signal ghostaddrx2: std_logic_vector(9 downto 0);

signal ghostx3: unsigned(9 downto 0) := 10d"485";
signal ghosty3 : unsigned(9 downto 0) := 10d"32";
signal ghostaddry3 : std_logic_vector(9 downto 0);
signal ghostaddrx3: std_logic_vector(9 downto 0);

signal applex: unsigned(9 downto 0) := 10d"577";
signal appley : unsigned(9 downto 0) := 10d"32";
signal appleaddry : std_logic_vector(9 downto 0);
signal appleaddrx: std_logic_vector(9 downto 0);


signal draw_pacman : std_logic;
signal draw_ghost : std_logic;
signal draw_ghost2 : std_logic;
signal draw_ghost3 : std_logic;
signal draw_apple : std_logic;


signal counter : unsigned(24 downto 0) := 25d"0";

signal display_colors : unsigned(19 downto 0);
signal gameoverscreen : std_logic_vector(5 downto 0);

--signal display_start_screen : std_logic := '0';

type State is (alive, dead, win);
signal game_state : State := alive;

begin

pacx <= pacxpos;
pacy <= pacypos;

ghostx <= ghostxpos;
ghosty <= ghostypos;
ghostx2 <= ghostxpos2;
ghosty2 <= ghostypos2;
ghostx3 <= ghostxpos3;
ghosty3 <= ghostypos3;

applex <= applexpos;
appley <= appleypos;

draw_ghost <= '1' when (column >= ghostx and column <= ghostx + 21 and row >= ghosty and row <= ghosty + 32) else '0';
draw_ghost2 <= '1' when (column >= ghostx2 and column <= ghostx2 + 21 and row >= ghosty2 and row <= ghosty2 + 32) else '0';
draw_ghost3 <= '1' when (column >= ghostx3 and column <= ghostx3 + 21 and row >= ghosty3 and row <= ghosty3 + 32) else '0';
draw_apple <= '1' when (column >= applex and column <= applex + 21 and row >= appley and row <= appley + 32) else '0';
draw_pacman <= '1' when (column >= pacx and column <= pacx + 21 and row >= pacy and row <= pacy + 32) else '0';

wall_checker:
wall_check port map(
	clk => clk_display,
	valid => valid,       
	address_x => column,
	address_y => row,
	wall => wall_here
);

eating1rom:
eating1_rom port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay1
);
eating2rom:
eating2_rom port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay2
);
eating3rom:
eating3_rom port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay3
);
eating1rom_updown:
eating1updown port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay4
);
eating2rom_updown:
eating2updown port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay5
);

eating1_down:
eating1down port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay6
);

eating2_down:
eating2down port map (
	row_address => pacaddry(4 downto 0),
	row_data => pacdisplay7
);

ghostrom:
ghost_rom port map (
	row_address => ghostaddry(4 downto 0),
	row_data => ghostdisplay
);

ghostrom2:
ghost_rom2 port map (
	row_address2 => ghostaddry2(4 downto 0),
	row_data2 => ghostdisplay2
);

ghostrom3:
ghost_rom3 port map (
	row_address3 => ghostaddry3(4 downto 0),
	row_data3 => ghostdisplay3
);


applerom :
apple_rom port map (
	applerow_address => appleaddry(4 downto 0),
	applerow_data => appledisplay
);

endrom:
gameover_rom port map (
	x_coord => std_logic_vector(column(9 downto 3)),
	y_coord => std_logic_vector(row(8 downto 3)),
	rgb => gameoverscreen
);


winrom : 
winner_rom port map (
	x_coord => std_logic_vector(column(9 downto 3)),
	y_coord => std_logic_vector(row(8 downto 3)),
	rgb => winscreen
);


pacaddry <= std_logic_vector(row - pacy);-- when (pac_has_moved = '0') else std_logic_vector(pacypos);
pacaddrx <= std_logic_vector(column - pacx);-- when (pac_has_moved = '0') else std_logic_vector(pacxpos);
ghostaddry <= std_logic_vector(row - ghosty);-- when (pac_has_moved = '0') else std_logic_vector(pacypos);
ghostaddrx <= std_logic_vector(column - ghostx);-- when (pac_has_moved = '0') else std_logic_vector(pacxpos);
ghostaddry2 <= std_logic_vector(row - ghosty2);-- when (pac_has_moved = '0') else std_logic_vector(pacypos);
ghostaddrx2 <= std_logic_vector(column - ghostx2);
ghostaddry3 <= std_logic_vector(row - ghosty3);-- when (pac_has_moved = '0') else std_logic_vector(pacypos);
ghostaddrx3 <= std_logic_vector(column - ghostx3);
appleaddry <= std_logic_vector(row - appley);
appleaddrx <= std_logic_vector(column - applex);

reset_button <= controls(4);
leftp <= controls(1);
rightp <= controls(0);
downp <= controls(2);
upp <= controls(3);
select_button <= controls(7);
a_button <= controls(6);
b_button <= controls(5);


process (clk_display) begin 
	if rising_edge(clk_display) then 
		-- switch pacman animations
		case game_state is
		when alive =>
		if (animation = 6000000) then 
				animation <= 23d"0";
			else 
				animation <= animation + 1;
			end if;
			if (animation < 2000000) then 
				 --left or right
				if (direction = "00" or direction = "01") then 
					pacdisplay <= pacdisplay1;
				 --up
				elsif (direction = "11") then
					pacdisplay <= pacdisplay4;
				 --down
				elsif (direction = "10") then 
					pacdisplay <= pacdisplay6;
				end if;
			elsif (animation < 4000000) then 
				 --left or rightk
				if (direction = "00" or direction = "01") then 
					pacdisplay <= pacdisplay2;
				 --up
				elsif (direction = "11") then
					pacdisplay <= pacdisplay5;
				 --down
				elsif (direction = "10") then 
					pacdisplay <= pacdisplay7;
				end if;
			else 
				pacdisplay <= pacdisplay3;
			end if;
		if (draw_apple = '1' and wall_here = '0') then 
			if appledisplay(21 - to_integer(unsigned(appleaddrx))) = '1'
				then RGB <= "110000";	
			elsif appledisplay(21 - to_integer(unsigned(appleaddrx))) = '0'
				then RGB <= "000000";
				end if;
		elsif (wall_here = '0' and draw_ghost = '1') then 
			if ghostdisplay(21 - to_integer(unsigned(ghostaddrx))) = '1'
				then RGB <= "100110";	
			elsif ghostdisplay(21 - to_integer(unsigned(ghostaddrx))) = '0'
				then RGB <= "000000";
				end if;
		elsif(wall_here = '0' and draw_ghost2 = '1') then 
			if ghostdisplay2(21 - to_integer(unsigned(ghostaddrx2))) = '1'
				then RGB <= "001111";	
			elsif ghostdisplay2(21 - to_integer(unsigned(ghostaddrx2))) = '0'
				then RGB <= "000000";
			end if;
		elsif(wall_here = '0' and draw_ghost3 = '1') then 
			if ghostdisplay3(21 - to_integer(unsigned(ghostaddrx3))) = '1'
				then RGB <= "111000";	
			elsif ghostdisplay3(21 - to_integer(unsigned(ghostaddrx3))) = '0'
				then RGB <= "000000";
			end if;
		elsif (wall_here = '1') then RGB <= "000011";
		--draw pacman
		elsif (wall_here = '0' and draw_pacman = '1') then 
			if (direction = "01") then -- causing issues
					if pacdisplay( to_integer(unsigned(pacaddrx)) ) = '1' 
						then RGB <= "111100";
					elsif pacdisplay( to_integer(unsigned(pacaddrx)) ) = '0' 
						then RGB <= "000000";
					end if;
			elsif (direction = "00") then --causing issues
				if pacdisplay(21 - to_integer(unsigned(pacaddrx))) = '1'
					then RGB <= "111100";	
				elsif pacdisplay(21 - to_integer(unsigned(pacaddrx))) = '0'
					then RGB <= "000000";
				end if;
			elsif (direction = "10" or direction = "11") then 
				if pacdisplay(21 - to_integer(unsigned(pacaddrx))) = '1'
					then RGB <= "111100";	
				elsif pacdisplay(21 - to_integer(unsigned(pacaddrx))) = '0'
					then RGB <= "000000";
				end if;
			end if;
		elsif ((wall_here = '0') and (((column >= 14 and column < 17)) -- and (display_colors(19) = '0'))
		 or
		 ((column > 45 and column < 49)) --and (display_colors(18) = '0'))
		 or
		 ((column > 77 and column < 81)) -- and (display_colors(17) = '0'))
		 or
		 ((column > 109 and column < 113)) -- and (display_colors(16) = '0'))
		 or
		 ((column > 141 and column < 145)) -- and (display_colors(15) = '0'))
		 or
		 ((column > 173 and column < 177)) -- and (display_colors(14) = '0'))
		 or
		 ((column > 205 and column < 209)) -- and (display_colors(13) = '0'))
		 or
		 ((column > 237 and column < 241)) -- and (display_colors(12) = '0'))
		 or
		 ((column > 269 and column < 273)) -- and (display_colors(11) = '0'))
		 or
		 ((column > 301 and column < 305)) -- and (display_colors(10) = '0'))
		 or
		 ((column > 333 and column < 337)) -- and (display_colors(9) = '0'))
		 or
		 ((column > 365 and column < 369)) -- and (display_colors(8) = '0'))
		 or
		 ((column > 397 and column < 401)) -- and (display_colors(7) = '0'))
		 or
		 ((column > 429 and column < 433))-- and (display_colors(6) = '0'))
		 or
		 ((column > 461 and column < 465)) -- and (display_colors(5) = '0'))
		 or
		 ((column > 493 and column < 497)) -- and (display_colors(4) = '0'))
		 or
		 ((column > 525 and column < 529)) -- and (display_colors(3) = '0'))
		 or
		 ((column > 557 and column < 561)) -- and (display_colors(2) = '0'))
		 or
		 ((column > 589 and column < 593)) -- and (display_colors(1) = '0'))
		 or
		 ((column > 621 and column < 625)) -- and (display_colors(0) = '0'))
		 )
		 and
		 (                  
		 (row >= 14 and row < 17)
		 or
		 (row > 45 and row < 49)
		 or
		 (row > 77 and row < 81)
		 or
		 (row > 109 and row < 113)
		 or
		 (row > 141 and row < 145)
		 or
		 (row > 173 and row < 177)
		 or
		 (row> 205 and row < 209)
		 or
		 (row > 237 and row < 241)
		 or
		 (row > 269 and row < 273)
		 or
		 (row > 301 and row < 305)
		 or
		 (row > 333 and row < 337)
		 or
		 (row > 365 and row < 369)
		 or
		 (row > 397 and row < 401)
		 or
		 (row > 429 and row < 433)
		 )) then 
				RGB <= "111111";
		else RGB <= "000000";
		--end if;
	end if;
			
		--draw map
	if ( (
		 ((pacy <= ghosty + 32 and pacy >= ghosty)
		 or 
		 (pacy + 32 >= ghosty and pacy + 32 <= ghosty + 32)
		 ) and (
		 (pacx <= ghostx + 20 and pacx >= ghostx - 2)
		 or
		 (pacx + 20 >= ghostx and pacx <= ghostx) )
		 )
		 or
		 (
		 ((pacy <= ghosty2 + 32 and pacy >= ghosty2)
		 or 
		 (pacy + 32 >= ghosty2 and pacy + 32 <= ghosty2 + 32)
		 ) and (
		 (pacx <= ghostx2 + 32 and pacx >= ghostx2)
		 or
		 (pacx + 20 >= ghostx2 and pacx <= ghostx2)) 
		 )
		 or
		 (
		 ((pacy <= ghosty3 + 32 and pacy >= ghosty3)
		 or 
		 (pacy + 32 >= ghosty3 and pacy + 32 <= ghosty3 + 32)
		 ) and (
		 (pacx <= ghostx3 + 20 and pacx >= ghostx3)
		 or
		 (pacx + 20 >= ghostx3 and pacx <= ghostx3)) 
		 )
		) then 
			game_state <= dead;
	elsif (
		 ((pacy <= appley + 32 and pacy >= appley)
		 or 
		 (pacy + 32 >= appley and pacy + 32 <= appley + 32)
		 ) and (
		 (pacx <= applex + 20 and pacx >= applex)
		 or
		 (pacx + 20 >= applex and pacx <= applex)) 
		 ) then 
			game_state <= win;
	end if;
	when dead =>
		if (gameoverscreen /= "001000") then 
				RGB <= unsigned(gameoverscreen);
		end if;
		if (select_button = '0') then game_state <= alive;
		end if;
	when win =>
		if (winscreen /= "001000") then 
				RGB <= unsigned(winscreen);
		end if;
		if (select_button = '0') then game_state <= alive;
		end if;
	end case;

end if;
end process;
row_addr <= row(8 downto 5); 
end;
