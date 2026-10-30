module EX(
    input wire [31:0] rs1_rdata,
    input wire [31:0] rs2_rdata,
    input wire [31:0] immediate,
    input wire [31:0] pc,
    input wire [31:0] pc4,
    input wire        ALUSrc,
    // From control_unit: 00 = add, 01 = branch, 10 = R/I-type, 11 = LUI
    input wire [1:0]  ALUOp,
    input wire [6:0]  funct7,
    input wire [2:0]  funct3,
    input wire [6:0]  opcode,
    output wire [31:0] ex_result
);

    localparam [6:0] OPCODE_JAL   = 7'b1101111;
    localparam [6:0] OPCODE_JALR  = 7'b1100111;
    localparam [6:0] OPCODE_AUIPC = 7'b0010111;

    wire [31:0] alu_op1;
    wire [31:0] alu_op2;
    wire [31:0] alu_result;
    wire [1:0]  alu_class;
    wire        is_lui;
    wire        is_auipc;
    wire        is_link;
    wire        ALU_sub;
    wire        ALU_arith;
    wire        ALU_unsigned;
    wire [2:0]  ALU_sel;

    assign is_lui   = (ALUOp == 2'b11);
    assign is_auipc = (opcode == OPCODE_AUIPC);
    assign is_link  = (opcode == OPCODE_JAL) || (opcode == OPCODE_JALR);

    assign alu_class = is_lui ? 2'b00 : (ALUOp == 2'b10 && !opcode[5])  ? 2'b11 : ALUOp;

    //ALU control
    ALU_Control alu_control (
        .ALU_Class(alu_class),
        .Funct3(funct3),
        .Funct7(funct7[5]),
        .ALU_sub(ALU_sub),
        .ALU_arith(ALU_arith),
        .ALU_unsigned(ALU_unsigned),
        .ALUop(ALU_sel)
    );

    //ALU src mux
    assign alu_op1 = is_auipc ? pc :
                     is_lui   ? 32'd0 :
                                rs1_rdata;
    assign alu_op2 = ALUSrc ? immediate : rs2_rdata;

    //ALU
    alu alu (
        .i_op1(alu_op1),
        .i_op2(alu_op2),
        .i_opsel(ALU_sel),
        .i_sub(ALU_sub),
        .i_unsigned(ALU_unsigned),
        .i_arith(ALU_arith),
        .o_result(alu_result),
        .o_eq(),
        .o_slt()
    );

    // jal/jalr write the return address to rd
    assign ex_result = is_link ? pc4 : alu_result;
endmodule
