`timescale 1ns/1ps
module regfile_tb;
  reg         clk = 0;
  reg         we = 0;
  reg  [4:0]  rs1 = 0, rs2 = 0, rd = 0;
  reg  [31:0] wd = 0;
  wire [31:0] rdata1, rdata2;
  integer     errors = 0;

  regfile dut(.clk(clk), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wd),
              .rdata1(rdata1), .rdata2(rdata2));

  always #5 clk = ~clk;

  // Write one register, driving inputs on the falling edge so the
  // rising edge sees stable values
  task write_reg(input [4:0] addr, input [31:0] data);
    begin
      @(negedge clk);
      we = 1; rd = addr; wd = data;
      @(negedge clk);
      we = 0;
    end
  endtask

  task check_read(input [4:0] a1, input [4:0] a2,
                  input [31:0] e1, input [31:0] e2, input [8*16-1:0] name);
    begin
      rs1 = a1; rs2 = a2;
      #1;
      if (rdata1 !== e1 || rdata2 !== e2) begin
        $display("FAIL %0s: got %h %h, expected %h %h", name, rdata1, rdata2, e1, e2);
        errors = errors + 1;
      end else
        $display("PASS %0s", name);
    end
  endtask

  initial begin
    $dumpfile("regfile.vcd");
    $dumpvars(0, regfile_tb);

    check_read(5'd1, 5'd2, 32'd0, 32'd0, "reset values");

    write_reg(5'd1, 32'hDEADBEEF);
    write_reg(5'd2, 32'h12345678);
    check_read(5'd1, 5'd2, 32'hDEADBEEF, 32'h12345678, "write/read x1 x2");

    write_reg(5'd0, 32'hFFFFFFFF);
    check_read(5'd0, 5'd1, 32'd0, 32'hDEADBEEF, "x0 stays zero");

    // we = 0 must not write
    @(negedge clk);
    we = 0; rd = 5'd3; wd = 32'h0000ABCD;
    @(negedge clk);
    check_read(5'd3, 5'd3, 32'd0, 32'd0, "we=0 no write");

    write_reg(5'd31, 32'hCAFEF00D);
    check_read(5'd31, 5'd1, 32'hCAFEF00D, 32'hDEADBEEF, "x31 and x1");

    write_reg(5'd1, 32'd1);
    check_read(5'd1, 5'd2, 32'd1, 32'h12345678, "overwrite x1");

    check_read(5'd2, 5'd2, 32'h12345678, 32'h12345678, "same reg both");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule