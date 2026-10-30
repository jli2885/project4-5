module ALU_Control(
	input wire [1:0] ALUop,
	input wire [2:0] funct3,
	input wire [6:0] funct7,
	input ALUsrc,

	output reg [3:0] ALU_control
);

always @(*) begin
	case(ALUop)
		2'b00 : ALU_control = 4'b0000; //load,store,JALR,AUIPC
		2'b01 : ALU_control = 4'b1011; //branch,
		2'b10 : begin
			case(funct3)
				3'b000: begin
					if(funct7[5] == 1'b1 && ALUsrc == 1'b0)
						ALU_control = 4'b0001; //SUB
					else
						ALU_control = 4'b0000; //ADD
				end
				3'b001: ALU_control = 4'b0101; //SLL
				3'b010: ALU_control = 4'b1000; //SLT
				3'b011: ALU_control = 4'b1001; //SLTU
				3'b100: ALU_control = 4'b0100; //XOR
				3'b101: begin
					if(funct7[5] == 1'b0)
						ALU_control = 4'b0110; //SRL
					else
						ALU_control = 4'b0111; //SRA
				end
				3'b110: ALU_control = 4'b0011; //OR
				3'b111: ALU_control = 4'b0010; //AND
				default: ALU_control = 4'b0000;
			endcase
		end
		2'b11 : ALU_control = 4'b1010; //LUI
		default: ALU_control = 4'b0000;
	endcase
end
	
endmodule
