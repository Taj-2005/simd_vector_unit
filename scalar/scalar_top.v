//=============================================================================
// scalar_top - the one-ALU baseline the SIMD unit is compared against.
//
// Owner: Jivit (feat/jivit-scalar-top)
// Testbench: tb/tb_scalar_top.v - checks C[i] = A[i] + B[i] for all 16
// Report section: 4.3, baseline and evaluation method
//
// Reuses Himanshu's lane_alu, so the two machines differ in how many ALUs run
// per cycle and in nothing else. Building a second adder here would make the
// speed-up number meaningless, and an examiner will ask.
//
// Memory is 32 bits wide, not 128. That is the point of the baseline: a scalar
// load moves one element per cycle where a vector load moves LANES of them.
// Giving this machine a wide memory would hide the effect being measured.
//=============================================================================
`timescale 1ns / 1ps
`include "simd_defs.vh"

module scalar_top #(
    parameter N         = 16,                            // elements per array
    parameter MEM_WORDS = 64,
    parameter A_BASE    = 0,                             // A[0..N-1]
    parameter B_BASE    = 16,                            // B[0..N-1]
    parameter C_BASE    = 32,                            // C[0..N-1]
    parameter DATA_FILE = "vectors/scalar_init.hex"
) (
    input  wire        clk,
    input  wire        rst,
    output wire        done,
    output wire [31:0] cycle_count
);

    //-------------------------------------------------------------------------
    // Narrow scalar memory, loaded from the same golden vectors the SIMD
    // machine runs, so both are adding byte-identical numbers.
    //-------------------------------------------------------------------------
    reg [31:0] mem [0:MEM_WORDS-1];
    integer    k;

    initial begin
        for (k = 0; k < MEM_WORDS; k = k + 1) begin
            mem[k] = 32'b0;
        end
        if (DATA_FILE != "") begin
            $readmemh(DATA_FILE, mem);
        end
    end

    //-------------------------------------------------------------------------
    // Four phases per element: load A, load B, add, store. One per cycle, which
    // is the same issue cost simd_top pays per instruction - that parity is
    // what makes the cycle comparison fair. See docs/cycle_counting.md.
    //-------------------------------------------------------------------------
    localparam S_LDA  = 3'd0,
               S_LDB  = 3'd1,
               S_ADD  = 3'd2,
               S_ST   = 3'd3,
               S_DONE = 3'd4;

    reg [2:0]  state;
    reg [31:0] idx;
    reg [31:0] ra, rb, rsum;
    reg [31:0] cycles;
    reg        done_reg;

    // The single ALU. Same module the four vector lanes are built from.
    wire [31:0] alu_y;
    lane_alu u_alu (
        .a  (ra),
        .b  (rb),
        .op (`ALU_ADD),
        .y  (alu_y)
    );

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_LDA;
            idx      <= 32'b0;
            ra       <= 32'b0;
            rb       <= 32'b0;
            rsum     <= 32'b0;
            cycles   <= 32'b0;
            done_reg <= 1'b0;
        end else if (!done_reg) begin
            // Counting rule, mirroring simd_top exactly: every working cycle is
            // counted, the terminal cycle is not. simd_top does not count its
            // HALT; this does not count entering S_DONE.
            if (state != S_DONE) begin
                cycles <= cycles + 1'b1;
            end

            case (state)
                S_LDA: begin
                    ra    <= mem[A_BASE + idx];
                    state <= S_LDB;
                end

                S_LDB: begin
                    rb    <= mem[B_BASE + idx];
                    state <= S_ADD;
                end

                S_ADD: begin
                    rsum  <= alu_y;
                    state <= S_ST;
                end

                S_ST: begin
                    mem[C_BASE + idx] <= rsum;
                    // The index increment rides along with the store rather
                    // than costing its own cycle, because simd_top's program
                    // counter increments for free alongside each instruction.
                    // Charging the scalar machine extra here would inflate the
                    // speed-up.
                    if (idx == N - 1) begin
                        state <= S_DONE;
                    end else begin
                        idx   <= idx + 1'b1;
                        state <= S_LDA;
                    end
                end

                S_DONE: begin
                    done_reg <= 1'b1;
                end

                default: state <= S_DONE;
            endcase
        end
    end

    assign done        = done_reg;
    assign cycle_count = cycles;

endmodule
