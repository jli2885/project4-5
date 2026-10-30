module IF#(
    parameter RESET_ADDR = 32'h00000000
)(
    input i_clk,
    input i_rst,
    input [31:0] i_imem_rdata,
    // Taken branch/jump resolved in ID. Loads redirect_pc into the PC.
    input redirect,
    input [31:0] redirect_pc,
    // Hold the PC while ID is stalled on a hazard.
    input IF_Stall,

    output wire [31:0] o_imem_raddr,
    output wire [31:0] PC_4,
    output reg [31:0] PC,
    output wire [31:0] inst
);

wire [31:0] next_pc;

// PC + 4 ADDER
assign PC_4 = PC + 32'd4;

// Next PC MUX
assign next_pc = redirect ? redirect_pc : PC_4;

// PC Register. Redirect takes priority over a stall.
always @(posedge i_clk) begin
    if (i_rst) begin
        PC <= RESET_ADDR;
    end else if (redirect || !IF_Stall) begin
        PC <= next_pc;
    end
end

// Instruction Memory
assign o_imem_raddr = PC;
assign inst = i_imem_rdata;

endmodule
