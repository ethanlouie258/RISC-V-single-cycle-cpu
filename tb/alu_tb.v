`timescale 1ns/1ps
module alu_tb;
  reg  [31:0] a, b;
  reg  [3:0]  alu_ctrl;
  wire [31:0] result;
  wire        zero;
  integer     errors = 0;

  alu dut(.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

  task check(input [3:0] ctrl, input [31:0] x, input [31:0] y,
             input [31:0] expected, input [8*10-1:0] name);
    begin
      alu_ctrl = ctrl; a = x; b = y;
      #1;
      if (result !== expected) begin
        $display("FAIL %0s: a=%h b=%h got=%h expected=%h", name, x, y, result, expected);
        errors = errors + 1;
      end else
        $display("PASS %0s", name);
    end
  endtask

  initial begin
    $dumpfile("alu.vcd");
    $dumpvars(0, alu_tb);

    check(4'd0, 32'd5,         32'd3,        32'd8,         "ADD");
    check(4'd0, 32'hFFFFFFFF,  32'd1,        32'd0,         "ADD wrap");
    check(4'd1, 32'd10,        32'd3,        32'd7,         "SUB");
    check(4'd1, 32'd3,         32'd10,       32'hFFFFFFF9,  "SUB neg");
    check(4'd2, 32'hF0F0F0F0,  32'hFF00FF00, 32'hF000F000,  "AND");
    check(4'd3, 32'hF0F0F0F0,  32'h0F0F0F0F, 32'hFFFFFFFF,  "OR");
    check(4'd4, 32'hFFFFFFFF,  32'h0F0F0F0F, 32'hF0F0F0F0,  "XOR");
    check(4'd5, 32'd1,         32'd4,        32'd16,        "SLL");
    check(4'd6, 32'h80000000,  32'd4,        32'h08000000,  "SRL");
    check(4'd7, 32'h80000000,  32'd4,        32'hF8000000,  "SRA");
    check(4'd8, 32'hFFFFFFFF,  32'd1,        32'd1,         "SLT -1<1");
    check(4'd8, 32'd1,         32'hFFFFFFFF, 32'd0,         "SLT 1<-1");
    check(4'd9, 32'd1,         32'hFFFFFFFF, 32'd1,         "SLTU 1<max");
    check(4'd9, 32'hFFFFFFFF,  32'd1,        32'd0,         "SLTU max<1");

    // zero flag: last ADD wrap result was 0, so test it directly
    alu_ctrl = 4'd0; a = 32'hFFFFFFFF; b = 32'd1; #1;
    if (zero !== 1'b1) begin $display("FAIL zero flag (expected 1)"); errors = errors + 1; end
    else $display("PASS zero flag");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule
