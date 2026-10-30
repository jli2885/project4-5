//Hazard Detection Unit
module HDU(
    // Destination register of the instruction in the execute stage.
    input wire [4:0] ID_EX_rd,
    // Destination register of the instruction in the memory stage.
    input wire [4:0] EX_MEM_rd,
    // First source register of the instruction in the decode stage.
    input wire [4:0] IF_ID_rs1,
    // Second source register of the instruction in the decode stage.
    input wire [4:0] IF_ID_rs2,
    // Indicates that the execute-stage instruction writes to a register.
    input wire ID_EX_RegWrite,
    // Indicates that the memory-stage instruction writes to a register.
    input wire EX_MEM_RegWrite,
    // Indicates whether the decode-stage instruction reads its first source register.
    // Note: Need to have some kind of logic that determines that we actually use the register.
    // If we dont do this some register number that we dont intend will propogate
    input wire uses_rs1,
    // Indicates whether the decode-stage instruction reads its second source register.
    input wire uses_rs2,
    // Stalls instruction fetch while a source-register hazard is present.
    output wire IF_Stall,
    // Stalls instruction decode while a source-register hazard is present.
    output wire ID_Stall
);  

    assign ID_Stall = (((ID_EX_rd == IF_ID_rs1 && uses_rs1) || (ID_EX_rd == IF_ID_rs2 && uses_rs2)) &&
                      ID_EX_RegWrite && (ID_EX_rd != 5'd0)) ||
                      (((EX_MEM_rd == IF_ID_rs1 && uses_rs1) || (EX_MEM_rd == IF_ID_rs2 && uses_rs2)) &&
                      EX_MEM_RegWrite && (EX_MEM_rd != 5'd0));
    assign IF_Stall = ID_Stall;
endmodule