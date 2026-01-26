----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/11/07 22:15:36
-- Design Name: 
-- Module Name: output_data_control - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity output_data_control is
    generic(
        WIDTH : integer := 32;
	    DEPTH : integer := 256;
	    depth_num_max : integer := 256
    );
    port (clk : in std_logic;
          srst : in std_logic;
          din_output_data_control : in std_logic_vector(WIDTH * DEPTH-1 downto 0);
          dout_output_data_control : out std_logic_vector(WIDTH - 1 downto 0);
          start_output_data_control : in std_logic;
          end_output_data_control : out std_logic;
          flag_output : out std_logic
          );
          
end output_data_control;

architecture Behavioral of output_data_control is
    
    signal first : std_logic;
    signal dividing_data : std_logic_vector(WIDTH * DEPTH -1 downto 0);
    signal divided_data : std_logic_vector(WIDTH - 1 downto 0);
    signal end_output_data_control_inside : std_logic;
    signal flag_output_inside : std_logic;
    signal depth_num : integer range 0 to depth_num_max;
    
    --start_output_data_control  1 ??     ??    ?         ? ?d l ?X   ? ??   M  
    signal start_inside : std_logic;
    
begin
    dout_output_data_control <= divided_data;
    end_output_data_control <= end_output_data_control_inside;
    flag_output <= flag_output_inside;
    
    process (clk) begin
        if (rising_edge(CLK))then
            if (srst = '1') then
                first <= '1';
                dividing_data <= (others => '0');
                divided_data <= (others => '0');
                end_output_data_control_inside <= '0';
                flag_output_inside <= '0';
                depth_num <= 0;
            else
                -- start_output_data_control    x P ??       1  o   M   ? 
                if(start_output_data_control = '1') then
                    start_inside <= '1';
                end if;
                --end_output_data_control    Z b g       ,  S ?        ?  ? 1 ??       
                if(end_output_data_control_inside = '1') then
                    end_output_data_control_inside <= '0'; 
                    flag_output_inside <= '0';
                    first <= '1';
                -- ? ?O ?     ?Y  
                -- elsif (start_output_data_control = '1') then
                elsif (start_inside = '1') then
                    -- ?  ??  ? ? 
                    if(first = '1') then
                        dividing_data <= din_output_data_control;
                        first <= '0';
                    else
                        divided_data <= dividing_data(depth_num *WIDTH + WIDTH - 1 downto depth_num *WIDTH + 0);
                        flag_output_inside <= '1';
                        if (depth_num = depth_num_max - 1) then
                            depth_num <= 0;
                            start_inside <= '0';
                            end_output_data_control_inside <= '1';
                        else 
                            depth_num <= depth_num + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
