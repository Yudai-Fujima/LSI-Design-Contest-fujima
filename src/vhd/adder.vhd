library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
  port (
    acc_in  : in  signed(31 downto 0); -- 32bit Accumulator
    prod_in : in  signed(31 downto 0); -- 32bit Product from multiple
    sum_out : out signed(31 downto 0)  -- 32bit Result
  );
end entity;

architecture rtl of adder is
begin
  -- 32bit同士の�?�? (Pythonの += acc に相�?)
  -- 256回�?��?算程度な�?32bitあれば通常オーバ�?�フローしな�?
  sum_out <= acc_in + prod_in;
end architecture;