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
    localparam [31:0] NOP=32'h00000013;
    wire [31:0] if_pc;
    wire [31:0] if_pc4;
    wire [31:0] if_inst;
    reg [31:0] id_pc,id_pc4,id_inst;
    reg ifid_valid;
    wire [6:0] id_opcode,id_funct7;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1_raddr,id_rs2_raddr,id_rd_waddr;
    wire [31:0] id_rs1_rdata,id_rs2_rdata,id_imm;
    wire id_regwrite,id_memtoreg,id_memread,id_memwrite,id_branch,id_ALUsrc,id_AUIPC;
    wire [1:0] id_ALUop,id_jump;
    reg idex_valid;
    reg [31:0] ex_pc,ex_pc4,ex_inst,ex_rs1_rdata,ex_rs2_rdata,ex_imm;
    reg [4:0] ex_rd_waddr,ex_rs1_raddr,ex_rs2_raddr;
    reg [6:0] ex_funct7;
    reg [2:0] ex_funct3;
    reg [1:0] ex_ALUop,ex_jump;
    reg ex_ALUsrc,ex_AUIPC,ex_regwrite,ex_memtoreg,ex_memread,ex_memwrite,ex_branch;
    wire [31:0] ex_ALU_result,ex_branch_target,ex_jump_target;
    wire ex_zero;
    wire branch_redirect;
    wire [31:0] target_pc;
    wire stall_PC,stall_IFID,flush_IFID,flush_IDEX,data_hazard;
    reg exmem_valid;
    reg [31:0] mem_pc,mem_pc4,mem_inst,mem_next_pc,mem_ALU_result,mem_rs2_rdata,mem_rs1_rdata;
    reg [4:0] mem_rd_waddr,mem_rs1_raddr,mem_rs2_raddr;
    reg [2:0] mem_funct3;
    reg mem_regwrite,mem_memtoreg,mem_memread,mem_memwrite;
    wire [31:0] mem_ReadData;
    wire mem_misaligned;
    reg memwb_valid;
    reg [31:0] wb_pc,wb_next_pc,wb_inst,wb_ALU_result,wb_ReadData;
    reg [31:0] wb_rs1_rdata,wb_rs2_rdata,wb_dmem_addr,wb_dmem_rdata,wb_dmem_wdata;
    reg [4:0] wb_rd_waddr,wb_rs1_raddr,wb_rs2_raddr;
    reg [3:0] wb_dmem_mask;
    reg wb_memread,wb_memwrite,wb_regwrite,wb_memtoreg,wb_trap;
    wire [31:0] wb_data;
    wire mem_trap;

    // Branch and jump resolved in EX. The ALU zero output means that
    // the selected branch condition is true (BEQ/BNE/BLT/BGE/BLTU/BGEU).
    assign branch_redirect = idex_valid && ((ex_branch && ex_zero) || (ex_jump!=2'b00));
    assign target_pc = (ex_jump!=2'b00)?ex_jump_target:ex_branch_target;

    HDU u_hdu(
        .IF_ID_inst(id_inst),
        .IF_ID_valid(ifid_valid),
        .ID_EX_valid(idex_valid),
        .ID_EX_RegWrite(ex_regwrite),
        .ID_EX_rd(ex_rd_waddr),
        .EX_MEM_valid(exmem_valid),
        .EX_MEM_RegWrite(mem_regwrite),
        .EX_MEM_rd(mem_rd_waddr),
        .MEM_WB_valid(memwb_valid),
        .MEM_WB_RegWrite(wb_regwrite),
        .MEM_WB_rd(wb_rd_waddr),
        .redirect_ex(branch_redirect),
        .stall_PC(stall_PC),
        .stall_IFID(stall_IFID),
        .flush_IFID(flush_IFID),
        .flush_IDEX(flush_IDEX),
        .data_hazard(data_hazard));
    
    IF #(.RESET_ADDR(RESET_ADDR)) u_if(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .PCsrc(branch_redirect),
        .if_stall(stall_PC),
        .i_imem_rdata(i_imem_rdata),
        .target_pc(target_pc),
        .o_imem_raddr(o_imem_raddr),
        .PC_4(if_pc4),
        .PC(if_pc),
        .inst(if_inst));

    // IF/ID Register: Flush > Stall > Normal.
    // Redirect throws away a wrong-path instruction, while Stall holds it.
    always @(posedge i_clk) begin
        if(i_rst || flush_IFID) begin
        ifid_valid<=1'b0;id_pc<=0;id_pc4<=0;id_inst<=NOP;
        end else if(!stall_IFID) begin
        ifid_valid<=1'b1;id_pc<=if_pc;id_pc4<=if_pc4;id_inst<=if_inst;
        end
    end

    ID u_id(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .inst(id_inst),
        .wb_data(wb_data),
        .wb_rd_waddr(wb_rd_waddr),
        .wb_regwrite(wb_regwrite && memwb_valid),
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .rs1_raddr(id_rs1_raddr),
        .rs2_raddr(id_rs2_raddr),
        .rd_waddr(id_rd_waddr),
        .rs1_rdata(id_rs1_rdata),
        .rs2_rdata(id_rs2_rdata),
        .imm(id_imm),
        .regwrite(id_regwrite),
        .memtoreg(id_memtoreg),
        .memread(id_memread),
        .memwrite(id_memwrite),
        .branch(id_branch),
        .ALUop(id_ALUop),
        .ALUsrc(id_ALUsrc),
        .jump(id_jump),
        .AUIPC(id_AUIPC)
    );

    // ID/EX Register: a RAW stall injects a bubble, NOT a frozen EX stage.
    // A taken branch also flushes the younger instruction from ID.
    always @(posedge i_clk) begin
        if(i_rst || flush_IDEX) begin
            idex_valid<=0;
            ex_pc<=0;
            ex_pc4<=0;
            ex_inst<=NOP;
            ex_rs1_rdata<=0;
            ex_rs2_rdata<=0;
            ex_imm<=0;
            ex_rd_waddr<=0;
            ex_rs1_raddr<=0;
            ex_rs2_raddr<=0;
            ex_funct7<=0;
            ex_funct3<=0;
            ex_ALUop<=0;
            ex_jump<=0;
            ex_ALUsrc<=0;
            ex_AUIPC<=0;
            ex_regwrite<=0;
            ex_memtoreg<=0;
            ex_memread<=0;
            ex_memwrite<=0;
            ex_branch<=0;
        end else begin
            idex_valid<=ifid_valid;
            ex_pc<=id_pc;
            ex_pc4<=id_pc4;
            ex_inst<=id_inst;
            ex_rs1_rdata<=id_rs1_rdata;
            ex_rs2_rdata<=id_rs2_rdata;
            ex_imm<=id_imm;
            ex_rd_waddr<=id_rd_waddr;
            ex_rs1_raddr<=id_rs1_raddr;
            ex_rs2_raddr<=id_rs2_raddr;
            ex_funct7<=id_funct7;
            ex_funct3<=id_funct3;
            ex_ALUop<=id_ALUop;
            ex_jump<=id_jump;
            ex_ALUsrc<=id_ALUsrc;
            ex_AUIPC<=id_AUIPC;
            ex_regwrite<=id_regwrite;
            ex_memtoreg<=id_memtoreg;
            ex_memread<=id_memread;
            ex_memwrite<=id_memwrite;
            ex_branch<=id_branch;
        end
    end
    EX u_ex(
        .ALUOp(ex_ALUop),
        .funct7(ex_funct7),
        .funct3(ex_funct3),
        .ALUSrc(ex_ALUsrc),
        .AUIPC(ex_AUIPC),
        .jump(ex_jump),
        .rs1_rdata(ex_rs1_rdata),
        .rs2_rdata(ex_rs2_rdata),
        .immediate(ex_imm),
        .pc(ex_pc),
        .zero(ex_zero),
        .ALU_result(ex_ALU_result),
        .branch_target(ex_branch_target),
        .jump_target(ex_jump_target)
    );

    // EX/MEM Register: it must keep advancing during front-end stalls.
    // Jump instructions write PC+4 into rd using the ALU-result WB path.
    always @(posedge i_clk) begin
        if(i_rst) begin
            exmem_valid<=0;
            mem_pc<=0;
            mem_pc4<=0;
            mem_inst<=NOP;
            mem_next_pc<=0;
            mem_ALU_result<=0;
            mem_rs2_rdata<=0;
            mem_rs1_rdata<=0;
            mem_rd_waddr<=0;
            mem_rs1_raddr<=0;
            mem_rs2_raddr<=0;
            mem_funct3<=0;
            mem_regwrite<=0;
            mem_memtoreg<=0;
            mem_memread<=0;
            mem_memwrite<=0;
        end else begin
            exmem_valid<=idex_valid;
            mem_pc<=ex_pc;
            mem_pc4<=ex_pc4;
            mem_inst<=ex_inst;
            mem_next_pc<=branch_redirect?target_pc:ex_pc4;
            mem_ALU_result<=(ex_jump!=2'b00)?ex_pc4:ex_ALU_result;
            mem_rs2_rdata<=ex_rs2_rdata;
            mem_rs1_rdata<=ex_rs1_rdata;
            mem_rd_waddr<=ex_rd_waddr;
            mem_rs1_raddr<=ex_rs1_raddr;
            mem_rs2_raddr<=ex_rs2_raddr;
            mem_funct3<=ex_funct3;
            mem_regwrite<=ex_regwrite;
            mem_memtoreg<=ex_memtoreg;
            mem_memread<=ex_memread;
            mem_memwrite<=ex_memwrite;
        end
    end

    MEM u_mem(.
        MemRead(mem_memread && exmem_valid),
        .MemWrite(mem_memwrite && exmem_valid),
        .ALU_result(mem_ALU_result),
        .WriteData(mem_rs2_rdata),
        .funct3(mem_funct3),
        .misaligned(mem_misaligned),
        .ReadData(mem_ReadData),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask)
    );
    assign mem_trap = (mem_memread && mem_memwrite) && mem_misaligned;

    // MEM/WB Register: older instructions continue while IF/ID is held.
    // External data-memory writes take effect on the MEM-stage rising edge.
    always @(posedge i_clk) begin
        if(i_rst) begin
            memwb_valid<=0;
            wb_pc<=0;
            wb_next_pc<=0;
            wb_inst<=NOP;
            wb_ALU_result<=0;
            wb_ReadData<=0;
            wb_rs1_rdata<=0;
            wb_rs2_rdata<=0;
            wb_rd_waddr<=0;
            wb_rs1_raddr<=0;
            wb_rs2_raddr<=0;
            wb_dmem_addr<=0;
            wb_dmem_rdata<=0;
            wb_dmem_wdata<=0;
            wb_dmem_mask<=0;
            wb_memread<=0;
            wb_memwrite<=0;
            wb_regwrite<=0;
            wb_memtoreg<=0;
            wb_trap<=0;
        end else begin
            memwb_valid<=exmem_valid;
            wb_pc<=mem_pc;
            wb_next_pc<=mem_next_pc;
            wb_inst<=mem_inst;
            wb_ALU_result<=mem_ALU_result;
            wb_ReadData<=mem_ReadData;
            wb_rs1_rdata<=mem_rs1_rdata;
            wb_rs2_rdata<=mem_rs2_rdata;
            wb_rd_waddr<=mem_rd_waddr;
            wb_rs1_raddr<=mem_rs1_raddr;
            wb_rs2_raddr<=mem_rs2_raddr;
            wb_dmem_addr<=o_dmem_addr;
            wb_dmem_rdata<=i_dmem_rdata;
            wb_dmem_wdata<=o_dmem_wdata;
            wb_dmem_mask<=o_dmem_mask;
            wb_memread<=o_dmem_ren;
            wb_memwrite<=o_dmem_wen;
            wb_regwrite<=mem_regwrite;
            wb_memtoreg<=mem_memtoreg;
            wb_trap<=exmem_valid && mem_trap;
        end
    end
    WB u_wb(
        .ALU_result(wb_ALU_result),
        .Mem_data(wb_ReadData),
        .MemtoReg(wb_memtoreg),
        .WB_data(wb_data)
    );
    // The retire signals should just the signals after the
    // write back stage
    assign o_retire_valid=memwb_valid;
    assign o_retire_inst=wb_inst;
    assign o_retire_trap=wb_trap;
    assign o_retire_halt=memwb_valid && wb_inst==32'h00100073;
    assign o_retire_rs1_raddr=wb_rs1_raddr;
    assign o_retire_rs2_raddr=wb_rs2_raddr;
    assign o_retire_rs1_rdata=wb_rs1_rdata;
    assign o_retire_rs2_rdata=wb_rs2_rdata;
    assign o_retire_rd_waddr=(wb_regwrite && memwb_valid)?wb_rd_waddr:5'd0;
    assign o_retire_rd_wdata=wb_data;
    assign o_retire_dmem_addr=wb_dmem_addr;
    assign o_retire_dmem_mask=wb_dmem_mask;
    assign o_retire_dmem_ren=wb_memread;
    assign o_retire_dmem_wen=wb_memwrite;
    assign o_retire_dmem_rdata=wb_dmem_rdata;
    assign o_retire_dmem_wdata=wb_dmem_wdata;
    assign o_retire_pc=wb_pc;
    assign o_retire_next_pc=wb_next_pc;
endmodule

`default_nettype wire
