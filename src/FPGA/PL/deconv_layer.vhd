library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deconv_layer is
  generic (
    CIN, COUT, HIN, WIN, K, S, P, HOUT, WOUT : integer;
    X_PLANE, Y_PLANE, DATA_WX, DATA_WW, ADDR_X_W, ADDR_W_W, ADDR_Y_W : integer
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    start     : in  std_logic;
    -- 【追�?】外部から処�?する出力チャネルを指定す�?
    oc_in     : in  integer; 
    done      : out std_logic;

    x_addr    : out unsigned(ADDR_X_W-1 downto 0);
    x_dout    : in  signed(DATA_WX-1 downto 0);
    w_raddr   : out unsigned(ADDR_W_W-1 downto 0);
    w_dout    : in  signed(DATA_WW-1 downto 0);
    y_raddr   : out unsigned(ADDR_Y_W-1 downto 0);
    y_rdata   : in  signed(31 downto 0);
    y_we      : out std_logic;
    y_waddr   : out unsigned(ADDR_Y_W-1 downto 0);
    y_wdata   : out signed(31 downto 0)
  );
end entity;

architecture rtl of deconv_layer is

  component kernel_multiple
    generic (
      CIN, COUT, HIN, WIN, K, S, P, HOUT, WOUT : integer;
      X_PLANE, Y_PLANE, DATA_WX, DATA_WW, ADDR_X_W, ADDR_W_W, ADDR_Y_W : integer
    );
    port (
      clk, rst, start : in std_logic;
      oc_sel : in integer;
      done : out std_logic;
      x_addr : out unsigned; x_dout : in signed;
      w_raddr : out unsigned; w_dout : in signed;
      y_raddr : out unsigned; y_rdata : in signed;
      y_we : out std_logic; y_waddr : out unsigned; y_wdata : out signed
    );
  end component;

  type state_t is (IDLE, CLEAR_RAM, RUN_KERNEL, WAIT_KERNEL, FINISH);
  signal st : state_t := IDLE;

  signal km_start, km_done : std_logic;
  signal clr_idx : integer range 0 to Y_PLANE-1 := 0;
  
  -- Signals from Kernel Multiple
  signal km_x_addr : unsigned(ADDR_X_W-1 downto 0);
  signal km_w_raddr : unsigned(ADDR_W_W-1 downto 0);
  signal km_y_raddr : unsigned(ADDR_Y_W-1 downto 0);
  signal km_y_we : std_logic;
  signal km_y_waddr : unsigned(ADDR_Y_W-1 downto 0);
  signal km_y_wdata : signed(31 downto 0);

begin

  u_kernel : kernel_multiple
    generic map (
      CIN=>CIN, COUT=>COUT, HIN=>HIN, WIN=>WIN, K=>K, S=>S, P=>P, HOUT=>HOUT, WOUT=>WOUT,
      X_PLANE=>X_PLANE, Y_PLANE=>Y_PLANE, DATA_WX=>DATA_WX, DATA_WW=>DATA_WW,
      ADDR_X_W=>ADDR_X_W, ADDR_W_W=>ADDR_W_W, ADDR_Y_W=>ADDR_Y_W
    )
    port map (
      clk=>clk, rst=>rst, start=>km_start, oc_sel=>oc_in, done=>km_done,
      x_addr=>km_x_addr, x_dout=>x_dout,
      w_raddr=>km_w_raddr, w_dout=>w_dout,
      y_raddr=>km_y_raddr, y_rdata=>y_rdata,
      y_we=>km_y_we, y_waddr=>km_y_waddr, y_wdata=>km_y_wdata
    );

  process(clk, rst)
  begin
    if rst = '1' then
      st <= IDLE;
      km_start <= '0';
      clr_idx <= 0;
      done <= '0';
    elsif rising_edge(clk) then
      done <= '0';

      case st is
        when IDLE =>
          if start = '1' then
            -- 計算前に、この出力チャネル(oc_in)に対応するY_RAM領域をクリアする
            st <= CLEAR_RAM;
            clr_idx <= 0;
          end if;

        when CLEAR_RAM =>
          if clr_idx = Y_PLANE - 1 then
            clr_idx <= 0;
            st <= RUN_KERNEL;
          else
            clr_idx <= clr_idx + 1;
          end if;

        when RUN_KERNEL =>
          km_start <= '1';
          st <= WAIT_KERNEL;

        when WAIT_KERNEL =>
          if km_done = '1' then
            st <= FINISH;
            km_start <= '0';
          end if;

        when FINISH =>
          done <= '1';
          if start = '0' then
            st <= IDLE;
          end if;
      end case;
    end if;
  end process;

  process(st, oc_in, clr_idx, km_x_addr, km_w_raddr, km_y_raddr, km_y_we, km_y_waddr, km_y_wdata)
  begin
    if st = CLEAR_RAM then
      -- Clear Mode: Write 0 to current channel plane in Y RAM
      x_addr  <= (others => '0');
      w_raddr <= (others => '0');
      y_we    <= '1';
      y_waddr <= to_unsigned(oc_in * Y_PLANE + clr_idx, ADDR_Y_W);
      y_wdata <= (others => '0');
      y_raddr <= (others => '0');
    else
      x_addr  <= km_x_addr;
      w_raddr <= km_w_raddr;
      y_we    <= km_y_we;
      y_waddr <= km_y_waddr;
      y_wdata <= km_y_wdata;
      y_raddr <= km_y_raddr;
    end if;
  end process;

end architecture;