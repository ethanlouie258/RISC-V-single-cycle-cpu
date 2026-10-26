`timescale 1ns/1ps
module cpu_tb;
  reg     clk = 0, rst = 1;
  integer errors = 0;

  cpu_top #(.PROGRAM("programs/sum.hex")) dut (.clk(clk), .rst(rst));

  always #5 clk = ~clk;

  task check_reg(input [4:0] n, input [31:0] expected);
    begin
      if (dut.u_regfile.regs[n] !== expected) begin
        $display("FAIL x%0d: got %0d, expected %0d", n, dut.u_regfile.regs[n], expected);
        errors = errors + 1;
      end else
        $display("PASS x%0d = %0d", n, expected);
    end
  endtask

  initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, cpu_tb);

    #22 rst = 0;                 // hold reset for two clock edges
    repeat (60) @(posedge clk);  // plenty of cycles for the program
    #1;

    check_reg(5'd0, 32'd0);
    check_reg(5'd1, 32'd55);
    check_reg(5'd2, 32'd11);
    check_reg(5'd4, 32'd11);
    check_reg(5'd5, 32'd55);

    if (dut.u_dmem.mem[0] !== 32'd55) begin
      $display("FAIL dmem[0]: got %0d, expected 55", dut.u_dmem.mem[0]);
      errors = errors + 1;
    end else
      $display("PASS dmem[0] = 55");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule