module IF_ID_reg (
    input wire i_clk,
    input wire i_rst,
    input wire redirect,

    input wire IF_Stall,

    input wire [31:0] pc_in,
    input wire [31:0] pc4_in,
    input wire [31:0] inst_in,

    output reg IF_ID_valid,
    output reg [31:0] pc_out,
    output reg [31:0] pc4_out,
    output reg [31:0] inst_out
);
    always @(posedge i_clk) begin
        if (i_rst || redirect) begin
            IF_ID_valid <= 1'b0;
            pc_out      <= 32'd0;
            pc4_out     <= 32'd0;
            inst_out    <= 32'h00000013;
        end else if (!IF_Stall) begin
            IF_ID_valid <= 1'b1;
            pc_out      <= pc_in;
            pc4_out     <= pc4_in;
            inst_out    <= inst_in;
        end
    end
endmodule

module ID_EX_reg (
    input wire i_clk,
    input wire i_rst,

    input wire in_RegWrite,
    input wire in_MemtoReg,
    input wire in_branch,
    input wire in_MemRead,
    input wire in_MemWrite,
    input wire in_ALUOp,
    input wire in_ALUSrc,

    input wire [31:0] in_pc,
    input wire [31:0] in_inst
    input wire [31:0] in_ReadData1,
    input wire [31:0] in_ReadData2,
    input wire [31:0] in_imm,

    output reg out_RegWrite,
    output reg out_MemtoReg,
    output reg out_branch,
    output reg out_MemRead,
    output reg out_MemWrite,
    output reg [1:0] out_ALUOp,
    output reg out_ALUSrc,

    output reg [31:0] out_pc,
    output reg [31:0] out_inst,
    output reg [31:0] out_ReadData1,
    output reg [31:0] out_ReadData2,
    output reg [31:0] out_imm
);

    always @(posedge i_clk) begin
        if (i_rst) begin
            out_RegWrite     <= 1'b0;
            out_MemtoReg     <= 1'b0;
            out_branch       <= 1'b0;
            out_MemRead      <= 1'b0;
            out_MemWrite     <= 1'b0;
            out_ALUOp        <= 1'b0;
            out_ALUSrc       <= 1'b0;

            out_pc           <= 32'd0;
            out_inst         <= 32'd0;
            out_ReadData1    <= 32'd0;
            out_ReadData2    <= 32'd0;
            out_imm          <= 32'd0;
        end else begin
            out_RegWrite     <= in_RegWrite;
            out_MemtoReg     <= in_MemtoReg;
            out_branch       <= in_branch;
            out_MemRead      <= in_MemRead;
            out_MemWrite     <= in_MemWrite;
            out_ALUOp        <= in_ALUOp;
            out_ALUSrc       <= in_ALUSrc;

            out_pc           <= in_pc;
            out_inst         <= in_inst;
            out_ReadData1    <= in_ReadData1;
            out_ReadData2    <= in_ReadData2;
            out_imm          <= in_imm;
        end
    end

    
    
endmodule

module EX_MEM_reg (
    input wire i_clk,
    input wire i_rst,
    input wire in_Zero,
    input wire in_RegWrite,
    input wire in_MemtoReg,
    input wire in_branch,
    input wire in_MemRead,
    input wire in_MemWrite,
    input wire [31:0] in_ALU_result,
    input wire [31:0] in_WriteData,
    input wire [31:0] in_Target_address,
    input wire [31:0] in_inst,

    output reg out_RegWrite,
    output reg out_MemtoReg,
    output reg out_branch,
    output reg out_MemRead,
    output reg out_MemWrite,
    output reg [31:0] out_Target_address,
    output reg [31:0] out_ALU_result,
    output reg [31:0] out_WriteData,
    output reg [31:0] out_inst
);
    always @(posedge i_clk) begin
        if (i_rst) begin
            out_RegWrite     <= 1'b0;
            out_MemtoReg     <= 1'b0;
            out_branch       <= 1'b0;
            out_MemRead      <= 1'b0;
            out_MemWrite     <= 1'b0;
            out_Target_address <= 32'd0;
            out_ALU_result   <= 32'd0;
            out_WriteData    <= 32'd0;
            out_inst         <= 32'd0;
        end else begin
            out_RegWrite     <= in_RegWrite;
            out_MemtoReg     <= in_MemtoReg;
            out_branch       <= in_branch;
            out_MemRead      <= in_MemRead;
            out_MemWrite     <= in_MemWrite;
            out_Target_address <= in_Target_address;
            out_ALU_result   <= in_ALU_result;
            out_WriteData    <= in_WriteData;
            out_inst         <= in_inst;
        end
    end
    
endmodule

module MEM_WB_reg (
    input wire i_clk,
    input wire i_rst,
    input wire in_MemtoReg,
    input wire in_RegWrite,
    input wire [31:0] in_LoadData,
    input wire [31:0] in_ALU_result,
 
    output reg out_MemtoReg,
    output reg out_RegWrite,
    output reg [31:0] out_LoadData,
    output reg [31:0] out_ALU_result
);
    always @(posedge i_clk) begin
        if (i_rst) begin
            out_LoadData  <= 32'd0;
            out_ALU_result <= 32'd0;
            out_MemtoReg   <= 1'b0;
            out_RegWrite   <= 1'b0;
        end else begin
            out_LoadData  <= in_LoadData;
            out_ALU_result <= in_ALU_result;
            out_MemtoReg   <= in_MemtoReg;
            out_RegWrite   <= in_RegWrite;
        end
    end
    
endmodule