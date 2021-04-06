----------------------------------------------------------------------------------------------------
--            _   _ _______  ____   ______        _  _      _____ ____   ____    _                --
--           | \ | | ____\ \/ /\ \ / / ___|      | || |    |  ___|  _ \ / ___|  / \               --
--           |  \| |  _|  \  /  \ V /\___ \ _____| || |_   | |_  | |_) | |  _  / _ \              --
--           | |\  | |___ /  \   | |  ___) |_____|__   _|  |  _| |  __/| |_| |/ ___ \             --
--           |_| \_|_____/_/\_\  |_| |____/         |_|    |_|   |_|    \____/_/   \_\            --
--                   ____                          ____                      _                    --
--                  |  _ \  ___ _ __ ___   ___    | __ )  ___   __ _ _ __ __| |                   --
--                  | | | |/ _ \ '_ ` _ \ / _ \   |  _ \ / _ \ / _` | '__/ _` |                   --
--                  | |_| |  __/ | | | | | (_) |  | |_) | (_) | (_| | | | (_| |                   --
--                  |____/ \___|_| |_| |_|\___/   |____/ \___/ \__,_|_|  \__,_|                   --
--                          __        __                                                          --
--                          \ \      / / __ __ _ _ __  _ __   ___ _ __                            --
--                           \ \ /\ / / '__/ _` | '_ \| '_ \ / _ \ '__|                           --
--                            \ V  V /| | | (_| | |_) | |_) |  __/ |                              --
--                             \_/\_/ |_|  \__,_| .__/| .__/ \___|_|                              --
--                                              |_|   |_|                                         --
----------------------------------------------------------------------------------------------------
--  NEXYS-4 FPGA Demo Board Wrapper                                                               --
----------------------------------------------------------------------------------------------------
--
--  This file contains a wrapper for the Nexys-4 FPGA demo board from Digilent.  The unused port
--  signals have been commented out, as has the connections of those ports to the internal circuitry.
--  Any port that requires a driven output (due to how the signal is connected on the board) has
--  not been commented out and the signal has been tied to its inactive state.

library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.

--library UNISIM;
--use UNISIM.VComponents.all;

------------------------
entity NEXYS4_WRAPPER is
------------------------
   port ( CLK_I         : in    std_logic;
          RSTN_I        : in    std_logic;

--        BTNL_I        : in    std_logic;                       --  Push-buttons
--        BTNC_I        : in    std_logic;
--        BTNR_I        : in    std_logic;
--        BTND_I        : in    std_logic;
--        BTNU_I        : in    std_logic;
          SW_I          : in    std_logic_vector (15 downto 0);  --  Switches

          DISP_SEG_O    : out   std_logic_vector (1 to 8);       --  7-segment display segments
          DISP_AN_O     : out   std_logic_vector (1 to 8);       --  7-segment display digits
          LED_O         : out   std_logic_vector (15 downto 0);  --  LEDs
          RGB1_RED_O    : out   std_logic;                       --  RGB LEDs
--        RGB1_GREEN_O  : out   std_logic;
--        RGB1_BLUE_O   : out   std_logic;
          RGB2_RED_O    : out   std_logic;
--        RGB2_GREEN_O  : out   std_logic;
--        RGB2_BLUE_O   : out   std_logic;

--        VGA_HS_O      : out   std_logic;                       --  VGA display
--        VGA_VS_O      : out   std_logic;
--        VGA_RED_O     : out   std_logic_vector  (3 downto 0);
--        VGA_BLUE_O    : out   std_logic_vector  (3 downto 0);
--        VGA_GREEN_O   : out   std_logic_vector  (3 downto 0);

--        TMP_SCL       : inout std_logic;                       --  Temperature sensor
--        TMP_SDA       : inout std_logic;
--        TMP_INT       : in    std_logic;
--        TMP_CT        : in    std_logic;

          PDM_CLK_O     : out   std_logic;                       --  PDM microphone
          PDM_DATA_I    : in    std_logic;
          PDM_LRSEL_O   : out   std_logic;

          PWM_AUDIO_O   : out   std_logic;                       --  PWM audio
          PWM_SDAUDIO_O : out   std_logic;

          ACL_SCLK      : out   std_logic;                       --  SPI Interface signals for the ADXL362 accelerometer
          ACL_CSN       : out   std_logic;
          ACL_MOSI      : out   std_logic;
          ACL_MISO      : in    std_logic;
          ACL_INT1      : in    std_logic;
          ACL_INT2      : in    std_logic;

          PS2_CLK       : inout std_logic;                       --  PS2 interface
          PS2_DATA      : inout std_logic;

          MEM_A         : out   std_logic_vector (22 downto 0);  --  Cellular RAM
          MEM_DQ        : inout std_logic_vector (15 downto 0);
          MEM_CEN       : out   std_logic;
          MEM_OEN       : out   std_logic;
          MEM_WEN       : out   std_logic;
          MEM_UB        : out   std_logic;
          MEM_LB        : out   std_logic;
          MEM_ADV       : out   std_logic;
          MEM_CLK       : out   std_logic;
          MEM_CRE       : out   std_logic;
          MEM_WAIT      : in    std_logic );
end NEXYS4_WRAPPER;

-------------------------------------
architecture RTL of NEXYS4_WRAPPER is
-------------------------------------

-------------------------------------------------------------------------------
--  Component Declarations
-------------------------------------------------------------------------------
  COMPONENT TAIL_LIGHT_CONTROLLER is
    GENERIC (	DIVIDE_RATE 	: natural := 500; 			-- Master clock divide rate
				FLASH_PERIOD 	: natural := 3000 ); 		-- Turn signal flash divide rate
				
    PORT    ( 	RESET : in  std_logic; 						-- Active high master reset
				CLOCK : in  std_logic; 						-- Master clock
				CTRL  : in  std_logic_vector (3 downto 0); 	-- Control inputs
				LEFT  : out std_logic; 						-- Left tail light PWM output
				RIGHT : out std_logic; 						-- Right tail light PWM output
				CYCLE : out std_logic                   ); 	-- PWM cycle indicator (for testing)
  END COMPONENT;
  
-------------------------------------------------------------------------------
--  Signal Declarations
-------------------------------------------------------------------------------
    signal RST_I       : std_logic;
	signal LEFT  	   : std_logic;
	signal RIGHT       : std_logic;
	signal CTRL        : std_logic_vector (3 downto 0);

begin

-------------------------------------------------------------------------------
--  Circuitry is defined here
-------------------------------------------------------------------------------
  UUT:  TAIL_LIGHT_CONTROLLER
    generic map ( DIVIDE_RATE 	=> 500, 					-- Master clock divide rate
			      FLASH_PERIOD  => 3000 ) 			    -- Turn signal flash divide rate  
    port map    ( RESET         => RST_I,
                  CLOCK         => CLK_I,
                  CTRL          => CTRL,
                  LEFT          => LEFT,
                  RIGHT         => RIGHT,
                  CYCLE         => open            );

-------------------------------------------------------------------------------
--  Connect the internal FPGA signals to the Digilent demo board interface pins
-------------------------------------------------------------------------------
--  Signals marked with a (*) can be left undefined if unused

--             <= CLK_I;
    RST_I <= not RSTN_I;  --  Pin is active low

--  The push buttons are tied to ground on the board through 10k resistors (*)

--              <= BTNL_I;
--              <= BTNC_I;
--              <= BTNR_I;
--              <= BTND_I;
--              <= BTNU_I;

--  The switches are tied to either ground (down) or +3.3V (up) (*)

	CTRL       <= SW_I(3 downto 0);

--  The LED outputs should be tied to their inactive state if unused

  DISP_SEG_O    <= (8 => '1', others => '0');  --  LED segment data is active low
  DISP_AN_O     <= (1 to 3 => not LEFT,
					6 to 8 => not RIGHT,
					others => '1');  --  LED digit select is active low
  LED_O         <= (3 => CTRL(3),
					2 => CTRL(2),
					1 => CTRL(1),
					0 => CTRL(0),
					others => '0');

--  The RGB LEDs are tied to ground on the board through 2.2k resistors (*)

RGB1_RED_O    <= RIGHT;
--RGB1_GREEN_O  <= '0';
--RGB1_BLUE_O   <= '0';
RGB2_RED_O    <= LEFT;
--RGB2_GREEN_O  <= '0';
--RGB2_BLUE_O   <= '0';

--  The VGA lines are connected to the DB15F connector (*)

--VGA_HS_O      <= '0';
--VGA_VS_O      <= '0';
--VGA_RED_O     <= (others => '0');
--VGA_BLUE_O    <= (others => '0');
--VGA_GREEN_O   <= (others => '0');

--  The temperature sensor inputs are tied to +3.3V via 1k resistors (*)

--TMP_SCL       <= '1';
--TMP_SDA       <= '1';
--              <= TMP_INT;
--              <= TMP_CT;

--  The microphone inputs should be tied to their inactive state if unused

  PDM_CLK_O     <= '0';
--              <= PDM_DATA_I;
  PDM_LRSEL_O   <= '0';

--  The PWM audio inputs should be tied to their inactive state if unused

  PWM_AUDIO_O   <= '0';
  PWM_SDAUDIO_O <= '0';

--  The accelerometer signals should be tied to their inactive state if unused

  ACL_SCLK      <= '0';
  ACL_CSN       <= '1';
  ACL_MOSI      <= '0';
--              <= ACL_MISO;
--              <= ACL_INT1;
--              <= ACL_INT2;

--  The PS2 interface should be tied to their inactive state if unused

  PS2_CLK       <= '1';
  PS2_DATA      <= '1';

--  The RAM interface control signals are tied to their inactive state on the board through 1k resistors
--  However, the address and data lines are not; therefore, they should be tied to their inactive state if unused

  MEM_A         <= (others => '0');
  MEM_DQ        <= (others => '0');
  MEM_CEN       <= '1';
  MEM_OEN       <= '1';
  MEM_WEN       <= '1';
  MEM_UB        <= '1';
  MEM_LB        <= '1';
  MEM_ADV       <= '1';
  MEM_CLK       <= '0';
  MEM_CRE       <= '0';
--              <= MEM_WAIT;

end RTL;