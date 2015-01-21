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

entity top_optim_sharp_driver is
  Port ( clk : in  STD_LOGIC;
         w1a : inout  STD_LOGIC_VECTOR (15 downto 0);
         w1b : inout  STD_LOGIC_VECTOR (15 downto 0));
end top_optim_sharp_driver;

architecture Behavioral of top_optim_sharp_driver is
  signal vsync : std_logic;
  signal hsync : std_logic;
  signal enable : std_logic;
  -- Signals to communicate with block giving color
  signal x_out : std_logic_vector ( 9 downto 0);
  signal y_out : std_logic_vector ( 8 downto 0);
  signal reset : std_logic;
begin

--Number of Slices : 71
--Number of Slice Flip Flops: 61
--Number of 4 input LUTs: 128
--Number of bonded IOBs: 23
--Clock : 92.524Mhz
--inst_optim_screen_driver : entity work.driver_sharp(v1_0)



--Number of Slices: 52
--Number of Slice Flip Flops: 48
--Number of 4 input LUTs: 97
--Number of bonded IOBs: 23
-- Clock : 181.455Mhz
--inst_optim_screen_driver : entity work.driver_sharp(v1_1)



--Number of Slices: 16
--Number of Slice Flip Flops: 27
--Number of 4 input LUTs: 29
--Number of bonded IOBs: 23
-- Clock 224.517 Mhz
--inst_optim_screen_driver : entity work.driver_sharp(v1_2)



--Number of Slices: 38
--Number of Slice Flip Flops: 69
--Number of 4 input LUTs: 49
--Number of bonded IOBs: 23
-- Clock : 221.141Mhz
inst_optim_screen_driver : entity work.driver_sharp(v1_3)
    port map(
      clk => clk,
      rst => reset,
      vsync => vsync,
      hsync => hsync,
      enable => enable,
      x_out => x_out,
      y_out => y_out);
  
  w1a(0) <= vsync;
  w1a(1) <= hsync;
  w1a(2) <= enable;
  w1a(12 downto 3) <= x_out(9 downto 0);
  w1b(8 downto 0) <= y_out(8 downto 0);
  
  reset <= '0';
end Behavioral;

