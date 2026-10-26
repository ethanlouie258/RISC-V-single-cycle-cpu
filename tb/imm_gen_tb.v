`timescale 1ns/1ps
module imm_gen_tb;
  reg  [31:0] inst;
  wire [31:0] imm;
  integer     errors = 0;

  imm_gen dut(.inst(inst), .imm(imm));

  task check(input [31:0] i, input [31:0] expected, input [8*16-1:0] name);
    begin
      inst = i;
      #1;
      if (imm !== expected) begin
        $display("FAIL %0s: inst=%h got=%h expected=%h", name, i, imm, expected);
        errors = errors + 1;
      end else
        $display("PASS %0s", name);
    end
  endtask

  initial begin
    $dumpfile("imm_gen.vcd");
    $dumpvars(0, imm_gen_tb);

    check(32'h00500093, 32'h00000005, "addi +5");
    check(32'hFFF00093, 32'hFFFFFFFF, "addi -1");
    check(32'h0080A103, 32'h00000008, "lw 8");
    check(32'h0020A623, 32'h0000000C, "sw +12");
    check(32'hFE20AE23, 32'hFFFFFFFC, "sw -4");
    check(32'h00208463, 32'h00000008, "beq +8");
    check(32'hFE208CE3, 32'hFFFFFFF8, "beq -8");
    check(32'h123452B7, 32'h12345000, "lui");
    check(32'h00001097, 32'h00001000, "auipc");
    check(32'h008000EF, 32'h00000008, "jal +8");
    check(32'hFF9FF0EF, 32'hFFFFFFF8, "jal -8");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule