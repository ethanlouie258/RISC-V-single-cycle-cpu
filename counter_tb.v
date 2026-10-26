`timescale 1ns/1ps
module counter_tb;
  reg clk = 0, rst = 1;
  wire [3:0] count;
  counter dut(.clk(clk), .rst(rst), .count(count));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("counter.vcd");
    $dumpvars(0, counter_tb);
    #20 rst = 0;
    #200 $finish;
  end
endmodule
