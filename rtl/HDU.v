//Hazard Detection Unit
module HDU(
    input wire [4:0] ID_EX_rd,
    input wire [4:0] EX_MEM_rd,
    input wire [4:0] IF_ID_rs1,
    input wire [4:0] IF_ID_rs2,
    input wire ID_EX_RegWrite,
    input wire EX_MEM_RegWrite,
    input wire uses_rs1,
    input wire uses_rs2,
    output wire IF_Stall,
    output wire ID_Stall
);
    assign ID_Stall = (((ID_EX_rd == IF_ID_rs1 && uses_rs1) || (ID_EX_rd == IF_ID_rs2 && uses_rs2)) &&
                      ID_EX_RegWrite && (ID_EX_rd != 5'd0)) ||
                      (((EX_MEM_rd == IF_ID_rs1 && uses_rs1) || (EX_MEM_rd == IF_ID_rs2 && uses_rs2)) &&
                      EX_MEM_RegWrite && (EX_MEM_rd != 5'd0));
    assign IF_Stall = ID_Stall;
endmodule