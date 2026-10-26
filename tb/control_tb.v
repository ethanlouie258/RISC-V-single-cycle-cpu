`timescale 1ns/1ps
module control_tb;
  reg  [31:0] inst = 0;
  wire        reg_write, alu_src_b, alu_a_pc, mem_write, branch, jump, jalr;
  wire [1:0]  wb_sel;
  wire [3:0]  alu_ctrl;
  integer     errors = 0;

  control dut(.inst(inst), .reg_write(reg_write), .alu_src_b(alu_src_b),
              .alu_a_pc(alu_a_pc), .mem_write(mem_write), .branch(branch),
              .jump(jump), .jalr(jalr), .wb_sel(wb_sel), .alu_ctrl(alu_ctrl));

  task check(input [31:0] i,
             input rw, input asb, input apc, input mw,
             input br, input jp, input jr,
             input [1:0] wb, input [3:0] alu,
             input [8*12-1:0] name);
    begin
      inst = i;
      #1;
      if ({reg_write, alu_src_b, alu_a_pc, mem_write, branch, jump, jalr, wb_sel, alu_ctrl} !==
          {rw, asb, apc, mw, br, jp, jr, wb, alu}) begin
        $display("FAIL %0s: got rw=%b asb=%b apc=%b mw=%b br=%b jp=%b jr=%b wb=%0d alu=%0d",
                 name, reg_write, alu_src_b, alu_a_pc, mem_write, branch, jump, jalr, wb_sel, alu_ctrl);
        errors = errors + 1;
      end else
        $display("PASS %0s", name);
    end
  endtask

  initial begin
    $dumpfile("control.vcd");
    $dumpvars(0, control_tb);

    //    inst         rw asb apc mw br jp jr wb  alu
    check(32'h002081B3, 1, 0, 0, 0, 0, 0, 0, 0, 0, "add");
    check(32'h402081B3, 1, 0, 0, 0, 0, 0, 0, 0, 1, "sub");
    check(32'h0020F1B3, 1, 0, 0, 0, 0, 0, 0, 0, 2, "and");
    check(32'h0020E1B3, 1, 0, 0, 0, 0, 0, 0, 0, 3, "or");
    check(32'h0020C1B3, 1, 0, 0, 0, 0, 0, 0, 0, 4, "xor");
    check(32'h002091B3, 1, 0, 0, 0, 0, 0, 0, 0, 5, "sll");
    check(32'h0020D1B3, 1, 0, 0, 0, 0, 0, 0, 0, 6, "srl");
    check(32'h4020D1B3, 1, 0, 0, 0, 0, 0, 0, 0, 7, "sra");
    check(32'h0020A1B3, 1, 0, 0, 0, 0, 0, 0, 0, 8, "slt");
    check(32'h0020B1B3, 1, 0, 0, 0, 0, 0, 0, 0, 9, "sltu");

    check(32'h00500093, 1, 1, 0, 0, 0, 0, 0, 0, 0, "addi +5");
    check(32'hFFF00093, 1, 1, 0, 0, 0, 0, 0, 0, 0, "addi -1");
    check(32'h0020D093, 1, 1, 0, 0, 0, 0, 0, 0, 6, "srli");
    check(32'h4020D093, 1, 1, 0, 0, 0, 0, 0, 0, 7, "srai");

    check(32'h0080A103, 1, 1, 0, 0, 0, 0, 0, 1, 0, "lw");
    check(32'h0020A623, 0, 1, 0, 1, 0, 0, 0, 0, 0, "sw");

    check(32'h00208463, 0, 0, 0, 0, 1, 0, 0, 0, 1, "beq");
    check(32'h00209463, 0, 0, 0, 0, 1, 0, 0, 0, 1, "bne");
    check(32'h0020C463, 0, 0, 0, 0, 1, 0, 0, 0, 8, "blt");
    check(32'h0020E463, 0, 0, 0, 0, 1, 0, 0, 0, 9, "bltu");

    check(32'h123452B7, 1, 0, 0, 0, 0, 0, 0, 3, 0, "lui");
    check(32'h00001097, 1, 1, 1, 0, 0, 0, 0, 0, 0, "auipc");
    check(32'h008000EF, 1, 0, 0, 0, 0, 1, 0, 2, 0, "jal");
    check(32'h00008067, 1, 1, 0, 0, 0, 0, 1, 2, 0, "jalr");

    check(32'h00000000, 0, 0, 0, 0, 0, 0, 0, 0, 0, "unknown");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TESTS FAILED", errors);
    $finish;
  end
endmodule