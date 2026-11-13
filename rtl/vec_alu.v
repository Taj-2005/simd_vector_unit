//=============================================================================
// vec_alu - LANES copies of lane_alu over a 128-bit vector.
//
// Owner: Himanshu (feat/himanshu-vec-alu)
// Testbench: tb/tb_vec_alu.v
// Report section: 4.2, lane and datapath design
//
// STUB. LANES stays a parameter: moving to 8 lanes must be a one-line change,
// which is the parameterisation claim the report makes.
//=============================================================================
`timescale 1ns / 1ps

module vec_alu #(
    parameter LANES  = 4,
    parameter LANE_W = 32
) (
    input  wire [LANES*LANE_W-1:0] a,
    input  wire [LANES*LANE_W-1:0] b,
    input  wire [2:0]              op,
    output wire [LANES*LANE_W-1:0] y
);

    // TODO(himanshu): replicate lane_alu in a generate loop. Shape:
    //
    //   genvar i;
    //   generate
    //       for (i = 0; i < LANES; i = i + 1) begin : lane
    //           lane_alu u_lane (
    //               .a (a[i*LANE_W +: LANE_W]),
    //               .b (b[i*LANE_W +: LANE_W]),
    //               .op(op),
    //               .y (y[i*LANE_W +: LANE_W])
    //           );
    //       end
    //   endgenerate
    //
    // Lane i owns bits [i*32 +: 32]; lane 0 is the low 32 bits. The golden
    // model (golden/golden_model.py) packs vectors the same way, so a lane
    // ordering swap here shows up as a system-test mismatch, not a warning.
    assign y = {LANES*LANE_W{1'b0}};

endmodule
