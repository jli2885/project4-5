module control_unit(
    input [6:0] opcode,

    output reg ALUsrc,
    output reg [1:0] ALUop,
    output reg branch,
    output reg memread,
    output reg memwrite,
    output reg regwrite,
    output reg memtoreg
);

always @(*) begin
    case(opcode)
        //R-type
        7'b0110011: begin
            ALUsrc = 0;
            ALUop = 2'b10;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 0;
        end

        //I-type
        7'b0010011: begin
            ALUsrc = 1;
            ALUop = 2'b10;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 0;
        end

        //Load
        7'b0000011: begin
            ALUsrc = 1;
            ALUop = 2'b00;
            branch = 0;
            memread = 1;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 1;
        end

        //Store
        7'b0100011: begin
            ALUsrc = 1;
            ALUop = 2'b00;
            branch = 0;
            memread = 0;
            memwrite = 1;
            regwrite = 0;
            memtoreg = 0;
        end

        //Branch
        7'b1100011: begin
            ALUsrc = 0;
            ALUop = 2'b01;
            branch = 1;
            memread = 0;
            memwrite = 0;
            regwrite = 0;
            memtoreg = 0;
        end

        //JAL
        7'b1101111: begin
            ALUsrc = 1;
            ALUop = 2'b00;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 0;
        end

        //JALR
        7'b1100111: begin
            ALUsrc = 1;
            ALUop = 2'b00;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 0;
        end

        //LUI
        7'b0110111: begin
            ALUsrc = 1;
            ALUop = 2'b11;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 0;
        end

        //AUIPC
        7'b0010111: begin
            ALUsrc = 1;
            ALUop = 2'b00;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 1;
            memtoreg = 0;
        end

        default: begin
            ALUsrc = 0;
            ALUop = 2'b00;
            branch = 0;
            memread = 0;
            memwrite = 0;
            regwrite = 0;
            memtoreg = 0;
        end
    endcase
end

endmodule