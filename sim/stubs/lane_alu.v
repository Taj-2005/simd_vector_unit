//=============================================================================
// THROWAWAY STUB: lane_alu (32-bit ALU lane)
// Owner of real module: Himanshu (rtl/lane_alu.v)
// Used only for early testing of simd_top integration.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module lane_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  op,
    output reg  [31:0] y
);

    always @(*) begin
        case (op)
            `ALU_ADD:   y = a + b;
            `ALU_SUB:   y = a - b;
            `ALU_AND:   y = a & b;
            `ALU_OR:    y = a | b;
            `ALU_CMPEQ: y = {31'b0, (a == b)};
            `ALU_CMPLT: y = {31'b0, ($signed(a) < $signed(b))};
            `ALU_SHL:   y = a << b[4:0];
            default:    y = 32'b0;
        endcase
    end

endmodule
