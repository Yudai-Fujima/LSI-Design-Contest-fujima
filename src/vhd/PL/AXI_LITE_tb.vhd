library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all; -- hwrite

entity AXI_LITE_tb_same_as_calc is
  generic (
    AXI_DATA_WIDTH : integer := 32;
    AXI_ADDR_WIDTH : integer := 4;

    -- ===== Layer���Ƃ̉� =====
    L1_CH_MAX : integer := 512;
    L2_CH_MAX : integer := 256;
    L3_CH_MAX : integer := 128;
    L4_CH_MAX : integer := 1;

    -- ===== Layer���Ƃ̏d��(s8)��/CH =====
    -- s8��4��1word32�Ƀp�b�N���đ���̂ŁA���M�񐔂� (W_PER_CH/4)
    L1_W_PER_CH : integer := 1600;
    L2_W_PER_CH : integer := 8192;
    L3_W_PER_CH : integer := 4096;
    L4_W_PER_CH : integer := 2048
  );
end entity;

architecture tb of AXI_LITE_tb_same_as_calc is

  component AXI_LITE_source_v1_0
    generic (
      C_S00_AXI_DATA_WIDTH : integer := 32;
      C_S00_AXI_ADDR_WIDTH : integer := 4
    );
    port (
      s00_axi_aclk    : in  std_logic;
      s00_axi_aresetn : in  std_logic;

      s00_axi_awaddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
      s00_axi_awprot  : in  std_logic_vector(2 downto 0);
      s00_axi_awvalid : in  std_logic;
      s00_axi_awready : out std_logic;

      s00_axi_wdata   : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
      s00_axi_wstrb   : in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
      s00_axi_wvalid  : in  std_logic;
      s00_axi_wready  : out std_logic;

      s00_axi_bresp   : out std_logic_vector(1 downto 0);
      s00_axi_bvalid  : out std_logic;
      s00_axi_bready  : in  std_logic;

      s00_axi_araddr  : in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
      s00_axi_arprot  : in  std_logic_vector(2 downto 0);
      s00_axi_arvalid : in  std_logic;
      s00_axi_arready : out std_logic;

      s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
      s00_axi_rresp   : out std_logic_vector(1 downto 0);
      s00_axi_rvalid  : out std_logic;
      s00_axi_rready  : in  std_logic
    );
  end component;

  constant CLK_PERIOD : time := 10 ns;
  signal clk          : std_logic := '0';

  -- AXI signals
  signal axi_aresetn : std_logic := '0';

  signal axi_awaddr  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal axi_awprot  : std_logic_vector(2 downto 0) := "000";
  signal axi_awvalid : std_logic := '0';
  signal axi_awready : std_logic;

  signal axi_wdata   : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) := (others => '0');
  signal axi_wstrb   : std_logic_vector((AXI_DATA_WIDTH/8)-1 downto 0) := (others => '1');
  signal axi_wvalid  : std_logic := '0';
  signal axi_wready  : std_logic;

  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_bready  : std_logic := '1';

  signal axi_araddr  : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal axi_arprot  : std_logic_vector(2 downto 0) := "000";
  signal axi_arvalid : std_logic := '0';
  signal axi_arready : std_logic;

  signal axi_rdata   : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;
  signal axi_rready  : std_logic := '0';

  -- addr map
  constant ADDR_REG0   : integer := 0*4;
  constant ADDR_REG1   : integer := 1*4;
  constant ADDR_FIFO   : integer := 2*4; -- �������ݐ�iFIFO_A or FIFO_C ��reg0�Őؑցj
  constant ADDR_FIFO_B : integer := 3*4; -- FIFO_B�ǂݏo���i���Ȃ��̐݌v�ɍ��킹�ĕK�v�Ȃ�ύX�j

  constant OUT_WORDS   : integer := 256;

  -- ===== ����/�d�݃t�@�C�� =====
  file file_in_x : text open read_mode is "z_000.txt";
  file file_w1   : text open read_mode is "clean_weight_l1_reordered.txt";
  file file_w2   : text open read_mode is "clean_weight_l2_reordered.txt";
  file file_w3   : text open read_mode is "clean_weight_l3_reordered.txt";
  file file_w4   : text open read_mode is "clean_weight_l4_reordered.txt";

  function s8_to_u8(val : integer) return unsigned is
    variable s : signed(7 downto 0);
  begin
    s := to_signed(val, 8);
    return unsigned(s);
  end function;

  function pack4_u32(b0, b1, b2, b3 : integer) return std_logic_vector is
    variable u : unsigned(31 downto 0);
  begin
    u := s8_to_u8(b0) & s8_to_u8(b1) & s8_to_u8(b2) & s8_to_u8(b3);
    return std_logic_vector(u);
  end function;
  
  function s16_to_u16(val : integer) return unsigned is
    variable s : signed(15 downto 0);
  begin
    s := to_signed(val, 16);
    return unsigned(s);  -- 2の補数ビット列をそのまま扱う
  end function;

  function pack2_u32(c0, c1 : integer) return std_logic_vector is
    variable u : unsigned(31 downto 0);
  begin
    u := s16_to_u16(c0) & s16_to_u16(c1);
    return std_logic_vector(u);
  end function;


  -- -------------------------
  -- REG�p AXI write/read�i���̂܂܁j
  -- -------------------------
  procedure axi_write(
    signal clk     : in  std_logic;
    signal awaddr  : out std_logic_vector;
    signal awvalid : out std_logic;
    signal awready : in  std_logic;
    signal wdata   : out std_logic_vector;
    signal wvalid  : out std_logic;
    signal wready  : in  std_logic;
    signal bvalid  : in  std_logic;
    signal bready  : out std_logic;
    constant addr_i: integer;
    constant data_i: std_logic_vector(31 downto 0)
  ) is
  begin
    awaddr  <= std_logic_vector(to_unsigned(addr_i, awaddr'length));
    awvalid <= '1';
    wdata   <= data_i;
    wvalid  <= '1';
    bready  <= '1';

    loop
      wait until rising_edge(clk);
      exit when awready = '1';
    end loop;

    loop
      wait until rising_edge(clk);
      exit when wready = '1';
    end loop;

    awvalid <= '0';
    wvalid  <= '0';

    loop
      wait until rising_edge(clk);
      exit when bvalid = '1';
    end loop;

    wait until rising_edge(clk);
  end procedure;

  procedure axi_read(
    signal clk     : in  std_logic;
    signal araddr  : out std_logic_vector;
    signal arvalid : out std_logic;
    signal arready : in  std_logic;
    signal rdata   : in  std_logic_vector;
    signal rvalid  : in  std_logic;
    signal rready  : out std_logic;
    constant addr_i: integer;
    variable data_o: out std_logic_vector(31 downto 0)
  ) is
  begin
    araddr  <= std_logic_vector(to_unsigned(addr_i, araddr'length));
    arvalid <= '1';
    rready  <= '1';

    loop
      wait until rising_edge(clk);
      exit when arready = '1';
    end loop;

    arvalid <= '0';

    loop
      wait until rising_edge(clk);
      exit when rvalid = '1';
    end loop;

    data_o := rdata;

    rready <= '0';
    wait until rising_edge(clk);
  end procedure;

begin

  dut: AXI_LITE_source_v1_0
    generic map (
      C_S00_AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      C_S00_AXI_ADDR_WIDTH => AXI_ADDR_WIDTH
    )
    port map (
      s00_axi_aclk    => clk,
      s00_axi_aresetn => axi_aresetn,
      s00_axi_awaddr  => axi_awaddr,
      s00_axi_awprot  => axi_awprot,
      s00_axi_awvalid => axi_awvalid,
      s00_axi_awready => axi_awready,
      s00_axi_wdata   => axi_wdata,
      s00_axi_wstrb   => axi_wstrb,
      s00_axi_wvalid  => axi_wvalid,
      s00_axi_wready  => axi_wready,
      s00_axi_bresp   => axi_bresp,
      s00_axi_bvalid  => axi_bvalid,
      s00_axi_bready  => axi_bready,
      s00_axi_araddr  => axi_araddr,
      s00_axi_arprot  => axi_arprot,
      s00_axi_arvalid => axi_arvalid,
      s00_axi_arready => axi_arready,
      s00_axi_rdata   => axi_rdata,
      s00_axi_rresp   => axi_rresp,
      s00_axi_rvalid  => axi_rvalid,
      s00_axi_rready  => axi_rready
    );

  -- clock
  clk <= not clk after CLK_PERIOD/2;

  -- -------------------------
  -- stimulus
  -- -------------------------
  stim: process
    variable L    : line;
    variable v    : integer;

    type int_arr is array(0 to 99) of integer;
    variable xbuf : int_arr;

    variable rdat  : std_logic_vector(31 downto 0);

    variable ch    : integer;
    variable i     : integer;

    variable data32 : std_logic_vector(31 downto 0);

    -- 4�ǂ��1word���iEOF�Ȃ�0�j
    procedure read4_pack(
      file f         : text;
      variable L     : inout line;
      variable o     : out std_logic_vector(31 downto 0)
    ) is
      variable a0, a1, a2, a3 : integer;
    begin
      if endfile(f) then
        a0 := 0;
      else
        readline(f, L);
        read(L, a0);
      end if;

      if endfile(f) then
        a1 := 0;
      else
        readline(f, L);
        read(L, a1);
      end if;

      if endfile(f) then
        a2 := 0;
      else
        readline(f, L);
        read(L, a2);
      end if;

      if endfile(f) then
        a3 := 0;
      else
        readline(f, L);
        read(L, a3);
      end if;

      o := pack4_u32(a3, a2, a1, a0);
    end procedure;

    -- FIFO�� 1�񂾂����M�iwren��2�񗧂��Ȃ���j
    procedure fifo_write_once(constant d : std_logic_vector(31 downto 0)) is
    begin
      axi_awaddr  <= std_logic_vector(to_unsigned(ADDR_FIFO, AXI_ADDR_WIDTH));
      axi_wdata   <= d;
      axi_awvalid <= '1';
      axi_wvalid  <= '1';
      axi_bready  <= '1';

      loop
        wait until rising_edge(clk);
        exit when (axi_awready='1' and axi_wready='1');
      end loop;

      axi_awvalid <= '0';
      axi_wvalid  <= '0';

      loop
        wait until rising_edge(clk);
        exit when axi_bvalid='1';
      end loop;

      wait until rising_edge(clk);
    end procedure;

    -- ��Layer�v�Z�I���҂��Fbit1 = st_layer_end
    procedure wait_layer_end is
    begin
      loop
        axi_read(
          clk,
          axi_araddr, axi_arvalid, axi_arready,
          axi_rdata,  axi_rvalid,  axi_rready,
          ADDR_REG1,
          rdat
        );
        exit when rdat(1) = '1';
      end loop;
    end procedure;

    -- ��move_done_layer �҂��Fbit2 = move_done_layer
    procedure wait_move_done is
    begin
      loop
        axi_read(
          clk,
          axi_araddr, axi_arvalid, axi_arready,
          axi_rdata,  axi_rvalid,  axi_rready,
          ADDR_REG1,
          rdat
        );
        exit when rdat(2) = '1';
      end loop;
    end procedure;

    -- ��end_all(cal_end) �҂��Fbit0 = end_all
    procedure wait_end_all is
    begin
      loop
        axi_read(
          clk,
          axi_araddr, axi_arvalid, axi_arready,
          axi_rdata,  axi_rvalid,  axi_rready,
          ADDR_REG1,
          rdat
        );
        exit when rdat(0) = '1';
      end loop;
    end procedure;

    -- FIFO_B����1word�ǂ�
    procedure fifo_b_read_once(variable data_o : out std_logic_vector(31 downto 0)) is
    begin
      axi_read(
        clk,
        axi_araddr, axi_arvalid, axi_arready,
        axi_rdata,  axi_rvalid,  axi_rready,
        ADDR_FIFO_B,
        data_o
      );
    end procedure;

    -- FIFO_B OUT_WORDS ��hex�ŕۑ�
    procedure dump_fifo_b_to_file(constant fname : in string) is
      file f_out : text open write_mode is fname;
      variable Lo : line;
      variable w  : std_logic_vector(31 downto 0);
    begin
      for k in 0 to OUT_WORDS-1 loop
        fifo_b_read_once(w);
        write(Lo, string'("0x"));
        hwrite(Lo, w);
        writeline(f_out, Lo);
      end loop;
    end procedure;

  begin
    -- reset
    axi_aresetn <= '0';
    wait for CLK_PERIOD*10;
    axi_aresetn <= '1';
    wait for CLK_PERIOD*5;

    -- mmio.write(0*4, 1)  reset=1
    axi_write(
      clk,
      axi_awaddr, axi_awvalid, axi_awready,
      axi_wdata,  axi_wvalid,  axi_wready,
      axi_bvalid, axi_bready,
      ADDR_REG0,
      std_logic_vector(to_unsigned(1, 32))
    );

    -- read x (100 lines)
    for i in 0 to 99 loop
      if endfile(file_in_x) then
        xbuf(i) := 0;
      else
        readline(file_in_x, L);
        read(L, v);
        xbuf(i) := v;
      end if;
    end loop;

    -- input x: 50word送信（16bit×2/word）
    for i in 0 to 49 loop
      data32 := pack2_u32(
        xbuf(i*2 + 1),
        xbuf(i*2 + 0)
      );
      fifo_write_once(data32);
    end loop;

    -- mmio.write(0*4, 3)
    axi_write(
      clk,
      axi_awaddr, axi_awvalid, axi_awready,
      axi_wdata,  axi_wvalid,  axi_wready,
      axi_bvalid, axi_bready,
      ADDR_REG0,
      std_logic_vector(to_unsigned(3, 32))
    );

    -- wait�i�K���j
    for i in 1 to 1000 loop
      wait for 30 ns;
    end loop;

    -- =========================
    -- Layer1 (toC=5, start=7)
    -- =========================
    for ch in 0 to L1_CH_MAX-1 loop
      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(5, 32))
      );

      for i in 0 to (L1_W_PER_CH/4)-1 loop
        read4_pack(file_w1, L, data32);
        fifo_write_once(data32);
      end loop;

      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(7, 32))
      );

      wait_layer_end; -- bit1
      report "L1 done ch=" & integer'image(ch);
    end loop;

    wait_move_done; -- bit2

    -- =========================
    -- Layer2 (toC=13, start=15)
    -- =========================
    for ch in 0 to L2_CH_MAX-1 loop
      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(13, 32))
      );

      for i in 0 to (L2_W_PER_CH/4)-1 loop
        read4_pack(file_w2, L, data32);
        fifo_write_once(data32);
      end loop;

      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(15, 32))
      );

      wait_layer_end;
      report "L2 done ch=" & integer'image(ch);
    end loop;

    wait_move_done;

    -- =========================
    -- Layer3 (toC=21, start=23)
    -- =========================
    for ch in 0 to L3_CH_MAX-1 loop
      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(21, 32))
      );

      for i in 0 to (L3_W_PER_CH/4)-1 loop
        read4_pack(file_w3, L, data32);
        fifo_write_once(data32);
      end loop;

      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(23, 32))
      );

      wait_layer_end;
      report "L3 done ch=" & integer'image(ch);
    end loop;

    wait_move_done;

    -- =========================
    -- Layer4 (toC=29, start=31)
    -- =========================
    for ch in 0 to L4_CH_MAX-1 loop
      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(29, 32))
      );

      for i in 0 to (L4_W_PER_CH/4)-1 loop
        read4_pack(file_w4, L, data32);
        fifo_write_once(data32);
      end loop;

      axi_write(
        clk, axi_awaddr, axi_awvalid, axi_awready,
        axi_wdata, axi_wvalid, axi_wready,
        axi_bvalid, axi_bready,
        ADDR_REG0,
        std_logic_vector(to_unsigned(31, 32))
      );

      wait_layer_end;
      report "L4 done ch=" & integer'image(ch);
    end loop;

    -- =========================
    -- FIFO_B dump�iend_all�҂���dump�j
    -- =========================
    wait_end_all; -- bit0 = end_all(cal_end)

    dump_fifo_b_to_file("out_fifo_b_hex.txt");
    report "Dumped FIFO_B output to out_fifo_b_hex.txt";

    report "TB finished (L1-L4 + dump).";
    wait;
  end process;

end architecture;
