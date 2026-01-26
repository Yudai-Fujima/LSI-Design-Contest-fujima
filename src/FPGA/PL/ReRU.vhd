library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ReRU is
  port (
    d_in  : in  signed(15 downto 0);
    d_out : out signed(15 downto 0)
  );
end entity;

architecture rtl of ReRU is
begin
  process(d_in)
  begin
    if d_in < 0 then
      d_out <= (others => '0');
    else
      d_out <= d_in;
    end if;
  end process;
end architecture;