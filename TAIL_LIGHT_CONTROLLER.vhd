------------------------------------------------------------------------------------------------------------
--  TAIL LIGHT CONTROLLER
------------------------------------------------------------------------------------------------------------
-- This is an entity that controls the intensity and flashing pattern of the left and right LED tail lights of a car depending 
-- on whether the headlights are on/off, the car is braking or not and if either or both of the turn signals are activated. 
-- The appropriate scenario and the corresponding intensity and flashing patternt is determined by the input signals BREAKS,  
-- LIGHTS, LTURN and RTURN. The Pulse Width Modulation (PWM) technique is incorporated here to vary the intensity of the LEDs. 
-- The output signals LEFT and RIGHT are used to generate the flashing of the left and right tail lights respectively.


LIBRARY IEEE;
USE     IEEE.std_logic_1164.all;
USE     IEEE.numeric_std.all;

-------------------------------
ENTITY TAIL_LIGHT_CONTROLLER is
-------------------------------
    GENERIC (	DIVIDE_RATE  : 	natural  := 500; 					-- Master clock divide rate
                FLASH_PERIOD : 	natural  := 3000 ); 				-- Turn signal flash divide rate
    PORT 	 ( 	RESET        : in  	std_logic; 							-- Active high master reset
                CLOCK        : in  	std_logic; 							-- Master clock
                CTRL         : in  	std_logic_vector (3 downto 0); 		-- Control inputs
                LEFT         : out 	std_logic; 							-- Left tail light PWM output
                RIGHT        : out 	std_logic; 							-- Right tail light PWM output
                CYCLE        : out 	std_logic ); 						-- PWM cycle indicator (for testing)
END TAIL_LIGHT_CONTROLLER;

--------------------------------------------
ARCHITECTURE RTL of TAIL_LIGHT_CONTROLLER is
--------------------------------------------
	-- Used in Mster Clock Driver
    SIGNAL    DIV_200KHZ  : natural range 0 to DIVIDE_RATE - 1;
    SIGNAL    ENA_200KHZ  : std_logic;							-- 200K MHz clock enable pulse train
	
	-- Used in PWM Counter
	CONSTANT  RESOLUTION  : natural := 100;
	SIGNAL    PWM_COUNT   : natural range 0 to RESOLUTION - 1;
	SIGNAL    ENA_2KHZ    : std_logic;
	
	-- Used in/related to Turn Sigal Flash Driver
    SIGNAL    FLASH_COUNT : natural range 0 to FLASH_PERIOD - 1;
    SIGNAL    FLASH       : std_logic;                          -- Output of the turn signal flash generator
    SIGNAL    FLASH_ENA   : std_logic;
    
	-- Used in Input Flip-Flop
    SIGNAL    CTRL_F      : std_logic_vector (3 downto 0);      -- Flip-flopped CTRL input
	
	-- Used in Synchronize Block
	SIGNAL 	  TURN_L	  : std_logic;							-- TURN for the left LED control
    SIGNAL    TURN_R	  : std_logic;							-- TURN for the right LED control

    -- Modified control inputs
    SIGNAL    BREAKS	  : std_logic;							-- Flip-flopped CTRL_F(2)
    SIGNAL 	  LIGHTS      : std_logic;							-- Flip-flopped CTRL_F(3)
    SIGNAL 	  LTURN		  : std_logic;							-- Flip-flopped CTRL_F(1)
    SIGNAL    RTURN		  : std_logic;							-- Flip-flopped CTRL_F(0)
	SIGNAL    CTRL_L      : std_logic_vector (3 downto 0);      -- Control inputs for left LED
    SIGNAL    CTRL_R      : std_logic_vector (3 downto 0);      -- Control inputs for right LED

    -- Intensity level 
    SIGNAL    THRESHOLD_L : natural range 0 to 100; 			-- PWM "on" percentage / intensity level for left LED
    SIGNAL    THRESHOLD_R : natural range 0 to 100;				-- PWM "on" percentage / intensity level for right LED	

BEGIN

	--Driving control inputs using flip-flopped CTRL:
    LIGHTS <=  CTRL_F(3);
    BREAKS <=  CTRL_F(2);
    LTURN  <=  CTRL_F(1);
    RTURN  <=  CTRL_F(0);
    
    CTRL_L <= LIGHTS & BREAKS & TURN_L & FLASH;
    CTRL_R <= LIGHTS & BREAKS & TURN_R & FLASH;
    
	-- Lookup table for Left LED Intensity:
    THRESHOLD_L  <= 0	when (CTRL_L = "0000") else
                    0	when (CTRL_L = "0001") else
                    0	when (CTRL_L = "0010") else
                    100	when (CTRL_L = "0011") else
					100	when (CTRL_L = "0100") else
					100	when (CTRL_L = "0101") else
					0	when (CTRL_L = "0110") else
					100	when (CTRL_L = "0111") else
					10  when (CTRL_L = "1000") else
					10  when (CTRL_L = "1001") else
					10  when (CTRL_L = "1010") else
					50  when (CTRL_L = "1011") else
					50  when (CTRL_L = "1100") else
					50  when (CTRL_L = "1101") else
					10  when (CTRL_L = "1110") else
					50  when (CTRL_L = "1111") else
					0 ;
    
	-- Lookup table for Right LED Intensity:	
    THRESHOLD_R  <= 0  	when (CTRL_R = "0000") else
                    0 	when (CTRL_R = "0001") else
                    0 	when (CTRL_R = "0010") else
					100	when (CTRL_R = "0011") else
					100	when (CTRL_R = "0100") else
					100	when (CTRL_R = "0101") else
					0	when (CTRL_R = "0110") else
					100	when (CTRL_R = "0111") else
					10  when (CTRL_R = "1000") else
					10  when (CTRL_R = "1001") else
					10  when (CTRL_R = "1010") else
					50  when (CTRL_R = "1011") else
					50  when (CTRL_R = "1100") else
					50  when (CTRL_R = "1101") else
					10  when (CTRL_R = "1110") else
					50  when (CTRL_R = "1111") else
					0 ;
    

    -- Mster Clock Driver that generates 200 KHz clock enable
    ---------------------------------------------
    ENA_200KHZ_PROCESS: PROCESS (RESET, CLOCK) BEGIN
    ---------------------------------------------
        if (RESET = '1') then
            DIV_200KHZ  <=  0;
            ENA_200KHZ  <= '0';
        elsif (CLOCK'event and CLOCK = '1') then
            if (DIV_200KHZ = 0) then
                DIV_200KHZ  <= DIVIDE_RATE - 1;
                ENA_200KHZ  <= '1';
            else
                DIV_200KHZ  <= DIV_200KHZ - 1;
                ENA_200KHZ  <= '0';
            end if;
        end if;
    end PROCESS;
	
    
    -- PWM Counter that generates 2 KHz clock enable
    ------------------------------------------------
    PWM_COUNTER_PROCESS: PROCESS (RESET, CLOCK) BEGIN
    ------------------------------------------------
        if (RESET = '1') then
            PWM_COUNT  <=  0;
            ENA_2KHZ   <= '0';
            CYCLE      <= '0';     -- CYCLE is first delayed by one clock cycle 
        elsif (CLOCK'event and CLOCK = '1') then
            if (ENA_200KHZ = '0') then
                ENA_2KHZ   <= '0';
            elsif (PWM_COUNT = RESOLUTION - 1) then
                PWM_COUNT  <=  0;
                ENA_2KHZ   <= '1';
            else
                PWM_COUNT  <= PWM_COUNT + 1;
                ENA_2KHZ   <= '0';
            end if;
            CYCLE  <= ENA_2KHZ;    -- CYCLE is then driven by ENA_2KHZ
        end if;
    end PROCESS;
    
    -- FLASH_ENA is drivin using outputs produced by Synchronize Block
    -- It is used to enable the process FLASH_PROCESS
	FLASH_ENA <= LTURN or RTURN or FLASH; 
    
    -- This process generates FLASH_COUNT that is used to drive FLASH
    ------------------------------------------------
    FLASH_PROCESS: PROCESS (RESET, CLOCK) BEGIN
    ------------------------------------------------
        if (RESET = '1') then
            FLASH_COUNT  <=  0;
        elsif (CLOCK'event and CLOCK = '1') then
            if (FLASH_ENA = '0') then              
                FLASH_COUNT  <= 0;          
            elsif (ENA_2KHZ = '1') then
                if (FLASH_COUNT = 0) then
                    FLASH_COUNT  <= FLASH_PERIOD - 1;
                else
                    FLASH_COUNT  <= FLASH_COUNT - 1;
                end if;
            end if;
        end if;
    end PROCESS;
    
    -- FLASH is "on" for the half of the cycle and "off" for the rest half of the cycle
    FLASH <= '1' when (FLASH_COUNT >= FLASH_PERIOD / 2) else '0';
    
    
    -- Input Flip-Flop to clock the input CTRL
    ------------------------------------------------
    INPUT_FF_PROCESS: PROCESS (RESET, CLOCK) BEGIN
    ------------------------------------------------
    	if (RESET = '1') then
            CTRL_F  <= (others => '0');
        elsif (CLOCK'event and CLOCK = '1') then
            if (ENA_2KHZ <= '1') then
                CTRL_F <= CTRL; 
            end if;        
        end if;
    end PROCESS;
    
    
    -- Synchronize Block that produces TURN for both left and right LEDs
    ------------------------------------------------
    synchronize_PROCESS: PROCESS (RESET, CLOCK) BEGIN
    ------------------------------------------------
    	 if (RESET = '1') then
            TURN_L  <= '0';
            TURN_R  <= '0';
        elsif (CLOCK'event and CLOCK = '1') then
            if (FLASH = '0') then 
                TURN_L <= LTURN;
                TURN_R <= RTURN;
            else 
                TURN_L <= LTURN or TURN_L;  --  Allows for delays between LTURN/RTURN for hazards
                TURN_R <= RTURN or TURN_R;
            end if;    
        end if;
    end PROCESS;
        
        
    -- Output Generater / Comparer
    ------------------------------------------------
    OUTPUT_COMP_PROCESS: PROCESS (RESET, CLOCK) BEGIN
    ------------------------------------------------
    	 if (RESET = '1') then
            LEFT   <= '0';
            RIGHT  <= '0';
        elsif (CLOCK'event and CLOCK = '1') then
            if (ENA_2KHZ <= '1') then 
                if (PWM_COUNT < THRESHOLD_L) then   
                    LEFT  <= '1';
                else
                    LEFT  <= '0';  
                end if;
                if (PWM_COUNT < THRESHOLD_R) then
                    RIGHT <= '1';
                else
                    RIGHT <= '0';
                end if;
            end if;
        end if;
    end PROCESS;


END ARCHITECTURE;