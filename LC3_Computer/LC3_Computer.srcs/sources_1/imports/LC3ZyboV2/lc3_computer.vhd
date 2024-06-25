-- This is the component that you'll need to fill in in order to create the LC3 computer.
-- It is FPGA independent. It can be used without any changes between the Zybo and the 
-- Nexys3 boards.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lc3_computer is
   port (
		--System clock
      clk              : in  std_logic; 

      --Virtual I/O
      led              : out std_logic_vector(7 downto 0);
      btn              : in  std_logic_vector(4 downto 0);
      sw               : in  std_logic_vector(7 downto 0);
      hex              : out std_logic_vector(15 downto 0); --16 bit hexadecimal value (shown on 7-seg sisplay)

		--Physical I/0 (IO on the Zybo FPGA)
		pbtn				  : in  std_logic_vector(3 downto 0);
		psw				  : in  std_logic_vector(3 downto 0);
		pled				  : out  std_logic_vector(2 downto 0);

		--VIO serial
      rx_data          : in  std_logic_vector(7 downto 0);
      rx_rd            : out std_logic;
      rx_empty         : in  std_logic;
      tx_data          : out std_logic_vector(7 downto 0);
      tx_wr            : out std_logic;
      tx_full          : in  std_logic;
		
		sink             : out std_logic;

      --Debug
      address_dbg      : out std_logic_vector(15 downto 0);
      data_dbg         : out std_logic_vector(15 downto 0);
      RE_dbg           : out std_logic;
      WE_dbg           : out std_logic;
		
		--LC3 CPU inputs
      cpu_clk_enable   : in  std_logic;
      sys_reset        : in  std_logic;
      sys_program      : in  std_logic;
      
      -- UART
      tx_p             : out std_logic;
      rx_p             : in std_logic
      
   );
end lc3_computer;

architecture Behavioral of lc3_computer is
   ---<<<<<<<<<<<<<<>>>>>>>>>>>>>>>---
   ---<<<<< Pregenerated code >>>>>---
   ---<<<<<<<<<<<<<<>>>>>>>>>>>>>>>---

	--Making	sure	that	our	output	signals	are	not	merged/removed	during	
	-- synthesis. We	achieve	this	by	setting	the keep	attribute for	all	our	outputs
	-- It's good to uncomment the following attributs if you get some errors with multiple 
	-- drivers for a signal.
--	attribute	keep:string;
--	attribute	keep	of	led			: signal	is	"true";
--	attribute	keep	of	pled			: signal	is	"true";
--	attribute	keep	of	hex			: signal	is	"true";
--	attribute	keep	of	rx_rd			: signal	is	"true";
--	attribute	keep	of	tx_data		: signal	is	"true";
--	attribute	keep	of	tx_wr			: signal	is	"true";
--	attribute	keep	of	address_dbg	: signal	is	"true";
--	attribute	keep	of	data_dbg		: signal	is	"true";
--	attribute	keep	of	RE_dbg		: signal	is	"true";
--	attribute	keep	of	WE_dbg		: signal	is	"true";
--	attribute	keep	of	sink			: signal	is	"true";

   --Creating user friently names for the buttons
   alias btn_u : std_logic is btn(0); --Button UP
   alias btn_l : std_logic is btn(1); --Button LEFT
   alias btn_d : std_logic is btn(2); --Button DOWN
   alias btn_r : std_logic is btn(3); --Button RIGHT
   alias btn_s : std_logic is btn(4); --Button SELECT (center button)
   alias btn_c : std_logic is btn(4); --Button CENTER
   
   signal sink_sw : std_logic;
   signal sink_psw : std_logic;
   signal sink_btn : std_logic;
   signal sink_pbtn : std_logic;
	signal sink_uart : std_logic;
   
	-- Memory interface signals
	signal address: std_logic_vector(15 downto 0);
	signal data, data_in, data_out: std_logic_vector(15 downto 0); -- data inputs
	signal RE, WE:  std_logic;


	-- I/O constants for addr from 0xFE00 to 0xFFFF:
   constant STDIN_S    : std_logic_vector(15 downto 0) := X"FE00";  -- Serial IN (terminal keyboard)
   constant STDIN_S_P  : std_logic_vector(15 downto 0) := X"FE01";  -- Serial IN (via UART)
   constant STDIN_D    : std_logic_vector(15 downto 0) := X"FE02";
   constant STDIN_D_P  : std_logic_vector(15 downto 0) := X"FE03"; 
   constant STDOUT_S   : std_logic_vector(15 downto 0) := X"FE04";  -- Serial OUT (terminal  display)
   constant STDOUT_S_P : std_logic_vector(15 downto 0) := X"FE05";
   constant STDOUT_D   : std_logic_vector(15 downto 0) := X"FE06";
   constant STDOUT_D_P : std_logic_vector(15 downto 0) := X"FE07";
	constant IO_SW      : std_logic_vector(15 downto 0) := X"FE0A";  -- Switches
   constant IO_PSW     : std_logic_vector(15 downto 0) := X"FE0B";  -- Physical Switches	
	constant IO_BTN     : std_logic_vector(15 downto 0) := X"FE0e";  -- Buttons
 	constant IO_PBTN    : std_logic_vector(15 downto 0) := X"FE0F";  -- Physical Buttons	
	constant IO_SSEG    : std_logic_vector(15 downto 0) := X"FE12";  -- 7 segment
	constant IO_LED     : std_logic_vector(15 downto 0) := X"FE16";  -- Leds
	constant IO_PLED    : std_logic_vector(15 downto 0) := X"FE17";  -- Physical Leds
	---<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>---
   ---<<<<< End of pregenerated code >>>>>---
   ---<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>---
   
   signal tx_full_p, rx_empty_p: std_logic;
   signal rx_data_p, tx_data_p: std_logic_vector(7 downto 0);
   signal rx_rd_p, tx_wr_p: std_logic;
   
   signal addr_reg: std_logic_vector(15 downto 0);
   
   type t_arr is array (0 to 2**16-1) of std_logic_vector(15 downto 0);
       signal ram: t_arr:=(
   -- Empty Traps/Interrupt Tables
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0000 to 0x0007
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0008 to 0x000f
   X"034b", X"034b", X"035a", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0010 to 0x0017
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0018 to 0x001f
   X"035c", X"0360", X"0366", X"0373", X"0381", X"0300", X"034b", X"034b",  -- addr 0x0020 to 0x0027
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0028 to 0x002f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0030 to 0x0037
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0038 to 0x003f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0040 to 0x0047
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0048 to 0x004f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0050 to 0x0057
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0058 to 0x005f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0060 to 0x0067
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0068 to 0x006f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0070 to 0x0077
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0078 to 0x007f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0080 to 0x0087
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0088 to 0x008f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0090 to 0x0097
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x0098 to 0x009f
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00a0 to 0x00a7
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00a8 to 0x00af
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00b0 to 0x00b7
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00b8 to 0x00bf
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00c0 to 0x00c7
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00c8 to 0x00cf
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00d0 to 0x00d7
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00d8 to 0x00df
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00e0 to 0x00e7
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00e8 to 0x00ef
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00f0 to 0x00f7
   X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b",  -- addr 0x00f8 to 0x00ff
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0100 to 0x0107
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0108 to 0x010f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0110 to 0x0117
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0118 to 0x011f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0120 to 0x0127
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0128 to 0x012f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0130 to 0x0137
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0138 to 0x013f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0140 to 0x0147
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0148 to 0x014f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0150 to 0x0157
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0158 to 0x015f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0160 to 0x0167
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0168 to 0x016f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0170 to 0x0177
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0178 to 0x017f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0180 to 0x0187
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0188 to 0x018f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0190 to 0x0197
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x0198 to 0x019f
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01a0 to 0x01a7
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01a8 to 0x01af
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01b0 to 0x01b7
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01b8 to 0x01bf
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01c0 to 0x01c7
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01c8 to 0x01cf
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01d0 to 0x01d7
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01d8 to 0x01df
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01e0 to 0x01e7
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01e8 to 0x01ef
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351",  -- addr 0x01f0 to 0x01f7
   X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0354", X"0357",  -- addr 0x01f8 to 0x01ff
   X"e00b", X"48d5", X"2007", X"b003", X"2006", X"b002", X"0e27", X"fe16",  -- addr 0x0200 to 0x0207
   X"fe12", X"fe00", X"00ff", X"cccc", X"000a", X"002d", X"002d", X"002d",  -- addr 0x0208 to 0x020f
   X"0020", X"0057", X"0061", X"0069", X"0074", X"0069", X"006e", X"0067",  -- addr 0x0210 to 0x0217
   X"0020", X"0066", X"006f", X"0072", X"0020", X"0070", X"0072", X"006f",  -- addr 0x0218 to 0x021f
   X"0067", X"0072", X"0061", X"006d", X"002e", X"002e", X"002e", X"000a",  -- addr 0x0220 to 0x0227
   X"0000", X"ffe5", X"ffaf", X"ffb9", X"ffab", X"ffad", X"48b1", X"23f9",  -- addr 0x0228 to 0x022f
   X"1001", X"0bfc", X"48ad", X"23f6", X"1201", X"040a", X"23f4", X"1201",  -- addr 0x0230 to 0x0237
   X"0411", X"23f2", X"1201", X"041b", X"23f0", X"1201", X"0477", X"0fee",  -- addr 0x0238 to 0x023f
   X"e002", X"4895", X"0feb", X"0052", X"0065", X"0061", X"0064", X"0079",  -- addr 0x0240 to 0x0247
   X"002e", X"0000", X"489b", X"1820", X"b1bb", X"4898", X"1a20", X"b1b8",  -- addr 0x0248 to 0x024f
   X"bbb7", X"6140", X"489d", X"1b61", X"193f", X"03fa", X"0fd7", X"488e",  -- addr 0x0250 to 0x0257
   X"1820", X"b1ae", X"488b", X"1a20", X"b1ab", X"4888", X"bba9", X"7140",  -- addr 0x0258 to 0x025f
   X"1b61", X"193f", X"03fa", X"e002", X"4872", X"0fc8", X"000a", X"0050",  -- addr 0x0260 to 0x0267
   X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"006d", X"0069",  -- addr 0x0268 to 0x026f
   X"006e", X"0067", X"0020", X"0064", X"006f", X"006e", X"0065", X"002e",  -- addr 0x0270 to 0x0277
   X"000a", X"002d", X"002d", X"002d", X"0020", X"0050", X"0072", X"0065",  -- addr 0x0278 to 0x027f
   X"0073", X"0073", X"0020", X"0072", X"0065", X"0073", X"0065", X"0074",  -- addr 0x0280 to 0x0287
   X"0028", X"0045", X"004e", X"0054", X"0045", X"0052", X"0020", X"0070",  -- addr 0x0288 to 0x028f
   X"0075", X"0073", X"0068", X"002d", X"0062", X"0075", X"0074", X"0074",  -- addr 0x0290 to 0x0297
   X"006f", X"006e", X"0029", X"0020", X"006f", X"0072", X"0020", X"0070",  -- addr 0x0298 to 0x029f
   X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"0020", X"006e",  -- addr 0x02a0 to 0x02a7
   X"0065", X"0078", X"0074", X"0020", X"0062", X"006c", X"006f", X"0063",  -- addr 0x02a8 to 0x02af
   X"006b", X"002e", X"002e", X"002e", X"000a", X"0000", X"5020", X"b14f",  -- addr 0x02b0 to 0x02b7
   X"b14f", X"e003", X"481c", X"482a", X"c000", X"000a", X"004a", X"0075",  -- addr 0x02b8 to 0x02bf
   X"006d", X"0070", X"0069", X"006e", X"0067", X"0020", X"0074", X"006f",  -- addr 0x02c0 to 0x02c7
   X"0020", X"0075", X"0073", X"0065", X"0072", X"0020", X"0063", X"006f",  -- addr 0x02c8 to 0x02cf
   X"0064", X"0065", X"002e", X"000a", X"0000", X"fe04", X"fe06", X"1220",  -- addr 0x02d0 to 0x02d7
   X"6040", X"0405", X"a5fa", X"07fe", X"b1f9", X"1261", X"0ff9", X"c1c0",  -- addr 0x02d8 to 0x02df
   X"2528", X"6080", X"07fe", X"6082", X"c1c0", X"0100", X"2522", X"6080",  -- addr 0x02e0 to 0x02e7
   X"07fe", X"6082", X"6280", X"07fe", X"6282", X"1018", X"1040", X"c1c0",  -- addr 0x02e8 to 0x02ef
   X"a3e4", X"07fe", X"5218", X"b3e2", X"a3e0", X"07fe", X"b1df", X"c1c0",  -- addr 0x02f0 to 0x02f7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x02f8 to 0x02ff
   X"3eff", X"e007", X"f022", X"a0b7", X"22b0", X"5001", X"b0b4", X"2ef8",  -- addr 0x0300 to 0x0307
   X"c1c0", X"000a", X"000a", X"002d", X"002d", X"002d", X"0020", X"0068",  -- addr 0x0308 to 0x030f
   X"0061", X"006c", X"0074", X"0069", X"006e", X"0067", X"0020", X"0074",  -- addr 0x0310 to 0x0317
   X"0068", X"0065", X"0020", X"004c", X"0043", X"002d", X"0033", X"0020",  -- addr 0x0318 to 0x031f
   X"002d", X"002d", X"002d", X"000a", X"000a", X"0000", X"000a", X"000a",  -- addr 0x0320 to 0x0327
   X"002d", X"002d", X"002d", X"0020", X"0075", X"006e", X"0064", X"0065",  -- addr 0x0328 to 0x032f
   X"0066", X"0069", X"006e", X"0065", X"0064", X"0020", X"0074", X"0072",  -- addr 0x0330 to 0x0337
   X"0061", X"0070", X"0020", X"0065", X"0078", X"0065", X"0063", X"0075",  -- addr 0x0338 to 0x033f
   X"0074", X"0065", X"0064", X"0020", X"002d", X"002d", X"002d", X"000a",  -- addr 0x0340 to 0x0347
   X"000a", X"0000", X"eeee", X"21fe", X"b070", X"0fb2", X"e1d7", X"f022",  -- addr 0x0348 to 0x034f
   X"0faf", X"5020", X"103d", X"0ff8", X"5020", X"103e", X"0ff5", X"5020",  -- addr 0x0350 to 0x0357
   X"103f", X"0ff2", X"b062", X"c1c0", X"a05a", X"07fe", X"a059", X"c1c0",  -- addr 0x0358 to 0x035f
   X"32a0", X"a257", X"07fe", X"b056", X"229c", X"c1c0", X"309d", X"329d",  -- addr 0x0360 to 0x0367
   X"3e9f", X"1220", X"6040", X"0403", X"f021", X"1261", X"0ffb", X"2094",  -- addr 0x0368 to 0x036f
   X"2294", X"2e96", X"c1c0", X"328e", X"3e8e", X"e02a", X"f022", X"f020",  -- addr 0x0370 to 0x0377
   X"f021", X"308a", X"5020", X"102a", X"f021", X"2086", X"2283", X"2e83",  -- addr 0x0378 to 0x037f
   X"c1c0", X"3082", X"3282", X"3482", X"3682", X"3e82", X"1220", X"6440",  -- addr 0x0380 to 0x0387
   X"202d", X"5002", X"040f", X"f021", X"5020", X"1628", X"1000", X"14a0",  -- addr 0x0388 to 0x038f
   X"0601", X"1021", X"1482", X"16ff", X"03f9", X"1020", X"0403", X"f021",  -- addr 0x0390 to 0x0397
   X"1261", X"0fed", X"2069", X"2269", X"2469", X"2669", X"2e69", X"c1c0",  -- addr 0x0398 to 0x039f
   X"000a", X"0049", X"006e", X"0070", X"0075", X"0074", X"0020", X"0061",  -- addr 0x03a0 to 0x03a7
   X"0020", X"0063", X"0068", X"0061", X"0072", X"0061", X"0063", X"0074",  -- addr 0x03a8 to 0x03af
   X"0065", X"0072", X"003e", X"0020", X"0000", X"7fff", X"00ff", X"fe00",  -- addr 0x03b0 to 0x03b7
   X"fe02", X"fe04", X"fe06", X"fffe", X"fe10", X"fe12", X"0000", X"0000",  -- addr 0x03b8 to 0x03bf
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03c0 to 0x03c7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03c8 to 0x03cf
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03d0 to 0x03d7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03d8 to 0x03df
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03e0 to 0x03e7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03e8 to 0x03ef
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03f0 to 0x03f7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x03f8 to 0x03ff
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0400 to 0x0407
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0408 to 0x040f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0410 to 0x0417
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0418 to 0x041f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0420 to 0x0427
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0428 to 0x042f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0430 to 0x0437
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0438 to 0x043f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0440 to 0x0447
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0448 to 0x044f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0450 to 0x0457
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0458 to 0x045f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0460 to 0x0467
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0468 to 0x046f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0470 to 0x0477
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0478 to 0x047f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0480 to 0x0487
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0488 to 0x048f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0490 to 0x0497
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x0498 to 0x049f
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04a0 to 0x04a7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04a8 to 0x04af
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04b0 to 0x04b7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04b8 to 0x04bf
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04c0 to 0x04c7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04c8 to 0x04cf
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04d0 to 0x04d7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04d8 to 0x04df
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04e0 to 0x04e7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04e8 to 0x04ef
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04f0 to 0x04f7
   X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000",  -- addr 0x04f8 to 0x04ff
X"481c", X"5260", X"4839", X"e4d6", X"1681", X"64c0", X"2815", X"1884",  -- addr 0x0500 to 0x0507
   X"080c", X"4855", X"4888", X"1480", X"74c0", X"1261", X"20ca", X"903f",  -- addr 0x0508 to 0x050f
   X"1021", X"1001", X"0801", X"5260", X"0fed", X"5020", X"103f", X"48a6",  -- addr 0x0510 to 0x0517
   X"48a5", X"1060", X"48a3", X"0fe4", X"ff9c", X"3e3c", X"4885", X"1020",  -- addr 0x0518 to 0x051f
   X"0814", X"0217", X"e0b7", X"7201", X"1021", X"14bf", X"03fc", X"20b1",  -- addr 0x0520 to 0x0527
   X"22ae", X"1400", X"1482", X"1482", X"1480", X"1480", X"94bf", X"14a1",  -- addr 0x0528 to 0x052f
   X"20a6", X"1480", X"34a4", X"2e26", X"c1c0", X"903f", X"1021", X"1220",  -- addr 0x0530 to 0x0537
   X"0fe5", X"1420", X"349e", X"0fe2", X"3218", X"3418", X"3e1b", X"4864",  -- addr 0x0538 to 0x053f
   X"1020", X"0206", X"040e", X"e292", X"1240", X"6040", X"4877", X"0ff7",  -- addr 0x0540 to 0x0547
   X"228e", X"248e", X"9ebf", X"1fe1", X"1247", X"7040", X"14a1", X"3488",  -- addr 0x0548 to 0x054f
   X"0fee", X"2203", X"2403", X"2e06", X"c1c0", X"0000", X"0000", X"0000",  -- addr 0x0550 to 0x0557
   X"0000", X"0000", X"0000", X"fe02", X"fe00", X"fe0b", X"fe12", X"3ffa",  -- addr 0x0558 to 0x055f
   X"33f4", X"35f4", X"37f4", X"39f4", X"3bf4", X"5260", X"2871", X"993f",  -- addr 0x0560 to 0x0567
   X"1921", X"21f3", X"5028", X"05fd", X"1037", X"4850", X"1029", X"1021",  -- addr 0x0568 to 0x056f
   X"1240", X"1644", X"0203", X"1244", X"1644", X"03fd", X"967f", X"16e1",  -- addr 0x0570 to 0x0577
   X"16c5", X"66c0", X"b7e3", X"25e1", X"14a0", X"03f1", X"103f", X"1240",  -- addr 0x0578 to 0x057f
   X"0203", X"1244", X"1644", X"03fd", X"967f", X"16e1", X"16c5", X"66c0",  -- addr 0x0580 to 0x0587
   X"b7d5", X"10e0", X"1440", X"03f2", X"2fcd", X"23c7", X"25c7", X"27c7",  -- addr 0x0588 to 0x058f
   X"29c7", X"2bc7", X"c1c0", X"3222", X"3422", X"3622", X"223f", X"263f",  -- addr 0x0590 to 0x0597
   X"96ff", X"16ff", X"6440", X"7040", X"10a0", X"127f", X"1443", X"03fa",  -- addr 0x0598 to 0x059f
   X"2215", X"2415", X"2615", X"c1c0", X"3211", X"21b6", X"07fe", X"23b3",  -- addr 0x05a0 to 0x05a7
   X"1241", X"1241", X"1241", X"1241", X"1241", X"1241", X"1241", X"1241",  -- addr 0x05a8 to 0x05af
   X"21ab", X"07fe", X"21a8", X"1001", X"2201", X"c1c0", X"0000", X"0000",  -- addr 0x05b0 to 0x05b7
   X"0000", X"0000", X"fe06", X"fe04", X"00ff", X"0100", X"33f7", X"35f7",  -- addr 0x05b8 to 0x05bf
   X"37f7", X"39f7", X"25fa", X"5920", X"1921", X"5202", X"1904", X"1482",  -- addr 0x05c0 to 0x05c7
   X"0bfc", X"27f1", X"07fe", X"33ee", X"25ef", X"5202", X"27ec", X"07fe",  -- addr 0x05c8 to 0x05cf
   X"33e9", X"23e4", X"25e4", X"27e4", X"29e4", X"c1c0", X"dfff", X"dfff",  -- addr 0x05d0 to 0x05d7
   X"0000", X"0000", X"0000",  -- addr 0x05d8 to 0x05db
   others => X"0000"

);
	
	
begin
  ---<<<<<<<<<<<<<<>>>>>>>>>>>>>>>---
   ---<<<<< Pregenerated code >>>>>---
   ---<<<<<<<<<<<<<<>>>>>>>>>>>>>>>--- 
   
   --In order to avoid warnings or errors all outputs should be assigned a value. 
   --The VHDL lines below assign a value to each otput signal. An otput signal can have
   --only one driver, so each otput signal that you plan to use in your own VHDL code
   --should be commented out in the lines below 

   
   --Virtual Leds on Zybo VIO (active high)
--   led(0) <= '0';
--   led(1) <= '0';
--   led(2) <= '0'; 
--   led(3) <= '0'; 
--   led(4) <= '0'; 
--   led(5) <= '0'; 
--   led(6) <= '0'; 
--   led(7) <= '0'; 

   --Physical leds on the Zybo board (active high)
  -- pled(0) <= '0';
  -- pled(1) <= '0';
   --pled(2) <= '0';

   --Virtual hexadecimal display on Zybo VIO
   --hex <= X"1234"; 

	--Virtual I/O UART
	--rx_rd <= '0';
	--tx_wr <= '0';
	--tx_data <= X"00";
	
	--Input data for the LC3 CPU
	--data_in <= X"0000";

   --All the input signals comming to the FPGA should be used at least once otherwise we get 
   --synthesis warnings. The following lines of VHDL code are meant to remove those warnings. 
   --Sink is just an output signal that that has the only purpose to allow all the inputs to 
   --be used at least once, by orring them and assigning the resulting the value to sink.
   --You are not suppoosed to modify the following lines of VHDL code, where inputs are orred and
   --assigned to the sink. 
   sink_psw <= psw(0) or psw(1) or psw(2) or psw(3);
   sink_pbtn <= pbtn(0) or pbtn(1) or pbtn(2) or pbtn(3);
   sink_sw <= sw(0) or sw(1) or sw(2) or sw(3) or sw(4) or sw(5) or sw(6) or sw(7); 
   sink_btn <= btn(0) or btn(1) or btn(2) or btn(3) or btn(4);
	sink_uart <= rx_data(0) or rx_data(1) or rx_data(2) or rx_data(3) or rx_data(4) or 
					 rx_data(5) or rx_data(6) or rx_data(7)or rx_empty or tx_full;
   sink <= sink_sw or sink_psw or sink_btn or sink_pbtn or sink_uart;

   ---<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>---
   ---<<<<< End of pregenerated code >>>>>---
   ---<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>---
	
	--You'll have to decide which type of data bus you need to use for the
	--  LC3 processor. Here are the options:
	-- 1. Bidirectional data bus (to which you write using tristates).
	-- 2. Two unidirctional busses data_in and data_out where you use
	--    multiplexors to dicide where the data for data_in is comming for.
	--The VHDL code that instantiate either one of these options for the LC3
	--  processor are provided below. Just uncomment the one you prefer
	
	-- <<< LC3 CPU using multiplexers for the data bus>>>	
	lc3_m: entity work.lc3_wrapper_multiplexers
	port map (
		 clk        => clk,
		 clk_enable => cpu_clk_enable,
		 reset      => sys_reset,
		 program    => sys_program,
		 addr       => address,
		 data_in    => data_in,
		 data_out   => data_out,
		 WE         => WE,
		 RE         => RE
		 );
   data_dbg <= data_in when RE='1' else data_out;
	-- <<< LC3 CPU using multiplexers end of instantiation>>>	
	
		 
--	-- <<< LC3 CPU using tristates for the data bus>>>
--	lc3_t: entity work.lc3_wrapper_tristates
--	port map (
--		 clk        => clk,
--		 clk_enable => cpu_clk_enable,
--		 reset      => sys_reset,
--		 program    => sys_program,
--		 addr       => address,
--		 data       => data,
--		 WE         => WE,
--		 RE         => RE 
--		 );
--   data_dbg <= data;
--	-- <<< LC3 CPU using tristates end of instantiation>>>
	
	--Information that is sent to the debugging module
   address_dbg <= address;
   RE_dbg <= RE;
   WE_dbg <= WE;
   
	-------------------------------------------------------------------------------
	-- <<< Write your VHDL code starting from here >>>
	-------------------------------------------------------------------------------
	uart_unit: entity work.uart(str_arch)
          port map(clk=>clk, 
                   reset=>sys_reset, 
                   rd_uart=>rx_rd_p,
                   wr_uart=>tx_wr_p, 
                   rx=>rx_p, 
                   w_data=>tx_data_p,
                   tx_full=>tx_full_p, 
                   rx_empty=>rx_empty_p,
                   r_data=>rx_data_p, 
                   tx=>tx_p);
	
	
	
	rx_rd <= '1' when address = STDIN_D and RE = '1' else
	         '0';
	tx_wr <= '1' when address = STDOUT_D and WE = '1' else
	         '0';
	rx_rd_p <= '1' when address = STDIN_D_P and RE = '1' else
             '0';
    tx_wr_p <= '1' when address = STDOUT_D_P and WE = '1' else
             '0';
	
	
	process(clk)
    begin
        if(clk'event and clk = '1') then
            if(WE = '1') then
                case address is
                    when IO_SSEG => hex  <= data_out;
                    when IO_LED  => led  <= data_out(7 downto 0);
                    when IO_PLED => pled <= data_out(2 downto 0);
                    when others => ram(to_integer(unsigned(address))) <= data_out;
                end case;
            end if;
            addr_reg <= address;
        end if;
    end process;
    
    tx_data <= data_out(7 downto 0);
    tx_data_p <= data_out(7 downto 0);
    
    data_in <= "00000000"     & SW   when addr_reg = IO_SW   else
               "000000000000" & PSW  when addr_reg = IO_PSW  else
               "00000000000"  & BTN  when addr_reg = IO_BTN  else
               "000000000000" & PBTN when addr_reg = IO_PBTN else
               X"00"          & rx_data when addr_reg = STDIN_D else
               not rx_empty & "000" & X"000" when addr_reg = STDIN_S else
               not tx_full  & "000" & X"000" when addr_reg = STDOUT_S else
               not rx_empty_p & "000" & X"000" when addr_reg = STDIN_S_P else
               not tx_full_p  & "000" & X"000" when addr_reg = STDOUT_S_P else
               X"00"          & rx_data_p when addr_reg = STDIN_D_P else
               ram(to_integer(unsigned(addr_reg)));
end Behavioral;