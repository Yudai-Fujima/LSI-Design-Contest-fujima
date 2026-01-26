library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_w is
  generic (
    DATA_W : integer := 32; -- 16bit
    ADDR_W : integer := 13
  );
  port (
    clk   : in std_logic;
    we    : in std_logic;
    waddr : in unsigned(ADDR_W-1 downto 0);
    din   : in signed(DATA_W-1 downto 0);
    raddr : in unsigned(ADDR_W-1 downto 0);
    dout  : out signed(DATA_W-1 downto 0)
  );
end entity;

architecture rtl of ram_w is
  type mem_t is array (0 to (2**ADDR_W)-1) of signed(DATA_W-1 downto 0);
  signal mem : mem_t := (others => (others => '0'));
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(waddr)) <= din;
      end if;
      dout <= mem(to_integer(raddr));
    end if;
  end process;
end architecture;