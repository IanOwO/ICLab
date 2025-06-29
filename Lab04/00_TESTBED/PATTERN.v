 	//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Two Head Attention
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      32
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 100

module PATTERN(
    //Output Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output  logic        clk, rst_n, in_valid;
output  logic[31:0]  in_str;
output  logic[31:0]  q_weight;
output  logic[31:0]  k_weight;
output  logic[31:0]  v_weight;
output  logic[31:0]  out_weight;

input           out_valid;
input   [31:0]  out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

integer total_latency, i, wait_val_time;
integer in_read,in_k_read,in_q_read,in_v_read,in_out_read,out_read;
integer in1_hold,in2_hold,in3_hold,in4_hold,in5_hold,out_hold;
integer patcount;

//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [31:0] golden_ans;

reg [31:0] sub_a,sub_b,sub_result;
reg equal_ab_minus, less_ab_minus, big_ab_minus;
reg equal_ab_plus, less_ab_plus, big_ab_plus;

reg [31:0] absolute_sub_result;
reg a_equal_b, a_less_b, a_big_b;
//================================================================
// clock
//================================================================

always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//---------------------------------------------------------------------
//   Pattern_Design
//---------------------------------------------------------------------

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
submm (  .a(sub_a),  .b(sub_b), .rnd(3'b000), .z(sub_result), .status());
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// cmp_minus_107 (  .a(32'hb3d6bf95),  .b(sub_result), .zctr(1'b0), .aeqb(equal_ab_minus), .altb(less_ab_minus), .agtb(big_ab_minus), .unordered(), .z0(), .z1(), .status0(), .status1());
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// cmp_plus_107  (  .a(sub_result),  .b(32'h33d6bf95), .zctr(1'b0), .aeqb(equal_ab_plus), .altb(less_ab_plus), .agtb(big_ab_plus), .unordered(), .z0(), .z1(), .status0(), .status1());
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
cmp_minus_107 (  .a(absolute_sub_result),  .b(32'h33d6bf95), .zctr(1'b0), .aeqb(a_equal_b), .altb(a_less_b), .agtb(a_big_b), .unordered(), .z0(), .z1(), .status0(), .status1());
//================================================================
// initial
//================================================================
initial 
begin

	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	// Read file here (two statements)
	in_read = $fopen("../00_TESTBED/in_str.txt", "r");
	in_k_read = $fopen("../00_TESTBED/in_k.txt", "r");
	in_q_read = $fopen("../00_TESTBED/in_q.txt", "r");
	in_v_read = $fopen("../00_TESTBED/in_v.txt", "r");
	in_out_read = $fopen("../00_TESTBED/in_weight.txt", "r");
	out_read = $fopen("../00_TESTBED/in_Final_res.txt", "r");
	
	//+++++++++++++++++++++++++++++++++++++++++++++++++++

	rst_n = 1'b1;
	in_valid = 1'b0;
	in_str = 32'bx;
	k_weight = 32'bx;
	q_weight = 32'bx;
	v_weight = 32'bx;
	out_weight = 32'bx;
    
	force clk = 0;
 	total_latency = 0;
	reset_signal_task;

	// k = $fscanf(in_read, "%d", PATNUM);
	for(patcount=1; patcount<=100; patcount=patcount+1) 
	begin
		input_task;
		wait_out_valid;
		check_ans;
	end	
  	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end


//================================================================
// task
//================================================================
task reset_signal_task; 
begin 
	#(5);  rst_n=0;
	#(100);
	if((out_valid !== 0)||(out !== 0)) 
	begin
		display_fail;
		$display("                    Reset FAIL                   ");
		$finish;
	end
	#(1);  rst_n=1;
	#(5);  release clk;
end 
endtask

task input_task; 
begin
	
	// Inputs start from second negtive edge after the begining of clock
	if(patcount=='d1)
		repeat(2)
		begin
			if(out_valid !== 0)
			begin
				display_fail;
				$display("                  out_valid high before in_valid                        ");
				repeat(2)@(negedge clk);
				$finish;
			end
            if(out !== 0)
			begin
				display_fail;
				$display("                  out high without out_valid                      ");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	// Set in_valid and input the data
    in_valid = 1'b1;
	for(i=0; i<16; i=i+1)
	begin
		if(out_valid !== 0 || out !== 0)
        begin
            display_fail;
            $display("                     out_valid or out high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
		//+++++++++++++++++++++++++++++++++++++++++++++++++++
		// Read input(in) and answer(ans) here (two statement)
		in1_hold = $fscanf(in_read,"%h",in_str);
		// in_str = i;
		in2_hold = $fscanf(in_k_read,"%h",k_weight);
		in3_hold = $fscanf(in_q_read,"%h",q_weight);
		// q_weight = i;
		in4_hold = $fscanf(in_v_read,"%h",v_weight);
		in5_hold = $fscanf(in_out_read,"%h",out_weight);
		//+++++++++++++++++++++++++++++++++++++++++++++++++++ 
		@(negedge clk);
	end
	// out_hold = $fscanf(inout_read,"%d",golden_worst);
	for(i=0; i<4; i=i+1)
	begin
		if(out_valid !== 0 || out !== 0)
        begin
            display_fail;
            $display("                     out_valid or out high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
		//+++++++++++++++++++++++++++++++++++++++++++++++++++
		// Read input(in) and answer(ans) here (two statement)
		in1_hold = $fscanf(in_read,"%h",in_str);
		// in_str = i + 32;
        k_weight = 32'bx;
        q_weight = 32'bx;
        v_weight = 32'bx;
        out_weight = 32'bx;
		//+++++++++++++++++++++++++++++++++++++++++++++++++++ 
		@(negedge clk);
	end
	// Disable input
	in_valid = 1'b0;
	in_str = 32'bx;
	k_weight = 32'bx;
	q_weight = 32'bx;
	v_weight = 32'bx;
	out_weight = 32'bx;
end
endtask


task wait_out_valid; begin
  wait_val_time = 0;
  
  while(out_valid !== 1) begin
	if((out !== 0)) 
	begin
		display_fail;
		$display("                  out high without out_valid                      ");
		repeat(2)@(negedge clk);
		$finish;
	end
	wait_val_time = wait_val_time + 1;
	if(wait_val_time == 200)
	begin
		display_fail;
		$display("                    execution latency is over 200 cycles                ");
		repeat(2)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  total_latency = total_latency + wait_val_time;
end endtask

task check_ans; 
begin
  
	//++++++++++++++++++++++++++++++++++++++++++++++++
	// Check the answer here
	i=0;
	while(out_valid)
	begin
		if(i==20)
		begin
			display_fail;
			$display("                    output high over 20 cycles                  ");
			repeat(2)@(negedge clk);
			$finish;
		end
		out_hold = $fscanf(out_read,"%h",golden_ans);
		sub_a = out;
		sub_b = golden_ans;

// reg equal_ab_minus, less_ab_minus, big_ab_minus;
// reg equal_ab_plus, less_ab_plus, big_ab_plus;

        // if(((equal_ab_minus === 1) | (big_ab_minus === 1)) && ((equal_ab_plus === 1) | (less_ab_plus === 1)))
        // begin
        //     display_fail;
		// 	$display("                    out is not correct                  ");
		// 	repeat(2)@(negedge clk);
		// 	$finish;
        // end
		if(out === 32'bx)
		begin
			display_fail;
			$display("                    out is X                   ");
			repeat(2)@(negedge clk);
			$finish;
		end
		absolute_sub_result = {1'b0, sub_result[30:0]};
		if(a_big_b === 1)
        begin
            display_fail;
			$display("                    out is not correct,absolute error is %h                  ", absolute_sub_result);
			repeat(2)@(negedge clk);
			$finish;
        end
		@(negedge clk);	
		i=i+1;
	end	
    if(i!=20)
    begin
        display_fail;
        $display("                    output should be high 20 cycles                  ");
        repeat(2)@(negedge clk);
        $finish;
    end
	//+++++++++++++++++++++++++++++++++++++++++++++++
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount ,wait_val_time);
	repeat(3)
    begin
		if(out_valid !== 0 || out !== 0)
		begin
			display_fail;
			$display("                    output should be rise once                   ");
			repeat(2)@(negedge clk);
			$finish;
		end
		@(negedge clk);
	end
	
end 
endtask
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task display_fail; begin
	$display("\033[31m \033[5m     //   / /     //   ) )     //   ) )     //   ) )     //   ) )\033[0m");
    $display("\033[31m \033[5m    //____       //___/ /     //___/ /     //   / /     //___/ /\033[0m");
    $display("\033[31m \033[5m   / ____       / ___ (      / ___ (      //   / /     / ___ (\033[0m");
    $display("\033[31m \033[5m  //           //   | |     //   | |     //   / /     //   | |\033[0m");
    $display("\033[31m \033[5m //____/ /    //    | |    //    | |    ((___/ /     //    | |\033[0m");
end endtask

task display_pass; begin
	$display("\033[0;32m \033[5m    //   ) )     // | |     //   ) )     //   ) )\033[m");
    $display("\033[0;32m \033[5m   //___/ /     //__| |    ((           ((\033[m");
    $display("\033[0;32m \033[5m  / ____ /     / ___  |      \\           \\\033[m");
    $display("\033[0;32m \033[5m //           //    | |        ) )          ) )\033[m");
    $display("\033[0;32m \033[5m//           //     | | ((___ / /    ((___ / /\033[m");
	$display("**************************************************");
	$display("                  Congratulations!                ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
	$display("**************************************************");
end endtask
endmodule
