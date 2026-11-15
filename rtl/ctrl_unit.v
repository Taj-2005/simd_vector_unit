//=============================================================================
// ctrl_unit - decodes one 16-bit instruction into datapath control.
//
// Owner: Parthraj Singh Bhati (spec and integration owner)
// Testbench: tb/tb_ctrl_unit.v - one directed check per opcode
// Report section: 4.1, architecture and control
//
// Pure combinational decode: no state, no clock.
//
// Instruction word format (16 bits):
//   Compute: | 15:12 opcode | 11:9 vd | 8:6 vs1 | 5:3 vs2 | 2:0 unused |
//   VLD:     | 15:12 opcode | 11:9 vd | 8:4 unused        | 3:0 addr   |
//   VST:     | 15:12 opcode | 11:9 rsv| 8:6 vs1 | 5:4 rsv | 3:0 addr   |
//
// Register addressing:
//   waddr  = vd  = instr[11:9]
//   raddr1 = vs1 = instr[8:6]  (for VST, vs1 is the data source)
//   raddr2 = vs2 = instr[5:3]
//
// ALU operations (opcodes 0000..0110):
//   alu_op = opcode[2:0] = instr[14:12]
//
// Unknown opcodes behave like NOP: we=0, mem_rd=0, mem_wr=0, halt=0.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module ctrl_unit (
    input  wire [15:0] instr,
    output wire        we,        // vector register-file write enable
    output wire [2:0]  waddr,     // destination register address (vd)
    output wire [2:0]  raddr1,    // source 1 register address (vs1)
    output wire [2:0]  raddr2,    // source 2 register address (vs2)
    output reg  [2:0]  alu_op,    // ALU operation code
    output reg         mem_rd,    // memory read enable (VLD)
    output reg         mem_wr,    // memory write enable (VST)
    output reg         halt       // halt execution flag
);

    wire [3:0] opcode = `F_OPCODE(instr);

    // Fixed register address wiring per frozen specification:
    // waddr is always vd; raddr1 is always vs1; raddr2 is always vs2.
    // For VST, raddr1 (vs1) directly drives the memory write data.
    assign waddr  = `F_VD(instr);
    assign raddr1 = `F_VS1(instr);
    assign raddr2 = `F_VS2(instr);

    reg reg_we;
    assign we = reg_we;

    always @(*) begin
        // Default: inert NOP (no writes, no mem access, no halt)
        reg_we  = 1'b0;
        alu_op  = 3'b000;
        mem_rd  = 1'b0;
        mem_wr  = 1'b0;
        halt    = 1'b0;

        case (opcode)
            `OP_VADD: begin
                reg_we = 1'b1;
                alu_op = `ALU_ADD;
            end
            `OP_VSUB: begin
                reg_we = 1'b1;
                alu_op = `ALU_SUB;
            end
            `OP_VAND: begin
                reg_we = 1'b1;
                alu_op = `ALU_AND;
            end
            `OP_VOR: begin
                reg_we = 1'b1;
                alu_op = `ALU_OR;
            end
            `OP_VCMPEQ: begin
                reg_we = 1'b1;
                alu_op = `ALU_CMPEQ;
            end
            `OP_VCMPLT: begin
                reg_we = 1'b1;
                alu_op = `ALU_CMPLT;
            end
            `OP_VSHL: begin
                reg_we = 1'b1;
                alu_op = `ALU_SHL;
            end
            `OP_VLD: begin
                reg_we = 1'b1;
                mem_rd = 1'b1;
                alu_op = 3'b000;
            end
            `OP_VST: begin
                reg_we = 1'b0;
                mem_wr = 1'b1;
                alu_op = 3'b000;
            end
            `OP_HALT: begin
                reg_we = 1'b0;
                halt   = 1'b1;
                alu_op = 3'b000;
            end
            default: begin
                // Any undefined opcode is a NOP: no writes, no halt
                reg_we  = 1'b0;
                alu_op  = 3'b000;
                mem_rd  = 1'b0;
                mem_wr  = 1'b0;
                halt    = 1'b0;
            end
        endcase
    end

endmodule
