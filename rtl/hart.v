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
    wire        redirect;
    wire [31:0] redirect_pc;
    wire        IF_Stall;
    wire        ID_Stall;
    wire        id_ALU_src;
    wire        id_auipc;
    wire        id_ALU_sub;
    wire [ 2:0] id_ALU_sel;
    wire        id_ALU_unsigned;
    wire        id_ALU_arith;
    wire        id_mem_read;
    wire        id_mem_write;
    wire [ 2:0] id_funct3;
    wire        id_reg_write;
    wire        id_mem_to_reg;
    wire        id_link;        // jal | jalr, writes pc + 4 to rd
    wire        id_is_lui;
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_imm;
    wire [ 4:0] id_rs1_addr;
    wire [ 4:0] id_rs2_addr;
    wire [ 4:0] id_rd;
    wire [31:0] id_next_pc;
    wire        id_trap;        // misaligned branch/jump target
    wire        id_halt;        // ebreak

    // EX Stage outputs
    wire [31:0] ex_alu_result;
    wire [31:0] ex_result;

    // MEM Stage outputs
    wire [31:0] mem_load_data;  // shifted and sign/zero extended
    wire        mem_misaligned;

    // WB Stage outputs
    wire [31:0] wb_data;

    // Pipeline register contents
    // IF/ID
    reg         IF_ID_valid;
    reg  [31:0] IF_ID_pc;
    reg  [31:0] IF_ID_pc4;
    reg  [31:0] IF_ID_inst;

    // ID/EX
    reg         ID_EX_valid;
    reg  [31:0] ID_EX_pc;
    reg  [31:0] ID_EX_pc4;
    reg  [31:0] ID_EX_inst;
    reg  [31:0] ID_EX_next_pc;
    reg  [31:0] ID_EX_rs1_data;
    reg  [31:0] ID_EX_rs2_data;
    reg  [31:0] ID_EX_imm;
    reg  [ 4:0] ID_EX_rs1_addr;
    reg  [ 4:0] ID_EX_rs2_addr;
    reg  [ 4:0] ID_EX_rd;
    reg         ID_EX_ALU_src;
    reg         ID_EX_auipc;
    reg         ID_EX_ALU_sub;
    reg  [ 2:0] ID_EX_ALU_sel;
    reg         ID_EX_ALU_unsigned;
    reg         ID_EX_ALU_arith;
    reg         ID_EX_mem_read;
    reg         ID_EX_mem_write;
    reg  [ 2:0] ID_EX_funct3;
    reg         ID_EX_RegWrite;
    reg         ID_EX_mem_to_reg;
    reg         ID_EX_link;
    reg         ID_EX_is_lui;
    reg         ID_EX_trap;
    reg         ID_EX_halt;

    // EX/MEM
    reg         EX_MEM_valid;
    reg  [31:0] EX_MEM_pc;
    reg  [31:0] EX_MEM_inst;
    reg  [31:0] EX_MEM_next_pc;
    reg  [31:0] EX_MEM_result;      // address for loads/stores, else rd value
    reg  [31:0] EX_MEM_rs1_data;
    reg  [31:0] EX_MEM_rs2_data;    // store data
    reg  [ 4:0] EX_MEM_rs1_addr;
    reg  [ 4:0] EX_MEM_rs2_addr;
    reg  [ 4:0] EX_MEM_rd;
    reg         EX_MEM_mem_read;
    reg         EX_MEM_mem_write;
    reg  [ 2:0] EX_MEM_funct3;
    reg         EX_MEM_RegWrite;
    reg         EX_MEM_mem_to_reg;
    reg         EX_MEM_trap;
    reg         EX_MEM_halt;

    // MEM/WB
    reg         MEM_WB_valid;
    reg  [31:0] MEM_WB_pc;
    reg  [31:0] MEM_WB_inst;
    reg  [31:0] MEM_WB_next_pc;
    reg  [31:0] MEM_WB_result;
    reg  [31:0] MEM_WB_load_data;
    reg  [31:0] MEM_WB_rs1_data;
    reg  [31:0] MEM_WB_rs2_data;
    reg  [ 4:0] MEM_WB_rs1_addr;
    reg  [ 4:0] MEM_WB_rs2_addr;
    reg  [ 4:0] MEM_WB_rd;
    reg         MEM_WB_RegWrite;
    reg         MEM_WB_mem_to_reg;
    reg         MEM_WB_trap;
    reg         MEM_WB_halt;
    reg  [31:0] MEM_WB_dmem_addr;
    reg  [ 3:0] MEM_WB_dmem_mask;
    reg         MEM_WB_dmem_ren;
    reg         MEM_WB_dmem_wen;
    reg  [31:0] MEM_WB_dmem_rdata;
    reg  [31:0] MEM_WB_dmem_wdata;

    // IF Instantiation
    IF #(
        .RESET_ADDR(RESET_ADDR)
    ) if_stage (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_imem_rdata(i_imem_rdata),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .IF_Stall(IF_Stall),
        .o_imem_raddr(o_imem_raddr),
        .PC_4(if_pc4),
        .PC(if_pc),
        .inst(if_inst)
    );

    // IF/ID Pipeline Register

    // ID Instantiation (Placeholder)

    // ID/EX Pipeline Register

    // EX Instantiation (Placeholder)

    // EX/MEM Pipeline Register

    // MEM Instantiation (Placeholder)

    // MEM/WB Pipeline register

    // WB Instantiation
    WB wb_stage (
        .ALU_result(MEM_WB_result),
        .Mem_data(MEM_WB_load_data),
        .MemtoReg(MEM_WB_mem_to_reg),
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
