----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2021/05/28 13:48:58
-- Design Name: 
-- Module Name: fifo - Behavioral
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
use ieee.numeric_std.all;
use IEEE.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo is
    generic (
        WIDTH : integer := 32;
        DEPTH : integer := 256);

    Port ( 
        clk : in std_logic;
	    srst : in std_logic;
	    full : out std_logic;
	    din : in std_logic_vector(WIDTH - 1 downto 0);
	    wr_en : in std_logic;
	    empty : out std_logic;
	    dout : out std_logic_vector(WIDTH - 1 downto 0);
	    rd_en : in std_logic);

end fifo;

architecture Behavioral of fifo is
    

--FIFO ?[   i     256 j   bit ?\     ?     ?? ??   Bceil ?? ƒO ?    ?    ?i  Fceil(3.2)=4 j
constant DEPTH_BIT : integer := integer(ceil(log2(real(DEPTH))));

--    ROM     ??  l i f [ ^  i [    j    , WIDTH bit ?   DEPTH bit   ?   
type ROM is array (0 to DEPTH - 1) of std_logic_vector(WIDTH - 1 downto 0);

--signal fifo:       ?  , fifo ?      O ?M    ?
--"ROM"  "fifo"     ??  f [ ^ ^      ?   .      , fifo  WIDTH bit ?   DEPTH bit   ?   ? ??
--":=" ?M  "fifo" ?    l  ?? ? ??     Z q
--"(others => (others => '0'))" ?  ,        z           ?   
-- ?    others =>  ??O w ?z  ?S v f  w   ?   ,      (others => '0')  ?A   ?   ?z ?  ? "0" ?  ç· ? ?    ?   
signal fifo : ROM := (others => (others => '0'));

--"rptr"  "wptr"  "read pointer"  "write pointer" ?  ?   A       ?A ??  ??  ?   s   ?   DEPTH ?  ??u  w ? ? ?? ?B   ?  ?z  ?v f    DEPTH_BIT bit ?? 
signal rptr : std_logic_vector(DEPTH_BIT - 1 downto 0);
signal wptr : std_logic_vector(DEPTH_BIT - 1 downto 0);

signal full_flag : std_logic;
signal empty_flag : std_logic;

signal almost_full : std_logic;
signal almost_empty : std_logic;

signal dout_reg : std_logic_vector(WIDTH - 1 downto 0);


begin

full <= full_flag;
empty <= empty_flag;

--   O ?? u ?? ?  ^   v ?u ?? ? v B
--almost_full ?Aread pointer  write pointer  1 ? ??u ?   ,    ?      ? read pointer  write pointer ??u       ?? ,     ?         ?   ???   ??   ??      ?  ? . 
--almost_empty ?Awrite pointer  read pointer  1 ? ??u ?   ,    ???  ? read pointer  write pointer ??u       ?? ,     ???     ?  ?  ?     ?  ? . 
almost_full <= '1' when (unsigned(rptr)= (unsigned(wptr) + 1)) else '0';
almost_empty <= '1' when ((unsigned(rptr) + 1)= unsigned(wptr)) else '0';


dout <= dout_reg;


--output
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
        --   Z b g  1 ? A o ? 0 ?? 
            dout_reg <= (others => '0');
        elsif((rd_en = '1') and (empty_flag = '0'))then
        -- ??  ??\    FIFO ?] T      ? Aread pointer ?? fifo ?f [ ^  o ?   
            dout_reg <= fifo(to_integer(unsigned(rptr)));
        else
        --    ?O ?? ?A o ??ƒÖ  ? 
            dout_reg <= dout_reg;
        end if;
    end if;
end process;

--input
process(clk)begin
    if(rising_edge(clk))then
        if((wr_en = '1') and (full_flag = '0'))then
        
            fifo(to_integer(unsigned(wptr))) <= din;

        end if;
    end if;
end process;
            
--write pointer
-- ?   `   I       A ?l I ??       ???     ?  
-- e ??     , write pointer   K ??ƒÖ     ? ??  ?   
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
        --srst  1 ?? ?A          write pointer  0 ?? 
            wptr <= (others => '0');
        elsif((wr_en = '1') and (full_flag = '0'))then
        --srst  0 ?A       ??\ M    1 ?AFIFO ?i [  full    ?  ? Awrite pointer  1 v   X    
            wptr <= std_logic_vector(unsigned(wptr) + 1);
        else
        --       ??\ ??  B       FIFO ?i [  full ? Awrite pointer ?ƒÖ      ?  i     ’Y       ??  j
            wptr <= wptr;
        end if;
    end if;
end process;

--read pointer
--  { I  write pointer ?   
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            rptr <= (others => '0');
        elsif((rd_en = '1') and (empty_flag = '0'))then
            rptr <= std_logic_vector(unsigned(rptr) + 1);
        else
            rptr <= rptr;
        end if;
    end if;
end process;

--empty flag state
--  ??  empty_flag  1 ?? ? ?  ? ??R [ h
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
        --srst  1 ?? ?A           ??  ? ??? ?Aempty_flag  1 ?? 
            empty_flag <= '1';
        
        --wr_en='1' ? A V   ? ?      ? ? ?A m   ? ???  ? B    ?    empty_flag <= '0' ?  ?     ...
        elsif(wr_en = '1')then
            empty_flag <= '0';
        --    1 ???  ?   empty ?? ?  ???  ??\ i ??  ?  j   ?Aempty ?? empty_flag <= '1' ?   
        elsif((almost_empty = '1') and (rd_en = '1'))then
            empty_flag <= '1';
        --    ?O ?? empty_flag   ƒÖ    ç· ???    ?Aelse  empty_flag <= empty_flag ?   
        else
            empty_flag <= empty_flag;
        end if;
    end if;
end process;

--full flag state
--  { I  empty flag state ?   
process(clk)begin
    if(rising_edge(clk))then
        if(srst = '1')then
            full_flag <= '0';
        elsif(rd_en = '1')then
            full_flag <= '0';
        elsif((almost_full = '1') and (wr_en = '1'))then
            full_flag <= '1';
        else
            full_flag <= full_flag;
        end if;
    end if;
end process;

end Behavioral;
