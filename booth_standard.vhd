library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity booth_standard is
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
end booth_standard;

architecture behavioral of booth_standard is

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

    -- Signals for standard Booth algorithm
    signal A : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others => '0');
    signal S : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others => '0');
    signal P : std_logic_vector(RESULT_WIDTH downto 0) := (others => '0');
    signal Nx_extended : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others => '0');
    signal Nx_neg : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others => '0');
    signal count : integer range 0 to WIDTH := 0;
    
    -- State machine for Booth algorithm
    type state_type is (INIT, COMPUTE, DONE);
    signal state : state_type := INIT;

begin

    -- Standard Booth algorithm implementation
    process(clk, reset)
    begin
        if reset = '1' then
            A <= (others => '0');
            S <= (others => '0');
            P <= (others => '0');
            count <= 0;
            state <= INIT;
            prod <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when INIT =>
                    -- Initialize registers
                    -- A = multiplicand (Nx) with sign extension
                    if Nx(WIDTH-1) = '0' then
                        Nx_extended <= (RESULT_WIDTH-1 downto WIDTH => '0') & Nx;
                    else
                        Nx_extended <= (RESULT_WIDTH-1 downto WIDTH => '1') & Nx;
                    end if;
                    
                    -- S = negative of multiplicand (-Nx) with sign extension
                    Nx_neg <= std_logic_vector(unsigned(not(Nx_extended)) + 1);
                    
                    -- P = 0...0 & multiplier (Ny) & 0
                    P <= (RESULT_WIDTH downto WIDTH => '0') & Ny & '0';
                    
                    count <= 0;
                    state <= COMPUTE;
                
                when COMPUTE =>
                    -- Check last two bits of P
                    case P(1 downto 0) is
                        when "01" =>    -- Add A to P
                            P(RESULT_WIDTH downto 1) <= std_logic_vector(signed(P(RESULT_WIDTH downto 1)) + signed(Nx_extended));
                        when "10" =>    -- Subtract A from P (add S)
                            P(RESULT_WIDTH downto 1) <= std_logic_vector(signed(P(RESULT_WIDTH downto 1)) + signed(Nx_neg));
                        when others =>  -- No operation (00 or 11)
                            null;
                    end case;
                    
                    -- Arithmetic right shift
                    P <= P(RESULT_WIDTH) & P(RESULT_WIDTH downto 1);
                    
                    -- Increment counter
                    count <= count + 1;
                    
                    -- Check if done
                    if count = WIDTH-1 then
                        state <= DONE;
                    end if;
                
                when DONE =>
                    -- Output result
                    prod <= P(RESULT_WIDTH downto 1);
                    state <= DONE;  -- Stay in DONE state until reset
            end case;
        end if;
    end process;

end behavioral; 