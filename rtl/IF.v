module IF#(
    parameter RESET_ADDR = 32'h00000000
)(
    input i_clk,
    input i_rst,
    input PCsrc,
    input if_stall,
    input [31:0] i_imem_rdata,
    input [31:0] target_pc,

    output wire [31:0] o_imem_raddr,
    output wire [31:0] PC_4,
    output reg [31:0] PC,
    output wire [31:0] inst
);

wire [31:0] next_pc;

// PC + 4 ADDER
assign PC_4 = PC + 32'd4;

// Next PC MUX
assign next_pc = PCsrc ? target_pc : (if_stall ? PC : PC_4);

// PC Register
always @(posedge i_clk) begin
    if (i_rst)
        PC <= RESET_ADDR;
    else if (!if_stall)
        PC <= next_pc;
end

// Instruction Memory
assign o_imem_raddr = PC;
assign inst = i_imem_rdata;

endmodule
