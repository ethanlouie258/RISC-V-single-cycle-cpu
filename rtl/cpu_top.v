module cpu_top #(
  parameter PROGRAM = "programs/program.hex"
)(
  input clk,
  input rst
);
  // ---------------- Wires ----------------
  wire [31:0] inst;
  wire [31:0] imm;
  wire [31:0] rdata1, rdata2;
  wire [31:0] alu_a, alu_b, alu_result;
  wire [31:0] mem_rdata;
  wire        alu_zero;

  wire        reg_write, alu_src_b, alu_a_pc, mem_write, branch, jump, jalr;
  wire [1:0]  wb_sel;
  wire [3:0]  alu_ctrl;

  wire [4:0]  rs1    = inst[19:15];
  wire [4:0]  rs2    = inst[24:20];
  wire [4:0]  rd     = inst[11:7];
  wire [2:0]  funct3 = inst[14:12];

  // ---------------- Program counter ----------------
  reg  [31:0] pc = 32'd0;
  wire [31:0] pc_plus4  = pc + 32'd4;
  wire [31:0] pc_target = pc + imm;
  reg  [31:0] pc_next;

  // Branch condition, using the ALU's compare result
  reg take;
  always @(*) begin
    case (funct3)
      3'b000:          take = alu_zero;        // BEQ
      3'b001:          take = ~alu_zero;       // BNE
      3'b100, 3'b110:  take = alu_result[0];   // BLT, BLTU
      3'b101, 3'b111:  take = ~alu_result[0];  // BGE, BGEU
      default:         take = 1'b0;
    endcase
  end
  wire branch_taken = branch & take;

  always @(*) begin
    if (jalr)                       pc_next = {alu_result[31:1], 1'b0};
    else if (jump | branch_taken)   pc_next = pc_target;
    else                            pc_next = pc_plus4;
  end

  always @(posedge clk) begin
    if (rst) pc <= 32'd0;
    else     pc <= pc_next;
  end

  // ---------------- Fetch / decode ----------------
  imem #(.INIT_FILE(PROGRAM)) u_imem (.addr(pc), .inst(inst));

  control u_control (
    .inst(inst), .reg_write(reg_write), .alu_src_b(alu_src_b),
    .alu_a_pc(alu_a_pc), .mem_write(mem_write), .branch(branch),
    .jump(jump), .jalr(jalr), .wb_sel(wb_sel), .alu_ctrl(alu_ctrl)
  );

  imm_gen u_immgen (.inst(inst), .imm(imm));

  // ---------------- Register file ----------------
  reg [31:0] wb_data;
  always @(*) begin
    case (wb_sel)
      2'd0:    wb_data = alu_result;
      2'd1:    wb_data = mem_rdata;
      2'd2:    wb_data = pc_plus4;
      default: wb_data = imm;
    endcase
  end

  regfile u_regfile (
    .clk(clk), .we(reg_write & ~rst),
    .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wb_data),
    .rdata1(rdata1), .rdata2(rdata2)
  );

  // ---------------- ALU ----------------
  assign alu_a = alu_a_pc   ? pc  : rdata1;
  assign alu_b = alu_src_b  ? imm : rdata2;

  alu u_alu (
    .a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl),
    .result(alu_result), .zero(alu_zero)
  );

  // ---------------- Data memory ----------------
  dmem u_dmem (
    .clk(clk), .we(mem_write & ~rst),
    .addr(alu_result), .wd(rdata2), .rdata(mem_rdata)
  );
endmodule