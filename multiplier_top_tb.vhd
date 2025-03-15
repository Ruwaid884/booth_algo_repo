library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_multiplier_top is
    generic (
        WIDTH : integer := 8;  -- Default to 8-bit, but can be changed
        RESULT_WIDTH : integer := 16  -- Default result width is 2*WIDTH
    );
end tb_multiplier_top;

architecture tb of tb_multiplier_top is

    component multiplier_top
        generic (
            WIDTH : integer := 8;
            RESULT_WIDTH : integer := 16
        );
        port (Ny   : in std_logic_vector (WIDTH-1 downto 0);
              Nx   : in std_logic_vector (WIDTH-1 downto 0);
              prod : out std_logic_vector (RESULT_WIDTH-1 downto 0);
              reset: in std_logic;
              clk  : in std_logic;
              sel  : in std_logic_vector(1 downto 0));
    end component;

    signal Ny   : std_logic_vector (WIDTH-1 downto 0);
    signal Nx   : std_logic_vector (WIDTH-1 downto 0);
    signal prod : std_logic_vector (RESULT_WIDTH-1 downto 0);
    signal clk  : std_logic;
    signal reset  : std_logic;
    signal sel  : std_logic_vector(1 downto 0);

    -- Performance metrics
    signal expected_result : std_logic_vector(RESULT_WIDTH-1 downto 0);
    signal error_count : integer := 0;
    signal test_count : integer := 0;
    
    -- Timing metrics
    signal start_time : time;
    signal end_time : time;
    signal booth_radix_8_time : time := 0 ns;
    signal booth_standard_time : time := 0 ns;
    signal array_multiplier_time : time := 0 ns;
    
    -- Test case array
    type test_case is record
        a : integer;
        b : integer;
        expected : integer;
    end record;
    
    type test_case_array is array (natural range <>) of test_case;
    
    constant test_cases : test_case_array := (
        (4, 9, 36),
        (6, 11, 66),
        (-7, -12, 84),
        (-18, 17, -306),
        (127, 127, 16129),    -- Maximum positive values for 8-bit
        (-128, -128, 16384),  -- Maximum negative values for 8-bit
        (127, -128, -16256)   -- Mixed large values
    );
    
    constant TbPeriod : time := 10 ns; -- Clock period
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : multiplier_top
    generic map (
        WIDTH => WIDTH,
        RESULT_WIDTH => RESULT_WIDTH
    )
    port map (Ny   => Ny,
              Nx   => Nx,
              prod => prod,
              clk  => clk,
              reset => reset,
              sel  => sel);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    -- Performance analysis process
    performance_analysis: process(clk)
    begin
        if rising_edge(clk) and reset = '0' then
            -- Calculate expected result
            expected_result <= std_logic_vector(signed(Nx) * signed(Ny));
            
            -- Check if result matches expected after appropriate delay
            if test_count >= 5 then  -- Allow time for pipeline to fill
                if prod /= expected_result then
                    error_count <= error_count + 1;
                    report "Error: Expected " & integer'image(to_integer(signed(expected_result))) & 
                           " but got " & integer'image(to_integer(signed(prod))) severity warning;
                end if;
            end if;
            
            test_count <= test_count + 1;
        end if;
    end process;

    -- Stimulus process
    stimuli : process
    begin
        -- Initialize
        Ny <= (others => '0');
        Nx <= (others => '0');
        reset <= '1';
        sel <= "00";  -- Start with Booth Radix-8
        wait for TbPeriod;
        reset <= '0';
        
        -- Test each multiplier with all test cases
        for multiplier_type in 0 to 2 loop
            -- Select multiplier type
            sel <= std_logic_vector(to_unsigned(multiplier_type, 2));
            
            -- Reset performance counters
            test_count <= 0;
            error_count <= 0;
            
            -- Record start time
            start_time := now;
            
            -- Run all test cases
            for i in test_cases'range loop
                Ny <= std_logic_vector(to_signed(test_cases(i).a, WIDTH));
                Nx <= std_logic_vector(to_signed(test_cases(i).b, WIDTH));
                wait for 5*TbPeriod;  -- Allow time for computation
            end loop;
            
            -- Record end time
            end_time := now;
            
            -- Store timing results
            case multiplier_type is
                when 0 => booth_radix_8_time := end_time - start_time;
                when 1 => booth_standard_time := end_time - start_time;
                when 2 => array_multiplier_time := end_time - start_time;
                when others => null;
            end case;
            
            -- Report results for this multiplier
            case multiplier_type is
                when 0 => report "Booth Radix-8 completed in " & time'image(end_time - start_time) & 
                                 " with " & integer'image(error_count) & " errors.";
                when 1 => report "Standard Booth completed in " & time'image(end_time - start_time) & 
                                 " with " & integer'image(error_count) & " errors.";
                when 2 => report "Array Multiplier completed in " & time'image(end_time - start_time) & 
                                 " with " & integer'image(error_count) & " errors.";
                when others => null;
            end case;
            
            -- Reset between multiplier types
            reset <= '1';
            wait for TbPeriod;
            reset <= '0';
        end loop;
        
        -- Final performance comparison
        report "Performance Comparison:";
        report "Booth Radix-8: " & time'image(booth_radix_8_time);
        report "Standard Booth: " & time'image(booth_standard_time);
        report "Array Multiplier: " & time'image(array_multiplier_time);
        
        -- Determine the fastest multiplier
        if booth_radix_8_time <= booth_standard_time and booth_radix_8_time <= array_multiplier_time then
            report "Booth Radix-8 is the fastest multiplier.";
        elsif booth_standard_time <= booth_radix_8_time and booth_standard_time <= array_multiplier_time then
            report "Standard Booth is the fastest multiplier.";
        else
            report "Array Multiplier is the fastest multiplier.";
        end if;
        
        -- End simulation
        wait for 100 * TbPeriod;
        TbSimEnded <= '1';
        wait;
    end process;

end tb; 