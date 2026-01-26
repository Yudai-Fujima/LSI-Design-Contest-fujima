library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fix_pre is
  generic (
    S      : integer := 2; -- Stride
    P      : integer := 1; -- Padding
    HOUT   : integer := 8; -- Output Height
    WOUT   : integer := 8  -- Output Width
  );
  port (
    -- Input Coordinates (from counters)
    iy     : in  integer;
    ix     : in  integer;
    ky     : in  integer;
    kx     : in  integer;

    -- Output Coordinates & Valid Flag
    oy     : out integer;
    ox     : out integer;
    valid  : out std_logic
  );
end entity;

architecture rtl of fix_pre is
begin
  process(iy, ix, ky, kx)
    variable v_oy : integer;
    variable v_ox : integer;
  begin
    -- Calculate Output Coordinates
    -- Original logic: oy = iy*S - P + ky
    v_oy := iy * S - P + ky;
    v_ox := ix * S - P + kx;

    -- Assign to outputs
    oy <= v_oy;
    ox <= v_ox;

    -- Range Check (Zero Padding logic)
    if (v_oy >= 0 and v_oy < HOUT) and (v_ox >= 0 and v_ox < WOUT) then
      valid <= '1';
    else
      valid <= '0';
    end if;
  end process;
end architecture;