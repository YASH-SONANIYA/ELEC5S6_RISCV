# Create and map the work library
vlib work
vmap work work

# Compile all synthesizable modules and the top-level testbench
vlog ../src/regfile.v ../src/rvc_imm_gen.v ../src/rvc_alu.v ../src/data_mem.v ../src/rvc_datapath.v \
    ../src/rvc_decoder.v ../src/riscv_16bit_core.v tb_riscv_16bit.v

# Load the simulation with full signal visibility
vsim -voptargs=+acc work.tb_riscv_16bit

# Add key top-level and internal signals to the ModelSim Wave window
add wave -divider "Clock & Reset"
add wave -radix binary /tb_riscv_16bit/clk
add wave -radix binary /tb_riscv_16bit/rst_n

add wave -divider "Fetch & Decode"
add wave -radix hex /tb_riscv_16bit/pc
add wave -radix hex /tb_riscv_16bit/instr
add wave -radix binary /tb_riscv_16bit/illegal_op

add wave -divider "Control Signals"
add wave -radix unsigned /tb_riscv_16bit/u_dut/u_decoder/rs1_addr
add wave -radix unsigned /tb_riscv_16bit/u_dut/u_decoder/rs2_addr
add wave -radix unsigned /tb_riscv_16bit/u_dut/u_decoder/rd_addr
add wave -radix unsigned /tb_riscv_16bit/u_dut/u_decoder/alu_op
add wave -radix binary /tb_riscv_16bit/u_dut/u_decoder/alu_src
add wave -radix binary /tb_riscv_16bit/u_dut/u_decoder/reg_write
add wave -radix binary /tb_riscv_16bit/u_dut/u_decoder/mem_write
add wave -radix binary /tb_riscv_16bit/u_dut/u_decoder/mem_read

add wave -divider "Datapath Execution & Registers"
add wave -radix signed /tb_riscv_16bit/alu_result
add wave -radix signed /tb_riscv_16bit/wb_data_out
add wave -radix signed /tb_riscv_16bit/u_dut/u_datapath/u_rf/registers(2)
add wave -radix signed /tb_riscv_16bit/u_dut/u_datapath/u_rf/registers(8)
add wave -radix signed /tb_riscv_16bit/u_dut/u_datapath/u_rf/registers(9)
add wave -radix signed /tb_riscv_16bit/u_dut/u_datapath/u_rf/registers(10)
add wave -radix signed /tb_riscv_16bit/u_dut/u_datapath/u_rf/registers(11)

# Run simulation to completion
run -all
wave zoom full
