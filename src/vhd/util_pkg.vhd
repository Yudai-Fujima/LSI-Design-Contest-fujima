library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package util_pkg is
  -- 整数 n を表現するのに必要なビット幅 (ceil(log2(n))) を返す関数
  function ceil_log2(n : integer) return integer;
end package;

package body util_pkg is
  function ceil_log2(n : integer) return integer is
    variable v : integer := 1;
    variable r : integer := 0;
  begin
    if n <= 1 then return 1; end if; -- 安全策
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;
end package body;