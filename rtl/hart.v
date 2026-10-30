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

    localparam [31:0] EBREAK = 32'h00100073;

    // IF
    wire [31:0] if_pc;
    wire [31:0] if_pc4;
    wire [31:0] if_inst;

    // ID
    wire        id_valid;
    wire [31:0] id_pc;
    wire [31:0] id_pc4;
    wire [31:0] id_inst;
    wire        id_RegWrite;
    wire        id_MemtoReg;
    wire        id_MemRead;
    wire        id_MemWrite;
    wire        id_branch;
    wire [1:0]  id_ALUOp;
    wire        id_ALUSrc;
    wire [31:0] id_rs1_rdata;
    wire [31:0] id_rs2_rdata;
    wire [31:0] id_imm;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [4:0]  id_rd;
    wire [6:0]  id_funct7;
    wire [2:0]  id_funct3;
    wire [6:0]  id_opcode;
    wire [31:0] id_next_pc;

    // Hazard / control-flow signals from ID
    wire        redirect;
    wire [31:0] redirect_pc;
    wire        IF_Stall;
    wire        ID_Stall;

    // EX
    wire        ex_valid;
    wire        ex_RegWrite;
    wire        ex_MemtoReg;
    wire        ex_MemRead;
    wire        ex_MemWrite;
    wire        ex_branch;
    wire [1:0]  ex_ALUOp;
    wire        ex_ALUSrc;
    wire [31:0] ex_rs1_rdata;
    wire [31:0] ex_rs2_rdata;
    wire [31:0] ex_imm;
    wire [31:0] ex_pc;
    wire [31:0] ex_pc4;
    wire [31:0] ex_inst;
    wire [31:0] ex_next_pc;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    wire [4:0]  ex_rd;
    wire [6:0]  ex_funct7;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_opcode;
    wire [31:0] ex_result;

    // MEM
    wire        mem_valid;
    wire        mem_RegWrite;
    wire        mem_MemtoReg;
    wire        mem_MemRead;
    wire        mem_MemWrite;
    wire [2:0]  mem_funct3;
    wire [4:0]  mem_rd;
    wire [31:0] mem_ALU_result;
    wire [31:0] mem_pc;
    wire [31:0] mem_next_pc;
    wire [31:0] mem_inst;
    wire [4:0]  mem_rs1;
    wire [4:0]  mem_rs2;
    wire [31:0] mem_rs1_rdata;
    wire [31:0] mem_rs2_rdata;
    wire [31:0] mem_LoadData;
    wire        mem_misaligned;
    wire        mem_trap;

    // WB
    wire        wb_valid;
    wire        wb_MemtoReg;
    wire        wb_RegWrite;
    wire [4:0]  wb_rd;
    wire [31:0] wb_LoadData;
    wire [31:0] wb_ALU_result;
    wire [31:0] wb_data;
    wire        wb_trap;
    wire [31:0] wb_pc;
    wire [31:0] wb_next_pc;
    wire [31:0] wb_inst;
    wire [4:0]  wb_rs1;
    wire [4:0]  wb_rs2;
    wire [31:0] wb_rs1_rdata;
    wire [31:0] wb_rs2_rdata;
    wire [31:0] wb_dmem_addr;
    wire [3:0]  wb_dmem_mask;
    wire        wb_dmem_ren;
    wire        wb_dmem_wen;
    wire [31:0] wb_dmem_rdata;
    wire [31:0] wb_dmem_wdata;

    
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

    // IF/ID Pipeline register
    IF_ID_reg if_id_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .redirect(redirect),
        .IF_Stall(IF_Stall),
        .in_pc(if_pc),
        .in_pc4(if_pc4),
        .in_inst(if_inst),
        .IF_ID_valid(id_valid),
        .out_pc(id_pc),
        .out_pc4(id_pc4),
        .out_inst(id_inst)
    );

    // ID Instantiation
    ID id_stage (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .inst(id_inst),
        .pc(id_pc),
        .pc4(id_pc4),
        .ID_EX_rd(ex_rd),
        .ID_EX_RegWrite(ex_RegWrite),
        .EX_MEM_rd(mem_rd),
        .EX_MEM_RegWrite(mem_RegWrite),
        .WB_rd_data(wb_data),
        .MEM_WB_rd(wb_rd),
        .MEM_WB_RegWrite(wb_RegWrite),
        .MEM_WB_valid(wb_valid),
        .regwrite(id_RegWrite),
        .memtoreg(id_MemtoReg),
        .memread(id_MemRead),
        .memwrite(id_MemWrite),
        .branch(id_branch),
        .ALUop(id_ALUOp),
        .ALUsrc(id_ALUSrc),
        .o_rs1_rdata(id_rs1_rdata),
        .o_rs2_rdata(id_rs2_rdata),
        .o_immediate(id_imm),
        .rd_waddr(id_rd),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .next_pc(id_next_pc),
        .IF_Stall(IF_Stall),
        .ID_Stall(ID_Stall),
        .i_rs1_raddr(id_rs1),
        .i_rs2_raddr(id_rs2),
        .funct7(id_funct7),
        .funct3(id_funct3),
        .opcode(id_opcode)
    );

    // ID/EX Pipeline register
    ID_EX_reg id_ex_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_bubble(ID_Stall),
        .ALUSrc(id_ALUSrc),
        .ALUOp(id_ALUOp),
        .branch(id_branch),
        .memread(id_MemRead),
        .memwrite(id_MemWrite),
        .regwrite(id_RegWrite),
        .memtoreg(id_MemtoReg),
        .o_rs1_rdata(id_rs1_rdata),
        .o_rs2_rdata(id_rs2_rdata),
        .o_immediate(id_imm),
        .pc(id_pc),
        .pc4(id_pc4),
        .i_rs1_raddr(id_rs1),
        .i_rs2_raddr(id_rs2),
        .i_rd_waddr(id_rd),
        .funct7(id_funct7),
        .funct3(id_funct3),
        .opcode(id_opcode),
        .valid(id_valid),
        .inst(id_inst),
        .next_pc(id_next_pc),
        .out_ALUSrc(ex_ALUSrc),
        .out_ALUOp(ex_ALUOp),
        .out_branch(ex_branch),
        .out_memread(ex_MemRead),
        .out_memwrite(ex_MemWrite),
        .out_regwrite(ex_RegWrite),
        .out_memtoreg(ex_MemtoReg),
        .out_o_rs1_rdata(ex_rs1_rdata),
        .out_o_rs2_rdata(ex_rs2_rdata),
        .out_o_immediate(ex_imm),
        .out_pc(ex_pc),
        .out_pc4(ex_pc4),
        .out_rs1(ex_rs1),
        .out_rs2(ex_rs2),
        .out_rd(ex_rd),
        .out_funct7(ex_funct7),
        .out_funct3(ex_funct3),
        .out_opcode(ex_opcode),
        .out_valid(ex_valid),
        .out_inst(ex_inst),
        .out_next_pc(ex_next_pc)
    );

    // EX Instantiation
    EX ex_stage (
        .rs1_rdata(ex_rs1_rdata),
        .rs2_rdata(ex_rs2_rdata),
        .immediate(ex_imm),
        .pc(ex_pc),
        .pc4(ex_pc4),
        .ALUSrc(ex_ALUSrc),
        .ALUOp(ex_ALUOp),
        .funct7(ex_funct7),
        .funct3(ex_funct3),
        .opcode(ex_opcode),
        .ex_result(ex_result)
    );
    // EX/MEM Pipeline register
    EX_MEM_reg ex_mem_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .in_valid(ex_valid),
        .in_RegWrite(ex_RegWrite),
        .in_MemtoReg(ex_MemtoReg),
        .in_MemRead(ex_MemRead),
        .in_MemWrite(ex_MemWrite),
        .in_funct3(ex_funct3),
        .in_rd(ex_rd),
        .in_ALU_result(ex_result),
        .in_pc(ex_pc),
        .in_next_pc(ex_next_pc),
        .in_inst(ex_inst),
        .in_rs1(ex_rs1),
        .in_rs2(ex_rs2),
        .in_rs1_rdata(ex_rs1_rdata),
        .in_rs2_rdata(ex_rs2_rdata),
        .out_valid(mem_valid),
        .out_RegWrite(mem_RegWrite),
        .out_MemtoReg(mem_MemtoReg),
        .out_MemRead(mem_MemRead),
        .out_MemWrite(mem_MemWrite),
        .out_funct3(mem_funct3),
        .out_rd(mem_rd),
        .out_ALU_result(mem_ALU_result),
        .out_pc(mem_pc),
        .out_next_pc(mem_next_pc),
        .out_inst(mem_inst),
        .out_rs1(mem_rs1),
        .out_rs2(mem_rs2),
        .out_rs1_rdata(mem_rs1_rdata),
        .out_rs2_rdata(mem_rs2_rdata)
    );

    // MEM Instantiation
    MEM mem_stage (
        .MemRead(mem_MemRead),
        .MemWrite(mem_MemWrite),
        .ALU_result(mem_ALU_result),
        .WriteData(mem_rs2_rdata),
        .funct3(mem_funct3),
        .misaligned(mem_misaligned),
        .ReadData(mem_LoadData),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask)
    );

    // misaligned is computed for every instruction; only memory ops trap
    assign mem_trap = (mem_MemRead || mem_MemWrite) && mem_misaligned;
    // MEM/WB Pipeline register
    MEM_WB_reg mem_wb_reg (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .in_valid(mem_valid),
        .in_MemtoReg(mem_MemtoReg),
        .in_RegWrite(mem_RegWrite),
        .in_rd(mem_rd),
        .in_LoadData(mem_LoadData),
        .in_ALU_result(mem_ALU_result),
        .in_trap(mem_trap),
        .in_pc(mem_pc),
        .in_next_pc(mem_next_pc),
        .in_inst(mem_inst),
        .in_rs1(mem_rs1),
        .in_rs2(mem_rs2),
        .in_rs1_rdata(mem_rs1_rdata),
        .in_rs2_rdata(mem_rs2_rdata),
        .in_dmem_addr(o_dmem_addr),
        .in_dmem_mask(o_dmem_mask),
        .in_dmem_ren(o_dmem_ren),
        .in_dmem_wen(o_dmem_wen),
        .in_dmem_rdata(i_dmem_rdata),
        .in_dmem_wdata(o_dmem_wdata),
        .out_valid(wb_valid),
        .out_MemtoReg(wb_MemtoReg),
        .out_RegWrite(wb_RegWrite),
        .out_rd(wb_rd),
        .out_LoadData(wb_LoadData),
        .out_ALU_result(wb_ALU_result),
        .out_trap(wb_trap),
        .out_pc(wb_pc),
        .out_next_pc(wb_next_pc),
        .out_inst(wb_inst),
        .out_rs1(wb_rs1),
        .out_rs2(wb_rs2),
        .out_rs1_rdata(wb_rs1_rdata),
        .out_rs2_rdata(wb_rs2_rdata),
        .out_dmem_addr(wb_dmem_addr),
        .out_dmem_mask(wb_dmem_mask),
        .out_dmem_ren(wb_dmem_ren),
        .out_dmem_wen(wb_dmem_wen),
        .out_dmem_rdata(wb_dmem_rdata),
        .out_dmem_wdata(wb_dmem_wdata)
    );

    // WB Instantiation
    WB wb_stage (
        .ALU_result(wb_ALU_result),
        .Mem_data(wb_LoadData),
        .MemtoReg(wb_MemtoReg),
        .WB_data(wb_data)
    );

    // Retire the instruction in writeback. Bubbles and flushed
    // instructions have valid cleared and do not retire.
    assign o_retire_valid      = wb_valid;
    assign o_retire_inst       = wb_inst;
    assign o_retire_trap       = wb_trap;
    assign o_retire_halt       = (wb_inst == EBREAK);
    assign o_retire_rs1_raddr  = wb_rs1;
    assign o_retire_rs2_raddr  = wb_rs2;
    assign o_retire_rs1_rdata  = wb_rs1_rdata;
    assign o_retire_rs2_rdata  = wb_rs2_rdata;
    assign o_retire_rd_waddr   = wb_RegWrite ? wb_rd : 5'd0;
    assign o_retire_rd_wdata   = wb_data;
    assign o_retire_dmem_addr  = wb_dmem_addr;
    assign o_retire_dmem_mask  = wb_dmem_mask;
    assign o_retire_dmem_ren   = wb_dmem_ren;
    assign o_retire_dmem_wen   = wb_dmem_wen;
    assign o_retire_dmem_rdata = wb_dmem_rdata;
    assign o_retire_dmem_wdata = wb_dmem_wdata;
    assign o_retire_pc         = wb_pc;
    assign o_retire_next_pc    = wb_next_pc;
endmodule

`default_nettype wire
