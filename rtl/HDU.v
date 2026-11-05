module HDU (
    input wire [31:0] IF_ID_inst,
    input wire IF_ID_valid,
    input wire ID_EX_valid, 
    input wire ID_EX_RegWrite,
    input wire [4:0] ID_EX_rd,
    input wire EX_MEM_valid, 
    input wire EX_MEM_RegWrite,
    input wire [4:0] EX_MEM_rd,
    input wire MEM_WB_valid, MEM_WB_RegWrite,
    input wire [4:0] MEM_WB_rd,
    input wire redirect_ex,
    output wire stall_PC, stall_IFID, flush_IFID, flush_IDEX,
    output wire data_hazard
);
    wire [6:0] opcode=IF_ID_inst[6:0];
    wire [4:0] rs1=IF_ID_inst[19:15];
    wire [4:0] rs2=IF_ID_inst[24:20];

    wire uses_rs1= (opcode==7'b0110011 || opcode==7'b0010011 || opcode==7'b0000011 || 
                    opcode==7'b0100011 || opcode==7'b1100011 || opcode==7'b1100111);
    wire uses_rs2= (opcode==7'b0110011 || opcode==7'b0100011 || opcode==7'b1100011);

    wire ex_hit= ID_EX_valid && ID_EX_RegWrite && |ID_EX_rd &&
                ((uses_rs1 && rs1==ID_EX_rd)||(uses_rs2 && rs2==ID_EX_rd));

    wire mem_hit= EX_MEM_valid && EX_MEM_RegWrite && |EX_MEM_rd &&
                ((uses_rs1 && rs1==EX_MEM_rd)||(uses_rs2 && rs2==EX_MEM_rd));

    assign data_hazard = IF_ID_valid && (ex_hit||mem_hit);
    assign stall_PC = data_hazard && !redirect_ex;
    assign stall_IFID = data_hazard && !redirect_ex;
    assign flush_IFID = redirect_ex;
    assign flush_IDEX = redirect_ex || data_hazard;
endmodule
