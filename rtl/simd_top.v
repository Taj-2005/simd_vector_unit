//=============================================================================
// simd_top - the SIMD machine: fetch, decode, vector register file, vec_alu,
// data memory, cycle counter.
//
// Owner: Parthraj Singh Bhati (feat/parth-simd-top) - integration
// Testbenches: tb/tb_simd_top.v (Parth), tb/tb_system.v (Taj, golden model)
// Report section: 4.1, architecture and control
//
// One instruction per clock:
//   1. Fetch from instr_mem using pc
//   2. Decode with ctrl_unit
//   3. Read vector register file (vreg_file)
//   4. Execute vector operation in vec_alu (LANES parallel lane_alu slices)
//   5. Data memory access (dmem) with address instr[3:0] and wdata from rdata1 (vs1)
//   6. Write-back mux: wdata = mem_rd ? dmem_rdata : alu_y
//
// Cycle-counting convention:
//   HALT sets done and freezes the PC. cycle_count counts clock cycles of
//   executed instructions after reset, EXCLUDING the HALT cycle.
//   Jivit's scalar baseline must count the exact same way.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module simd_top #(
    parameter LANES     = 4,
    parameter PROG_FILE = "programs/bench_add16.hex",
    parameter DATA_FILE = ""
) (
    input  wire        clk,
    input  wire        rst,
    output wire        done,
    output wire [31:0] cycle_count
);

    localparam VEC_W       = LANES * 32;
    localparam IMEM_ADDR_W = 5;
    localparam IMEM_WORDS  = 32;

    // Registers: program counter, cycle counter, done latch
    reg [IMEM_ADDR_W-1:0] pc;
    reg [31:0]            cycles;
    reg                   done_reg;

    assign done        = done_reg;
    assign cycle_count = cycles;

    // Instruction Memory (fetch)
    wire [15:0] instr;
    instr_mem #(
        .WORDS     (IMEM_WORDS),
        .ADDR_W    (IMEM_ADDR_W),
        .INIT_FILE (PROG_FILE)
    ) u_imem (
        .addr  (pc),
        .instr (instr)
    );

    // Control Unit (decode)
    wire       rf_we;
    wire [2:0] rf_waddr;
    wire [2:0] rf_raddr1;
    wire [2:0] rf_raddr2;
    wire [2:0] alu_op;
    wire       mem_rd;
    wire       mem_wr;
    wire       halt;

    ctrl_unit u_ctrl (
        .instr  (instr),
        .we     (rf_we),
        .waddr  (rf_waddr),
        .raddr1 (rf_raddr1),
        .raddr2 (rf_raddr2),
        .alu_op (alu_op),
        .mem_rd (mem_rd),
        .mem_wr (mem_wr),
        .halt   (halt)
    );

    // Vector Register File (8 registers x VEC_W bits, 2R1W)
    wire [VEC_W-1:0] rf_rdata1;
    wire [VEC_W-1:0] rf_rdata2;
    wire [VEC_W-1:0] rf_wdata;

    vreg_file #(
        .NREGS   (8),
        .VEC_W   (VEC_W),
        .REG_SEL (3)
    ) u_vrf (
        .clk    (clk),
        .we     (rf_we),
        .waddr  (rf_waddr),
        .wdata  (rf_wdata),
        .raddr1 (rf_raddr1),
        .raddr2 (rf_raddr2),
        .rdata1 (rf_rdata1),
        .rdata2 (rf_rdata2)
    );

    // Vector ALU (LANES x lane_alu)
    wire [VEC_W-1:0] alu_y;

    vec_alu #(
        .LANES  (LANES),
        .LANE_W (32)
    ) u_valu (
        .a      (rf_rdata1),
        .b      (rf_rdata2),
        .op     (alu_op),
        .y      (alu_y)
    );

    // Data Memory (16 words x VEC_W bits)
    // Address comes from instr[3:0], store data comes from rdata1 (vs1)
    wire [VEC_W-1:0] dmem_rdata;

    dmem #(
        .WORDS     (16),
        .VEC_W     (VEC_W),
        .ADDR_W    (4),
        .INIT_FILE (DATA_FILE)
    ) u_dmem (
        .clk   (clk),
        .we    (mem_wr),
        .addr  (instr[3:0]),
        .wdata (rf_rdata1),
        .rdata (dmem_rdata)
    );

    // Write-back multiplexer:
    // Memory loads (VLD) write memory read data; ALU instructions write ALU output
    assign rf_wdata = mem_rd ? dmem_rdata : alu_y;

    // Execution control & cycle counter:
    // One instruction per clock cycle after reset.
    // HALT stops execution, sets done=1, and freezes the PC.
    // cycle_count increments only on executed instructions prior to HALT.
    always @(posedge clk) begin
        if (rst) begin
            pc       <= {IMEM_ADDR_W{1'b0}};
            cycles   <= 32'b0;
            done_reg <= 1'b0;
        end else if (!done_reg) begin
            if (halt) begin
                done_reg <= 1'b1;
            end else begin
                cycles <= cycles + 1'b1;
                pc     <= pc + 1'b1;
            end
        end
    end

endmodule
