module alu(
    input [31:0] op1,
    input [31:0] op2,
    input [3:0] ALU_control,
    input [2:0] funct3,

    output reg [31:0] ALU_result,
    output reg zero
);

wire fill;
wire [31:0] l1,l2,l4,l8,l16;
wire [31:0] r1,r2,r4,r8,r16;

wire sign_lt;

assign fill = (ALU_control == 4'b0111) & op1[31];

assign l1 = op2[0] ? {op1[30:0], 1'b0} : op1;
assign l2 = op2[1] ? {l1[29:0], 2'b0} : l1;
assign l4 = op2[2] ? {l2[27:0], 4'b0} : l2;
assign l8 = op2[3] ? {l4[23:0], 8'b0} : l4;
assign l16 = op2[4] ? {l8[15:0], 16'b0} : l8;

assign r1 = op2[0] ? {fill, op1[31:1]} : op1;
assign r2 = op2[1] ? {{2{fill}}, r1[31:2]} : r1;
assign r4 = op2[2] ? {{4{fill}}, r2[31:4]} : r2;
assign r8 = op2[3] ? {{8{fill}}, r4[31:8]} : r4;
assign r16 = op2[4] ? {{16{fill}}, r8[31:16]} : r8;

assign sign_lt = (op1[31] != op2[31]) ? op1[31] : (op1 < op2);

always @(*) begin
    ALU_result = 32'b0;
    zero = 1'b0;

    case(ALU_control)
        4'b0000: ALU_result = op1 + op2; //ADD
        4'b0001: ALU_result = op1 - op2; //SUB
        4'b0010: ALU_result = op1 & op2; //AND
        4'b0011: ALU_result = op1 | op2; //OR
        4'b0100: ALU_result = op1 ^ op2; //XOR
        4'b0101: ALU_result = l16; //SLL
        4'b0110: ALU_result = r16; //SRL
        4'b0111: ALU_result = r16; //SRA
        4'b1000: ALU_result = {31'b0, sign_lt}; //SLT
        4'b1001: ALU_result = {31'b0, (op1 < op2)}; //SLTU
        4'b1010: ALU_result = op2; //LUI
        4'b1011: begin//branch
            ALU_result = op1 - op2;
            case(funct3)
                3'b000: zero = (ALU_result == 32'b0) ? 1'b1 : 1'b0; //BEQ
                3'b001: zero = (ALU_result != 32'b0) ? 1'b1 : 1'b0; //BNE
                3'b100: zero = sign_lt; //BLT
                3'b101: zero = ~sign_lt; //BGE
                3'b110: zero = (op1 < op2) ? 1'b1 : 1'b0; //BLTU
                3'b111: zero = (op1 >= op2) ? 1'b1 : 1'b0; //BGEU
                default: zero = 1'b0;
            endcase
        end
        default: begin
            ALU_result = 32'b0;
            zero = 1'b0;
        end
    endcase
end

endmodule