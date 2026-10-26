module imem #(
  parameter INIT_FILE = "programs/program.hex"
)(
  input  [31:0] addr,
  output [31:0] inst
);
  reg [31:0] mem [0:255];
  integer i;

  initial begin
    // Unused locations hold NOP (addi x0, x0, 0)
    for (i = 0; i < 256; i = i + 1) mem[i] = 32'h00000013;
    $readmemh(INIT_FILE, mem);
  end

  assign inst = mem[addr[9:2]];
endmodule