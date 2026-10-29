module IF#(
    parameter RESET_ADDR = 32'h00000000
)(
    input i_clk,
    input i_rst,
    input [31:0] i_imem_rdata,
    input [1:0] PC_src,
    input [31:0] PC_target,

    output wire [31:0] o_imem_raddr,
    output wire [31:0] PC_4,
    output reg [31:0] PC,
    output wire [31:0] inst
);

wire [31:0] next_pc;
wire [31:0] pc_target;
wire [31:0] jalr_target;
// PC + 4 ADDER
assign PC_4 = PC + 32'd4;

// Next PC MUX
assign next_pc = PC_src ? PC_4 : PC_target;

// PC Register
always @(posedge i_clk) begin
    if (i_rst) begin
        PC <= RESET_ADDR;
    end else begin
        PC <= next_pc;
    end
end

// Instruction Memory
assign o_imem_raddr = PC;
assign inst = i_imem_rdata;

endmodule


module IF_ID_Reg (
    input clk,
    input rst_n,

    input flush,      // Keep for branch/jump handling

    input [31:0] PC_in,
    input [31:0] PC4_in,
    input [31:0] inst_in,

    output reg [31:0] PC_out,
    output reg [31:0] PC4_out,
    output reg [31:0] inst_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            PC_out          <= 32'b0;
            PC4_out         <= 32'b0;
            // Reset instruction to NOP (ADDI x0, x0, 0)
            inst_out <= 32'h00000013;
        end

        else if (flush) begin
            PC_out          <= 32'b0;
            PC4_out         <= 32'b0;
            // Flush instruction to NOP (ADDI x0, x0, 0)
            inst_out <= 32'h00000013;
        end

        else begin
            PC_out          <= PC_in;
            PC4_out         <= PC4_in;
            // Pass through the instruction
            inst_out <= inst_in;
        end
    end

endmodule
