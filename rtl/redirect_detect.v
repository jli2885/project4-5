module redirect_detect(
    input wire [6:0] opcode,
    input wire [31:0] pc,
    input wire [31:0] pc4,
    input wire [31:0] o_rs1_rdata,
    input wire [31:0] o_immediate,
    input wire take_branch,
    input wire ID_Stall,
    output wire redirect,
    output wire [31:0] redirect_pc,
    output wire [31:0] next_pc
);
    wire is_jal  = (opcode == 7'b1101111);
    wire is_jalr = (opcode == 7'b1100111);
    assign redirect_pc = is_jalr ? ((o_rs1_rdata + o_immediate) & 32'hFFFF_FFFE) : (pc + o_immediate);
    assign redirect    = (take_branch | is_jal | is_jalr) & !ID_Stall;
    assign next_pc     = redirect ? redirect_pc : pc4;  
endmodule