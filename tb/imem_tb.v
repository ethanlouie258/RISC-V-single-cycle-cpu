`timescale 1ns/1ps
module imem_tb;
  reg  [31:0] addr = 0;
  wire [31:0] inst;
  integer     errors = 0;

  imem #(.INIT_FILE("programs/test.hex")) dut(.addr(addr), .inst(inst));

  task check(input [31:0] a, input [31:0] expected, input [8*16-1:0] name);
    begin
      addr = a;
      #1;
      if (inst !== expected) begin
        $display("FAIL %0s: addr=%h got=%h expected=%h", name, a, inst, expected);
        errors = errors + 1;
      end else
        $display("PASS %0s", name);
    end
  endtask

  initial begin
    check(32'd0,    32'h00500093, "word 0");
    check(32'd4,    32'h00A00113, "word 1");
    check(32'd8,    32'h002081B3, "word 2");
    check(32'd12,   32'h00000013, "unused is NOP");
    check(32'd1020, 32'h00000013, "last word NOP");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule