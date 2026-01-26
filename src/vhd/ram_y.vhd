library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_y is
  generic (
    DATA_W : integer := 16; -- 16bitに変更
    ADDR_W : integer := 15
  );
  port (
    clk         : in std_logic;
    core_we     : in std_logic;
    core_waddr  : in unsigned(ADDR_W-1 downto 0);
    core_din    : in signed(DATA_W-1 downto 0);
    core_raddr  : in unsigned(ADDR_W-1 downto 0);
    core_dout   : out signed(DATA_W-1 downto 0)
  );
end entity;

architecture rtl of ram_y is
  type mem_t is array (0 to (2**ADDR_W)-1) of signed(DATA_W-1 downto 0);
  signal mem : mem_t := (others => (others => '0'));
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if core_we = '1' then
        mem(to_integer(core_waddr)) <= core_din;
      end if;
      core_dout <= mem(to_integer(core_raddr));
    end if;
  end process;
end architecture;