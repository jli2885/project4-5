module MEM (
    input wire MemRead,
    input wire MemWrite,
    input wire [31:0] ALU_result,
    input wire [31:0] WriteData,
    input wire [2:0] funct3,

    output wire misaligned,
    output wire [31:0] ReadData,

    // Data from/to dmem
    input wire [31:0] i_dmem_rdata,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_addr,
    output wire [31:0] o_dmem_wdata,
    output wire [3:0] o_dmem_mask
);

    Data_Memory data_memory (
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALU_result(ALU_result),
        .WriteData(WriteData),
        .funct3(funct3),
        .misaligned(misaligned),
        .ReadData(ReadData),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask)
    );
    
endmodule