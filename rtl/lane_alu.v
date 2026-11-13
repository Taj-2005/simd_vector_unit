//=============================================================================
// lane_alu - one 32-bit ALU lane.
//
// Owner: Himanshu (feat/himanshu-lane-alu)
// Testbench: tb/tb_lane_alu.v (same owner)
// Report section: 4.2, lane and datapath design
//
// STUB. The port list below is frozen - Jivit's scalar_top and Himanshu's own
// vec_alu both instantiate this module, so the ports must not change. Replace
// the body, leave the header alone.
//=============================================================================
`timescale 1ns / 1ps

module lane_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  op,
    output wire [31:0] y
);

    // TODO(himanshu): implement the six ops. Shape it is expected to take:
    //
    //   always @(*) begin
    //       case (op)
    //           `ALU_ADD:   y = a + b;
    //           `ALU_SUB:   y = a - b;
    //           `ALU_AND:   y = a & b;
    //           `ALU_OR:    y = a | b;
    //           `ALU_CMPEQ: y = {31'b0, (a == b)};
    //           `ALU_CMPLT: y = {31'b0, ($signed(a) < $signed(b))};   // signed
    //           `ALU_SHL:   y = a << b[4:0];                          // optional
    //           default:    y = 32'b0;
    //       endcase
    //   end
    //
    // Two things the testbench will check and the report has to state:
    //   - compares return 1 or 0 in bit 0 and zero in bits 31:1, not all-ones;
    //   - CMPLT is signed, so -1 < 1 must hold.
    //
    // Switch y to  output reg  when you move to an always block.
    assign y = 32'b0;

endmodule
