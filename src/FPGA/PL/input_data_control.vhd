----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2024/11/06 21:16:28
-- Design Name: 
-- Module Name: input_data_control - Behavioral
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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity input_data_control is
    
    generic(
        WIDTH : integer := 32;
	    DEPTH : integer := 25;
	    depth_num_max : integer := 50
    );
    port (clk : in std_logic;
          srst : in std_logic;
          din_input_data_control : in std_logic_vector(WIDTH-1 downto 0);--fifo    o ?   input_data_control ?   M  
          start_input_data_control : in std_logic;    --input_data_control   f [ ^        ??
          end_input_data_control : out std_logic;
          dout_input_data_control : out std_logic_vector(WIDTH * DEPTH -1 downto 0)   -- ??   ? f [ ^
    );
    
end input_data_control;

architecture Behavioral of input_data_control is
    signal connecting_data : std_logic_vector(WIDTH * DEPTH -1 downto 0) := (others => '0');
    signal depth_num : integer range 0 to depth_num_max;
    signal full_input_data_control : std_logic;
    signal end_input_data_control_inside : std_logic;
    
begin
    end_input_data_control <= end_input_data_control_inside;
    
    process (clk) begin
        if(rising_edge(clk))then
            if (srst = '1') then
                connecting_data <= (others => '0');
                dout_input_data_control <= (others => '0');
                full_input_data_control <= '0';
                depth_num <= 0;
                end_input_data_control_inside <= '0';
            else
                --end_input_data_control    Z b g       ,  S ?         ?  ? 1 ??       
                if(end_input_data_control_inside = '1') then
                    end_input_data_control_inside <= '0'; 
                --input_data_control     ^   ??  B
                elsif(full_input_data_control = '1') then
                        dout_input_data_control <= connecting_data;
                        full_input_data_control <= '0';
                        end_input_data_control_inside <= '1';
                -- ? ?O ?     ?Y  
                elsif (start_input_data_control = '1') then
                    --depth_num ???   connecting_data ?i [
                    connecting_data (depth_num * WIDTH + WIDTH - 1 downto depth_num * WIDTH + 0) <= din_input_data_control(WIDTH - 1 downto 0);
                    
                    if (depth_num = depth_num_max - 1) then
                        depth_num <= 0;
                        full_input_data_control <= '1';
                        
                    
                            
                    else
                        depth_num <= depth_num + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
