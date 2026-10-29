module ID_EX_reg(
    input i_clk,
    input i_rst,
    input [2:0] EX,
    input [2:0] MEM,
    input [2:0] WB,
    input [31:0] o_rs1_rdata,
    input [31:0] o_rs2_rdata,
    input [31:0] o_immediate,
    input [31:0] pc,
    input [31:0] pc4,

    output reg [2:0] out_EX,
    output reg [2:0] out_MEM,
    output reg [2:0] out_WB,
    output reg [31:0] out_o_rs1_rdata,
    output reg [31:0] out_o_rs2_rdata,
    output reg [31:0] out_o_immediate,
    output reg [31:0] out_pc,
    output reg [31:0] out_pc4
);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            out_EX <= 3'b0;
            out_MEM <= 3'b0;
            out_WB <= 3'b0;
            out_o_rs1_rdata <= 32'b0;
            out_o_rs2_rdata <= 32'b0;
            out_o_immediate <= 32'b0;
        end else begin
            out_EX <= EX;
            out_MEM <= MEM;
            out_WB <= WB;
            out_o_rs1_rdata <= o_rs1_rdata;
            out_o_rs2_rdata <= o_rs2_rdata;
            out_o_immediate <= o_immediate;
            out_pc <= pc;
            out_pc4 <= pc4;
        end
    end

endmodule