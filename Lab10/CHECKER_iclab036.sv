/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Strategy_and_mode;
    Strategy_Type f_type;
    Mode f_mode;
endclass

Strategy_and_mode fm_info = new();
logic valid_coverage_3;

always_ff @(posedge clk) begin
    if(inf.strategy_valid) begin
        fm_info.f_type = inf.D.d_strategy[0];
    end
    if(inf.mode_valid) begin
        fm_info.f_mode = inf.D.d_mode[0];
    end
end

always_ff @(posedge clk) begin
    valid_coverage_3 <= inf.mode_valid;
end

covergroup spec1_strategy @(posedge clk iff(inf.strategy_valid));
  // Coverpoint for Strategy_Type
  cp_strategy: coverpoint inf.D.d_strategy[0] {
    bins strategy_bins[] = {Strategy_A, Strategy_B, Strategy_C, Strategy_D, 
                            Strategy_E, Strategy_F, Strategy_G, Strategy_H};
    option.at_least = 100;
  }
endgroup
spec1_strategy spec1 = new();

covergroup spec2_mode @(posedge clk iff(inf.mode_valid));
  // Coverpoint for Mode
  cp_mode: coverpoint inf.D.d_mode[0] {
    bins mode_bins[] = {Single, Group_Order, Event};
    option.at_least = 100;
  }
endgroup
spec2_mode spec2 = new();

covergroup spec3_combination @(posedge clk iff(valid_coverage_3));
  // Cross coverage between SPEC1 and SPEC2
  cp_cross: cross fm_info.f_type, fm_info.f_mode {
    option.at_least = 100;
  }
endgroup
spec3_combination spec3 = new();

covergroup spec4_errmsg @(posedge clk iff(inf.out_valid));
  // Coverpoint for Mode
  cp_mode: coverpoint inf.warn_msg {
    bins mode_bins[] = {No_Warn, Date_Warn, Stock_Warn, Restock_Warn};
    option.at_least = 10;
  }
endgroup
spec4_errmsg spec4 = new();

Action input_act;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        input_act = Purchase;
    end
    else if(inf.sel_action_valid) begin
        input_act = inf.D.d_act[0];
    end
end

covergroup spec5_action @(posedge clk iff(inf.sel_action_valid));
  // Coverpoint for Mode
  cp_act: coverpoint inf.D.d_act[0] {
    bins act_transition[] = ([Purchase:Check_Valid_Date] => [Purchase:Check_Valid_Date]);
    option.at_least = 300;
  }
endgroup
spec5_action spec5 = new();

covergroup spec6_supply @(posedge clk iff(inf.restock_valid));
  // Coverpoint for Mode
  cp_supply: coverpoint inf.D.d_stock[0] {
    option.auto_bin_max = 32;
    option.at_least = 1;
  }
endgroup
spec6_supply spec6 = new();


// assert 1
always @(negedge inf.rst_n) begin
    #(100)
    check_reset: assert (inf.out_valid === 0 && inf.warn_msg === No_Warn && inf.complete === 0 && 
                        inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 &&
                        inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_DATA === 0 && inf.B_READY === 0)
        else begin
            $display("**************************************************");
            $display("            Assertion 1 is violated               ");
            // $display("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",inf.out_valid,inf.warn_msg,inf.complete,inf.AR_VALID,inf.AR_ADDR,inf.R_READY,inf.AW_VALID,inf.AW_ADDR,inf.W_DATA,inf.B_READY);
            $display("**************************************************");
            $fatal;
        end
end

// assert 2
property latency_count;
     @ (posedge clk) inf.sel_action_valid |-> ##[1:1000]inf.out_valid;
endproperty

check_latency: assert property (latency_count)
    else begin
        $display("**************************************************");
        $display("            Assertion 2 is violated               ");
        $display("**************************************************");
        $fatal;
    end

// assert 3
property complete_no_warn;
     @ (negedge clk) (inf.complete === 1) |-> (inf.warn_msg === No_Warn);
endproperty

check_complete: assert property (complete_no_warn)
    else begin
        $display("**************************************************");
        $display("            Assertion 3 is violated               ");
        // $display("%d,%d",inf.complete,inf.warn_msg);
        $display("**************************************************");
        $fatal;
    end

// assert 4
property invalid_action;
     @ (posedge clk) (inf.sel_action_valid === 1) |-> 
                        ##[1:4](inf.date_valid === 1 || inf.strategy_valid === 1);
endproperty
property invalid_purchase;
     @ (posedge clk) (inf.strategy_valid === 1) |-> 
                        ##[1:4](inf.mode_valid === 1)
                        ##[1:4](inf.date_valid === 1)
                        ##[1:4](inf.data_no_valid === 1);
                        // ##[1:4](inf.sel_action_valid === 1);
endproperty
property invalid_restock;
     @ (posedge clk) (inf.date_valid === 1) |-> 
                        ##[1:4](inf.data_no_valid === 1)
                        ##[1:4](inf.restock_valid === 1)
                        ##[1:4](inf.restock_valid === 1)
                        ##[1:4](inf.restock_valid === 1)
                        ##[1:4](inf.restock_valid === 1);
                        // ##[1:4](inf.sel_action_valid === 1);
endproperty
property invalid_checkdate;
     @ (posedge clk) (inf.date_valid === 1) |-> 
                        ##[1:4](inf.data_no_valid === 1);
                        // ##[1:4](inf.sel_action_valid === 1);
endproperty

always @(posedge clk) begin
    check_invalid: assert property (invalid_action)
        else begin
            $display("**************************************************");
            $display("            Assertion 4 is violated               ");
            $display("**************************************************");
            $fatal;
        end
    case (input_act)
        Purchase: begin
            check_purchase: assert property (invalid_purchase)
                else begin
                    $display("**************************************************");
                    $display("            Assertion 4 is violated               ");
                    $display("**************************************************");
                    $fatal;
                end
        end
        Restock: begin
            check_restock: assert property (invalid_restock)
                else begin
                    $display("**************************************************");
                    $display("            Assertion 4 is violated               ");
                    $display("**************************************************");
                    $fatal;
                end
        end
        Check_Valid_Date: begin
            check_checkdate: assert property (invalid_checkdate)
                else begin
                    $display("**************************************************");
                    $display("            Assertion 4 is violated               ");
                    $display("**************************************************");
                    $fatal;
                end
        end
    endcase
end

// assert 5
logic [5:0] in_valid_bus; // invalid[0] to invalid[3]
always @(posedge clk) begin
    in_valid_bus[5] = inf.sel_action_valid;
    in_valid_bus[4] = inf.strategy_valid;
    in_valid_bus[3] = inf.mode_valid;
    in_valid_bus[2] = inf.date_valid;
    in_valid_bus[1] = inf.data_no_valid;
    in_valid_bus[0] = inf.restock_valid;
end
property invalid_overlap;
     @ (posedge clk) ($countones(in_valid_bus) <= 1);
endproperty

check_overlap: assert property (invalid_overlap)
    else begin
        $display("**************************************************");
        $display("            Assertion 5 is violated               ");
        // $display("%b",in_valid_bus);
        $display("**************************************************");
        $fatal;
    end

// assert 6
property outvalid_count;
     @ (posedge clk) (inf.out_valid === 1) |=> (inf.out_valid !== 1);
endproperty

check_outvalid: assert property (outvalid_count)
    else begin
        $display("**************************************************");
        $display("            Assertion 6 is violated               ");
        $display("**************************************************");
        $fatal;
    end

// assert 7
property next_operation;
     @ (posedge clk) (inf.out_valid === 1) |-> ##[1:4](inf.sel_action_valid === 1);
endproperty

check_next_operation: assert property (next_operation)
    else begin
        $display("**************************************************");
        $display("            Assertion 7 is violated               ");
        $display("**************************************************");
        $fatal;
    end

// assert 8
property date_real;
     @(posedge clk) (inf.date_valid === 1) |-> (
      (inf.D.d_date[0].M == 1  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ||
      (inf.D.d_date[0].M == 2  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 28) ||
      (inf.D.d_date[0].M == 3  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ||
      (inf.D.d_date[0].M == 4  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 30) ||
      (inf.D.d_date[0].M == 5  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ||
      (inf.D.d_date[0].M == 6  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 30) ||
      (inf.D.d_date[0].M == 7  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ||
      (inf.D.d_date[0].M == 8  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ||
      (inf.D.d_date[0].M == 9  && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 30) ||
      (inf.D.d_date[0].M == 10 && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31) ||
      (inf.D.d_date[0].M == 11 && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 30) ||
      (inf.D.d_date[0].M == 12 && inf.D.d_date[0].D >= 1 && inf.D.d_date[0].D <= 31)
    );
endproperty

check_date_31: assert property (date_real)
    else begin
        $display("**************************************************");
        $display("            Assertion 8 is violated               ");
        $display("**************************************************");
        $fatal;
    end

// assert 9
property dram_addr_opverlap;
     @ (posedge clk) (inf.AR_VALID === 1) |-> (inf.AW_VALID === 0);
endproperty

check_dram_addr: assert property (dram_addr_opverlap)
    else begin
        $display("**************************************************");
        $display("            Assertion 9 is violated               ");
        $display("**************************************************");
        $fatal;
    end

endmodule