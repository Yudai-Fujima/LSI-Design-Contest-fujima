library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Saturation is
  generic (
    SHIFT_Q : integer := 8
  );
  port (
    val_in  : in  signed(31 downto 0);
    val_out : out signed(15 downto 0) -- 16bit出力に変更
  );
end entity;

architecture rtl of Saturation is
begin
  process(val_in)
    variable v_rounded : signed(31 downto 0);
    variable v_shifted : integer;
    variable v_out     : integer;
    constant ROUND_ADD : signed(31 downto 0) := to_signed(2**(SHIFT_Q-1), 32);
  begin
    -- 四捨五入とシフト
    v_rounded := val_in + ROUND_ADD;
    v_shifted := to_integer(shift_right(v_rounded, SHIFT_Q));

    -- Saturation (Clip to -32768 .. 32767 for int16)
    if v_shifted > 32767 then
      v_out := 32767;
    elsif v_shifted < -32768 then
      v_out := -32768;
    else
      v_out := v_shifted;
    end if;

    val_out <= to_signed(v_out, 16);
  end process;
end architecture;