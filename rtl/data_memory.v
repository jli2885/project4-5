module Data_Memory (
    // Input signals
    input wire MemRead,
    input wire MemWrite,
    
    // Address and WriteData inputs
    input wire [31:0] ALU_result,
    input wire [31:0] WriteData,
    input wire [2:0] funct3,
    // Output write back data
    output wire misaligned,
    output wire [31:0] ReadData,

    // Data from dmem
    input wire [31:0] i_dmem_rdata,
    // Signals & Data to dmem
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_addr,
    output wire [31:0] o_dmem_wdata,
    output wire [3:0] o_dmem_mask
    
);

    wire [1:0] byte_offset;
    wire [31:0] shifted_data;
    wire [3:0] byte_mask;

    wire byte_access;
    wire half_access;
    wire word_access;
    wire access_valid;

    // Address Alignment
    assign byte_offset = ALU_result[1:0];
    assign o_dmem_addr = {ALU_result[31:2], 2'b00};

    // Access Type Detection
    assign byte_access = (funct3 == 3'b000) || (MemRead && funct3 == 3'b100);

    assign half_access = (funct3 == 3'b001) || (MemRead && funct3 == 3'b101);

    assign word_access = (funct3 == 3'b010);

    assign access_valid = byte_access || half_access || word_access;

    // Misalignment Detection
    assign misaligned = (half_access && ALU_result[0]) || (word_access && (byte_offset != 2'b00));

    // Read / Write Enable
    assign o_dmem_ren = MemRead && !MemWrite && access_valid && !misaligned;

    assign o_dmem_wen = MemWrite && !MemRead && access_valid && !misaligned;

    // Byte Mask Generation
    assign byte_mask =
        byte_access ?
            ((byte_offset == 2'b00) ? 4'b0001 :
            (byte_offset == 2'b01) ? 4'b0010 :
            (byte_offset == 2'b10) ? 4'b0100 :
            4'b1000) :

        half_access ?
            ((byte_offset == 2'b00) ? 4'b0011 :
            (byte_offset == 2'b10) ? 4'b1100 :
            4'b0000) :

        word_access ? 4'b1111 : 4'b0000;

    assign o_dmem_mask = (o_dmem_ren || o_dmem_wen) ? byte_mask : 4'b0000;

    // Store Data Alignment
    assign o_dmem_wdata = (byte_offset == 2'b00) ? WriteData :
                          (byte_offset == 2'b01) ? {WriteData[23:0], 8'b0} :
                          (byte_offset == 2'b10) ? {WriteData[15:0], 16'b0} :
                          {WriteData[7:0], 24'b0};


    // Load Data 
    assign shifted_data = (byte_offset == 2'b00) ? i_dmem_rdata :
                          (byte_offset == 2'b01) ? {8'b0,  i_dmem_rdata[31:8]} :
                          (byte_offset == 2'b10) ? {16'b0, i_dmem_rdata[31:16]} :
                          {24'b0, i_dmem_rdata[31:24]};

    //  According to funct3, sign extend or zero extend the data
    assign ReadData = !o_dmem_ren ? 32'b0 :
                      (funct3 == 3'b000) ?{{24{shifted_data[7]}}, shifted_data[7:0]} :
                      (funct3 == 3'b001) ?{{16{shifted_data[15]}}, shifted_data[15:0]} :
                      (funct3 == 3'b010) ? shifted_data :
                      (funct3 == 3'b100) ? {24'b0, shifted_data[7:0]} :
                      (funct3 == 3'b101) ? {16'b0, shifted_data[15:0]} :
                      32'b0;


endmodule