//=============================================================================
// instr_mem - program ROM, 16-bit instructions, loaded with $readmemh.
//
// Owner: Parthraj Singh Bhati (spec and integration owner)
//
// Parameters:
//   WORDS     - memory depth (default 32 words)
//   ADDR_W    - address bus width (default 5 bits for 32 words)
//   INIT_FILE - path to hex file loaded via $readmemh
//
// Combinational read driven by program counter (addr).
// Pre-fills unused memory words with HALT (16'hF000) so a runaway PC safely
// stops execution.
//=============================================================================
`timescale 1ns / 1ps

module instr_mem #(
    parameter WORDS     = 32,
    parameter ADDR_W    = 5,
    parameter INIT_FILE = ""
) (
    input  wire [ADDR_W-1:0] addr,
    output wire [15:0]       instr
);

    reg [15:0] rom [0:WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            rom[i] = 16'hF000;   // Pre-fill with HALT
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, rom);
        end
    end

    // Combinational read; out-of-bounds access returns HALT safely
    assign instr = (addr < WORDS) ? rom[addr] : 16'hF000;

endmodule
