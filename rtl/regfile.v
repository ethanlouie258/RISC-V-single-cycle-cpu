module regfile(
  input         clk,
  input         we,
  input  [4:0]  rs1,
  input  [4:0]  rs2,
  input  [4:0]  rd,
  input  [31:0] wd,
  output [31:0] rdata1,
  output [31:0] rdata2
);
  reg [31:0] regs [0:31];
  integer i;

  // Start all registers at 0 (simulation, and FPGA power-up value)
  initial begin
    for (i = 0; i < 32; i = i + 1) regs[i] = 32'd0;
  end

  // Synchronous write; writes to x0 are ignored
  always @(posedge clk) begin
    if (we && rd != 5'd0)
      regs[rd] <= wd;
  end

  // Combinational reads; x0 always reads as 0
  assign rdata1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
  assign rdata2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
endmodule