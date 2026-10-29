module EX(
    //Data signals
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [31:0] imm,
    input wire [31:0] pc,
    input wire [31:0] pc_plus4,
    //Control signals
    input wire ALU_Src,
    input wire auipc,
    input wire ALU_sub,
    input wire ALU_sel,
    input wire ALU_unsigned,
    input wire ALU_arith,
    input wire [1:0] PC_sel,
    //Outputs
    output wire [31:0] ALU_result,
);


endmodule