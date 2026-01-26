library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity AXI_LITE_source_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end AXI_LITE_source_v1_0_S00_AXI;

architecture Behavioral of AXI_LITE_source_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	-------------------------------------------------------
    --state_machine L q    
    -------------------------------------------------------
    component state_machine is
    
    port (clk : in std_logic;
          srst : in std_logic;
          start : in std_logic;
          start_input_data_control : out std_logic;
          end_input_data_control : in std_logic;
          start_decoder : out std_logic := '0';
          end_decoder : in std_logic;
          start_output_data_control : out std_logic;
          end_output_data_control : in std_logic;
          state : out std_logic_vector(3 downto 0)
          );
    end component; 
    
    signal start_input_data_control : std_logic;
    signal end_input_data_control : std_logic;
    signal start_decoder : std_logic:= '0';
    signal end_decoder : std_logic;
    signal start_output_data_control : std_logic;
    signal end_output_data_control : std_logic;
    signal state : std_logic_vector(3 downto 0);
	
	--------------------------------------------------
	----fifo L q    
	--------------------------------------------------
	component fifo is
	   generic(
	       WIDTH : integer := 32;
	       DEPTH : integer := 256);--     ??   `
	       
	   port(
	       clk : in std_logic;
	       srst : in std_logic;
	       full : out std_logic;
	       din : in std_logic_vector(WIDTH - 1 downto 0);
	       wr_en : in std_logic;
	       empty : out std_logic;
	       dout : out std_logic_vector(WIDTH - 1 downto 0);
	       rd_en : in std_logic
	       );
    end component;
    
    signal srst : std_logic;
    -------------------------------------------------------
    --full  empty V O i   B g        ?g   ?B
    -------------------------------------------------------
    signal full_a : std_logic;--fifo_a  full signal
    signal empty_a : std_logic;--fifo_a  empty signal
    signal full_b : std_logic;--fifo_b  full signal
    signal empty_b : std_logic;--fifo_b  empty signal
    signal full_c : std_logic;--fifo_b  full signal
    signal empty_c : std_logic;--fifo_b  empty signal
    -------------------------------------------------------
    --   o  fifo  enable M   ?f [ ^ B
    -------------------------------------------------------
    signal wren_a : std_logic;
    signal rden_a : std_logic;--fifo_a ???       signal.      ? H    ??o       ^ C ~   O ?A T [ g B
    signal dout_a : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);--fifo_a ???o   f [ ^ B     H ??  ?B     ? H ??  B
    signal wren_b : std_logic;--fifo_b ?      ?   signal.      ? H   ?     ?    ^ C ~   O ?A T [ g B
    signal rden_b : std_logic;
    signal din_b : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);----fifo_b ?      ?f [ ^ B     H    ?o ?B     ? H ??  B
    signal dout_b : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal wren_c : std_logic;
    signal rden_c : std_logic;--fifo_c ???       signal.      ? H    ??o       ^ C ~   O ?A T [ g B
    signal dout_c : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);--fifo_c ???o   f [ ^ B     H ??  ?B     ? H ??  B
    signal wren : std_logic;--wren_a, wren_c ?O g
    
    -- === FIFO params (���R�ɕς�����) ===
    -- W�͂߂�ǂ�������32bit�Œ�ɂ���
    -- FIFO_A, x��8bit���Z�ō쐬
    constant FIFO_A_W : integer := 32;
    constant FIFO_A_D : integer := 64; -- 2�̔{���ɂ���
    
    constant FIFO_C_W : integer := 32;
    constant FIFO_C_D : integer := 4096;
    
    constant FIFO_B_W : integer := 32;
    constant FIFO_B_D : integer := 256;
    
    
     -------------------------------------------------------
    --input_data_control L q    
    -------------------------------------------------------
    constant Input_DATA_con_DEPTH : integer := 50;
    
    component input_data_control is
    
    generic(
	       WIDTH : integer := 32;
	       DEPTH : integer := 50);
    port (clk : in std_logic;
          srst : in std_logic;
          din_input_data_control : in std_logic_vector(WIDTH-1 downto 0);--fifo    o ?   input_data_control ?   M  
          start_input_data_control : in std_logic;     --input_data_control   f [ ^        ??
          end_input_data_control : out std_logic;
          dout_input_data_control : out std_logic_vector(WIDTH * DEPTH -1 downto 0)   -- ??   ? f [ ^
          );
    end component; 
    
    signal din_input_data_control : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal dout_input_data_control : std_logic_vector(FIFO_A_W * Input_DATA_con_DEPTH -1 downto 0);
    
    -------------------------------------------------------
    --output_data_control L q    
    -------------------------------------------------------
    
    component output_data_control is
    
    generic(
	       WIDTH : integer := 32;
	       DEPTH : integer := 256);
    port (clk : in std_logic;
          srst : in std_logic;
          din_output_data_control : in std_logic_vector(WIDTH * DEPTH-1 downto 0);
          dout_output_data_control : out std_logic_vector(WIDTH - 1 downto 0);
          start_output_data_control : in std_logic;
          end_output_data_control : out std_logic;
          flag_output : out std_logic
          );
    end component; 
    
    signal din_output_data_control : std_logic_vector(C_S_AXI_DATA_WIDTH * FIFO_B_D -1 downto 0);
    signal dout_output_data_control : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal flag_output : std_logic;
    
    
    --------------------------------------------------------------------------------
    ----    calculation part
    --------------------------------------------------------------------------------
    component top_module is
    generic (
      SHIFT_Q : integer := 8);
    port (
      clk        : in std_logic;
      rst        : in std_logic;
      -- �ʐM����M��
      start_x       : in std_logic;
      start_w       : in std_logic;
      state_cal : in std_logic_vector(1 downto 0);
      end_cal_1out : out std_logic;
      end_move : out std_logic;
      end_all       : out std_logic;
      -- ���o�̓f�[�^
      x        : in std_logic_vector((100*16)-1 downto 0);
      w        : in std_logic_vector(31 downto 0);
      out_img : out std_logic_vector((32*32*8)-1 downto 0)
    );
    end component;
    
    signal start_x : std_logic;
    signal start_w : std_logic;
    signal state_cal : std_logic_vector(1 downto 0);
    signal end_cal_1out : std_logic;
    signal end_move : std_logic;
    signal end_all : std_logic;
    signal x_in : std_logic_vector((100*16)-1 downto 0);
    signal w_in : std_logic_vector(32-1 downto 0);
    signal out_img : std_logic_vector((32*32*8)-1 downto 0);
    
--    constant CALCULATION_DIN : integer := 512;--   ? ?    ?K v ?? 
--    constant CALCULATION_DOUT : integer := 12288;--        
    
--    signal din_calculation : std_logic_vector(CALCULATION_DIN -1 downto 0);
--    signal dout_calculation : std_logic_vector(CALCULATION_DOUT -1 downto 0);

    --     ? 
    
    signal myreset : std_logic;
    signal start : std_logic;
    signal sel_fifo : std_logic;
    signal layer_id : std_logic_vector(1 downto 0);
    signal layercal_end : std_logic;
    signal cal_end : std_logic;
    signal st_layer_end : std_logic;
    signal move_done_layer : std_logic;
    
    signal start_d : std_logic;
    signal start_p : std_logic;
    
    -- start_w��rden_c�J�n�ŗ��Ă�1CLK�x�点�č~�낷�Ƃ����M������邽�߂̓����M��
    signal rden_c_d : std_logic;
    signal use_delay : std_logic;
    
	---- Number of Slave Registers 4
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0 <= (others => '0');
	      slv_reg1 <= (others => '0');
	      slv_reg2 <= (others => '0');
	      slv_reg3 <= (others => '0');
	      wren <= '0';
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"00" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	                wren <= '0';
	              end if;
	            end loop;
	          when b"01" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	                wren <= '0';
	              end if;
	            end loop;
	          when b"10" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	                wren <= '1';
	              end if;
	            end loop;
	          when b"11" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	                wren <= '0';
	              end if;
	            end loop;
	          when others =>
	            slv_reg0 <= slv_reg0;
	            slv_reg1 <= slv_reg1;
	            slv_reg2 <= slv_reg2;
	            slv_reg3 <= slv_reg3;
	            wren <= '0';
	        end case;
	      else
	        wren <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	--process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr, S_AXI_ARESETN, slv_reg_wren, slv_reg_rden)
	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr, S_AXI_ARESETN, slv_reg_wren, slv_reg_rden, cal_end, st_layer_end, move_done_layer)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"00" =>
	        reg_data_out <= slv_reg0;
	        rden_b <= '0';
	      when b"01" =>
	        -- reg_data_out <= std_logic_vector(to_unsigned(0, C_S_AXI_DATA_WIDTH - 1)) & cal_end;
	        reg_data_out <= (others => '0');
            reg_data_out(0) <= cal_end;
            reg_data_out(1) <= st_layer_end;
            reg_data_out(2) <= move_done_layer;
            rden_b <= '0';
	      when b"10" =>
	        reg_data_out <= slv_reg2;
	        rden_b <= '0';
	      when b"11" =>
	        reg_data_out <= dout_b;
	        rden_b <= slv_reg_rden;
	      when others =>
	        reg_data_out  <= (others => '0');
	        rden_b <= '0';
	    end case;
	end process; 


    axi_rdata <= reg_data_out;


	-- Add user logic here
	--      ??      ? ?  ?          y B ??  ?    ?  ???      B	
	
	-- �ǂ������������̂��B�B�B
    srst <= not S_AXI_ARESETN or not myreset;
    -- srst <= not S_AXI_ARESETN or myreset;
    
    ------------------------------
    --fifo_a(CPU    ?  ? ?     fifo)
    ------------------------------
    fifo_a : entity work.fifo
	generic map(
	       WIDTH => FIFO_A_W,
	       DEPTH => FIFO_A_D)
	       
	port map (
	       clk => S_AXI_ACLK,
	       srst => srst,
	       din => S_AXI_WDATA,
	       wr_en => wren_a,
	       empty => empty_a,
	       full => full_a,
	       dout => dout_a,
	       rd_en => rden_a
	       );
	       
	 ------------------------------
    --fifo_c(CPU    ?  ? ?     fifo)
    ------------------------------
    fifo_c : entity work.fifo
	generic map(
	       WIDTH => FIFO_C_W,
	       DEPTH => FIFO_C_D)
	       
	port map (
	       clk => S_AXI_ACLK,
	       srst => srst,
	       din => S_AXI_WDATA,
	       wr_en => wren_c,
	       empty => empty_c,
	       full => full_c,
	       dout => dout_c,
	       rd_en => rden_c
	       );
	       
	------------------------------
	--INPUT_DATA_CONTROL
	------------------------------
	input_data:input_data_control
	generic map(
	   WIDTH => FIFO_A_W,
	   DEPTH => Input_DATA_con_DEPTH)
	
	port map (
	   clk => S_AXI_ACLK,
       srst => srst,
       din_input_data_control => din_input_data_control,
       start_input_data_control => start_input_data_control,
       end_input_data_control => end_input_data_control, -- 
       dout_input_data_control => dout_input_data_control
	);

    ------------------------------
	--OUTPUT_DATA_CONTROL
	------------------------------
    output_data:output_data_control
    generic map(
       WIDTH => FIFO_B_W,
	   DEPTH => FIFO_B_D)
    
    port map(
       clk => S_AXI_ACLK,
       srst  => srst,
       din_output_data_control => din_output_data_control,
       dout_output_data_control => dout_output_data_control,
       start_output_data_control => start_output_data_control,
       end_output_data_control => end_output_data_control,
       flag_output => flag_output
    );

	
    
    ------------------------------
    --fifo_b(CPU ??o ? ?     fifo)
    ------------------------------       
    --        fifo_b  depth  2^n ?l ???   ,  i [   ? ?   FIFO_B_DEPTH     ? ?   2^n ?       ,    ?   , full M    1 ??  ?   ? 
	fifo_b : entity work.fifo
	generic map(
	       WIDTH => FIFO_B_W,
	       DEPTH => FIFO_B_D)
	       
	port map (
	       clk => S_AXI_ACLK,
	       srst => srst,
	       din => din_b,
	       wr_en => wren_b,
	       empty => empty_b,
	       full => full_b,
	       dout => dout_b,
	       rd_en => rden_b
	       );
	--------------------------------------------------
	--     H ?K v ?L q ?  ?     ???? ??
	--------------------------------------------------
	
	myreset <= slv_reg0(0);
	start <= slv_reg0(1);
	sel_fifo <= slv_reg0(2);
	layer_id <= slv_reg0(4 downto 3);
	
	slv_reg1(0) <= cal_end;
    slv_reg1(1) <= st_layer_end;
    slv_reg1(2) <= move_done_layer;
	slv_reg1(31 downto 3) <= (others => '0');
	
	calculation : top_module
    generic map(
            SHIFT_Q => 8)
    port map(
          clk => S_AXI_ACLK,
          rst => srst,
          -- �ʐM����M��
          start_x => start_x,
          start_w => start_w,
          state_cal => layer_id,
          end_cal_1out => end_cal_1out,
          end_move => end_move,
          end_all => end_all,
          -- ���o�̓f�[�^
          x => x_in,
          w => w_in,
          out_img => out_img 
    );
	
	-- CPU������̌v�Z�J�n�M��start�Ɉˑ�
	-- FIFO A �̃��[�h�G�l�C�u���ƌv�Z��H�̌v�Z�J�n�����֐��ł����HFIFO A�����^���̎��X�^�[�g�̕�����������
	-- rden_a, rden_c�͂����܂�FIFO���̃X�^�[�g�A�v�Z����delay�ł����
	rden_a <= start and not empty_a and (not sel_fifo);
	rden_c <= start and not empty_c and sel_fifo;
	
	-- FIFO_B�����^���ɂȂ�����PS���̑҂����I������
	cal_end <= full_b;
	
	-- �����M���̔z���ɂ��Ă͈ȉ��ɋL�q����
	--FIFO A, FIFO C�̕���
	wren_a <= wren and not(sel_fifo);
	wren_c <= wren and sel_fifo;
	-- FIFO A, FIO C��input datacontrol
	din_input_data_control <= dout_a;
	-- start_input_data_control <= rden_a; --full_a��rden_a��
	process(S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        start_input_data_control <= rden_a;   -- ������1�T�C�N���x���
      end if;
    end process;
	-- input datacontrol�ƌv�Z��H
	x_in <= dout_input_data_control;
	w_in <= dout_c;
	start_x <= end_input_data_control;
	-- start_w���쐬
    start_w <= rden_c_d or rden_c;
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            rden_c_d <= rden_c;
        end if;
    end process;
	-- �v�Z��H��output datacontrol
	din_output_data_control <= out_img;
	start_output_data_control <= end_all;
	-- output datacontrol��FIFO B
    din_b <= dout_output_data_control;
        -- FIFO B ��full�łȂ����v�Z���ɏ������ރf�[�^��������
	wren_b <= flag_output and not(full_b);
    
    -- �P�񂲂Ƃ̃p�����[�^�v�Z���I���������Ƃ������M��
	--layercal_end <= end_cal_1out;
	-- User logic ends
	
	-- 1�w���Ƃ̌v�Z�I����ǂ߂�悤�ɂ���i�ǂݍ��ނ܂�end�ێ��j
	process(S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        if srst='1' then
          st_layer_end <= '0';
          move_done_layer <= '0';
        else
          if end_cal_1out='1' then
            st_layer_end <= '1';
          elsif st_layer_end='1' and wren_c='1' then
            st_layer_end <= '0';
          end if;
    
          if end_move='1' then
            move_done_layer <= '1';
          elsif move_done_layer='1' and wren_c='1' then
            move_done_layer <= '0';
          end if;
        end if;
      end if;
    end process;
    
end Behavioral;
