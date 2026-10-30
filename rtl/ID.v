module ID(
    input i_clk,
    input i_rst,

    input wire EX_MEM_RegWrite,
    input [31:0] inst,
    input wire [31:0] WB_rd_data,
    input wire [4:0] MEM_WB_rd

    output wire regwrite,
    output wire memtoreg,
    output wire memread,
    output wire memwrite,
    output wire branch,
    output wire [1:0] ALUop,
    output wire ALUsrc,
    output wire [1:0] jump,
    output wire AUIPC,
    
    output [31:0] o_rs1_rdata,
    output [31:0] o_rs2_rdata,
    output [31:0] o_immediate,
    output [6:0] funct7,
    output [2:0] funct3,
    output [6:0] opcode
);
    wire uses_rs1;
    wire uses_rs2;
    wire [4:0] rs1_raddr;
    wire [4:0] rs2_raddr;
    wire [5:0] i_format;
    
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
        .i_rs1_raddr(rs1_raddr),
        .i_rs2_raddr(rs2_raddr),
        .i_rd_waddr(i_rd_waddr),
        .i_format(i_format),
        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2)
    );

    rf #(.BYPASS_EN(1)) u_rf(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(rs1_raddr),
        .i_rs2_raddr(rs2_raddr),
        .i_rd_waddr(i_rd_waddr),
        .i_rd_wdata(i_rd_wdata),
        .o_rs1_rdata(o_rs1_rdata),
        .o_rs2_rdata(o_rs2_rdata),
        .i_rd_wen(i_rd_wen)
    );

    imm u_imm(
        .i_inst(inst),
        .i_format(i_format),
        .o_immediate(o_immediate)
    );


    

endmodule