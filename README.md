# Enhanced Booth Multiplier Project

<img src="./svg/booth-1.svg">

## Project Overview

This project implements and compares different hardware multiplication algorithms with a focus on the Booth algorithm and its variants. The implementation is parameterizable, allowing for different bit widths, and includes performance analysis tools to compare the efficiency of different multiplication techniques.

## Key Features

1. **Parameterizable Bit Width**: All multiplier implementations support configurable bit widths through VHDL generics.

2. **Multiple Multiplication Algorithms**:
   - **Booth Radix-8**: An advanced version of the Booth algorithm that processes 3 bits at a time
   - **Standard Booth**: The classic Booth algorithm that reduces the number of additions
   - **Array Multiplier**: A traditional parallel multiplier implementation

3. **Performance Analysis Dashboard**: Built-in performance metrics to compare:
   - Execution time
   - Resource utilization
   - Power consumption estimates

4. **Interactive Learning Tool**: Visualization of the Booth algorithm's internal operations:
   - Step-by-step execution
   - Partial product generation
   - Shifting and accumulation operations

## Directory Structure

```
booth_algo_pro/
├── booth_radix_8.vhd         # Original Booth Radix-8 implementation
├── booth_radix_8_tb.vhd      # Testbench for Booth Radix-8
├── booth_standard.vhd        # Standard Booth algorithm implementation
├── array_multiplier.vhd      # Array multiplier implementation
├── multiplier_top.vhd        # Top-level entity for comparing multipliers
├── multiplier_top_tb.vhd     # Testbench for performance comparison
├── booth_visualizer.vhd      # Visualization component for educational purposes
├── fa.vhd                    # Full adder component
├── ha.vhd                    # Half adder component
└── svg/                      # Diagrams and visualizations
```

## How to Use

### Simulation

To simulate the different multiplier implementations:

1. Use the `multiplier_top_tb.vhd` testbench to compare all implementations:
   ```
   ghdl -a fa.vhd ha.vhd booth_radix_8.vhd booth_standard.vhd array_multiplier.vhd multiplier_top.vhd multiplier_top_tb.vhd
   ghdl -e tb_multiplier_top
   ghdl -r tb_multiplier_top --wave=multiplier_comparison.ghw
   ```

2. View the simulation results:
   ```
   gtkwave multiplier_comparison.ghw
   ```

### Educational Visualization

To use the interactive visualization tool:

1. Simulate the booth_visualizer component:
   ```
   ghdl -a fa.vhd ha.vhd booth_visualizer.vhd
   ghdl -e booth_visualizer
   ghdl -r booth_visualizer --wave=booth_visualization.ghw
   ```

2. View the visualization:
   ```
   gtkwave booth_visualization.ghw
   ```

## Performance Comparison

The project includes built-in performance metrics that measure:

1. **Execution Time**: Number of clock cycles required for multiplication
2. **Accuracy**: Verification against expected results
3. **Scalability**: Performance with different bit widths

Typical results show:
- Booth Radix-8 is fastest for larger bit widths
- Standard Booth offers a good balance of speed and simplicity
- Array multiplier is simpler but less efficient for large operands

## Educational Value

This project serves as an excellent educational tool for understanding:
- Binary multiplication algorithms
- Hardware optimization techniques
- Digital design tradeoffs
- VHDL implementation of complex algorithms

## Future Enhancements

Potential areas for further development:
- FPGA implementation with real-time visualization
- Additional multiplication algorithms (Wallace Tree, Vedic, etc.)
- Power optimization techniques
- Pipelined implementations for higher throughput

## References

1. Computer Arithmetic: Algorithms and Hardware Designs by Behrooz Parhami
2. Digital Design and Computer Architecture by David Harris & Sarah Harris
3. VHDL: Programming by Example by Douglas Perry
