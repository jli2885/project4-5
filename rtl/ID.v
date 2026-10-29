module ID(
    input i_clk,
    input i_rst,
    input [31:0] inst,
    input [31:0] pc4,
    input [31:0] pc,

    output [2:0] EX,
    output [2:0] MEM,
    output [2:0] WB,
    output [31:0] o_rs1_rdata,
    output [31:0] o_rs2_rdata,
    output [31:0] o_immediate
);

control_unit u_control_unit(
    .inst(inst),
    .EX(EX),
    .MEM(MEM),
    .WB(WB)
);

decoder u_decoder(
    .inst(inst),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .i_rs1_raddr(i_rs1_raddr),
    .i_rs2_raddr(i_rs2_raddr),
    .i_rd_waddr(i_rd_waddr),
    .i_format(i_format),
    .uses_rs1(uses_rs1),
    .uses_rs2(uses_rs2)
);

rf u_rf(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_rs1_raddr(i_rs1_raddr),
    .i_rs2_raddr(i_rs2_raddr),
    .i_rd_waddr(i_rd_waddr),
    .i_rd_wdata(i_rd_wdata),
    .o_rs1_rdata(o_rs1_rdata),
    .o_rs2_rdata(o_rs2_rdata),
    .i_rd_wen(i_rd_wen)
);

imm u_imm(
    .inst(inst),
    .i_format(i_format),
    .o_immediate(o_immediate)
);

branch_control u_branch_control(
    .branch(branch),
    .funct3(funct3),
    .o_rs1_rdata(o_rs1_rdata),
    .o_rs2_rdata(o_rs2_rdata),
    .take_branch(take_branch)
);

HDU u_HDU(
    .ID_EX_rd(ID_EX_rd),
    .EX_MEM_rd(EX_MEM_rd),
    .IF_ID_rs1(IF_ID_rs1),
    .IF_ID_rs2(IF_ID_rs2),
    .ID_EX_RegWrite(ID_EX_RegWrite),
    .EX_MEM_RegWrite(EX_MEM_RegWrite),
    .uses_rs1(uses_rs1),
    .uses_rs2(uses_rs2),
    .IF_Stall(IF_Stall),
    .ID_Stall(ID_Stall)
);

endmodule