library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Input_Deserializer is
  generic (
    INPUT_DIM  : integer := 100;
    DATA_WIDTH : integer := 16;  -- ★16bit入力に変更
    ADDR_WIDTH : integer := 15
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    start_x    : in  std_logic;
    x_vec      : in  std_logic_vector(INPUT_DIM*DATA_WIDTH-1 downto 0);
    
    ram_we     : out std_logic;
    ram_addr   : out unsigned(ADDR_WIDTH-1 downto 0);
    ram_din    : out signed(15 downto 0); -- 出力は変換後の16bit
    done       : out std_logic
  );
end entity;

architecture rtl of Input_Deserializer is
  type state_t is (IDLE, WRITE_LOOP, FINISH);
  signal st : state_t := IDLE;
  signal cnt : integer range 0 to INPUT_DIM := 0;

begin
  process(clk, rst)
    variable v_raw : signed(15 downto 0);
  begin
    if rst = '1' then
      st <= IDLE;
      cnt <= 0;
      ram_we <= '0'; 
      ram_addr <= (others=>'0');
      ram_din <= (others=>'0');
      done <= '0';
    elsif rising_edge(clk) then
      ram_we <= '0';
      done <= '0';

      case st is
        when IDLE =>
          if start_x = '1' then
            cnt <= 0;
            st <= WRITE_LOOP;
          end if;

        when WRITE_LOOP =>
          if cnt < INPUT_DIM then
            ram_we <= '1';
            ram_addr <= to_unsigned(cnt, ADDR_WIDTH);
            
            -- ★修正: データ抽出をプロセス内で行い、cnt更新前の値を使う
            v_raw := signed(x_vec((cnt+1)*DATA_WIDTH-1 downto cnt*DATA_WIDTH));
            
            ram_din <= v_raw;
            -- 8bit -> 16bit 変換 & 左シフト1 (x2)
            --ram_din <= shift_left(v_raw, 1);
            
            cnt <= cnt + 1;
          else
            st <= FINISH;
          end if;

        when FINISH =>
          done <= '1';
          if start_x = '0' then st <= IDLE; end if;
      end case;
    end if;
  end process;

end architecture;