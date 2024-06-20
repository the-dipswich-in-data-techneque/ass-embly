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
      sys_program      : in  std_logic
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
   constant STDIN_D    : std_logic_vector(15 downto 0) := X"FE02";
   constant STDOUT_S   : std_logic_vector(15 downto 0) := X"FE04";  -- Serial OUT (terminal  display)
   constant STDOUT_D   : std_logic_vector(15 downto 0) := X"FE06";
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
   
   signal addr_reg: std_logic_vector(15 downto 0);
   
   type t_arr is array (0 to 2**16-1) of std_logic_vector(15 downto 0);
       signal ram: t_arr:=(
   -- Empty Traps/Interrupt Tables
        X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"035a", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"035c", X"0360", X"0366", X"0373", X"037f", X"0300", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"034b", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0351", X"0354", X"0357", X"e00b", X"48d5", X"2007", X"b003", X"2006", X"b002", X"0e27", X"fe16", X"fe12", X"fe00", X"00ff", X"cccc", X"000a", X"002d", X"002d", X"002d", X"0020", X"0057", X"0061", X"0069", X"0074", X"0069", X"006e", X"0067", X"0020", X"0066", X"006f", X"0072", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"002e", X"002e", X"002e", X"000a", X"0000", X"ffe5", X"ffaf", X"ffb9", X"ffab", X"ffad", X"48b1", X"23f9", X"1001", X"0bfc", X"48ad", X"23f6", X"1201", X"040a", X"23f4", X"1201", X"0411", X"23f2", X"1201", X"041b", X"23f0", X"1201", X"0477", X"0fee", X"e002", X"4895", X"0feb", X"0052", X"0065", X"0061", X"0064", X"0079", X"002e", X"0000", X"489b", X"1820", X"b1bb", X"4898", X"1a20", X"b1b8", X"bbb7", X"6140", X"489d", X"1b61", X"193f", X"03fa", X"0fd7", X"488e", X"1820", X"b1ae", X"488b", X"1a20", X"b1ab", X"4888", X"bba9", X"7140", X"1b61", X"193f", X"03fa", X"e002", X"4872", X"0fc8", X"000a", X"0050", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"006d", X"0069", X"006e", X"0067", X"0020", X"0064", X"006f", X"006e", X"0065", X"002e", X"000a", X"002d", X"002d", X"002d", X"0020", X"0050", X"0072", X"0065", X"0073", X"0073", X"0020", X"0072", X"0065", X"0073", X"0065", X"0074", X"0028", X"0045", X"004e", X"0054", X"0045", X"0052", X"0020", X"0070", X"0075", X"0073", X"0068", X"002d", X"0062", X"0075", X"0074", X"0074", X"006f", X"006e", X"0029", X"0020", X"006f", X"0072", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"0020", X"006e", X"0065", X"0078", X"0074", X"0020", X"0062", X"006c", X"006f", X"0063", X"006b", X"002e", X"002e", X"002e", X"000a", X"0000", X"5020", X"b14f", X"b14f", X"e003", X"481c", X"482a", X"c000", X"000a", X"004a", X"0075", X"006d", X"0070", X"0069", X"006e", X"0067", X"0020", X"0074", X"006f", X"0020", X"0075", X"0073", X"0065", X"0072", X"0020", X"0063", X"006f", X"0064", X"0065", X"002e", X"000a", X"0000", X"fe04", X"fe06", X"1220", X"6040", X"0405", X"a5fa", X"07fe", X"b1f9", X"1261", X"0ff9", X"c1c0", X"2528", X"6080", X"07fe", X"6082", X"c1c0", X"0100", X"2522", X"6080", X"07fe", X"6082", X"6280", X"07fe", X"6282", X"1018", X"1040", X"c1c0", X"a3e4", X"07fe", X"5218", X"b3e2", X"a3e0", X"07fe", X"b1df", X"c1c0", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"3eff", X"e007", X"f022", X"a0b5", X"22ae", X"5001", X"b0b2", X"2ef8", X"c1c0", X"000a", X"000a", X"002d", X"002d", X"002d", X"0020", X"0068", X"0061", X"006c", X"0074", X"0069", X"006e", X"0067", X"0020", X"0074", X"0068", X"0065", X"0020", X"004c", X"0043", X"002d", X"0033", X"0020", X"002d", X"002d", X"002d", X"000a", X"000a", X"0000", X"000a", X"000a", X"002d", X"002d", X"002d", X"0020", X"0075", X"006e", X"0064", X"0065", X"0066", X"0069", X"006e", X"0065", X"0064", X"0020", X"0074", X"0072", X"0061", X"0070", X"0020", X"0065", X"0078", X"0065", X"0063", X"0075", X"0074", X"0065", X"0064", X"0020", X"002d", X"002d", X"002d", X"000a", X"000a", X"0000", X"eeee", X"21fe", X"b06e", X"0fb2", X"e1d7", X"f022", X"0faf", X"5020", X"103d", X"0ff8", X"5020", X"103e", X"0ff5", X"5020", X"103f", X"0ff2", X"b060", X"c1c0", X"a058", X"07fe", X"a057", X"c1c0", X"32a0", X"a255", X"07fe", X"b054", X"229c", X"c1c0", X"309c", X"329c", X"3e9e", X"1220", X"6040", X"0403", X"f021", X"1261", X"0ffb", X"2093", X"2293", X"2e95", X"c1c0", X"3e8e", X"e029", X"f022", X"f020", X"f021", X"308a", X"5020", X"102a", X"f021", X"2086", X"2e84", X"c1c0", X"3083", X"3283", X"3483", X"3683", X"3e83", X"1220", X"6440", X"202d", X"5002", X"040f", X"f021", X"5020", X"1628", X"1000", X"14a0", X"0601", X"1021", X"1482", X"16ff", X"03f9", X"1020", X"0403", X"f021", X"1261", X"0fed", X"206a", X"226a", X"246a", X"266a", X"2e6a", X"c1c0", X"000a", X"0049", X"006e", X"0070", X"0075", X"0074", X"0020", X"0061", X"0020", X"0063", X"0068", X"0061", X"0072", X"0061", X"0063", X"0074", X"0065", X"0072", X"003e", X"0020", X"0000", X"7fff", X"00ff", X"fe00", X"fe02", X"fe04", X"fe06", X"fffe", X"fe10", X"fe12", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"e004", X"f022", X"2001", X"c000", X"0916", X"000a", X"0020", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0054", X"0068", X"0069", X"0073", X"0020", X"0075", X"0073", X"0065", X"0072", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"0020", X"0064", X"006f", X"0065", X"0073", X"006e", X"0027", X"0074", X"0020", X"0064", X"006f", X"0020", X"0061", X"006e", X"0079", X"0074", X"0068", X"0069", X"006e", X"0067", X"0020", X"0069", X"006e", X"0074", X"0065", X"0072", X"0065", X"0073", X"0074", X"0069", X"006e", X"0067", X"002e", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0059", X"006f", X"0075", X"0020", X"0073", X"0068", X"006f", X"0075", X"006c", X"0064", X"0020", X"0074", X"0072", X"0079", X"0020", X"0074", X"006f", X"0020", X"0075", X"0070", X"006c", X"006f", X"0061", X"0064", X"0020", X"0079", X"006f", X"0075", X"0072", X"0020", X"006f", X"0077", X"006e", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"003a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0031", X"002e", X"0020", X"0043", X"006f", X"006d", X"0070", X"0069", X"006c", X"0065", X"0020", X"0079", X"006f", X"0075", X"0072", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"0020", X"0028", X"0070", X"0072", X"006f", X"0064", X"0075", X"0063", X"0065", X"0020", X"002e", X"006f", X"0062", X"006a", X"0020", X"0066", X"0069", X"006c", X"0065", X"0029", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"005b", X"006f", X"0070", X"0074", X"0069", X"006f", X"006e", X"0031", X"005d", X"0020", X"0055", X"0073", X"0065", X"0020", X"004c", X"0043", X"0033", X"0045", X"0064", X"0069", X"0074", X"002e", X"0065", X"0078", X"0065", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"005b", X"006f", X"0070", X"0074", X"0069", X"006f", X"006e", X"0032", X"005d", X"0020", X"0055", X"0073", X"0065", X"0020", X"004c", X"0043", X"0033", X"0020", X"0063", X"006f", X"006d", X"006d", X"0061", X"006e", X"0064", X"0020", X"006c", X"0069", X"006e", X"0065", X"0020", X"0061", X"0073", X"0073", X"0065", X"006d", X"0062", X"006c", X"0065", X"0072", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"006c", X"0063", X"0033", X"0061", X"0073", X"0020", X"0061", X"0073", X"006d", X"005f", X"0073", X"006f", X"0075", X"0072", X"0063", X"0065", X"002e", X"0061", X"0073", X"006d", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"005b", X"006f", X"0070", X"0074", X"0069", X"006f", X"006e", X"0033", X"005d", X"0020", X"0043", X"006f", X"006d", X"0070", X"0069", X"006c", X"0065", X"0020", X"0043", X"0020", X"0073", X"006f", X"0075", X"0072", X"0063", X"0065", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"006c", X"0063", X"0063", X"0020", X"002d", X"006f", X"0020", X"0063", X"005f", X"0073", X"006f", X"0075", X"0072", X"0063", X"0065", X"002e", X"006f", X"0062", X"006a", X"0020", X"0063", X"005f", X"0073", X"006f", X"0075", X"0072", X"0063", X"0065", X"002e", X"0063", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0032", X"002e", X"0020", X"0041", X"0063", X"0074", X"0069", X"0076", X"0061", X"0074", X"0065", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"006d", X"0065", X"0072", X"0020", X"006f", X"006e", X"0020", X"0046", X"0050", X"0047", X"0041", X"0020", X"0028", X"0070", X"0075", X"0073", X"0068", X"0020", X"0060", X"004c", X"0045", X"0046", X"0054", X"0027", X"0020", X"0070", X"0075", X"0073", X"0068", X"002d", X"0062", X"0075", X"0074", X"0074", X"006f", X"006e", X"0029", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0033", X"002e", X"0020", X"0052", X"0069", X"0067", X"0068", X"0074", X"0020", X"0063", X"006c", X"0069", X"0063", X"006b", X"0020", X"006f", X"006e", X"0020", X"002e", X"006f", X"0062", X"006a", X"0020", X"0066", X"0069", X"006c", X"0065", X"0020", X"0061", X"006e", X"0064", X"0020", X"0073", X"0065", X"006c", X"0065", X"0063", X"0074", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0043", X"003a", X"005c", X"006c", X"0063", X"0033", X"005c", X"0062", X"0069", X"006e", X"005c", X"004c", X"0043", X"0033", X"0054", X"0065", X"0072", X"006d", X"0069", X"006e", X"0061", X"006c", X"002e", X"0065", X"0078", X"0065", X"0020", X"0069", X"006e", X"0020", X"0022", X"004f", X"0070", X"0065", X"006e", X"0020", X"0077", X"0069", X"0074", X"0068", X"0022", X"0020", X"0064", X"0069", X"0061", X"006c", X"006f", X"0067", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0034", X"002e", X"0020", X"0057", X"0061", X"0069", X"0074", X"0020", X"0066", X"006f", X"0072", X"0020", X"0070", X"0072", X"006f", X"0067", X"0072", X"0061", X"006d", X"006d", X"0069", X"006e", X"0067", X"0020", X"0074", X"006f", X"0020", X"0066", X"0069", X"006e", X"0069", X"0073", X"0068", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0020", X"0054", X"0068", X"0065", X"0020", X"0049", X"002f", X"004f", X"0020", X"0062", X"006f", X"0061", X"0072", X"0064", X"0020", X"006c", X"0065", X"0064", X"0073", X"0020", X"0077", X"0069", X"006c", X"006c", X"0020", X"0067", X"006f", X"0020", X"006f", X"0066", X"0066", X"0020", X"0061", X"006e", X"0064", X"0020", X"006d", X"0065", X"0073", X"0073", X"0061", X"0067", X"0065", X"0020", X"0077", X"0069", X"006c", X"006c", X"0020", X"0061", X"0070", X"0070", X"0065", X"0061", X"0072", X"002e", X"0020", X"0020", X"002a", X"000a", X"0020", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"002a", X"000a", X"000a", X"0000", X"004b", X"0065", X"0079", X"0020", X"0070", X"0072", X"0065", X"0073", X"0073", X"0065", X"0064", X"003a", X"0020", X"005b", X"0020", X"005d", X"000a", X"0000", X"e3ed", X"e5fe", X"14bc", X"f020", X"7080", X"1060", X"f022", X"0ffb",
	   others => x"0000"
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
   led(0) <= '0';
   led(1) <= '0';
   led(2) <= '0'; 
   led(3) <= '0'; 
   led(4) <= '0'; 
   led(5) <= '0'; 
   led(6) <= '0'; 
   led(7) <= '0'; 

   --Physical leds on the Zybo board (active high)
   pled(0) <= '0';
   pled(1) <= '0';
   pled(2) <= '0';

   --Virtual hexadecimal display on Zybo VIO
   hex <= X"1234"; 

	--Virtual I/O UART
	rx_rd <= '0';
	tx_wr <= '0';
	tx_data <= X"00";
	
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
   process (clk,address)
   begin
    if(address < x"e000" and clk'event and clk = '1') then
        if WE='1' then
            ram(to_integer(unsigned(address)))<=data_out;
            end if;
        addr_reg<=address;
        end if;
            if(address >= x"e000" and clk'event and clk = '1') then
                case address is
                when IO_SW =>
                if (RE = '1') then
                    data_in(7 downto 0) <= sw;
                    data_in(15 downto 8) <= x"00";
                end if;
                when IO_BTN =>
                 if (RE = '1') then
                    data_in(4 downto 0) <= btn;
                    data_in(15 downto 5) <= "00000000000";
                end if;
                when IO_SSEG =>
                 if (WE = '1') then
                    hex <= data_out;
                end if;
                if(RE = '1') then
                    data_in <= x"0000";
                end if;
                when IO_LED =>
                 if (WE = '1') then
                    led <= data_out(7 downto 0);
                end if;
                if(RE = '1') then
                    data_in <= x"0000";
                end if;
                when STDIN_S =>
                 if (RE = '1') then
                    data_in(15) <= not rx_empty;
                    data_in(14 downto 0) <= "000000000000000";
                end if;
                when STDIN_D =>
                    if(RE = '1') then
                        data_in <= rx_data;
                    end if;
                when STDOUT_S =>
                 if (RE = '1') then
                    data_in(15) <= not tx_full;
                    data_in(14 downto 0) <= "000000000000000";
                end if;
                when STDOUT_D =>
                if(WE = '1') then
                    tx_data <= data_out;
                end if;
                when others =>
                if(RE = '1') then
                    data_in <= x"0000";
                end if;
                end case;
            end if;
            if (addr_reg < x"e000" and address < x"e000") then
            data_in<=ram(to_integer(unsigned(addr_reg)));
            end if;
        end process;

end Behavioral;

