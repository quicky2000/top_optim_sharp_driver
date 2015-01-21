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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity driver_compare is
  Port ( clk : in  STD_LOGIC;
         rst : in  STD_LOGIC);
end driver_compare;

architecture Behavioral of driver_compare is
  -- Signals for reference driver
  signal reference_vsync : std_logic ;
  signal reference_hsync : std_logic ;
  signal reference_enable : std_logic ;
  signal reference_x_out : std_logic_vector ( 9 downto 0);
  signal reference_y_out : std_logic_vector ( 8 downto 0);

  -- Signals for new driver
  signal new_vsync : std_logic ;
  signal new_hsync : std_logic ;
  signal new_enable : std_logic ;
  signal new_x_out : std_logic_vector ( 9 downto 0);
  signal new_y_out : std_logic_vector ( 8 downto 0);

begin
  Inst_reference_driver_sharp : entity work.driver_sharp(v1_0) PORT MAP(
    clk => clk,
    rst => rst,
    vsync => reference_vsync,
    hsync => reference_hsync,
    enable => reference_enable,
    x_out => reference_x_out,
    y_out => reference_y_out
    );
  
  Inst_new_driver_sharp : entity work.driver_sharp(v1_4) PORT MAP(
    clk => clk,
    rst => rst,
    vsync => new_vsync,
    hsync => new_hsync,
    enable => new_enable,
    x_out => new_x_out,
    y_out => new_y_out
    );
    
end Behavioral;

