library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Output_Serializer is
  generic (
    H_OUT      : integer := 32;
    W_OUT      : integer := 32;
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 8
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    start      : in  std_logic;
    
    -- RAM 読み出しポート
    ram_addr   : out unsigned(ADDR_WIDTH-1 downto 0);
    ram_dout   : in  signed(DATA_WIDTH-1 downto 0);
    
    -- 出力ベクトル
    out_img    : out std_logic_vector((H_OUT*W_OUT*DATA_WIDTH)-1 downto 0);
    done       : out std_logic
  );
end entity;

architecture rtl of Output_Serializer is
  constant TOTAL_PIXELS : integer := H_OUT * W_OUT;
  type state_t is (IDLE, READ_REQ, READ_WAIT_1, READ_WAIT_2, STORE, FINISH);
  signal st : state_t := IDLE;
  
  signal cnt : integer range 0 to TOTAL_PIXELS := 0;
  signal img_reg : std_logic_vector((H_OUT*W_OUT*DATA_WIDTH)-1 downto 0) := (others=>'0');
  
begin

  process(clk, rst)
  begin
    if rst = '1' then
      st <= IDLE;
      cnt <= 0;
      ram_addr <= (others=>'0');
      img_reg <= (others=>'0');
      done <= '0';
    elsif rising_edge(clk) then
      done <= '0';
      
      case st is
        when IDLE =>
          if start = '1' then
            cnt <= 0;
            st <= READ_REQ;
          end if;

        when READ_REQ =>
          if cnt < TOTAL_PIXELS then
            ram_addr <= to_unsigned(cnt, ADDR_WIDTH);
            st <= READ_WAIT_1;
          else
            st <= FINISH;
          end if;

        when READ_WAIT_1 =>
          -- RAM Read Latency
          st <= READ_WAIT_2;

        when READ_WAIT_2 =>
          -- Tanh/Computation Latency
          st <= STORE;

        when STORE =>
          img_reg((cnt+1)*DATA_WIDTH-1 downto cnt*DATA_WIDTH) <= std_logic_vector(ram_dout);
          cnt <= cnt + 1;
          st <= READ_REQ;

        when FINISH =>
          done <= '1';
          if start = '0' then
            st <= IDLE;
          end if;
      end case;
    end if;
  end process;

  out_img <= img_reg;

end architecture;