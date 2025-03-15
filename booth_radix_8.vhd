-- Author 	: Urs Gompper
-- Date 	: 06-29-2020 

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity booth_radix_8 is
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
  end booth_radix_8;

architecture behavioral of booth_radix_8 is

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

type action_array is array (0 to 2) of std_logic_vector(WIDTH-1 downto 0);
type control_array is array (0 to 2) of std_logic_vector(3 downto 0); 

signal Nx_comp  : std_logic_vector(WIDTH-1 downto 0);
signal action   : action_array;
signal control  : control_array; 
signal pp1 : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others=>'0');
signal pp2 : std_logic_vector((RESULT_WIDTH-4) downto 0) := (others=>'0');
signal N_x : std_logic_vector(RESULT_WIDTH-1 downto 0) := (others=>'0');
signal N_y : std_logic_vector((RESULT_WIDTH-4) downto 0) := (others=>'0');
signal N_z : std_logic_vector(WIDTH-1 downto 0) := (others=>'0');
signal c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,cout : std_logic := '0';
-- Additional carry signals for wider bit widths
signal c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24 : std_logic := '0';

begin

-- 
process(clk,reset)
begin
    if reset = '1' then
        for i in 0 to 2 loop
            action(i)  <= (others => '0');
            control(i) <= (others => '0');
        end loop;
        Nx_comp <= (others=>'0');
    elsif rising_edge(clk) then 
        for i in 0 to 2 loop
            case control(i) is
                when "0000" => action(i) <= (others =>'0');
                when "0001" => action(i) <= Nx;
                when "0010" => action(i) <= Nx;
                when "0011" => action(i) <= Nx(WIDTH-2 downto 0) & '0'; -- 2*Nx
                when "0100" => action(i) <= Nx(WIDTH-2 downto 0) & '0'; -- 2*Nx
                when "0101" => action(i) <= std_logic_vector(signed(Nx) + signed(Nx) + signed(Nx)); -- 3*Nx
                when "0110" => action(i) <= std_logic_vector(signed(Nx) + signed(Nx) + signed(Nx)); -- 3*Nx
                when "0111" => action(i) <= Nx(WIDTH-3 downto 0) & "00"; -- 4*Nx
                when "1000" => action(i) <= Nx_comp(WIDTH-3 downto 0) & "00"; -- 4*Nx_comp
                when "1001" => action(i) <= std_logic_vector(signed(Nx_comp) + signed(Nx_comp) + signed(Nx_comp)); -- 3*Nx_comp
                when "1010" => action(i) <= std_logic_vector(signed(Nx_comp) + signed(Nx_comp) + signed(Nx_comp)); -- 3*Nx_comp
                when "1011" => action(i) <= Nx_comp(WIDTH-2 downto 0) & '0'; -- 2*Nx_comp
                when "1100" => action(i) <= Nx_comp(WIDTH-2 downto 0) & '0'; -- 2*Nx_comp
                when "1101" => action(i) <= Nx_comp; -- Nx_comp
                when "1110" => action(i) <= Nx_comp; -- Nx_comp
                when "1111" => action(i) <= (others =>'0');
                when others => action(i) <= (others =>'0');
            end case;
        end loop;
        Nx_comp <= std_logic_vector(unsigned(not(Nx)) + 1);
        if WIDTH >= 3 then
            if Ny(WIDTH-1) = '0' then
                control(2) <= '0' & Ny(WIDTH-1 downto WIDTH-3); 
            else 
                control(2) <= '1' & Ny(WIDTH-1 downto WIDTH-3);
            end if;
        else
            -- Handle case where WIDTH < 3
            control(2) <= (others => '0');
        end if;
        
        if WIDTH >= 6 then
            control(1) <= Ny(WIDTH-3 downto WIDTH-6);
        else
            -- Handle case where WIDTH < 6
            control(1) <= (others => '0');
        end if;
        
        if WIDTH >= 8 then
            control(0) <= Ny(WIDTH-6 downto WIDTH-8) & '0';
        else
            -- Handle case where WIDTH < 8
            control(0) <= (others => '0');
        end if;
    end if;
end process;

-- arithmetic shifting
process(clk)
begin
    if reset = '1' then
        N_x <= (others=>'0');
        N_y <= (others=>'0');
        N_z <= (others=>'0');
    elsif rising_edge(clk) then
        -- Sign extension for N_x
        if action(0)(WIDTH-1) = '0' then
            -- Positive number, pad with zeros
            N_x <= (RESULT_WIDTH-WIDTH-1 downto 0 => '0') & action(0);
        else
            -- Negative number, pad with ones
            N_x <= (RESULT_WIDTH-WIDTH-1 downto 0 => '1') & action(0);
        end if;
        
        -- Sign extension for N_y
        if action(1)(WIDTH-1) = '0' then
            -- Positive number, pad with zeros
            N_y <= (RESULT_WIDTH-WIDTH-5 downto 0 => '0') & action(1);
        else
            -- Negative number, pad with ones
            N_y <= (RESULT_WIDTH-WIDTH-5 downto 0 => '1') & action(1);
        end if;
        
        -- Direct assignment for N_z
        N_z <= action(2);
    end if;
end process;

-- Generate Wallace tree based on WIDTH parameter
-- This is a simplified version for demonstration
-- A complete implementation would generate the full Wallace tree based on WIDTH
wallace_tree_gen: if WIDTH = 8 generate
    -- Original 8-bit implementation
    pp1(5 downto 0) <= N_x(5 downto 0); 
    HA_0 : HA port map(N_x(6),N_y(3),pp1(6),pp2(4));
    FA_0 : FA port map(N_x(7),N_y(4),N_z(1),pp1(7),pp2(5));
    FA_1 : FA port map(N_x(8),N_y(5),N_z(2),pp1(8),pp2(6));
    FA_2 : FA port map(N_x(9),N_y(6),N_z(3),pp1(9),pp2(7));
    FA_3 : FA port map(N_x(10),N_y(7),N_z(4),pp1(10),pp2(8));
    FA_4 : FA port map(N_x(11),N_y(8),N_z(5),pp1(11),pp2(9));
    FA_5 : FA port map(N_x(12),N_y(9),N_z(6),pp1(12),pp2(10));
    FA_6 : FA port map(N_x(13),N_y(10),N_z(7),pp1(13)); 
    pp2(2 downto 0) <= N_y(2 downto 0); 
    pp2(3)  <= N_z(0); 
    prod(2 downto 0) <= pp1(2 downto 0);
    HA_2 : HA port map(pp1(3),pp2(0),prod(3),c1);
    FA_7 : FA port map(pp1(4),pp2(1),c1,prod(4),c2);
    FA_8 : FA port map(pp1(5),pp2(2),c2,prod(5),c3);
    FA_9 : FA port map(pp1(6),pp2(3),c3,prod(6),c4);
    FA_10 : FA port map(pp1(7),pp2(4),c4,prod(7),c5);
    FA_11 : FA port map(pp1(8),pp2(5),c5,prod(8),c6);
    FA_12 : FA port map(pp1(9),pp2(6),c6,prod(9),c7);
    FA_13 : FA port map(pp1(10),pp2(7),c7,prod(10),c8);
    FA_14 : FA port map(pp1(11),pp2(8),c8,prod(11),c9);
    FA_15 : FA port map(pp1(12),pp2(9),c9,prod(12),c10);
    FA_16: FA port map(pp1(13),pp2(10),c10,prod(13),cout);
end generate;

-- For other WIDTH values, implement a generic multiplier
generic_multiplier: if WIDTH /= 8 generate
    -- Simple direct multiplication for other bit widths
    process(clk)
    begin
        if rising_edge(clk) and reset = '0' then
            -- Use a simple multiplication for non-8-bit widths
            prod <= std_logic_vector(signed(Nx) * signed(Ny));
        end if;
    end process;
end generate;

end behavioral;