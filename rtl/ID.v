
module ID(
    input i_clk,
    input i_rst,

    // ID stage input
    input [31:0] inst,

    // WB stage input
    input [31:0] wb_data,
    input [4:0] wb_rd_waddr,
    input wb_regwrite,

    // ID stage output
    output [6:0] opcode,
    output [2:0] funct3,
    output [6:0] funct7,
    output [4:0] rs1_raddr,
    output [4:0] rs2_raddr,
    output [31:0] rs1_rdata,
    output [31:0] rs2_rdata,
    output [4:0] rd_waddr,
    output [31:0] imm,

    // Control signals
    output wire regwrite,
    output wire memtoreg,
    output wire memread,
    output wire memwrite,
    output wire branch,
    output wire [1:0] ALUop,
    output wire ALUsrc,
    output wire [1:0] jump,
    output wire AUIPC
);

    wire [5:0] i_format;

    control_unit u_control_unit(
        .opcode(opcode),
        .ALUsrc(ALUsrc),
        .ALUop(ALUop),
        .branch(branch),
        .memread(memread),
        .memwrite(memwrite),
        .regwrite(regwrite),
        .memtoreg(memtoreg),
        .jump(jump),
        .AUIPC(AUIPC)
    );

    decoder u_decoder(
        .inst(inst),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .i_rs1_raddr(rs1_raddr),
        .i_rs2_raddr(rs2_raddr),
        .i_rd_waddr(rd_waddr),
        .i_format(i_format)
    );

    rf #(.BYPASS_EN(1)) u_rf(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(rs1_raddr),
        .i_rs2_raddr(rs2_raddr),
        .i_rd_waddr(wb_rd_waddr),
        .i_rd_wdata(wb_data),
        .i_rd_wen(wb_regwrite),
        .o_rs1_rdata(rs1_rdata),
        .o_rs2_rdata(rs2_rdata)
    );

    imm u_imm(
        .i_inst(inst),
        .i_format(i_format),
        .o_immediate(imm)
    );

endmodule
