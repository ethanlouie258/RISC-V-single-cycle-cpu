`timescale 1ns/1ps
module dmem_tb;
  reg         clk = 0, we = 0;
  reg  [31:0] addr = 0, wd = 0;
  wire [31:0] rdata;
  integer     errors = 0;

  dmem dut(.clk(clk), .we(we), .addr(addr), .wd(wd), .rdata(rdata));

  always #5 clk = ~clk;

  task write_mem(input [31:0] a, input [31:0] d);
    begin
      @(negedge clk);
      we = 1; addr = a; wd = d;
      @(negedge clk);
      we = 0;
    end
  endtask

  task check_mem(input [31:0] a, input [31:0] expected, input [8*16-1:0] name);
    begin
      addr = a;
      #1;
      if (rdata !== expected) begin
        $display("FAIL %0s: addr=%h got=%h expected=%h", name, a, rdata, expected);
        errors = errors + 1;
      end else
        $display("PASS %0s", name);
    end
  endtask

  initial begin
    check_mem(32'd0, 32'd0, "initial zero");

    write_mem(32'd0, 32'hDEADBEEF);
    check_mem(32'd0, 32'hDEADBEEF, "write/read 0");

    write_mem(32'd4, 32'h12345678);
    check_mem(32'd4, 32'h12345678, "write/read 4");
    check_mem(32'd0, 32'hDEADBEEF, "no overlap");

    // we = 0 must not write
    @(negedge clk);
    we = 0; addr = 32'd8; wd = 32'h0000ABCD;
    @(negedge clk);
    check_mem(32'd8, 32'd0, "we=0 no write");

    write_mem(32'd0, 32'd1);
    check_mem(32'd0, 32'd1, "overwrite");

    write_mem(32'd252, 32'hCAFEF00D);
    check_mem(32'd252, 32'hCAFEF00D, "high address");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule