module IF_ID_reg (
    input wire i_clk,
    input wire i_rst,
    input wire redirect,

    input wire IF_Stall,

    input wire [31:0] in_pc,
    input wire [31:0] in_pc4,
    input wire [31:0] in_inst,

    output reg IF_ID_valid,
    output reg [31:0] out_pc,
    output reg [31:0] out_pc4,
    output reg [31:0] out_inst
);
    always @(posedge i_clk) begin
        if (i_rst || redirect) begin
            IF_ID_valid <= 1'b0;
            out_pc      <= 32'd0;
            out_pc4     <= 32'd0;
            out_inst    <= 32'h00000013;
        end else if (!IF_Stall) begin
            IF_ID_valid <= 1'b1;
            out_pc      <= in_pc;
            out_pc4     <= in_pc4;
            out_inst    <= in_inst;
        end
    end
endmodule

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

    // Retire interface
    input valid,
    input [31:0] inst,
    input [31:0] next_pc,

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
    output reg [6:0] out_opcode,

    output reg out_valid,
    output reg [31:0] out_inst,
    output reg [31:0] out_next_pc
);

    always @(posedge i_clk) begin
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

            out_valid <= 1'b0;
            out_inst <= 32'h00000013;
            out_next_pc <= 32'b0;
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

            out_valid <= valid;
            out_inst <= inst;
            out_next_pc <= next_pc;
        end
    end

endmodule

module EX_MEM_reg (
    input wire i_clk,
    input wire i_rst,

    input wire in_valid,
    input wire in_RegWrite,
    input wire in_MemtoReg,
    input wire in_MemRead,
    input wire in_MemWrite,
    input wire [2:0] in_funct3,
    input wire [4:0] in_rd,
    // Memory address for loads/stores, rd value otherwise
    input wire [31:0] in_ALU_result,

    // Retire interface. rs2_rdata is also the store data.
    input wire [31:0] in_pc,
    input wire [31:0] in_next_pc,
    input wire [31:0] in_inst,
    input wire [4:0] in_rs1,
    input wire [4:0] in_rs2,
    input wire [31:0] in_rs1_rdata,
    input wire [31:0] in_rs2_rdata,

    output reg out_valid,
    output reg out_RegWrite,
    output reg out_MemtoReg,
    output reg out_MemRead,
    output reg out_MemWrite,
    output reg [2:0] out_funct3,
    output reg [4:0] out_rd,
    output reg [31:0] out_ALU_result,

    output reg [31:0] out_pc,
    output reg [31:0] out_next_pc,
    output reg [31:0] out_inst,
    output reg [4:0] out_rs1,
    output reg [4:0] out_rs2,
    output reg [31:0] out_rs1_rdata,
    output reg [31:0] out_rs2_rdata
);
    always @(posedge i_clk) begin
        if (i_rst) begin
            out_valid      <= 1'b0;
            out_RegWrite   <= 1'b0;
            out_MemtoReg   <= 1'b0;
            out_MemRead    <= 1'b0;
            out_MemWrite   <= 1'b0;
            out_funct3     <= 3'd0;
            out_rd         <= 5'd0;
            out_ALU_result <= 32'd0;

            out_pc         <= 32'd0;
            out_next_pc    <= 32'd0;
            out_inst       <= 32'h00000013;
            out_rs1        <= 5'd0;
            out_rs2        <= 5'd0;
            out_rs1_rdata  <= 32'd0;
            out_rs2_rdata  <= 32'd0;
        end else begin
            out_valid      <= in_valid;
            out_RegWrite   <= in_RegWrite;
            out_MemtoReg   <= in_MemtoReg;
            out_MemRead    <= in_MemRead;
            out_MemWrite   <= in_MemWrite;
            out_funct3     <= in_funct3;
            out_rd         <= in_rd;
            out_ALU_result <= in_ALU_result;

            out_pc         <= in_pc;
            out_next_pc    <= in_next_pc;
            out_inst       <= in_inst;
            out_rs1        <= in_rs1;
            out_rs2        <= in_rs2;
            out_rs1_rdata  <= in_rs1_rdata;
            out_rs2_rdata  <= in_rs2_rdata;
        end
    end

endmodule

module MEM_WB_reg (
    input wire i_clk,
    input wire i_rst,

    input wire in_valid,
    input wire in_MemtoReg,
    input wire in_RegWrite,
    input wire [4:0] in_rd,
    input wire [31:0] in_LoadData,
    input wire [31:0] in_ALU_result,

    // Retire interface
    input wire in_trap,
    input wire [31:0] in_pc,
    input wire [31:0] in_next_pc,
    input wire [31:0] in_inst,
    input wire [4:0] in_rs1,
    input wire [4:0] in_rs2,
    input wire [31:0] in_rs1_rdata,
    input wire [31:0] in_rs2_rdata,
    input wire [31:0] in_dmem_addr,
    input wire [3:0] in_dmem_mask,
    input wire in_dmem_ren,
    input wire in_dmem_wen,
    input wire [31:0] in_dmem_rdata,
    input wire [31:0] in_dmem_wdata,

    output reg out_valid,
    output reg out_MemtoReg,
    output reg out_RegWrite,
    output reg [4:0] out_rd,
    output reg [31:0] out_LoadData,
    output reg [31:0] out_ALU_result,

    output reg out_trap,
    output reg [31:0] out_pc,
    output reg [31:0] out_next_pc,
    output reg [31:0] out_inst,
    output reg [4:0] out_rs1,
    output reg [4:0] out_rs2,
    output reg [31:0] out_rs1_rdata,
    output reg [31:0] out_rs2_rdata,
    output reg [31:0] out_dmem_addr,
    output reg [3:0] out_dmem_mask,
    output reg out_dmem_ren,
    output reg out_dmem_wen,
    output reg [31:0] out_dmem_rdata,
    output reg [31:0] out_dmem_wdata
);
    always @(posedge i_clk) begin
        if (i_rst) begin
            out_valid      <= 1'b0;
            out_MemtoReg   <= 1'b0;
            out_RegWrite   <= 1'b0;
            out_rd         <= 5'd0;
            out_LoadData   <= 32'd0;
            out_ALU_result <= 32'd0;

            out_trap       <= 1'b0;
            out_pc         <= 32'd0;
            out_next_pc    <= 32'd0;
            out_inst       <= 32'h00000013;
            out_rs1        <= 5'd0;
            out_rs2        <= 5'd0;
            out_rs1_rdata  <= 32'd0;
            out_rs2_rdata  <= 32'd0;
            out_dmem_addr  <= 32'd0;
            out_dmem_mask  <= 4'd0;
            out_dmem_ren   <= 1'b0;
            out_dmem_wen   <= 1'b0;
            out_dmem_rdata <= 32'd0;
            out_dmem_wdata <= 32'd0;
        end else begin
            out_valid      <= in_valid;
            out_MemtoReg   <= in_MemtoReg;
            out_RegWrite   <= in_RegWrite;
            out_rd         <= in_rd;
            out_LoadData   <= in_LoadData;
            out_ALU_result <= in_ALU_result;

            out_trap       <= in_trap;
            out_pc         <= in_pc;
            out_next_pc    <= in_next_pc;
            out_inst       <= in_inst;
            out_rs1        <= in_rs1;
            out_rs2        <= in_rs2;
            out_rs1_rdata  <= in_rs1_rdata;
            out_rs2_rdata  <= in_rs2_rdata;
            out_dmem_addr  <= in_dmem_addr;
            out_dmem_mask  <= in_dmem_mask;
            out_dmem_ren   <= in_dmem_ren;
            out_dmem_wen   <= in_dmem_wen;
            out_dmem_rdata <= in_dmem_rdata;
            out_dmem_wdata <= in_dmem_wdata;
        end
    end

endmodule
