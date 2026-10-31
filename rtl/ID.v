module ID(
    input i_clk,
    input i_rst,

    input [31:0] inst,
    input wire [31:0] pc,
    input wire [31:0] pc4,

    // Older instructions in flight, checked by the HDU
    input wire [4:0] ID_EX_rd,
    input wire ID_EX_RegWrite,
    input wire [4:0] EX_MEM_rd,
    input wire EX_MEM_RegWrite,

    // Register file write port, driven by the instruction in writeback
    input wire [31:0] WB_rd_data,
    input wire [4:0] MEM_WB_rd,
    input wire MEM_WB_RegWrite,
    input wire MEM_WB_valid,

    output wire regwrite,
    output wire memtoreg,
    output wire memread,
    output wire memwrite,
    output wire branch,
    output wire [1:0] ALUop,
    output wire ALUsrc,
    
    output [31:0] o_rs1_rdata,
    output [31:0] o_rs2_rdata,
    output [31:0] o_immediate,
    // Destination register of the instruction in decode, passed to ID/EX
    output [4:0] rd_waddr,
    // Taken branch/jump: load redirect_pc into the PC and flush IF/ID
    output wire redirect,
    output wire [31:0] redirect_pc,
    // PC of the next instruction to execute, for o_retire_next_pc
    output wire [31:0] next_pc,
    // Hold PC and IF/ID, and send a bubble into ID/EX, while a hazard is present
    output IF_Stall,
    output ID_Stall,
    output [4:0] i_rs1_raddr,
    output [4:0] i_rs2_raddr,
    output [6:0] funct7,
    output [2:0] funct3,
    output [6:0] opcode
);
    wire uses_rs1;
    wire uses_rs2;
    wire [5:0] i_format;
    wire rf_wen;
    wire take_branch;

    // Bubbles and flushed instructions must not write the register file
    assign rf_wen = MEM_WB_RegWrite && MEM_WB_valid;

    control_unit u_control_unit(
        .opcode(opcode),
        .ALUsrc(ALUsrc),
        .ALUop(ALUop),
        .branch(branch),
        .memread(memread),
        .memwrite(memwrite),
        .regwrite(regwrite),
        .memtoreg(memtoreg)
    );

    decoder u_decoder(
        .inst(inst),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .i_rs1_raddr(i_rs1_raddr),
        .i_rs2_raddr(i_rs2_raddr),
        .i_rd_waddr(rd_waddr),
        .i_format(i_format),
        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2)
    );

    rf #(.BYPASS_EN(1)) u_rf(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(i_rs1_raddr),
        .i_rs2_raddr(i_rs2_raddr),
        .i_rd_waddr(MEM_WB_rd),
        .i_rd_wdata(WB_rd_data),
        .o_rs1_rdata(o_rs1_rdata),
        .o_rs2_rdata(o_rs2_rdata),
        .i_rd_wen(rf_wen)
    );

    imm u_imm(
        .i_inst(inst),
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
        .IF_ID_rs1(i_rs1_raddr),
        .IF_ID_rs2(i_rs2_raddr),
        .ID_EX_RegWrite(ID_EX_RegWrite),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2),
        .IF_Stall(IF_Stall),
        .ID_Stall(ID_Stall)
    );

    redirect_detect u_redirect_detect(
        .opcode(opcode),
        .pc(pc),
        .pc4(pc4),
        .o_rs1_rdata(o_rs1_rdata),
        .o_immediate(o_immediate),
        .take_branch(take_branch),
        .ID_Stall(ID_Stall),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .next_pc(next_pc)
    );
     

endmodule