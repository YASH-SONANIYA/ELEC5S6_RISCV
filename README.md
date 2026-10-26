# ELEC5S6_RISCV: Parameterized 16-bit Compressed RISC-V Core

An implementation of a parameterized **16-bit Compressed RISC-V (RVC)** processor core in Verilog HDL.

## Architecture Overview

The core is designed to decode and execute 16-bit compressed RISC-V instructions with configurable datapath width (`XLEN` parameter supporting 32-bit, 64-bit, and 128-bit architectures; default is 64-bit).

### Features
- **Configurable Datapath**: Parameterized `XLEN = 64` (RV64C), adaptable to `XLEN = 32` (RV32C) and `XLEN = 128` (RV128C).
- **Comprehensive RVC Support**: Supports Quadrant 0, Quadrant 1, and Quadrant 2 compressed instruction sets:
  - Register-immediate arithmetic (`c.addi`, `c.li`, `c.lui`, `c.addi16sp`, `c.addi4spn`, `c.slli`)
  - Register-register operations (`c.mv`, `c.add`, `c.sub`, `c.and`, `c.or`, `c.xor`)
  - Memory load/store (`c.lw`, `c.sw`, `c.ld`, `c.sd`, `c.lq`, `c.sq`)
  - Control transfer (`c.j`, `c.jal`, `c.jr`, `c.jalr`, `c.beqz`, `c.bnez`)
  - Illegal operation detection and write safety guards.
- **Dedicated Immediate Generation**: Handles CI, CSS, CIW, CL, CS, CB, and CJ formats.
- **Synchronous Register File**: 32 general-purpose registers (x0 hardwired to zero) with synchronous writes and asynchronous dual reads.
- **Configurable Data Memory**: Supports byte, halfword, word, and doubleword read/write access.

---

## Directory Structure

```text
ELEC5S6_RISCV/
├── sim/
│   ├── run_sim.do             # ModelSim / QuestaSim automated simulation macro script
│   ├── tb_riscv_16bit.v       # Top-level verification testbench
│   ├── modelsim.ini           # Simulator environment configuration
│   └── elec5s6_simulation.vcd # Simulation waveform dump (VCD)
├── src/
│   ├── riscv_16bit_core.v     # Top-level core module (Decoder + Datapath)
│   ├── rvc_decoder.v          # 16-bit RVC instruction decoder and control unit
│   ├── rvc_datapath.v         # Processor datapath integrating ALU, RF, and PC logic
│   ├── rvc_alu.v              # Arithmetic Logic Unit
│   ├── rvc_imm_gen.v          # Compressed immediate generator
│   ├── regfile.v              # 32xXLEN dual-read, single-write register file
│   └── data_mem.v             # Parameterized synchronous data memory
├── .gitignore
└── README.md
```

---

## Source Modules

| Module Name | File | Description |
|---|---|---|
| `riscv_16bit_core` | `src/riscv_16bit_core.v` | Top-level module connecting the instruction decoder, datapath, and safety controls. |
| `rvc_decoder` | `src/rvc_decoder.v` | Decodes 16-bit compressed instructions into execution control signals, register addresses, and immediate types. |
| `rvc_datapath` | `src/rvc_datapath.v` | Manages program counter (PC), ALU operands, writeback multiplexing, and memory interfacing. |
| `rvc_alu` | `src/rvc_alu.v` | Executes arithmetic, logical, and shift operations. |
| `rvc_imm_gen` | `src/rvc_imm_gen.v` | Extracts and sign-extends immediates across all RVC instruction formats. |
| `regfile` | `src/regfile.v` | General-purpose register file with 32 registers ($x0–$x31). |
| `data_mem` | `src/data_mem.v` | Dual-port / synchronous RAM module supporting varying access granularities. |

---

## Simulation & Verification

The core includes an automated testbench (`tb_riscv_16bit.v`) and ModelSim script (`run_sim.do`).

### Running Simulation with ModelSim / QuestaSim:
1. Open ModelSim/QuestaSim and change directory to `sim`:
   ```tcl
   cd ELEC5S6_RISCV/sim
   ```
2. Execute the simulation script:
   ```tcl
   do run_sim.do
   ```
3. The script compiles all source files, initializes the testbench, logs signals, and displays key signals in the Wave window.
