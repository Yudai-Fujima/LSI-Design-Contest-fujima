library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiple is
  generic (
    DATA_WIDTH : integer := 16
  );
  port (
    x_in  : in  signed(DATA_WIDTH-1 downto 0);      -- 16bit
    w_in  : in  signed(DATA_WIDTH-1 downto 0);      -- 16bit
    p_out : out signed((DATA_WIDTH*2)-1 downto 0)   -- 32bit (丸めなし�?�完�?�な�?)
  );
end entity;

architecture rtl of multiple is
begin
  -- 単純な掛け算を行い�?32bitの結果をそのまま出�?
  p_out <= x_in * w_in;
end architecture;