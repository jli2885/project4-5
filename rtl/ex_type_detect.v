module ex_type_detect(
    input wire [1:0] ALUOp,
    input wire [6:0] opcode,
    output wire is_lui,
    output wire is_auipc,
    output wire is_link,
    output wire [1:0] alu_class
);
    localparam [6:0] OPCODE_JAL   = 7'b1101111;
    localparam [6:0] OPCODE_JALR  = 7'b1100111;
    localparam [6:0] OPCODE_AUIPC = 7'b0010111;

    assign is_lui   = (ALUOp == 2'b11);
    assign is_auipc = (opcode == OPCODE_AUIPC);
    assign is_link  = (opcode == OPCODE_JAL) || (opcode == OPCODE_JALR);
    assign alu_class = is_lui ? 2'b00 : (ALUOp == 2'b10 && !opcode[5])  ? 2'b11 : ALUOp;
    
endmodule