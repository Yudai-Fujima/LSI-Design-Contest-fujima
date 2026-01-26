library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kernel_multiple_1 is
  generic (
    S, P, HOUT, WOUT, Y_PLANE, DATA_WIDTH : integer
  );
  port (
    iy, ix, ky, kx, ocv : in integer;
    x_in, w_in : in signed(DATA_WIDTH-1 downto 0);
    addr_y : out integer;
    
    -- 親モジュール(kernel_multiple)との互換性維持のためポートは残すが
    -- 中身はダミー(0)を出力する
    prod_out : out signed(DATA_WIDTH-1 downto 0); 
    valid : out std_logic
  );
end entity;

architecture rtl of kernel_multiple_1 is

  component fix_pre
    generic (S, P, HOUT, WOUT : integer);
    port (iy, ix, ky, kx : in integer; oy, ox : out integer; valid : out std_logic);
  end component;

  -- multiple コンポーネントは削除 (親モジュールで32bit計算するため不要)

  signal s_oy, s_ox : integer;
  signal s_valid : std_logic;

begin

  u_fix_pre : fix_pre
    generic map (S, P, HOUT, WOUT)
    port map (iy, ix, ky, kx, s_oy, s_ox, s_valid);

  -- 以前ここにあった u_multiple は削除

  -- prod_out は使用しないので 0 固定 (16bit)
  prod_out <= (others => '0');

  process(s_oy, s_ox, ocv, s_valid)
    variable v_oidx : integer;
  begin
    if s_valid = '1' then
      v_oidx := s_oy * WOUT + s_ox;
      addr_y <= (ocv * Y_PLANE) + v_oidx;
    else
      addr_y <= 0;
    end if;
  end process;

  valid <= s_valid;

end architecture;