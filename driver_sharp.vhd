--
--    This file is part of top_optim_sharp_driver
--    Copyright (C) 2011  Julien Thevenon ( julien_thevenon at yahoo.fr )
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity driver_sharp is
  port (
    clk : in std_logic;                -- Clock input
    rst : in std_logic;                -- Reset input
    -- Signals to drive the screen
    vsync : out std_logic;
    hsync : out std_logic;
    enable : out std_logic;
    -- Signals to communicate with block giving color
    x_out : out std_logic_vector ( 9 downto 0);
    y_out : out std_logic_vector ( 8 downto 0)
    );
end driver_sharp;

architecture v1_0 of driver_sharp is
  constant THd : positive := 640;     -- Width of display
  constant TVd : positive := 480;     -- Height of display
  constant TH : positive := 800;      -- Horizontal sync signal cycle width in clock cycle
  constant THp : positive := 96;      -- Horizontal sync signal pulse width in clock cyle
  constant TVs : positive := 34;      -- Vertical start period in clock cycle
  constant TV : positive := 525;      -- Vertical sync signal period in clock cycle
begin  -- behavorial

  process(clk,rst)
    variable x_counter : positive range 1 to TH := 1;       -- counter for x axis
    variable y_counter : positive range 1 to TV := 1;       -- counter for y axis
    variable x : natural range 0 to THd := 0;         -- x coordinate of active pixel
    variable y : natural range 0 to TVd := 0;         -- x coordinate of active pixel
  begin
    if rst = '1' then
      x_counter := 1;
      y_counter := 1;
      vsync <= '0';
      hsync <= '0';
      enable <= '0';
      x_out <= (others => '0');
      y_out <= (others => '0');
      x := 0;
      y := 0;
    elsif rising_edge(clk) then 
      if y_counter < 2 then
        vsync <= '0';
      else
        vsync <= '1';
      end if;
      if x_counter < TH then        
        x_counter := x_counter + 1;
      else
        x_counter := 1;
        if y_counter <  TV then
          y_counter := y_counter + 1;
        else
          y_counter := 1;
          y := 0;
          y_out <= (others => '0');
        end if;
        if y_counter > TVs and y < TVd then 
          y_out <= std_logic_vector(to_unsigned(y,9));
          y := y +1;
        end if;
      end if;

      if x_counter <= THp then
        hsync <= '0';
        x := 0;
        x_out <= (others => '0');
      else
        hsync <= '1';
        if x < THd and y_counter > TVs and y_counter <= TVd + TVs then
          x_out <= std_logic_vector(to_unsigned(x,10));
          x := x + 1;
          enable <= '1';
        else
          enable <= '0';
          x_out <= (others => '0');
        end if;
      end if;
    end if;
  end process;

end v1_0;

architecture v1_1 of driver_sharp is
  -- Constants defined by specification 
  constant THd : positive := 640;     -- Width of display
  constant TVd : positive := 480;     -- Height of display
  constant TH : positive := 799;      -- Horizontal sync signal cycle width in clock cycle
  constant TV : positive := 524;      -- Vertical sync signal period in clock cycle
  constant THp : positive := 95;      -- Horizontal sync signal pulse width in clock cyle
  constant TVp : positive := 1;      -- Vertical sync signal pulse width in hsync cyle
  constant TVs : positive := 34;      -- Vertical start period in clock cycle
  -- Internal signals
  signal x_counter : std_logic_vector( 9 downto 0) := (others => '0');       -- counter for x axis
  signal y_counter : std_logic_vector( 9 downto 0) := (others => '0');       -- counter for x axis

  signal x : std_logic_vector( 9 downto 0) := (others => '0');
  signal y : std_logic_vector( 8 downto 0) := (others => '0');
  -- FSM for hsync
  type hsync_state_type is (low,high);
  signal hsync_state : hsync_state_type := low;
  signal hsync_next_state : hsync_state_type := low ;
  -- FSM for vsync
  type vsync_state_type is (low,high,ready_to_low);
  signal vsync_state : vsync_state_type := low;
  signal vsync_next_state : vsync_state_type := low ;

  signal ycounter_next : std_logic_vector (9 downto 0):= (others => '0');

  -- FSM for enable
  type line_state_type is (virtual,real);                      -- State indicating if we are in non real lines or real lines
  signal line_state : line_state_type := virtual;  -- State of line
  signal line_next_state : line_state_type := virtual;  -- State of line

  type enable_state_type is (active,inactive,done);
  signal enable_state : enable_state_type := inactive;
  signal enable_next_state : enable_state_type := inactive;

  -- FSM for y
  type y_state_type is (active,inactive,done,ready,ready_to_reset);
  signal y_state : y_state_type := inactive;
  signal y_next_state : y_state_type := inactive;
  
begin  -- behavorial

  x_counter_process: process(clk,rst)
  begin
    if rising_edge(clk) then 
      if rst = '1' or unsigned(x_counter) = TH then
        x_counter <= (others => '0');
      else
        x_counter <= std_logic_vector(unsigned(x_counter) + 1);
      end if;
    end if;
  end process;

  
  -- ycounter state register process
  ycounter_state_register_process : process(clk,rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        y_counter <= (others => '0');
      elsif unsigned(x_counter) = TH then
        y_counter <= ycounter_next;
      else
        y_counter <= y_counter;
      end if;
    end if;
  end process;

  --ycounter state transition
  y_counter_state_transition_process : process(y_counter)
  begin
    if unsigned(y_counter) = TV then 
      ycounter_next <= (others => '0');
    else
      ycounter_next <= std_logic_vector(unsigned(y_counter) + 1);
    end if;
  end process;

  --hsync state register
  hsync_state_register_process : process(clk,rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        hsync_state <= low;
      else
        hsync_state <= hsync_next_state;
      end if;
    end if;
  end process;
  
  --hsync state transition
  hsync_state_transition_process : process(hsync_state,x_counter)
  begin
    case hsync_state is
      when low => if unsigned(x_counter) = THp then
                    hsync_next_state <= high;
                  else
                    hsync_next_state <= low ;
                  end if;
      when high => if unsigned(x_counter) = TH then
                     hsync_next_state <= low;
                   else
                     hsync_next_state <= high;
                   end if;
      when others => hsync_next_state <= low ;
    end case;
  end process;
  
  --hsync output function
  hsync <= '1' when hsync_state = high else '0';
  
  --vsync state register
  vsync_state_register_process : process(clk,rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        vsync_state <= low;
      else
        vsync_state <= vsync_next_state;
      end if;
    end if;
  end process;
  
  --vsync state transition
  vsync_state_transition_process : process(vsync_state,y_counter,x_counter)
  begin
    case vsync_state is
      when low => if unsigned(y_counter) = TVp then
                    vsync_next_state <= high;
                  else
                    vsync_next_state <= low ;
                  end if;
      when high => if unsigned(y_counter) = TV then
                     vsync_next_state <= ready_to_low;
                   else
                     vsync_next_state <= high;
                   end if;
      when ready_to_low => if unsigned(x_counter) = TH then
                             vsync_next_state <= low;
                           else
                             vsync_next_state <= ready_to_low;
                           end if;
      when others => vsync_next_state <= low ;
    end case;
  end process;
  
  --vsync output function
  vsync <= '0' when vsync_state = low else '1';

  -- Process managing line state 
  line_state_register_process: process(clk,rst)
  begin
    if rising_edge(clk) then 
      if rst = '1' then
        line_state <= virtual;
      else
        line_state <= line_next_state;
      end if;
    end if;
  end process;

  --line_state transition
  line_state_transition_process : process(line_state,y_counter)
  begin
    case line_state is
      when virtual => if unsigned(y_counter) = TVs then
                        line_next_state <= real;
                      else
                        line_next_state <= virtual ;
                      end if;
      when real => if unsigned(y_counter) = (TVd + TVs) then
                     line_next_state <= virtual;
                   else
                     line_next_state <= real;
                   end if;
      when others => line_next_state <= virtual;
    end case;
  end process;
  
  -- enable process management
  enable_state_register_process: process(clk,rst)
  begin
    if rising_edge(clk) then 
      if rst = '1' then
        enable_state <= inactive;
      else
        enable_state <= enable_next_state;
      end if;
    end if;
  end process;

  --enable_state transition
  enable_state_transition_process : process(enable_state,hsync_next_state,x,line_state)
  begin
    case enable_state is
      when inactive => if hsync_next_state = high and line_state = real then
                         enable_next_state <= active;
                       else
                         enable_next_state <= inactive ;
                       end if;
      when active => if unsigned(x) = (THd -1) then
                       enable_next_state <= done;
                     else
                       enable_next_state <= active;
                     end if;
      when done => if hsync_next_state = low then
                     enable_next_state <= inactive;
                   else
                     enable_next_state <= done;
                   end if;
      when others => enable_next_state <= inactive;
    end case;
  end process;

  enable <= '1' when enable_state = active else '0';

  x_out_process : process(clk,rst)
  begin
    if rising_edge(clk) then
      if rst = '1' or unsigned(x) = (THd -1) then
        x <= (others => '0');
      elsif enable_state = active then
        x <= std_logic_vector(unsigned(x) + 1);
      else
        x <= x;
      end if;
    end if;
  end process;

  y_out_process : process(clk,rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        y_state <= inactive;
      else
        y_state <= y_next_state;
      end if;
    end if;
  end process;

  --y state transition
  process(y_state,y_counter,hsync_state,hsync_next_state,vsync_state)
  begin
    case y_state is
      when inactive => if unsigned(y_counter) = TVs then
                         y_next_state <= ready;
                       else
                         y_next_state <= inactive ;
                       end if;
      when active => if hsync_state = low then
                       y_next_state <= done;
                       y <= std_logic_vector(unsigned(y) + 1);
                     else
                       y <= y;
                       y_next_state <= active;
                     end if;
      when done => if unsigned(y) = (TVd - 1) then
                     y_next_state <= ready_to_reset;
                   else
                     y_next_state <= ready;
                     y <= y;
                   end if;
      when ready_to_reset => if vsync_state = low then
                               y_next_state <= inactive;
                               y <= (others => '0');
                             else
                               y_next_state <= ready_to_reset;
                               y <= y;
                             end if;
      when ready => if  hsync_next_state = high then
                      y_next_state <= active;
                    else
                      y_next_state <= ready;
                    end if;
      when others => y_next_state <= inactive ;
    end case;
  end process;
  
  x_out <= x;
  y_out <= y;
  
end v1_1;

architecture v1_2 of driver_sharp is
  -- Constants defined by specification 
  constant THd : positive := 640;     -- Width of display
  constant TVd : positive := 480;     -- Height of display
  constant TH : positive := 799;      -- Horizontal sync signal cycle width in clock cycle
  constant TV : positive := 524;      -- Vertical sync signal period in clock cycle
  constant THp : positive := 95;      -- Horizontal sync signal pulse width in clock cyle
  constant TVp : positive := 1;      -- Vertical sync signal pulse width in hsync cyle
  constant TVs : positive := 34;      -- Vertical start period in clock cycle

  -- Constants for internal use
  constant x_counter_low : positive :=  1024 - THp ;
  constant x_counter_low_start : positive := x_counter_low + 1;
  constant x_counter_high : positive :=  1024 - (TH - THp) + 1;
  constant y_counter_low : positive :=  1024 - TVp;
  constant y_counter_high : positive :=  1024 - (TV - TVp) + 1;
  -- Internal signals 
  signal x_counter: std_logic_vector( 10 downto 0) := std_logic_vector(to_unsigned(x_counter_low_start,11));       -- counter for x axis
  signal x_counter_init: std_logic_vector( 10 downto 0) := std_logic_vector(to_unsigned(x_counter_high,11));       -- counter for x axis
  signal hsyncP : std_logic := '0';
  signal hsyncN : std_logic := '1';
  
  signal y_counterP: std_logic_vector( 10 downto 0) := std_logic_vector(to_unsigned(y_counter_low,11));       -- counter for x axis
  signal y_counter_init: std_logic_vector( 10 downto 0) := std_logic_vector(to_unsigned(y_counter_high,11));       -- counter for x axis

  -- FSM for vsync
  type vsync_state_type is (low,after_low,high,ready_to_low,before_low);
  signal vsyncP : vsync_state_type := low;
  signal vsyncN : vsync_state_type := low ;

  -- counter to determine if line is active or not
  constant line_counter_low_start : positive :=  512 - TVs;
  constant line_counter_low : positive :=  512 - (TV - TVd);
  constant line_counter_high : positive :=  512 - TVd + 1;
  signal line_counter : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(line_counter_low_start,10));
  signal line_counter_init : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(line_counter_low_start,10));
  type line_state_type is(virtual,first_real,real,after_real);
  signal line_stateP : line_state_type := virtual;
  signal line_stateN : line_state_type := virtual;
begin  -- behavorial

  -- Process managing outputs
  output_management : process(clk,rst)
  begin
    if rst = '1' then
--			vsync <= '0';
      hsync <= '0';
      enable <= '0';
      x_out <= (others => '0');
      y_out <= (others => '0');
    elsif rising_edge(clk) then
--			vsync <= vsyncP;
      hsync <= hsyncP;
--			enable <= enableP;
--			x_out <= x_outP;
--			y_out <= x_outP;
    end if;
  end process;

  -- process managing xcounter increment
  xcounter_increment : process(clk,rst)
  begin
    if rst = '1' then
      x_counter <= std_logic_vector(to_unsigned(x_counter_low_start,11));
      hsyncP <= '0';
    elsif rising_edge(clk) then
      if x_counter(10) = '1' then
        x_counter <= x_counter_init;
        hsyncP <= hsyncN;
      else
        x_counter <= std_logic_vector(unsigned(x_counter)+1);
      end if;
    end if;
  end process;

  -- process preparing next hsync_value
  prepare_next_hsync : process(hsyncP)
  begin
    case hsyncP is
      when '0' => hsyncN <= '1';
      when '1' => hsyncN <= '0';
      when others => hsyncN <= '0';
    end case;
  end process;

  -- process computing next x_counter_init
  prepare_next_counter_init : process (hsyncP)
  begin
    case hsyncP is
      when '0' => x_counter_init <= std_logic_vector(to_unsigned(x_counter_high,11));
      when '1' => x_counter_init <= std_logic_vector(to_unsigned(x_counter_low,11));
      when others => x_counter_init <= std_logic_vector(to_unsigned(x_counter_high,11));
    end case;
  end process;	

  -- process managing ycounter increment
  ycounter_increment : process(clk,rst)
  begin
    if rst = '1' then
      y_counterP <= std_logic_vector(to_unsigned(y_counter_low,11));
    elsif rising_edge(clk) then
      if x_counter(10) = '1' and hsyncP = '1' then
        if y_counterP(10) = '1' then 
          y_counterP <= y_counter_init;
        else
          y_counterP <= std_logic_vector(unsigned(y_counterP) + 1);
        end if;
      else
        y_counterP <= y_counterP;
      end if;
    end if;
  end process;

  -- prepare the init value for ycounter
  prepare_ycounter_init : process(vsyncP)
  begin
    case vsyncP is
      when low => y_counter_init <= std_logic_vector(to_unsigned(y_counter_high,11));
      when after_low => y_counter_init <= std_logic_vector(to_unsigned(y_counter_high,11));
      when high => y_counter_init <= std_logic_vector(to_unsigned(y_counter_low,11));
      when ready_to_low => y_counter_init <= std_logic_vector(to_unsigned(y_counter_low,11));
      when others => y_counter_init <= std_logic_vector(to_unsigned(y_counter_high,11));
    end case;
  end process;

  --vsync state register
  vsync_state_register_process : process(clk,rst)
  begin
    if rst = '1' then
      vsyncP <= low;
    elsif rising_edge(clk) then
      vsyncP <= vsyncN;
    end if;
  end process;
  
  --vsync state transition
  vsync_state_transition_process : process(vsyncP,hsyncP,y_counterP,x_counter)
  begin
    case vsyncP is
      when low => if y_counterP(10) = '1' then
                    vsyncN <= after_low;
                  else
                    vsyncN <= low ;
                  end if;
      when after_low => if y_counterP(10) = '1' then
                          vsyncN <= after_low;
                        else
                          vsyncN <= high ;
                        end if;
      when high => if y_counterP(10) = '1' and vsyncP = high then
                     vsyncN <= ready_to_low;
                   else
                     vsyncN <= high;
                   end if;
      when ready_to_low => if x_counter(10) = '1' and hsyncP = '1' then
                             vsyncN <= before_low;
                           else
                             vsyncN <= ready_to_low;
                           end if;
      when before_low => vsyncN <= low;
      when others => vsyncN <= low ;
    end case;
  end process;
  
  --vsync output function
  apply_vsync : vsync <= '0' when vsyncP = low else '1';

  -- Process managing line state 
  line_state_register: process(clk,rst)
  begin
    if rst = '1' then
      line_stateP <= virtual;
    elsif rising_edge(clk) then
      line_stateP <= line_stateN;
    end if;
  end process;

  --line_state transition
  line_state_transition : process(line_stateP,line_counter(9))
  begin
    case line_stateP is
      when virtual => if line_counter(9) = '1' then
                        line_stateN <= first_real ;
                      else
                        line_stateN <= virtual;
                      end if;
      when first_real => if line_counter(9) = '0' then
                           line_stateN <= real;
                         else
                           line_stateN <= first_real;
                         end if;
      when real => if line_counter(9) = '1' then
                     line_stateN <= after_real;
                   else
                     line_stateN <= real;
                   end if;
      when after_real => if line_counter(9) = '0' then
                           line_stateN <= virtual;
                         else
                           line_stateN <= after_real;
                         end if;
      when others => line_stateN <= virtual;
    end case;
  end process;
  
  -- line counter increment
  line_couter_increment : process(clk,rst)
  begin
    if rst = '1' then
      line_counter <= std_logic_vector(to_unsigned(line_counter_low_start,10));
    elsif rising_edge(clk) then
      if x_counter(10) = '1' and hsyncP = '1' then
        if line_counter(9) = '1' then 
          line_counter <= line_counter_init;
        else
          line_counter <= std_logic_vector(unsigned(line_counter) + 1);
        end if;
      end if;
    end if;
  end process;

  prepare_line_counter_init : process(line_stateP)
  begin
    case line_stateP is
      when virtual => line_counter_init <= std_logic_vector(to_unsigned(line_counter_high,10));
      when first_real => line_counter_init <= std_logic_vector(to_unsigned(line_counter_high,10));
      when real => line_counter_init <= std_logic_vector(to_unsigned(line_counter_low,10));
      when after_real => line_counter_init <= std_logic_vector(to_unsigned(line_counter_low,10));
      when others => line_counter_init <= std_logic_vector(to_unsigned(line_counter_high,10));
    end case;
  end process;
  
end v1_2;

architecture v1_3 of driver_sharp is
  -- Constants defined by specification 
  constant THd : positive := 640;     -- Width of display
  constant TVd : positive := 480;     -- Height of display
  constant TH : positive := 799;      -- Horizontal sync signal cycle width in clock cycle
  constant TV : positive := 524;      -- Vertical sync signal period in clock cycle
  constant THp : positive := 95;      -- Horizontal sync signal pulse width in clock cyle
  constant TVp : positive := 1;      -- Vertical sync signal pulse width in hsync cyle
  constant TVs : positive := 34;      -- Vertical start period in clock cycle

  -- Constants for internal use
  -- X axis
  constant x_counter_low : positive :=  1024 - THp ;
  constant x_counter_low_start : positive := x_counter_low+1;
--  constant x_counter_low_start : positive := x_counter_low;
  constant x_counter_valid : positive :=  1024 - THd + 1;
  constant x_counter_fill : positive :=  1024 - (TH - THp - THd) + 1;
  -- Y axis
  constant y_counter_low : positive :=  512 - TVp + 1;
  constant y_counter_low_start : positive :=  y_counter_low;
  constant y_counter_pre_fill : positive :=  512 - (TVs - TVp) + 1;
  constant y_counter_valid : positive :=  512 - TVd + 1;
  constant y_counter_post_fill : positive := 512 - (TV - TVp - TVs - TVd + 1) ;

  -- Internal signals related to X axis
  signal x_counter: std_logic_vector( 10 downto 0) := std_logic_vector(to_unsigned(x_counter_low_start,11));       -- counter for x axis
  signal x_counter_init: std_logic_vector( 10 downto 0) := (others => '0');
  signal hsyncP : std_logic := '0';
  signal enableP : std_logic := '0';
  type x_fsm_state_type is (x_low,x_valid,x_fill);
  signal x_fsm_stateP : x_fsm_state_type := x_low;
  signal x_fsm_stateN : x_fsm_state_type := x_valid;
  signal x : std_logic_vector(9 downto 0) := (others => '0');
  
  -- Internal signals related to Y axis
  signal y_counter: std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(y_counter_low_start,10));       -- counter for x axis
  signal y_counter_init: std_logic_vector(9 downto 0) := (others => '0');
  signal vsyncP : std_logic := '0';
  type y_fsm_state_type is (y_low,y_pre_fill,y_valid,y_post_fill);
  signal y_fsm_stateP : y_fsm_state_type;
  signal y_fsm_stateN : y_fsm_state_type;
  signal y : std_logic_vector(8 downto 0) := (others => '0');
begin  -- behavorial

  -- Process managing outputs
  output_management : process(clk,rst)
  begin
    if rst = '1' then
      hsync <= '0';
      vsync <= '0';
      enable <= '0';
      x_out <= (others => '0');
      y_out <= (others => '0');
    elsif rising_edge(clk) then
      vsync <= vsyncP;
      hsync <= hsyncP;
      enable <= enableP;
      x_out <= x;
      y_out <= y;
    end if;
  end process;

  -- process managing x_counter increment
  x_counter_increment : process(clk,rst)
  begin
    if rst = '1' then
      x_counter <= std_logic_vector(to_unsigned(x_counter_low_start,11));
    elsif rising_edge(clk) then
      if x_counter(10) = '1' then
        x_counter <= x_counter_init;
      else
        x_counter <= std_logic_vector(unsigned(x_counter)+1);
      end if;
    end if;
  end process;

  -- process computing x_counter_init
  prepare_x_counter_init : process (x_fsm_stateP)
  begin
    case x_fsm_stateP is
      when x_low => x_counter_init <= std_logic_vector(to_unsigned(x_counter_valid,11));
      when x_valid => x_counter_init <= std_logic_vector(to_unsigned(x_counter_fill,11));
      when x_fill => x_counter_init <= std_logic_vector(to_unsigned(x_counter_low,11));
      when others => x_counter_init <= (others => '0');
    end case;
  end process;	

  -- process computing next x_fsm_state
  prepare_next_x_fsm_state : process (x_fsm_stateP)
  begin
    case x_fsm_stateP is
      when x_low => x_fsm_stateN <= x_valid;
      when x_valid => x_fsm_stateN <= x_fill;
      when x_fill => x_fsm_stateN <= x_low;
      when others => x_fsm_stateN <= x_low;
    end case;
  end process;	

  -- process managing x_fsm_state register
  x_fsm_state_register : process(clk,rst)
  begin
    if rst = '1' then
      x_fsm_stateP <= x_low;
    elsif rising_edge(clk) then
      if x_counter(10) = '1' then
        x_fsm_stateP <= x_fsm_stateN;
      else
        x_fsm_stateP <= x_fsm_stateP;
      end if;
    end if;
  end process;

  apply_hsync : hsyncP <= '0' when x_fsm_stateP = x_low else '1';
  
  -- process managing ycounter increment
  ycounter_increment : process(clk,rst)
  begin
    if rst = '1' then
      y_counter <= std_logic_vector(to_unsigned(y_counter_low_start,10));
    elsif rising_edge(clk) then
      if x_counter(10) = '1' and x_fsm_stateP = x_fill then
        if y_counter(9) = '1' then 
          y_counter <= y_counter_init;
        else
          y_counter <= std_logic_vector(unsigned(y_counter) + 1);
        end if;
      else
        y_counter <= y_counter;
      end if;

    end if;
  end process;

  -- prepare the init value for ycounter
  prepare_ycounter_init : process(y_fsm_stateP)
  begin
    case y_fsm_stateP is
      when y_low => y_counter_init <= std_logic_vector(to_unsigned(y_counter_pre_fill,10));
      when y_pre_fill => y_counter_init <= std_logic_vector(to_unsigned(y_counter_valid,10));
      when y_valid => y_counter_init <= std_logic_vector(to_unsigned(y_counter_post_fill,10));
      when y_post_fill => y_counter_init <= std_logic_vector(to_unsigned(y_counter_low,10));
      when others => y_counter_init <= std_logic_vector(to_unsigned(y_counter_low,10));
    end case;
  end process;

  -- process computing next y_fsm_state
  vsync_state_transition_process : process(y_fsm_stateP)
  begin
    case y_fsm_stateP is
      when y_low => y_fsm_stateN <= y_pre_fill;
      when y_pre_fill => y_fsm_stateN <= y_valid;
      when y_valid => y_fsm_stateN <= y_post_fill;
      when y_post_fill => y_fsm_stateN <= y_low;
      when others => y_fsm_stateN <= y_low;
    end case;
  end process;
  
  -- process managing y_fsm_state_register
  y_fsm_state_register : process(clk,rst)
  begin
    if rst = '1' then
      y_fsm_stateP <= y_low;
    elsif rising_edge(clk) then
      if y_counter(9) = '1' and x_counter(10) = '1' and x_fsm_stateP = x_fill then 
        y_fsm_stateP <= y_fsm_stateN;
      else
        y_fsm_stateP <= y_fsm_stateP;
      end if;
    end if;
  end process;
  
--vsync output function
  apply_vsync : vsyncP <= '0' when y_fsm_stateP = y_low else '1';

-- enable output function
  apply_enable : enableP <= '1' when y_fsm_stateP = y_valid and x_fsm_stateP = x_valid else '0';

  --process managing x increment
  x_increment : process(clk,rst)
  begin
    if rst = '1' then
      x <= (others => '0');
    elsif rising_edge(clk) then
      if x_fsm_stateP = x_valid and y_fsm_statep = y_valid then
        if x_counter(10) = '0' then
          x <= std_logic_vector(unsigned(x) + 1);
        else
          x <= (others => '0');
        end if;
      else
        x <= x;
      end if;
    end if;
  end process;
  
  -- process managing y increment
  y_increment : process(clk,rst)
  begin
    if rst = '1' then
      y <= (others => '0');
    elsif rising_edge(clk) then
      if y_fsm_stateP = y_valid  and x_fsm_stateP = x_fill then
        if x_counter(10) = '1'then
          if y_counter(9) = '0' then
            y <= std_logic_vector(unsigned(y) + 1);
          else
            y <= (others => '0');
          end if;
        end if;
      else
        y <= y;
      end if;
    end if;
  end process;

end v1_3;

