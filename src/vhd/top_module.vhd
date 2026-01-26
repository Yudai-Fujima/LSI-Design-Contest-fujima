library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity top_module is
  generic (
    SHIFT_Q : integer := 8
  );
  port (
    clk           : in std_logic;
    rst           : in std_logic;
    start_x       : in std_logic;
    start_w       : in std_logic;
    state_cal     : in std_logic_vector(1 downto 0);
    end_cal_1out : out std_logic;
    end_move : out std_logic;
    end_all       : out std_logic;

    x         : in std_logic_vector((100*16)-1 downto 0);
    w         : in std_logic_vector(31 downto 0);
    out_img   : out std_logic_vector((32*32*8)-1 downto 0)
  );
end entity;

architecture rtl of top_module is

  constant L_DATA_W : integer := 16;

  -- Layer parameters
  constant L1_CIN: integer := 100; constant L1_COUT: integer := 512;
  constant L1_HIN: integer := 1;   constant L1_WIN:  integer := 1;
  constant L1_K:   integer := 4;   constant L1_S:    integer := 1; constant L1_P: integer := 0;
  constant L1_HOUT:integer := 4;   constant L1_WOUT: integer := 4;

  constant L2_CIN: integer := 512; constant L2_COUT: integer := 256;
  constant L2_HIN: integer := 4;   constant L2_WIN:  integer := 4;
  constant L2_K:   integer := 4;   constant L2_S:    integer := 2; constant L2_P: integer := 1;
  constant L2_HOUT:integer := 8;   constant L2_WOUT: integer := 8;

  constant L3_CIN: integer := 256; constant L3_COUT: integer := 128;
  constant L3_HIN: integer := 8;   constant L3_WIN:  integer := 8;
  constant L3_K:   integer := 4;   constant L3_S:    integer := 2; constant L3_P: integer := 1;
  constant L3_HOUT:integer := 16;  constant L3_WOUT: integer := 16;

  constant L4_CIN: integer := 128; constant L4_COUT: integer := 1;
  constant L4_HIN: integer := 16;  constant L4_WIN:  integer := 16;
  constant L4_K:   integer := 4;   constant L4_S:    integer := 2; constant L4_P: integer := 1;
  constant L4_HOUT:integer := 32;  constant L4_WOUT: integer := 32;

  constant ADDR_X_W      : integer := 15;
  constant ADDR_Y_W      : integer := 15;
  constant ADDR_W_W      : integer := 13;

  -- Components
  component Input_Deserializer
    generic (INPUT_DIM, DATA_WIDTH, ADDR_WIDTH : integer);
    port (clk, rst, start_x : in std_logic; x_vec : in std_logic_vector;
          ram_we : out std_logic; ram_addr : out unsigned; ram_din : out signed(15 downto 0); done : out std_logic);
  end component;

  component Output_Serializer
    generic (H_OUT, W_OUT, DATA_WIDTH, ADDR_WIDTH : integer);
    port (clk, rst, start : in std_logic; ram_addr : out unsigned; ram_dout : in signed;
          out_img : out std_logic_vector; done : out std_logic);
  end component;

  -- =========================================================
  -- Component�錾�̏C��: DATA_WX, DATA_WW ��ǉ�
  -- =========================================================
  component deconv_layer is
    generic (
      CIN, COUT, HIN, WIN, K, S, P, HOUT, WOUT, 
      X_PLANE, Y_PLANE, 
      DATA_WX, DATA_WW, -- �ǉ�
      ADDR_X_W, ADDR_W_W, ADDR_Y_W : integer
    );
    port (
      clk, rst, start : in std_logic; oc_in : in integer; done : out std_logic;
      x_addr : out unsigned; 
      x_dout : in signed(DATA_WX-1 downto 0);  -- generic���g�p
      w_raddr : out unsigned; 
      w_dout : in signed(DATA_WW-1 downto 0);  -- generic���g�p
      y_raddr : out unsigned; y_rdata : in signed; y_we : out std_logic; y_waddr : out unsigned; y_wdata : out signed
    );
  end component;

  component Saturation is generic (SHIFT_Q : integer); port (val_in : in signed; val_out : out signed(15 downto 0)); end component;
  component ReRU is port (d_in : in signed(15 downto 0); d_out : out signed(15 downto 0)); end component;
  component tanh_q1p7_lut is port (clk : in std_logic; x_in : in signed; y_out : out signed); end component;

  -- =========================================================
  -- Component�錾�̏C��: ram_w �� 32bit �Ή���
  -- =========================================================
  component ram_w
    generic (DATA_W : integer := 32; ADDR_W : integer := 13);
    port (clk:in std_logic; we:in std_logic; waddr:in unsigned; 
          din:in signed(31 downto 0); 
          raddr:in unsigned; 
          dout:out signed(31 downto 0));
  end component;

  component ram_x
    generic (DATA_W : integer := 16; ADDR_W : integer := 15);
    port (clk:in std_logic; we:in std_logic; waddr:in unsigned; din:in signed(15 downto 0); raddr:in unsigned; dout:out signed(15 downto 0));
  end component;

  component ram_y
    generic (DATA_W : integer := 32; ADDR_W : integer := 15);
    port (clk:in std_logic; core_we:in std_logic; core_waddr:in unsigned; core_din:in signed; core_raddr:in unsigned; core_dout:out signed);
  end component;

  -- Signals
  type state_t is (
      IDLE, LOAD_X, INIT_LAYER,
      WAIT_W_REQ, LOAD_W,
      RUN_CORE, WAIT_CORE,
      SIGNAL_END,           -- ������Ԃ������ő���
      MOVE_DATA, SER_OUT, ALL_DONE
    );
  signal st : state_t := IDLE;

  signal cur_oc, max_oc, cur_layer : integer := 0;
  signal w_load_cnt : integer := 0;
  signal des_done, ser_done : std_logic;
  signal l1_start, l2_start, l3_start, l4_start : std_logic := '0';
  signal l1_done, l2_done, l3_done, l4_done : std_logic;
  signal ser_start : std_logic := '0';
  -- ���ǉ�: �f�[�^�ړ������t���O
  signal move_done : std_logic := '0';
  -- start_w edge���o
  signal start_w_d : std_logic := '0';
  signal start_w_rise : std_logic;

  signal ram_x_we : std_logic;
  signal ram_x_addr : unsigned(ADDR_X_W-1 downto 0);
  signal ram_x_din, ram_x_dout : signed(15 downto 0);

  signal ram_w_we : std_logic;
  signal ram_w_addr : unsigned(ADDR_W_W-1 downto 0);
  
  -- =========================================================
  -- Signal��`�̏C��: ram_w �p�� 32bit ��
  -- =========================================================
  signal ram_w_din, ram_w_dout : signed(31 downto 0);

  -- RAM Y signals (MUX output)
  signal ram_y_we : std_logic;
  signal ram_y_waddr, ram_y_raddr : unsigned(ADDR_Y_W-1 downto 0);
  signal ram_y_wdata, ram_y_rdata : signed(31 downto 0);

  signal ram_y_zero_addr : unsigned(ADDR_Y_W-1 downto 0) := (others => '0');

  -- Layer connections
  signal l1_x_addr, l2_x_addr, l3_x_addr, l4_x_addr : unsigned(ADDR_X_W-1 downto 0);
  signal l1_w_addr, l2_w_addr, l3_w_addr, l4_w_addr : unsigned(ADDR_W_W-1 downto 0);

  signal l1_y_raddr, l2_y_raddr, l3_y_raddr, l4_y_raddr : unsigned(ADDR_Y_W-1 downto 0);
  signal l1_y_waddr, l2_y_waddr, l3_y_waddr, l4_y_waddr : unsigned(ADDR_Y_W-1 downto 0);
  signal l1_y_wdata, l2_y_wdata, l3_y_wdata, l4_y_wdata : signed(31 downto 0);
  signal l1_y_we, l2_y_we, l3_y_we, l4_y_we : std_logic;

  signal des_we : std_logic;
  signal des_addr : unsigned(ADDR_X_W-1 downto 0);
  signal des_din : signed(15 downto 0);
  signal ser_addr : unsigned(ADDR_Y_W-1 downto 0);

  signal mv_cnt, mv_max : integer := 0;

  signal sat_in         : signed(31 downto 0);
  signal sat_out_layer  : signed(15 downto 0);
  signal sat_out_tanh   : signed(15 downto 0);
  signal relu_out       : signed(15 downto 0);
  signal tanh_in        : signed(7 downto 0);
  signal tanh_out       : signed(7 downto 0);
  signal ser_din_signed : signed(7 downto 0);

  signal move_data_active : std_logic;

begin
  start_w_rise <= start_w and not start_w_d;

    process(clk) begin
      if rising_edge(clk) then
        start_w_d <= start_w;
      end if;
    end process;
  
  -- RAM Connections
  u_ram_x : ram_x generic map (16, ADDR_X_W)
    port map (clk, ram_x_we, ram_x_addr, ram_x_din, ram_x_addr, ram_x_dout);

  -- =========================================================
  -- RAM W �C���X�^���X: DATA_W=32
  -- =========================================================
  u_ram_w : ram_w generic map (32, ADDR_W_W)
    port map (clk, ram_w_we, ram_w_addr, ram_w_din, ram_w_addr, ram_w_dout);

  -- RAM Y (Accumulator)
  u_ram_y : ram_y generic map (32, ADDR_Y_W)
    port map (clk, ram_y_we, ram_y_waddr, ram_y_wdata, ram_y_raddr, ram_y_rdata);

  -- =========================================================
  -- Layer �C���X�^���X: 
  -- DATA_WX => 16 (�摜)
  -- DATA_WW => 32 (�d��)
  -- �𐔒l�œn��
  -- =========================================================
  u_l1 : deconv_layer
    generic map (L1_CIN, L1_COUT, L1_HIN, L1_WIN, L1_K, L1_S, L1_P, L1_HOUT, L1_WOUT,
                 L1_HIN*L1_WIN, L1_HOUT*L1_WOUT, 
                 16, 32, -- �������C��
                 ADDR_X_W, ADDR_W_W, ADDR_Y_W)
    port map (clk, rst, l1_start, cur_oc, l1_done,
              l1_x_addr, ram_x_dout, l1_w_addr, ram_w_dout,
              l1_y_raddr, ram_y_rdata, l1_y_we, l1_y_waddr, l1_y_wdata);

  u_l2 : deconv_layer
    generic map (L2_CIN, L2_COUT, L2_HIN, L2_WIN, L2_K, L2_S, L2_P, L2_HOUT, L2_WOUT,
                 L2_HIN*L2_WIN, L2_HOUT*L2_WOUT, 
                 16, 32, -- �������C��
                 ADDR_X_W, ADDR_W_W, ADDR_Y_W)
    port map (clk, rst, l2_start, cur_oc, l2_done,
              l2_x_addr, ram_x_dout, l2_w_addr, ram_w_dout,
              l2_y_raddr, ram_y_rdata, l2_y_we, l2_y_waddr, l2_y_wdata);

  u_l3 : deconv_layer
    generic map (L3_CIN, L3_COUT, L3_HIN, L3_WIN, L3_K, L3_S, L3_P, L3_HOUT, L3_WOUT,
                 L3_HIN*L3_WIN, L3_HOUT*L3_WOUT, 
                 16, 32, -- �������C��
                 ADDR_X_W, ADDR_W_W, ADDR_Y_W)
    port map (clk, rst, l3_start, cur_oc, l3_done,
              l3_x_addr, ram_x_dout, l3_w_addr, ram_w_dout,
              l3_y_raddr, ram_y_rdata, l3_y_we, l3_y_waddr, l3_y_wdata);

  u_l4 : deconv_layer
    generic map (L4_CIN, L4_COUT, L4_HIN, L4_WIN, L4_K, L4_S, L4_P, L4_HOUT, L4_WOUT,
                 L4_HIN*L4_WIN, L4_HOUT*L4_WOUT, 
                 16, 32, -- �������C��
                 ADDR_X_W, ADDR_W_W, ADDR_Y_W)
    port map (clk, rst, l4_start, cur_oc, l4_done,
              l4_x_addr, ram_x_dout, l4_w_addr, ram_w_dout,
              l4_y_raddr, ram_y_rdata, l4_y_we, l4_y_waddr, l4_y_wdata);

  u_des : Input_Deserializer generic map (100, 16, ADDR_X_W)
    port map (clk, rst, start_x, x, des_we, des_addr, des_din, des_done);

  u_ser : Output_Serializer generic map (32, 32, 8, ADDR_Y_W)
    port map (clk, rst, ser_start, ser_addr, ser_din_signed, out_img, ser_done);

  -- Post Processing Chain
  sat_in <= ram_y_rdata;
  u_sat_layer : Saturation generic map (SHIFT_Q) port map (sat_in, sat_out_layer);
  u_relu      : ReRU port map (sat_out_layer, relu_out);

  -- Tanh Logic
  u_sat_tanh : Saturation generic map (9) port map (sat_in, sat_out_tanh);

  process(sat_out_tanh)
    variable v : integer;
  begin
    v := to_integer(sat_out_tanh);
    if v > 127 then
      tanh_in <= to_signed(127, 8);
    elsif v < -128 then
      tanh_in <= to_signed(-128, 8);
    else
      tanh_in <= to_signed(v, 8);
    end if;
  end process;

  u_tanh : tanh_q1p7_lut port map (clk, tanh_in, tanh_out);

  process(tanh_out)
  begin
    ser_din_signed(7) <= not tanh_out(7);
    ser_din_signed(6 downto 0) <= tanh_out(6 downto 0);
  end process;

  -- =========================================================
  -- FSM
  -- =========================================================
  process(clk, rst)
  begin
    if rst = '1' then
      st <= IDLE;
      cur_oc <= 0; max_oc <= 0; cur_layer <= 0;
      w_load_cnt <= 0;
      l1_start <= '0'; l2_start <= '0'; l3_start <= '0'; l4_start <= '0';
      ser_start <= '0';
      end_cal_1out <= '0'; end_all <= '0';
      mv_cnt <= 0;
      move_done <= '0'; -- ���Z�b�g
    elsif rising_edge(clk) then
      ser_start <= '0';
      end_cal_1out <= '0'; end_all <= '0';

      case st is
        when IDLE =>
          if start_x = '1' then
            cur_layer <= 1;  -- 1�w�ڂ𖾎��I�ɃZ�b�g
            st <= LOAD_X;
            
            -- ������2: 2�w�ڈȍ~�̊J�n (move_done) -> LOAD_X���X�L�b�v
          elsif move_done = '1' then
            move_done <= '0'; -- �t���O���
            st <= INIT_LAYER; -- �����Ȃ菉������
          end if;

        when LOAD_X =>
          if des_done = '1' then
            st <= INIT_LAYER;
            --cur_layer <= 1;
          end if;

        when INIT_LAYER =>
          cur_oc <= 0;
          case cur_layer is
            when 1 => max_oc <= L1_COUT;
            when 2 => max_oc <= L2_COUT;
            when 3 => max_oc <= L3_COUT;
            when 4 => max_oc <= L4_COUT;
            when others => null;
          end case;
          st <= WAIT_W_REQ;

        when WAIT_W_REQ =>
          if start_w = '1' then
            w_load_cnt <= 0;
            st <= LOAD_W;
          end if;
        
        when LOAD_W =>
          if start_w = '1' then
            -- ���̃T�C�N���� w �� addr=w_load_cnt �ɏ����iWE�͏�̃��W�b�N�ŗ��j
            w_load_cnt <= w_load_cnt + 1;
          else
            -- ���[�h�������R�A�N��
            st <= RUN_CORE;
            case cur_layer is
              when 1 => l1_start <= '1';
              when 2 => l2_start <= '1';
              when 3 => l3_start <= '1';
              when 4 => l4_start <= '1';
              when others => null;
            end case;
          end if;

        when RUN_CORE =>
          st <= WAIT_CORE;

        when WAIT_CORE =>
          if (cur_layer=1 and l1_done='1') or
             (cur_layer=2 and l2_done='1') or
             (cur_layer=3 and l3_done='1') or
             (cur_layer=4 and l4_done='1') then
            st <= SIGNAL_END;
            l1_start <= '0'; l2_start <= '0'; l3_start <= '0'; l4_start <= '0';
          end if;

        when SIGNAL_END =>
          end_cal_1out <= '1';
        
          if cur_oc = max_oc - 1 then
            if cur_layer = 4 then
              st <= SER_OUT;
              ser_start <= '1';
            else
              st <= MOVE_DATA;
              mv_cnt <= 0;
              case cur_layer is
                when 1 => mv_max <= L1_COUT * L1_HOUT * L1_WOUT;
                when 2 => mv_max <= L2_COUT * L2_HOUT * L2_WOUT;
                when 3 => mv_max <= L3_COUT * L3_HOUT * L3_WOUT;
                when others => null;
              end case;
            end if;
          else
            cur_oc <= cur_oc + 1;
            st <= WAIT_W_REQ;  -- �������̏d�ݗv���҂���
          end if;

        when MOVE_DATA =>
          --if mv_cnt < mv_max + 1 then
          if mv_cnt < mv_max then
            mv_cnt <= mv_cnt + 1;
          else
            -- ��������ύX: ���C���[��i�߂Ċ����t���O�𗧂āAIDLE�֖߂�
            cur_layer <= cur_layer + 1;
            move_done <= '1'; 
            st <= IDLE; -- IDLE�ɖ߂邪�A���̃N���b�N��move_done�ɂ��INIT_LAYER�֑�������
          end if;

        when SER_OUT =>
          if ser_done = '1' then
            st <= ALL_DONE;
          end if;

        when ALL_DONE =>
          end_all <= '1';
          if start_x = '0' then
            st <= IDLE;
          end if;

      end case;
    end if;
  end process;

  -- =========================================================
  -- RAM W Write Logic  ����������ԑ厖
  -- =========================================================
  -- start_w �� w ������N���b�N�ŗL���Ȃ�ALOAD_W������������OK
  ram_w_we <= '1' when (st = LOAD_W and start_w = '1') else '0';
  --ram_w_we <= '1' when start_w = '1' else '0';

  -- �������ݎ��� w_load_cnt�A�v�Z���͊elayer��read addr
  ram_w_addr <= to_unsigned(w_load_cnt, ADDR_W_W) when (st = LOAD_W and start_w = '1') else
                l1_w_addr when cur_layer=1 else
                l2_w_addr when cur_layer=2 else
                l3_w_addr when cur_layer=3 else
                l4_w_addr;

  -- �y�C���ӏ��z
  -- 32bit���͂����̂܂�RAM�ɓ���� (�p�b�L���O�E�g���Ȃǂ͕s�v)
  ram_w_din <= signed(w);

  -- =========================================================
  -- RAM X Write Logic
  -- =========================================================
  move_data_active <= '1' when st = MOVE_DATA and mv_cnt > 0 else '0';
  ram_x_we <= des_we when st = LOAD_X else move_data_active;

  process(st, des_addr, des_din, mv_cnt, relu_out,
          l1_x_addr, l2_x_addr, l3_x_addr, l4_x_addr, cur_layer)
  begin
    if st = LOAD_X then
      ram_x_addr <= des_addr;
      ram_x_din  <= des_din;
    elsif st = MOVE_DATA then
      ram_x_addr <= to_unsigned(mv_cnt - 1, ADDR_X_W);
      ram_x_din  <= relu_out;
    else
      ram_x_din <= (others=>'0');
      case cur_layer is
        when 1 => ram_x_addr <= l1_x_addr;
        when 2 => ram_x_addr <= l2_x_addr;
        when 3 => ram_x_addr <= l3_x_addr;
        when 4 => ram_x_addr <= l4_x_addr;
        when others => ram_x_addr <= (others=>'0');
      end case;
    end if;
  end process;

  -- =========================================================
  -- RAM Y Mux Process
  -- =========================================================
  process(st, cur_layer, ser_addr, mv_cnt,
          l1_y_we, l1_y_waddr, l1_y_wdata, l1_y_raddr,
          l2_y_we, l2_y_waddr, l2_y_wdata, l2_y_raddr,
          l3_y_we, l3_y_waddr, l3_y_wdata, l3_y_raddr,
          l4_y_we, l4_y_waddr, l4_y_wdata, l4_y_raddr)
  begin
    ram_y_we    <= '0';
    ram_y_waddr <= (others => '0');
    ram_y_wdata <= (others => '0');
    ram_y_raddr <= (others => '0');

    if st = SER_OUT then
      ram_y_raddr <= ser_addr;
    elsif st = MOVE_DATA then
      ram_y_raddr <= to_unsigned(mv_cnt, ADDR_Y_W);
    else
      case cur_layer is
        when 1 =>
          ram_y_we    <= l1_y_we;
          ram_y_waddr <= l1_y_waddr;
          ram_y_wdata <= l1_y_wdata;
          ram_y_raddr <= l1_y_raddr;
        when 2 =>
          ram_y_we    <= l2_y_we;
          ram_y_waddr <= l2_y_waddr;
          ram_y_wdata <= l2_y_wdata;
          ram_y_raddr <= l2_y_raddr;
        when 3 =>
          ram_y_we    <= l3_y_we;
          ram_y_waddr <= l3_y_waddr;
          ram_y_wdata <= l3_y_wdata;
          ram_y_raddr <= l3_y_raddr;
        when 4 =>
          ram_y_we    <= l4_y_we;
          ram_y_waddr <= l4_y_waddr;
          ram_y_wdata <= l4_y_wdata;
          ram_y_raddr <= l4_y_raddr;
        when others =>
          null;
      end case;
    end if;
  end process;
  
  -- fujima
  end_move <= move_done;
end architecture;