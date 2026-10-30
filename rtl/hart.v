module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    output wire [31:0] o_retire_dmem_addr,
    output wire [ 3:0] o_retire_dmem_mask,
    output wire        o_retire_dmem_ren,
    output wire        o_retire_dmem_wen,
    output wire [31:0] o_retire_dmem_rdata,
    output wire [31:0] o_retire_dmem_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

    // IF Stage outputs 
    wire [31:0] if_pc;
    wire [31:0] if_pc4;
    wire [31:0] if_inst;

    // ID Stage outputs
    wire id_RegWrite,
    wire id_MemtoReg,
    wire id_branch,
    wire id_MemRead,
    wire id_MemWrite,
    wire [1:0] id_ALUOp,
    wire id_ALUSrc,

    wire [31:0] id_pc,
    wire [31:0] id_inst
    wire [31:0] id_ReadData1,
    wire [31:0] id_ReadData2,
    wire [31:0] id_imm,

    // EX Stage outputs
    wire ex_Zero,
    wire ex_RegWrite,
    wire ex_MemtoReg,
    wire ex_branch,
    wire ex_MemRead,
    wire ex_MemWrite,
    wire [31:0] ex_ALU_result,
    wire [31:0] ex_WriteData,
    wire [31:0] ex_Target_address,
    wire [31:0] ex_inst,

    // MEM Stage outputs
    wire mem_MemtoReg,
    wire mem_RegWrite,
    wire [31:0] mem_LoadData,
    wire [31:0] mem_ALU_result,

    // WB Stage inputs
    wire wb_MemtoReg,
    wire [31:0] wb_Alu_result,
    wire [31:0] wb_Mem_data,
   
    // WB Stage outputs
    wire [31:0] wb_data;

    // IF Instantiation
    IF #(
        .RESET_ADDR(RESET_ADDR)
    ) if_stage (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_mem_rdata(i_imem_rdata),
        // Hold
        .redirect(),
        .redirect_pc(),
        .IF_Stall(),
        .o_mem_raddr(o_imem_raddr),
        .PC_4(if_pc4),
        .PC(if_pc),
        .inst(if_inst)
    );

    // IF/ID Pipeline Register
    If_ID_reg if_id_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .in_pc(if_pc),
        .in_pc4(if_pc4),
        .in_inst(if_inst),
        .out_pc(id_pc),
        .out_pc4(),
        .out_inst(id_inst)
        .IF_Stall(),
        .redirect()
        .IF_ID_valid()
    );

    // ID Instantiation (Placeholder)
    ID id_stage (
        
    );

    // ID/EX Pipeline Register
    ID_EX_reg id_ex_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .inRegWrite(id_RegWrite),
        .inMemtoReg(id_MemtoReg),
        .inbranch(id_branch),
        .inMemRead(id_MemRead),
        .inMemWrite(id_MemWrite),
        .inALUOp(id_ALUOp),
        .inALUSrc(id_ALUSrc),
        .in_pc(id_pc),
        .in_inst(id_inst),
        .in_ReadData1(id_ReadData1),
        .in_ReadData2(id_ReadData2),
        .in_imm(id_imm),
        .outRegWrite(ex_RegWrite),
        .outMemtoReg(ex_MemtoReg),
        .outbranch(ex_branch),
        .outMemRead(ex_MemRead),
        .outMemWrite(ex_MemWrite),
        .outALUOp(ex_ALUOp),
        .outALUSrc(ex_ALUSrc),
        .out_pc(ex_pc),
        .out_inst(ex_inst),
        .out_ReadData1(ex_ReadData1),
        .out_ReadData2(ex_ReadData2),
        .out_imm(ex_imm)
    );
    // EX Instantiation (Placeholder)

    // EX/MEM Pipeline Register
    EX_MEM_reg ex_mem_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .inZero(ex_Zero),
        .inRegWrite(ex_RegWrite),
        .inMemtoReg(ex_MemtoReg),
        .inbranch(ex_branch),
        .inMemRead(ex_MemRead),
        .inMemWrite(ex_MemWrite),
        .in_ALU_result(ex_ALU_result),
        .in_WriteData(ex_WriteData),
        .in_Target_address(ex_Target_address),
        .out_RegWrite(mem_RegWrite),
        .out_MemtoReg(mem_MemtoReg),
        .out_branch(mem_branch),
        .out_MemRead(mem_MemRead),
        .out_MemWrite(mem_MemWrite),
        .out_ALU_result(mem_ALU_result),
        .out_WriteData(mem_WriteData),
        .out_Target_address(mem_Target_address)
        .out_inst(mem_inst)
    );
    // MEM Instantiation (Placeholder)

    // MEM/WB Pipeline register
    MEM_WB_reg mem_wb_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .in_MemtoReg(mem_MemtoReg),
        .in_RegWrite(mem_RegWrite),
        .in_LoadData(mem_LoadData),
        .in_ALU_result(mem_ALU_result),
        .out_MemtoReg(wb_MemtoReg),
        .out_RegWrite(wb_RegWrite),
        .out_LoadData(wb_Mem_data),
        .out_ALU_result(wb_Alu_result)
    );
    // WB Instantiation
    WB wb_stage (
        .ALU_result(wb_Alu_result),
        .Mem_data(wb_Mem_data),
        .MemtoReg(wb_MemtoReg),
        .WB_data(wb_data)
    );

    // The retire signals should just the signals after the
    // write back stage
    assign o_retire_valid      = MEM_WB_valid;
    assign o_retire_inst       = MEM_WB_inst;
    assign o_retire_trap       = MEM_WB_trap;
    assign o_retire_halt       = MEM_WB_halt;
    assign o_retire_rs1_raddr  = MEM_WB_rs1_addr;
    assign o_retire_rs2_raddr  = MEM_WB_rs2_addr;
    assign o_retire_rs1_rdata  = MEM_WB_rs1_data;
    assign o_retire_rs2_rdata  = MEM_WB_rs2_data;
    assign o_retire_rd_waddr   = MEM_WB_RegWrite ? MEM_WB_rd : 5'd0;
    assign o_retire_rd_wdata   = wb_data;
    assign o_retire_dmem_addr  = MEM_WB_dmem_addr;
    assign o_retire_dmem_mask  = MEM_WB_dmem_mask;
    assign o_retire_dmem_ren   = MEM_WB_dmem_ren;
    assign o_retire_dmem_wen   = MEM_WB_dmem_wen;
    assign o_retire_dmem_rdata = MEM_WB_dmem_rdata;
    assign o_retire_dmem_wdata = MEM_WB_dmem_wdata;
    assign o_retire_pc         = MEM_WB_pc;
    assign o_retire_next_pc    = MEM_WB_next_pc;
endmodule

`default_nettype wire
