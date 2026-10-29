module control_unit(
    input [6:0] opcode,

    output reg [2:0] EX,        //ALUsrc[2],ALUop[1:0]
    output reg [2:0] MEM,       //branch[2],memread[1],memwrite[0]
    output reg [1:0] WB,        //regwrite[1],memtoreg[0]
);

reg ALUsrc;
reg [1:0] ALUop;
reg branch;
reg memread;
reg memwrite;
reg regwrite;
reg memtoreg;

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
    EX = {ALUsrc, ALUop};
    MEM = {branch, memread, memwrite};
    WB = {regwrite, memtoreg};
end

endmodule