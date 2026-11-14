//=============================================================================
// THROWAWAY STUB: vec_alu (LANES x lane_alu)
// Owner of real module: Himanshu (rtl/vec_alu.v)
// Used only for early testing of simd_top integration.
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

    genvar i;
    generate
        for (i = 0; i < LANES; i = i + 1) begin : lane
            lane_alu u_lane (
                .a  (a[i*LANE_W +: LANE_W]),
                .b  (b[i*LANE_W +: LANE_W]),
                .op (op),
                .y  (y[i*LANE_W +: LANE_W])
            );
        end
    endgenerate

endmodule
