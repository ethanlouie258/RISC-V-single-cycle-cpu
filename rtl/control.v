module control(
  input  [31:0]    inst,
  output reg       reg_write,
  output reg       alu_src_b,   // 0: rs2, 1: imm
  output reg       alu_a_pc,    // 0: rs1, 1: pc
  output reg       mem_write,
  output reg       branch,
  output reg       jump,        // JAL
  output reg       jalr,
  output reg [1:0] wb_sel,      // 0: alu, 1: mem, 2: pc+4, 3: imm
  output reg [3:0] alu_ctrl
);
  wire [6:0] opcode   = inst[6:0];
  wire [2:0] funct3   = inst[14:12];
  wire       funct7_5 = inst[30];

  localparam ALU_ADD  = 4'd0;
  localparam ALU_SUB  = 4'd1;
  localparam ALU_AND  = 4'd2;
  localparam ALU_OR   = 4'd3;
  localparam ALU_XOR  = 4'd4;
  localparam ALU_SLL  = 4'd5;
  localparam ALU_SRL  = 4'd6;
  localparam ALU_SRA  = 4'd7;
  localparam ALU_SLT  = 4'd8;
  localparam ALU_SLTU = 4'd9;

  localparam OP_RTYPE  = 7'b0110011;
  localparam OP_ITYPE  = 7'b0010011;
  localparam OP_LOAD   = 7'b0000011;
  localparam OP_STORE  = 7'b0100011;
  localparam OP_BRANCH = 7'b1100011;
  localparam OP_LUI    = 7'b0110111;
  localparam OP_AUIPC  = 7'b0010111;
  localparam OP_JAL    = 7'b1101111;
  localparam OP_JALR   = 7'b1100111;

  always @(*) begin
    // Defaults: do nothing
    reg_write = 1'b0;
    alu_src_b = 1'b0;
    alu_a_pc  = 1'b0;
    mem_write = 1'b0;
    branch    = 1'b0;
    jump      = 1'b0;
    jalr      = 1'b0;
    wb_sel    = 2'd0;
    alu_ctrl  = ALU_ADD;

    case (opcode)
      OP_RTYPE: begin
        reg_write = 1'b1;
        case (funct3)
          3'b000:  alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD;
          3'b001:  alu_ctrl = ALU_SLL;
          3'b010:  alu_ctrl = ALU_SLT;
          3'b011:  alu_ctrl = ALU_SLTU;
          3'b100:  alu_ctrl = ALU_XOR;
          3'b101:  alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
          3'b110:  alu_ctrl = ALU_OR;
          default: alu_ctrl = ALU_AND;
        endcase
      end

      OP_ITYPE: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        case (funct3)
          3'b000:  alu_ctrl = ALU_ADD;   // ADDI: bit 30 is part of the immediate
          3'b001:  alu_ctrl = ALU_SLL;
          3'b010:  alu_ctrl = ALU_SLT;
          3'b011:  alu_ctrl = ALU_SLTU;
          3'b100:  alu_ctrl = ALU_XOR;
          3'b101:  alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
          3'b110:  alu_ctrl = ALU_OR;
          default: alu_ctrl = ALU_AND;
        endcase
      end

      OP_LOAD: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        wb_sel    = 2'd1;
      end

      OP_STORE: begin
        alu_src_b = 1'b1;
        mem_write = 1'b1;
      end

      OP_BRANCH: begin
        branch = 1'b1;
        case (funct3)
          3'b000, 3'b001: alu_ctrl = ALU_SUB;    // BEQ, BNE
          3'b100, 3'b101: alu_ctrl = ALU_SLT;    // BLT, BGE
          default:        alu_ctrl = ALU_SLTU;   // BLTU, BGEU
        endcase
      end

      OP_LUI: begin
        reg_write = 1'b1;
        wb_sel    = 2'd3;
      end

      OP_AUIPC: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        alu_a_pc  = 1'b1;
      end

      OP_JAL: begin
        reg_write = 1'b1;
        jump      = 1'b1;
        wb_sel    = 2'd2;
      end

      OP_JALR: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        jalr      = 1'b1;
        wb_sel    = 2'd2;
      end

      default: ;
    endcase
  end
endmodule