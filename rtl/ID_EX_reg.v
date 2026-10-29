module ID_EX_reg(
    input i_clk,
    input i_rst,
    input i_bubble,//ID_stall
    input ALUSrc,
    input [1:0] ALUOp,
    input branch,
    input memread,
    input memwrite,
    input regwrite,
    input memtoreg,

    input [31:0] o_rs1_rdata,
    input [31:0] o_rs2_rdata,
    input [31:0] o_immediate,
    input [31:0] pc,
    input [31:0] pc4,

    input [4:0] i_rs1_raddr,
    input [4:0] i_rs2_raddr,
    input [4:0] i_rd_waddr,
    input [6:0] funct7,
    input [2:0] funct3,
    input [6:0] opcode,

    output reg out_ALUSrc,
    output reg [1:0] out_ALUOp,
    output reg out_branch,
    output reg out_memread,
    output reg out_memwrite,
    output reg out_regwrite,
    output reg out_memtoreg,

    output reg [31:0] out_o_rs1_rdata,
    output reg [31:0] out_o_rs2_rdata,
    output reg [31:0] out_o_immediate,
    output reg [31:0] out_pc,
    output reg [31:0] out_pc4,

    output reg [4:0] out_rs1,
    output reg [4:0] out_rs2,
    output reg [4:0] out_rd,
    output reg [6:0] out_funct7,
    output reg [2:0] out_funct3,
    output reg [6:0] out_opcode
);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst || i_bubble) begin
            out_ALUSrc <= 1'b0;
            out_ALUOp <= 2'b0;
            out_branch <= 1'b0;
            out_memread <= 1'b0;
            out_memwrite <= 1'b0;
            out_regwrite <= 1'b0;
            out_memtoreg <= 1'b0;

            out_o_rs1_rdata <= 32'b0;
            out_o_rs2_rdata <= 32'b0;
            out_o_immediate <= 32'b0;
            out_pc <= 32'b0;
            out_pc4 <= 32'b0;

            out_rs1 <= 5'b0;
            out_rs2 <= 5'b0;
            out_rd <= 5'b0;
            out_funct7 <= 7'b0;
            out_funct3 <= 3'b0;
            out_opcode <= 7'b0;
        end else begin
            out_ALUSrc <= ALUSrc;
            out_ALUOp <= ALUOp;
            out_branch <= branch;
            out_memread <= memread;
            out_memwrite <= memwrite;
            out_regwrite <= regwrite;
            out_memtoreg <= memtoreg;

            out_o_rs1_rdata <= o_rs1_rdata;
            out_o_rs2_rdata <= o_rs2_rdata;
            out_o_immediate <= o_immediate;
            out_pc <= pc;
            out_pc4 <= pc4;

            out_rs1 <= i_rs1_raddr;
            out_rs2 <= i_rs2_raddr;
            out_rd <= i_rd_waddr;
            out_funct7 <= funct7;
            out_funct3 <= funct3;
            out_opcode <= opcode;
        end
    end

endmodule