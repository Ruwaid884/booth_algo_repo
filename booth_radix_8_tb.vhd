library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;			 

entity tb_booth_radix_8_struct is
    generic (
        WIDTH : integer := 8;  -- Default to 8-bit, but can be changed
        RESULT_WIDTH : integer := 16  -- Default result width is 2*WIDTH
    );
end tb_booth_radix_8_struct;

architecture tb of tb_booth_radix_8_struct is

    component booth_radix_8
        generic (
            WIDTH : integer := 8;
            RESULT_WIDTH : integer := 16
        );
        port (Ny   : in std_logic_vector (WIDTH-1 downto 0);
              Nx   : in std_logic_vector (WIDTH-1 downto 0);
              prod : out std_logic_vector (RESULT_WIDTH-1 downto 0);
              reset: in std_logic;
              clk  : in std_logic);
    end component;

    signal Ny   : std_logic_vector (WIDTH-1 downto 0);
    signal Nx   : std_logic_vector (WIDTH-1 downto 0);
    signal prod : std_logic_vector (RESULT_WIDTH-1 downto 0);
    signal clk  : std_logic;
    signal reset  : std_logic;

    -- Performance metrics
    signal expected_result : std_logic_vector(RESULT_WIDTH-1 downto 0);
    signal error_count : integer := 0;
    signal test_count : integer := 0;
    
    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : booth_radix_8
    generic map (
        WIDTH => WIDTH,
        RESULT_WIDTH => RESULT_WIDTH
    )
    port map (Ny   => Ny,
              Nx   => Nx,
              prod => prod,
              clk  => clk,
              reset => reset);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    -- Performance analysis process
    performance_analysis: process(clk)
    begin
        if rising_edge(clk) and reset = '0' then
            -- Calculate expected result
            expected_result <= std_logic_vector(signed(Nx) * signed(Ny));
            
            -- Check if result matches expected after 2 clock cycles (allowing for pipeline delay)
            if test_count >= 2 then
                if prod /= expected_result then
                    error_count <= error_count + 1;
                    report "Error: Expected " & to_string(to_integer(signed(expected_result))) & 
                           " but got " & to_string(to_integer(signed(prod))) severity warning;
                end if;
            end if;
            
            test_count <= test_count + 1;
        end if;
    end process;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        Ny <= (others => '0');
        Nx <= (others => '0');
        reset <= '1';
        wait for TbPeriod;
        reset <= '0';

        -- Test case 1: 4 * 9
        Ny <= std_logic_vector(to_signed(4, Ny'length));
        Nx <= std_logic_vector(to_signed(9, Nx'length));
        wait for 2*TbPeriod;
        
        -- Test case 2: 6 * 11
        Ny <= std_logic_vector(to_signed(6, Ny'length));
        Nx <= std_logic_vector(to_signed(11, Nx'length));
        wait for 2*TbPeriod;
        
        -- Test case 3: -7 * -12
        Ny <= std_logic_vector(to_signed(-7, Ny'length));
        Nx <= std_logic_vector(to_signed(-12, Nx'length));
        wait for 2*TbPeriod;
        
        -- Test case 4: -18 * 17
        Ny <= std_logic_vector(to_signed(-18, Ny'length));
        Nx <= std_logic_vector(to_signed(17, Nx'length));
        wait for 2*TbPeriod;
        
        -- Test case 5: Maximum positive values
        Ny <= std_logic_vector(to_signed(2**(WIDTH-1)-1, Ny'length));
        Nx <= std_logic_vector(to_signed(2**(WIDTH-1)-1, Nx'length));
        wait for 2*TbPeriod;
        
        -- Test case 6: Maximum negative values
        Ny <= std_logic_vector(to_signed(-2**(WIDTH-1), Ny'length));
        Nx <= std_logic_vector(to_signed(-2**(WIDTH-1), Nx'length));
        wait for 2*TbPeriod;
        
        -- Test case 7: Mixed large values
        Ny <= std_logic_vector(to_signed(2**(WIDTH-1)-1, Ny'length));
        Nx <= std_logic_vector(to_signed(-2**(WIDTH-1), Nx'length));
        wait for 2*TbPeriod;

        -- Report performance metrics
        report "Test completed with " & integer'image(error_count) & " errors out of " & 
               integer'image(test_count-2) & " tests." severity note;

        -- EDIT Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;