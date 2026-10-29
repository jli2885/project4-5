module WB(
   input [31:0] ALU_result,
   input [31:0] Mem_data,

   input MemtoReg,

   output reg [31:0] WB_data
);

    assign WB_data = MemtoReg ? Mem_data : ALU_result;
    
endmodule