module decoder(
    input [31:0] inst,
    output [6:0] opcode,
    output [4:0] i_rd_waddr,
    output [4:0] i_rs1_raddr,
    output [4:0] i_rs2_raddr,
    output [6:0] funct7,
    output [2:0] funct3,
    output uses_rs1,
    output uses_rs2,
    output reg [5:0] i_format
);
    assign opcode = inst[6:0];
    assign i_rd_waddr = inst[11:7];
    assign i_rs1_raddr = inst[19:15];
    assign i_rs2_raddr = inst[24:20];
    assign funct7 = inst[31:25];
    assign funct3 = inst[14:12];

    assign uses_rs1 = (opcode == 7'b0110011) || (opcode == 7'b0010011) || (opcode == 7'b0000011) || (opcode == 7'b0100011) || (opcode == 7'b1100011) || (opcode == 7'b1100111);
    assign uses_rs2 = (opcode == 7'b0110011) || (opcode == 7'b0100011) || (opcode == 7'b1100011);

    always @(*) begin
        case (opcode)
            7'b0110011: i_format = 6'b000001; //R-type
            7'b0010011, 7'b0000011, 7'b1100111: i_format = 6'b000010; //I-type, Load, JALR
            7'b0100011: i_format = 6'b000100; //S-type
            7'b1100011: i_format = 6'b001000; //B-type
            7'b0110111, 7'b0010111: i_format = 6'b010000; //U-type
            7'b1101111: i_format = 6'b100000; //J-type
            default: i_format = 6'b000000;
        endcase
    end

endmodule