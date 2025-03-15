library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity array_multiplier is
    generic (
        WIDTH : integer := 8;  -- Default to 8-bit, but can be changed
        RESULT_WIDTH : integer := 16  -- Default result width is 2*WIDTH
    );
    Port( Ny     : in    std_logic_vector(WIDTH-1 downto 0);
          Nx     : in    std_logic_vector(WIDTH-1 downto 0);
          prod   : out   std_logic_vector(RESULT_WIDTH-1 downto 0);
          clk    : in    std_logic;
          reset  : in    std_logic
          );
end array_multiplier;

architecture behavioral of array_multiplier is

    COMPONENT FA -- Full Adder
        PORT(
        x , y , ci : IN STD_LOGIC ;
        s , co : OUT STD_LOGIC 
        );
    END COMPONENT;
    
    COMPONENT HA -- Half Adder
        PORT(
        x , y  : IN STD_LOGIC ;
        s , c : OUT STD_LOGIC 
        );
    END COMPONENT;

    -- Define a type for the partial product array
    type pp_array is array (0 to WIDTH-1) of std_logic_vector(WIDTH-1 downto 0);
    
    -- Define a type for the carry array
    type carry_array is array (0 to WIDTH-1) of std_logic_vector(WIDTH-1 downto 0);
    
    -- Define a type for the sum array
    type sum_array is array (0 to WIDTH-1) of std_logic_vector(WIDTH-1 downto 0);
    
    -- Signals for array multiplier
    signal partial_products : pp_array := (others => (others => '0'));
    signal carries : carry_array := (others => (others => '0'));
    signal sums : sum_array := (others => (others => '0'));
    signal result_reg : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others => '0');

begin

    -- Array multiplier implementation
    process(clk, reset)
    begin
        if reset = '1' then
            partial_products <= (others => (others => '0'));
            carries <= (others => (others => '0'));
            sums <= (others => (others => '0'));
            result_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Generate partial products
            for i in 0 to WIDTH-1 loop
                for j in 0 to WIDTH-1 loop
                    partial_products(i)(j) <= Nx(j) and Ny(i);
                end loop;
            end loop;
            
            -- First row is special (no carry-in)
            sums(0)(0) <= partial_products(0)(0);
            for j in 1 to WIDTH-1 loop
                -- Half adder for first row
                sums(0)(j) <= partial_products(0)(j) xor partial_products(1)(j-1);
                carries(0)(j) <= partial_products(0)(j) and partial_products(1)(j-1);
            end loop;
            
            -- Middle rows use full adders
            for i in 1 to WIDTH-2 loop
                -- First column of each row
                sums(i)(0) <= partial_products(i)(0);
                
                -- Middle columns use full adders
                for j in 1 to WIDTH-1 loop
                    if j < WIDTH-1 then
                        -- Full adder
                        sums(i)(j) <= partial_products(i+1)(j-1) xor sums(i-1)(j+1) xor carries(i-1)(j);
                        carries(i)(j) <= (partial_products(i+1)(j-1) and sums(i-1)(j+1)) or
                                        (partial_products(i+1)(j-1) and carries(i-1)(j)) or
                                        (sums(i-1)(j+1) and carries(i-1)(j));
                    else
                        -- Last column of each row
                        sums(i)(j) <= sums(i-1)(j+1) xor carries(i-1)(j);
                        carries(i)(j) <= sums(i-1)(j+1) and carries(i-1)(j);
                    end if;
                end loop;
            end loop;
            
            -- Assemble the final result
            -- Lower bits come directly from the sums
            for i in 0 to WIDTH-1 loop
                result_reg(i) <= sums(i)(0);
            end loop;
            
            -- Upper bits come from the last row
            for j in 1 to WIDTH-1 loop
                result_reg(WIDTH-1+j) <= sums(WIDTH-2)(j);
            end loop;
            
            -- Assign to output
            prod <= result_reg;
        end if;
    end process;

end behavioral; 