library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity multiplier_top is
    generic (
        WIDTH : integer := 8;  -- Default to 8-bit, but can be changed
        RESULT_WIDTH : integer := 16  -- Default result width is 2*WIDTH
    );
    Port( Ny     : in    std_logic_vector(WIDTH-1 downto 0);
          Nx     : in    std_logic_vector(WIDTH-1 downto 0);
          prod   : out   std_logic_vector(RESULT_WIDTH-1 downto 0);
          clk    : in    std_logic;
          reset  : in    std_logic;
          sel    : in    std_logic_vector(1 downto 0)  -- Select which multiplier to use
          );
end multiplier_top;

architecture behavioral of multiplier_top is

    -- Component declarations for all multiplier types
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
    
    component booth_standard
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
    
    component array_multiplier
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
    
    -- Signals for outputs from each multiplier
    signal prod_booth_radix_8 : std_logic_vector(RESULT_WIDTH-1 downto 0);
    signal prod_booth_standard : std_logic_vector(RESULT_WIDTH-1 downto 0);
    signal prod_array : std_logic_vector(RESULT_WIDTH-1 downto 0);
    
    -- Performance counters
    signal cycles_booth_radix_8 : integer := 0;
    signal cycles_booth_standard : integer := 0;
    signal cycles_array : integer := 0;
    
    -- Signals for tracking when each multiplier is done
    signal done_booth_radix_8 : std_logic := '0';
    signal done_booth_standard : std_logic := '0';
    signal done_array : std_logic := '0';

begin

    -- Instantiate all multiplier types
    booth_radix_8_inst : booth_radix_8
    generic map (
        WIDTH => WIDTH,
        RESULT_WIDTH => RESULT_WIDTH
    )
    port map (
        Ny => Ny,
        Nx => Nx,
        prod => prod_booth_radix_8,
        reset => reset,
        clk => clk
    );
    
    booth_standard_inst : booth_standard
    generic map (
        WIDTH => WIDTH,
        RESULT_WIDTH => RESULT_WIDTH
    )
    port map (
        Ny => Ny,
        Nx => Nx,
        prod => prod_booth_standard,
        reset => reset,
        clk => clk
    );
    
    array_multiplier_inst : array_multiplier
    generic map (
        WIDTH => WIDTH,
        RESULT_WIDTH => RESULT_WIDTH
    )
    port map (
        Ny => Ny,
        Nx => Nx,
        prod => prod_array,
        reset => reset,
        clk => clk
    );
    
    -- Multiplexer to select which multiplier output to use
    process(clk, reset)
    begin
        if reset = '1' then
            prod <= (others => '0');
            cycles_booth_radix_8 <= 0;
            cycles_booth_standard <= 0;
            cycles_array <= 0;
            done_booth_radix_8 <= '0';
            done_booth_standard <= '0';
            done_array <= '0';
        elsif rising_edge(clk) then
            -- Select output based on sel input
            case sel is
                when "00" => prod <= prod_booth_radix_8;
                when "01" => prod <= prod_booth_standard;
                when "10" => prod <= prod_array;
                when others => prod <= (others => '0');
            end case;
            
            -- Performance counters
            -- Count cycles until each multiplier produces a result
            -- This is a simplified approach - in a real implementation you would need
            -- proper detection of when each multiplier has completed
            
            -- For Booth Radix-8
            if done_booth_radix_8 = '0' then
                if prod_booth_radix_8 /= (prod_booth_radix_8'range => '0') then
                    done_booth_radix_8 <= '1';
                else
                    cycles_booth_radix_8 <= cycles_booth_radix_8 + 1;
                end if;
            end if;
            
            -- For Standard Booth
            if done_booth_standard = '0' then
                if prod_booth_standard /= (prod_booth_standard'range => '0') then
                    done_booth_standard <= '1';
                else
                    cycles_booth_standard <= cycles_booth_standard + 1;
                end if;
            end if;
            
            -- For Array Multiplier
            if done_array = '0' then
                if prod_array /= (prod_array'range => '0') then
                    done_array <= '1';
                else
                    cycles_array <= cycles_array + 1;
                end if;
            end if;
        end if;
    end process;

end behavioral; 