module EX(
    input wire [31:0] rs1_rdata,
    input wire [31:0] rs2_rdata,
    input wire [31:0] immediate,
    input wire [31:0] pc,
    input wire ALUSrc,
    input wire AUIPC,
    input wire [1:0] jump,
    
    input [1:0] ALUOp,
    input [6:0] funct7,
    input [2:0] funct3,
    
    output [31:0] ALU_result,
    output zero,
    output [31:0] branch_target,
    output [31:0] jump_target
);

    wire [31:0] op2;
    wire [31:0] op1;
    assign op2 = ALUSrc ? immediate : rs2_rdata;
    assign op1 = AUIPC ? pc : 
                 LUI ? 32'd0 :
                       rs1_rdata;

    alu u_alu (
        .op1(op1),
        .op2(op2),
        .ALU_control(ALU_control),
        .funct3(funct3),
        .ALU_result(ALU_result),
        .zero(zero)
    );

    wire [3:0] ALU_control;

    ALU_Control u_ALU_Control (
        .ALUop(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUsrc(ALUSrc),
        .ALU_control(ALU_control)
    );

    //branch_target ADDER
    assign branch_target = pc + immediate;

    //jump_target ADDER
    assign jump_target = (jump == 2'b01) ? (pc + immediate) : (jump == 2'b10) ? ((rs1_rdata + immediate) & 32'hFFFFFFFE) : 32'b0;
    
endmodule
