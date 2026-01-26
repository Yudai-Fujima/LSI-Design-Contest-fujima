library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tanh_q1p7_lut is
  port (
    clk   : in  std_logic;
    x_in  : in  signed(7 downto 0);  -- Q1.7 (-128..127 -> -1.0..1.0)
    y_out : out signed(7 downto 0)   -- Q1.7
  );
end entity;

architecture rtl of tanh_q1p7_lut is
  type lut_t is array (0 to 127) of signed(7 downto 0);
  -- 0.0 ~ 1.0 に対応する tanh 値 (正の側のみ保持し、負は符号反転で対応)
  constant TANH_LUT : lut_t := (
      0 => to_signed(  0, 8),   1 => to_signed(  1, 8),   2 => to_signed(  2, 8),   3 => to_signed(  3, 8),
      4 => to_signed(  4, 8),   5 => to_signed(  5, 8),   6 => to_signed(  6, 8),   7 => to_signed(  7, 8),
      8 => to_signed(  8, 8),   9 => to_signed(  9, 8),  10 => to_signed( 10, 8),  11 => to_signed( 11, 8),
     12 => to_signed( 12, 8),  13 => to_signed( 13, 8),  14 => to_signed( 14, 8),  15 => to_signed( 15, 8),
     16 => to_signed( 16, 8),  17 => to_signed( 17, 8),  18 => to_signed( 18, 8),  19 => to_signed( 19, 8),
     20 => to_signed( 20, 8),  21 => to_signed( 21, 8),  22 => to_signed( 22, 8),  23 => to_signed( 23, 8),
     24 => to_signed( 24, 8),  25 => to_signed( 25, 8),  26 => to_signed( 26, 8),  27 => to_signed( 27, 8),
     28 => to_signed( 28, 8),  29 => to_signed( 29, 8),  30 => to_signed( 29, 8),  31 => to_signed( 30, 8),
     32 => to_signed( 31, 8),  33 => to_signed( 32, 8),  34 => to_signed( 33, 8),  35 => to_signed( 34, 8),
     36 => to_signed( 35, 8),  37 => to_signed( 36, 8),  38 => to_signed( 37, 8),  39 => to_signed( 38, 8),
     40 => to_signed( 39, 8),  41 => to_signed( 40, 8),  42 => to_signed( 41, 8),  43 => to_signed( 41, 8),
     44 => to_signed( 42, 8),  45 => to_signed( 43, 8),  46 => to_signed( 44, 8),  47 => to_signed( 45, 8),
     48 => to_signed( 46, 8),  49 => to_signed( 47, 8),  50 => to_signed( 48, 8),  51 => to_signed( 48, 8),
     52 => to_signed( 49, 8),  53 => to_signed( 50, 8),  54 => to_signed( 51, 8),  55 => to_signed( 52, 8),
     56 => to_signed( 53, 8),  57 => to_signed( 54, 8),  58 => to_signed( 54, 8),  59 => to_signed( 55, 8),
     60 => to_signed( 56, 8),  61 => to_signed( 57, 8),  62 => to_signed( 58, 8),  63 => to_signed( 58, 8),
     64 => to_signed( 59, 8),  65 => to_signed( 60, 8),  66 => to_signed( 61, 8),  67 => to_signed( 61, 8),
     68 => to_signed( 62, 8),  69 => to_signed( 63, 8),  70 => to_signed( 64, 8),  71 => to_signed( 65, 8),
     72 => to_signed( 65, 8),  73 => to_signed( 66, 8),  74 => to_signed( 67, 8),  75 => to_signed( 67, 8),
     76 => to_signed( 68, 8),  77 => to_signed( 69, 8),  78 => to_signed( 70, 8),  79 => to_signed( 70, 8),
     80 => to_signed( 71, 8),  81 => to_signed( 72, 8),  82 => to_signed( 72, 8),  83 => to_signed( 73, 8),
     84 => to_signed( 74, 8),  85 => to_signed( 74, 8),  86 => to_signed( 75, 8),  87 => to_signed( 76, 8),
     88 => to_signed( 76, 8),  89 => to_signed( 77, 8),  90 => to_signed( 78, 8),  91 => to_signed( 78, 8),
     92 => to_signed( 79, 8),  93 => to_signed( 79, 8),  94 => to_signed( 80, 8),  95 => to_signed( 81, 8),
     96 => to_signed( 81, 8),  97 => to_signed( 82, 8),  98 => to_signed( 82, 8),  99 => to_signed( 83, 8),
    100 => to_signed( 84, 8), 101 => to_signed( 84, 8), 102 => to_signed( 85, 8), 103 => to_signed( 85, 8),
    104 => to_signed( 86, 8), 105 => to_signed( 86, 8), 106 => to_signed( 87, 8), 107 => to_signed( 88, 8),
    108 => to_signed( 88, 8), 109 => to_signed( 89, 8), 110 => to_signed( 89, 8), 111 => to_signed( 90, 8),
    112 => to_signed( 90, 8), 113 => to_signed( 91, 8), 114 => to_signed( 91, 8), 115 => to_signed( 92, 8),
    116 => to_signed( 92, 8), 117 => to_signed( 93, 8), 118 => to_signed( 93, 8), 119 => to_signed( 93, 8),
    120 => to_signed( 94, 8), 121 => to_signed( 94, 8), 122 => to_signed( 95, 8), 123 => to_signed( 95, 8),
    124 => to_signed( 96, 8), 125 => to_signed( 96, 8), 126 => to_signed( 97, 8), 127 => to_signed( 97, 8)
  );

  signal y_reg : signed(7 downto 0) := (others => '0');

begin
  process(clk)
    variable abs_val : integer;
    variable idx_v   : integer range 0 to 127;
    variable lut_val : signed(7 downto 0);
    variable sign_m  : std_logic;
    variable x_v     : signed(7 downto 0);
  begin
    if rising_edge(clk) then
      x_v := x_in;
      -- 符号と絶対値を取り出し
      if x_v < to_signed(0, 8) then
        sign_m  := '1';
        abs_val := -to_integer(x_v); -- abs(-128) becomes 128, handled by clamp
      else
        sign_m  := '0';
        abs_val :=  to_integer(x_v);
      end if;

      if abs_val > 127 then
        abs_val := 127;
      end if;

      idx_v := abs_val;
      lut_val := TANH_LUT(idx_v);

      if sign_m = '1' then
        y_reg <= -lut_val;
      else
        y_reg <= lut_val;
      end if;
    end if;
  end process;

  y_out <= y_reg;
end architecture;