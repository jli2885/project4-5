module branch_control(
    input branch,
    input [2:0] funct3,
    input [31:0] o_rs1_rdata,
    input [31:0] o_rs2_rdata,

    output reg take_branch
);

wire sign_lt;
assign sign_lt = (o_rs1_rdata[31] != o_rs2_rdata[31]) ? o_rs1_rdata[31] : (o_rs1_rdata < o_rs2_rdata);

always @(*) begin
    case(funct3)
        3'b000: take_branch = branch & (o_rs1_rdata == o_rs2_rdata); // BEQ
        3'b001: take_branch = branch & (o_rs1_rdata != o_rs2_rdata); // BNE
        3'b100: take_branch = branch & sign_lt; // BLT
        3'b101: take_branch = branch & !sign_lt; // BGE
        3'b110: take_branch = branch & (o_rs1_rdata < o_rs2_rdata); // BLTU
        3'b111: take_branch = branch & (o_rs1_rdata >= o_rs2_rdata); // BGEU
        default: take_branch = 1'b0;
    endcase
end

endmodule