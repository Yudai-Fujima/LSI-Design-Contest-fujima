library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity loop_counter is
  generic (
    K    : integer := 4;  -- Kernel Size
    WIN  : integer := 4;  -- Input Width
    HIN  : integer := 4;  -- Input Height
    CIN  : integer := 3   -- Input Channels
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    step    : in  std_logic; -- Enable signal to increment counter

    -- Loop Indices
    kx      : out integer;
    ky      : out integer;
    ix      : out integer;
    iy      : out integer;
    ic      : out integer;

    -- Status
    done    : out std_logic  -- Asserted when all loops finished
  );
end entity;

architecture rtl of loop_counter is
  -- Internal signals
  signal r_kx, r_ky : integer range 0 to K-1;
  signal r_ix       : integer range 0 to WIN-1;
  signal r_iy       : integer range 0 to HIN-1;
  signal r_ic       : integer range 0 to CIN-1;
  signal r_done     : std_logic;

begin
  process(clk, rst)
  begin
    if rst = '1' then
      r_kx <= 0; r_ky <= 0;
      r_ix <= 0; r_iy <= 0;
      r_ic <= 0;
      r_done <= '0';
    elsif rising_edge(clk) then
      if step = '1' and r_done = '0' then
        -- Nested Loop Logic
        if r_kx = K-1 then
          r_kx <= 0;
          if r_ky = K-1 then
            r_ky <= 0;
            if r_ix = WIN-1 then
              r_ix <= 0;
              if r_iy = HIN-1 then
                r_iy <= 0;
                if r_ic = CIN-1 then
                  -- All loops finished
                  r_done <= '1';
                else
                  r_ic <= r_ic + 1;
                end if;
              else
                r_iy <= r_iy + 1;
              end if;
            else
              r_ix <= r_ix + 1;
            end if;
          else
            r_ky <= r_ky + 1;
          end if;
        else
          r_kx <= r_kx + 1;
        end if;
      end if;
    end if;
  end process;

  -- Output assignment
  kx <= r_kx;
  ky <= r_ky;
  ix <= r_ix;
  iy <= r_iy;
  ic <= r_ic;
  done <= r_done;

end architecture;