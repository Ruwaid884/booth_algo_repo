library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity booth_visualizer is
    generic (
        WIDTH : integer := 8  -- Default to 8-bit, but can be changed
    );
    Port( 
        Ny     : in    std_logic_vector(WIDTH-1 downto 0);
        Nx     : in    std_logic_vector(WIDTH-1 downto 0);
        clk    : in    std_logic;
        reset  : in    std_logic;
        
        -- Visualization outputs
        current_step : out integer range 0 to WIDTH;
        pp_value     : out std_logic_vector(2*WIDTH-1 downto 0);  -- Current partial product
        operation    : out std_logic_vector(2 downto 0);          -- Current operation (add, subtract, shift)
        final_result : out std_logic_vector(2*WIDTH-1 downto 0)   -- Final multiplication result
    );
end booth_visualizer;

architecture behavioral of booth_visualizer is
    -- Signals for standard Booth algorithm
    signal A : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');  -- Accumulator
    signal Q : std_logic_vector(WIDTH-1 downto 0) := (others => '0');    -- Multiplier (Ny)
    signal M : std_logic_vector(WIDTH-1 downto 0) := (others => '0');    -- Multiplicand (Nx)
    signal Q_minus_1 : std_logic := '0';                                -- Extra bit for Booth algorithm
    signal count : integer range 0 to WIDTH := 0;
    
    -- Operation codes
    constant OP_NONE    : std_logic_vector(2 downto 0) := "000";
    constant OP_ADD     : std_logic_vector(2 downto 0) := "001";
    constant OP_SUB     : std_logic_vector(2 downto 0) := "010";
    constant OP_SHIFT   : std_logic_vector(2 downto 0) := "011";
    constant OP_INIT    : std_logic_vector(2 downto 0) := "100";
    constant OP_DONE    : std_logic_vector(2 downto 0) := "111";
    
    -- State machine for Booth algorithm
    type state_type is (INIT, CHECK_BITS, ADD, SUBTRACT, SHIFT, DONE);
    signal state : state_type := INIT;
    signal next_state : state_type;
    
    -- Signals for visualization
    signal current_operation : std_logic_vector(2 downto 0) := OP_NONE;

begin
    -- Main Booth algorithm process
    process(clk, reset)
    begin
        if reset = '1' then
            A <= (others => '0');
            Q <= (others => '0');
            M <= (others => '0');
            Q_minus_1 <= '0';
            count <= 0;
            state <= INIT;
            current_operation <= OP_NONE;
            
        elsif rising_edge(clk) then
            case state is
                when INIT =>
                    -- Initialize registers
                    A <= (others => '0');
                    Q <= Ny;
                    M <= Nx;
                    Q_minus_1 <= '0';
                    count <= 0;
                    current_operation <= OP_INIT;
                    state <= CHECK_BITS;
                    
                when CHECK_BITS =>
                    -- Check the two rightmost bits of Q and Q_minus_1
                    if Q(0) = '1' and Q_minus_1 = '0' then
                        -- Subtract M from A
                        state <= SUBTRACT;
                    elsif Q(0) = '0' and Q_minus_1 = '1' then
                        -- Add M to A
                        state <= ADD;
                    else
                        -- No operation, just shift
                        state <= SHIFT;
                    end if;
                    
                when ADD =>
                    -- A = A + M
                    A <= std_logic_vector(signed(A) + signed(M & (WIDTH-1 downto 0 => '0')));
                    current_operation <= OP_ADD;
                    state <= SHIFT;
                    
                when SUBTRACT =>
                    -- A = A - M
                    A <= std_logic_vector(signed(A) - signed(M & (WIDTH-1 downto 0 => '0')));
                    current_operation <= OP_SUB;
                    state <= SHIFT;
                    
                when SHIFT =>
                    -- Arithmetic right shift of A:Q:Q_minus_1
                    Q_minus_1 <= Q(0);
                    Q <= A(0) & Q(WIDTH-1 downto 1);
                    A <= A(2*WIDTH-1) & A(2*WIDTH-1 downto 1);  -- Sign extension
                    current_operation <= OP_SHIFT;
                    
                    -- Increment counter
                    count <= count + 1;
                    
                    -- Check if done
                    if count = WIDTH-1 then
                        state <= DONE;
                    else
                        state <= CHECK_BITS;
                    end if;
                    
                when DONE =>
                    -- Stay in DONE state
                    current_operation <= OP_DONE;
                    state <= DONE;
            end case;
        end if;
    end process;
    
    -- Output assignments for visualization
    current_step <= count;
    pp_value <= A;
    operation <= current_operation;
    final_result <= A(WIDTH-1 downto 0) & Q when state = DONE else (others => '0');

end behavioral; 