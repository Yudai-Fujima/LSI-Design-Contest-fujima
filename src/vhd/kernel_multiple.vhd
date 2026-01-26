library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kernel_multiple is
  generic (
    CIN, COUT, HIN, WIN, K, S, P, HOUT, WOUT : integer;
    X_PLANE, Y_PLANE, DATA_WX, DATA_WW, ADDR_X_W, ADDR_W_W, ADDR_Y_W : integer
  );
  port (
    clk, rst, start : in std_logic;
    oc_sel : in integer;
    done : out std_logic;

    x_addr : out unsigned(ADDR_X_W-1 downto 0);
    x_dout : in  signed(DATA_WX-1 downto 0);

    w_raddr : out unsigned(ADDR_W_W-1 downto 0);
    w_dout  : in  signed(31 downto 0);

    y_raddr : out unsigned(ADDR_Y_W-1 downto 0);
    y_rdata : in  signed(31 downto 0);

    y_we    : out std_logic;
    y_waddr : out unsigned(ADDR_Y_W-1 downto 0);
    y_wdata : out signed(31 downto 0)
  );
end entity;

architecture rtl of kernel_multiple is

  component loop_counter
    generic (K, WIN, HIN, CIN : integer);
    port (
      clk, rst, step : in std_logic;
      kx, ky, ix, iy, ic : out integer;
      done : out std_logic
    );
  end component;

  component kernel_multiple_1
    generic (S, P, HOUT, WOUT, Y_PLANE, DATA_WIDTH : integer);
    port (
      iy, ix, ky, kx, ocv : in integer;
      x_in, w_in : in signed(DATA_WIDTH-1 downto 0);
      addr_y : out integer;
      prod_out : out signed(DATA_WIDTH-1 downto 0);
      valid : out std_logic
    );
  end component;

  component multiple
    generic (DATA_WIDTH : integer);
    port (
      x_in, w_in : in signed(DATA_WIDTH-1 downto 0);
      p_out : out signed(31 downto 0)
    );
  end component;

  component adder
    port (
      acc_in  : in signed(31 downto 0);
      prod_in : in signed(31 downto 0);
      sum_out : out signed(31 downto 0)
    );
  end component;

  type state_t is (
    IDLE,
    X_SETUP, X_WAIT, X_LATCH,
    W_SETUP, W_WAIT, W_LATCH,
    CALC_AND_READ_Y, WAIT_Y, ADD_WRITE,
    STEP_LOOP, POST_STEP,
    FINISH
  );
  signal st : state_t := IDLE;

  signal step_cnt  : std_logic := '0';
  signal loop_done : std_logic := '0';

  signal kx, ky, ix, iy, ic : integer := 0;

  signal x_reg, w_reg : signed(DATA_WX-1 downto 0) := (others=>'0');

  signal km1_addr_y     : integer := 0;
  signal km1_prod_dummy : signed(DATA_WX-1 downto 0) := (others=>'0');
  signal km1_valid      : std_logic := '0';

  signal mult_prod_32 : signed(31 downto 0) := (others=>'0');
  signal add_sum_32   : signed(31 downto 0) := (others=>'0');

  signal r_y_raddr_sig : unsigned(ADDR_Y_W-1 downto 0) := (others=>'0');
  signal cnt_rst       : std_logic;

  -- q(ラッチしたループ値)
  signal kx_q, ky_q, ix_q, iy_q, ic_q : integer := 0;

  -- ★prime制御：OCごとに最初の1回だけ書かない
  signal priming : std_logic := '1';

  -- ★start立ち上がり検出
  signal start_d    : std_logic := '0';
  signal start_rise : std_logic;
  -- 【追加】バイト選択用の信号（0～3を保持）
  signal w_byte_sel : integer range 0 to 3 := 0;

begin

  -- loop_counter を IDLE の間はリセット
  --cnt_rst <= '1' when (rst = '1' or st = IDLE) else '0';
  cnt_rst <= '1' when (rst='1' or start_rise='1') else '0';

  u_counter : loop_counter
    generic map (K=>K, WIN=>WIN, HIN=>HIN, CIN=>CIN)
    port map (clk, cnt_rst, step_cnt, kx, ky, ix, iy, ic, loop_done);

  -- ★km1 には q を入れる（あなたの構成維持）
  u_km1 : kernel_multiple_1
    generic map (S=>S, P=>P, HOUT=>HOUT, WOUT=>WOUT, Y_PLANE=>Y_PLANE, DATA_WIDTH=>DATA_WX)
    port map (iy_q, ix_q, ky_q, kx_q, oc_sel, x_reg, w_reg, km1_addr_y, km1_prod_dummy, km1_valid);

  u_mult_32 : multiple
    generic map (DATA_WIDTH => DATA_WX)
    port map (x_reg, w_reg, mult_prod_32);

  u_adder_32 : adder
    port map (y_rdata, mult_prod_32, add_sum_32);

  y_raddr <= r_y_raddr_sig;
  y_wdata <= add_sum_32;

  -- ★start立ち上がり
  start_rise <= start and (not start_d);

  process(clk, rst)
    variable widx : integer;
  begin
    if rst = '1' then
      st <= IDLE;

      step_cnt <= '0';
      done     <= '0';

      x_addr  <= (others=>'0');
      w_raddr <= (others=>'0');

      x_reg <= (others=>'0');
      w_reg <= (others=>'0');

      y_we    <= '0';
      y_waddr <= (others=>'0');

      r_y_raddr_sig <= (others=>'0');

      kx_q <= 0; ky_q <= 0; ix_q <= 0; iy_q <= 0; ic_q <= 0;

      priming <= '1';
      start_d <= '0';

    elsif rising_edge(clk) then
      -- -----------------------------------------
      -- start edge の保持
      -- -----------------------------------------
      start_d <= start;

      -- ★ここが肝：
      -- start が立ち上がったら「そのOCの最初は捨てる」に戻す
      if start_rise = '1' then
        priming <= '1';
        -- qもここで確実に初期化（最初の addr 計算を安定させる）
        kx_q <= 0; ky_q <= 0; ix_q <= 0; iy_q <= 0; ic_q <= 0;
      end if;

      -- デフォルト
      step_cnt <= '0';
      y_we     <= '0';
      done     <= '0';

      case st is
        when IDLE =>
          -- ★IDLEでは priming を触らない（ここ重要）
          if start = '1' then
            st <= X_SETUP;
          end if;

        when X_SETUP =>
          x_addr <= to_unsigned(ic_q * X_PLANE + iy_q * WIN + ix_q, ADDR_X_W);
          st <= X_WAIT;

        when X_WAIT =>
          st <= X_LATCH;

        when X_LATCH =>
          x_reg <= x_dout;
          st <= W_SETUP;

        -- =========================================================
        -- 【修正箇所 1】 アドレス計算とバイト選択位置の決定
        -- =========================================================
        when W_SETUP =>
          -- 本来の通し番号を計算
          widx := (ic_q * K + ky_q) * K + kx_q;
          
          -- RAMアドレスは 1/4 (整数の割り算で自動的に切り捨て)
          w_raddr <= to_unsigned(widx / 4, ADDR_W_W);
          
          -- 32bit中のどの位置か (余りを保存)
          w_byte_sel <= widx mod 4;
          
          st <= W_WAIT;

        when W_WAIT =>
          st <= W_LATCH;

        -- =========================================================
        -- 【修正箇所 2】 データの切り出し・符号拡張・2倍化(左シフト)
        -- =========================================================
        when W_LATCH =>
          -- w_dout(32bit)から8bit切り出し -> DATA_WX(16bit等)に拡張 -> 1ビット左シフト(2倍)
          
          case w_byte_sel is
            when 0 => 
              -- Bits 7-0
              w_reg <= shift_left(resize(w_dout(7 downto 0), DATA_WX), 1);
            when 1 => 
              -- Bits 15-8
              w_reg <= shift_left(resize(w_dout(15 downto 8), DATA_WX), 1);
            when 2 => 
              -- Bits 23-16
              w_reg <= shift_left(resize(w_dout(23 downto 16), DATA_WX), 1);
            when 3 => 
              -- Bits 31-24
              w_reg <= shift_left(resize(w_dout(31 downto 24), DATA_WX), 1);
            when others =>
              w_reg <= (others => '0');
          end case;

          st <= CALC_AND_READ_Y;

        when CALC_AND_READ_Y =>
          if km1_valid = '1' and km1_addr_y >= 0 and km1_addr_y < (COUT * Y_PLANE) then
            r_y_raddr_sig <= to_unsigned(km1_addr_y, ADDR_Y_W);
            st <= WAIT_Y;
          else
            st <= STEP_LOOP;
          end if;

        when WAIT_Y =>
          st <= ADD_WRITE;

        when ADD_WRITE =>
          -- ★prime：OC切替直後の "最初の1回" は書かない
          if priming = '0' then
            y_we    <= '1';
            y_waddr <= r_y_raddr_sig;
          end if;

          -- ★ここで1回目を消化したので解除
          priming <= '0';
          st <= STEP_LOOP;

        when STEP_LOOP =>
          step_cnt <= '1';
          st <= POST_STEP;

        when POST_STEP =>
          -- loop_counter の更新を q に反映
          kx_q <= kx; ky_q <= ky; ix_q <= ix; iy_q <= iy; ic_q <= ic;

          if loop_done = '1' then
            st <= FINISH;
          else
            st <= X_SETUP;
          end if;

        when FINISH =>
          done <= '1';
          if start = '0' then
            st <= IDLE;
          end if;

      end case;
    end if;
  end process;

end architecture;