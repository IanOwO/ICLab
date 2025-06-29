/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: April-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

`ifdef RTL
  `include "AFS.sv"
  `define CYCLE_TIME 3.0
`endif

`ifdef GATE
  `include "AFS_SYN.v"
  `include "AFS_Wrapper.sv"
  `define CYCLE_TIME 2.5
`endif

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";


integer total_latency,wait_val_time,patcount,i;
integer flower_count,rose_count,lily_count,carnation_count,baby_breath_count;
parameter SEED = 12334333;
parameter TEST_PATTERN = 10000;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box

Warn_Msg reset_warn;
Warn_Msg golden_warn_msg;
logic golden_complete;
logic [7:0] month, day;
logic [12:0] baby_breath, carnation, lily, rose;

Action rand_act;
Order_Info rand_order_info;
Data_Dir rand_restock;
Date rand_date;
Data_No rand_addr;

//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Purchase, Restock, Check_Valid_Date};
    }
    function new (int seed);
        this.srandom(seed);
    endfunction
endclass

class random_purchase;
    // randc Strategy_Type strategy_purchase;
    // randc Mode mode_purchase;
    randc Order_Info purchase_order;

    constraint range_set{
        purchase_order.Strategy_Type_O inside{Strategy_A, Strategy_B, Strategy_C, Strategy_D, Strategy_E, Strategy_F, Strategy_G, Strategy_H};
        purchase_order.Mode_O inside{Single, Group_Order, Event};
    }
    function new (int seed);
        this.srandom(seed);
    endfunction
endclass

class random_restock;
    rand Data_Dir restock_value;

    constraint month_set{
        restock_value.M inside{[1:12]};
    }

    constraint day_set{
        if (restock_value.M inside {1, 3, 5, 7, 8, 10, 12}) {restock_value.D inside {[1:31]}; }
        if (restock_value.M inside {4, 6, 9, 11}) {restock_value.D inside {[1:30]}; }
        if (restock_value.M == 2) {restock_value.D inside {[1:28]}; }
    }

    constraint rose_range{
        restock_value.Rose inside{[0:4095]};
    }
    constraint lily_range{
        restock_value.Lily inside{[0:4095]};
    }
    constraint car_range{
        restock_value.Carnation inside{[0:4095]};
    }
    constraint baby_range{
        restock_value.Baby_Breath inside{[0:4095]};
    }
    function new (int seed);
        this.srandom(seed);
    endfunction
endclass

class random_date;
    rand Date date_value;
    rand Data_No dram_addr;

    constraint month_set{
        date_value.M inside{[1:12]};
    }
    constraint day_set{
        if (date_value.M inside {1, 3, 5, 7, 8, 10, 12}) {date_value.D inside {[1:31]}; }
        if (date_value.M inside {4, 6, 9, 11}) {date_value.D inside {[1:30]}; }
        if (date_value.M == 2) {date_value.D inside {[1:28]}; }
    }

    constraint addr_range{
        dram_addr inside{[0:255]};
    }
    function new (int seed);
        this.srandom(seed);
    endfunction
endclass

//================================================================
// initial
//================================================================

random_act testcase_act = new(30);
random_purchase testcase_purchase = new(30);
random_restock testcase_restock = new(30);
random_date testcase_date = new(30);

initial 
begin
    $readmemh(DRAM_p_r, golden_DRAM);   

    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.strategy_valid = 1'b0;
    inf.mode_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.data_no_valid = 1'b0;
    inf.restock_valid = 1'b0;
    
    reset_warn = No_Warn;

	force clk = 0;
 	total_latency = 0;
	reset_signal_task;
    
	for(patcount=1; patcount<=TEST_PATTERN; patcount=patcount+1) 
	begin
        

        testcase_act.randomize();
        testcase_purchase.randomize();
        testcase_restock.randomize();
        testcase_date.randomize();

        rand_act = testcase_act.act_id;
        rand_order_info = testcase_purchase.purchase_order;
        rand_restock = testcase_restock.restock_value;
        rand_date = testcase_date.date_value;
        rand_addr = testcase_date.dram_addr;

		input_task;
        calculate_ans;
        wait_out_valid;
        check_ans;
	end	
  	display_pass;
    repeat(3) @(negedge clk);
    $finish;

end


//======================================
//              TASKS
//======================================
task reset_signal_task; 
begin 
	#(5);  inf.rst_n=0;
	#(100);
	if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn)) 
	begin
		display_fail;
		$display("                    Reset FAIL                   ");
		$finish;
	end
	#(10);  inf.rst_n=1;
	#(5);  release clk;
end 
endtask

task input_task; 
begin	
	// Inputs start from second negtive edge after the begining of clock
    if(patcount=='d1)
    begin
        repeat({$random(SEED)} % 4 + 1)
		begin
			if(inf.out_valid !== 0)
			begin
				display_fail;
				$display("                  out_valid high before in_valid                        ");
				repeat(2)@(negedge clk);
				$finish;
			end
            if((inf.complete !== 0) || (inf.warn_msg !== reset_warn))
			begin
				display_fail;
				$display("                  complete high without out_valid                      ");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
    end

    // data_valid		
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0] = rand_act;
    if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
    begin
        display_fail;
        $display("                   out_valid or complete high when in_valid high                  ");
        repeat(2)@(negedge clk);
        $finish;
    end
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    repeat({$random(SEED)} % 4) @(negedge clk);

    case(rand_act)
    Purchase: begin
        // strategy_valid
        inf.strategy_valid = 1'b1;
        inf.D.d_strategy[0] = rand_order_info.Strategy_Type_O;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.strategy_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED*2)} % 4) @(negedge clk);

        // mode_valid
        inf.mode_valid = 1'b1;
        inf.D.d_mode[0] = rand_order_info.Mode_O;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.mode_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED*3)} % 4) @(negedge clk);

        // date_valid
        inf.date_valid = 1'b1;
        inf.D.d_date[0] = rand_date;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.date_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED*4)} % 4) @(negedge clk);

        // data_no_valid
        inf.data_no_valid = 1'b1;
        inf.D.d_data_no[0] = rand_addr;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.data_no_valid = 1'b0;
        inf.D = 'bx;
        // repeat({$random(SEED)} % 4) @(negedge clk);
    end
    Restock: begin
        // date_valid
        inf.date_valid = 1'b1;
        inf.D.d_date[0] = rand_date;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.date_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED)} % 4) @(negedge clk);

        // data_no_valid
        inf.data_no_valid = 1'b1;
        inf.D.d_data_no[0] = rand_addr;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.data_no_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED)} % 4) @(negedge clk);

        // restock_valid rose
        inf.restock_valid = 1'b1;
        inf.D.d_stock[0] = rand_restock.Rose;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.restock_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED)} % 4) @(negedge clk);

        // restock_valid lily
        inf.restock_valid = 1'b1;
        inf.D.d_stock[0] = rand_restock.Lily;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.restock_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED)} % 4) @(negedge clk);

        // restock_valid carnation
        inf.restock_valid = 1'b1;
        inf.D.d_stock[0] = rand_restock.Carnation;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.restock_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED)} % 4) @(negedge clk);

        // restock_valid baby breath
        inf.restock_valid = 1'b1;
        inf.D.d_stock[0] = rand_restock.Baby_Breath;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.restock_valid = 1'b0;
        inf.D = 'bx;
        // repeat({$random(SEED)} % 4) @(negedge clk);
    end
    Check_Valid_Date: begin
        // date_valid
        inf.date_valid = 1'b1;
        inf.D.d_date[0] = rand_date;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.date_valid = 1'b0;
        inf.D = 'bx;
        repeat({$random(SEED)} % 4) @(negedge clk);

        // data_no_valid
        inf.data_no_valid = 1'b1;
        inf.D.d_data_no[0] = rand_addr;
        if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
        begin
            display_fail;
            $display("                   out_valid or complete high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
        inf.data_no_valid = 1'b0;
        inf.D = 'bx;
        // repeat({$random(SEED)} % 4) @(negedge clk);
    end
    endcase
end endtask

task wait_out_valid; begin
    wait_val_time = 0;
    while(inf.out_valid !== 1) begin
        if((inf.complete !== 0) || (inf.warn_msg !== reset_warn)) 
        begin
            display_fail;
            $display("                  out_location high without out_valid                      ");
            repeat(2)@(negedge clk);
            $finish;
        end
        if(wait_val_time == 1000)
        begin
            display_fail;
            $display("                    execution latency is over 1000 cycles                ");
            repeat(2)@(negedge clk);
            $finish;
        end
        wait_val_time = wait_val_time + 1;
        @(negedge clk);
    end
    total_latency = total_latency + wait_val_time;
end endtask

task calculate_ans;
begin
    reg [11:0] temp_rose,temp_lily,temp_carnation,temp_babybreath;

    golden_complete = 1'b1;
    golden_warn_msg = No_Warn;

    day = golden_DRAM[65536+(rand_addr*8)];
    baby_breath = {1'b0, golden_DRAM[65536+(rand_addr*8)+2][3:0], golden_DRAM[65536+(rand_addr*8)+1]};
    carnation = {1'b0, golden_DRAM[65536+(rand_addr*8)+3], golden_DRAM[65536+(rand_addr*8)+2][7:4]};
    month = golden_DRAM[65536+(rand_addr*8)+4];
    lily = {1'b0, golden_DRAM[65536+(rand_addr*8)+6][3:0], golden_DRAM[65536+(rand_addr*8)+5]};
    rose = {1'b0, golden_DRAM[65536+(rand_addr*8)+7], golden_DRAM[65536+(rand_addr*8)+6][7:4]};
    
    case(rand_act)
    Purchase: begin
        // mode_valid
        case(rand_order_info.Mode_O)
        Single:
            flower_count = 120;
        Group_Order:
            flower_count = 480;
        Event:
            flower_count = 960;
        endcase

        // strategy_valid
        case(rand_order_info.Strategy_Type_O)
        Strategy_A: begin
            rose_count = flower_count;
            lily_count = 0;
            carnation_count = 0;
            baby_breath_count = 0;
        end
        Strategy_B: begin
            rose_count = 0;
            lily_count = flower_count;
            carnation_count = 0;
            baby_breath_count = 0;
        end
        Strategy_C: begin
            rose_count = 0;
            lily_count = 0;
            carnation_count = flower_count;
            baby_breath_count = 0;
        end
        Strategy_D: begin
            rose_count = 0;
            lily_count = 0;
            carnation_count = 0;
            baby_breath_count = flower_count;
        end
        Strategy_E: begin
            rose_count = flower_count/2;
            lily_count = flower_count/2;
            carnation_count = 0;
            baby_breath_count = 0;
        end
        Strategy_F: begin
            rose_count = 0;
            lily_count = 0;
            carnation_count = flower_count/2;
            baby_breath_count = flower_count/2;
        end
        Strategy_G: begin
            rose_count = flower_count/2;
            lily_count = 0;
            carnation_count = flower_count/2;
            baby_breath_count = 0;
        end
        Strategy_H: begin
            rose_count = flower_count/4;
            lily_count = flower_count/4;
            carnation_count = flower_count/4;
            baby_breath_count = flower_count/4;
        end
        endcase

        // date_valid
        if(month > rand_date.M) begin
            golden_complete = 0;
            golden_warn_msg = Date_Warn;
        end
        else if((month == rand_date.M) & (day > rand_date.D)) begin
            golden_complete = 0;
            golden_warn_msg = Date_Warn;
        end
        else begin
            if((rose_count > rose) || (lily_count > lily) || (carnation_count > carnation) || (baby_breath_count > baby_breath)) begin
                golden_complete = 0;
                golden_warn_msg = Stock_Warn;
            end
            else begin
                temp_rose = rose - rose_count;
                temp_lily = lily - lily_count;
                temp_carnation = carnation - carnation_count;
                temp_babybreath = baby_breath - baby_breath_count;

                golden_DRAM[65536+(rand_addr*8)+7] = temp_rose[11:4];
                golden_DRAM[65536+(rand_addr*8)+6] = {temp_rose[3:0], temp_lily[11:8]};
                golden_DRAM[65536+(rand_addr*8)+5] = temp_lily[7:0];
                golden_DRAM[65536+(rand_addr*8)+3] = temp_carnation[11:4];
                golden_DRAM[65536+(rand_addr*8)+2] = {temp_carnation[3:0], temp_babybreath[11:8]};
                golden_DRAM[65536+(rand_addr*8)+1] = temp_babybreath[7:0];
            end
        end
    end
    Restock: begin
        // date_valid
        golden_DRAM[65536+(rand_addr*8)] = rand_date.D;
        golden_DRAM[65536+(rand_addr*8)+4] = rand_date.M;

        // restock_valid rose
        if(rose+rand_restock.Rose > 4095) begin
            golden_complete = 0;
            golden_warn_msg = Restock_Warn;
            temp_rose = 12'd4095;
        end
        else begin
            temp_rose = rose + rand_restock.Rose;
        end

        // restock_valid lily
        if(lily+rand_restock.Lily > 4095) begin
            golden_complete = 0;
            golden_warn_msg = Restock_Warn;
            temp_lily = 12'd4095;
        end
        else begin
            temp_lily = lily + rand_restock.Lily;
        end

        // restock_valid carnation
        if(carnation+rand_restock.Carnation > 4095) begin
            golden_complete = 0;
            golden_warn_msg = Restock_Warn;
            temp_carnation = 12'd4095;
        end
        else begin
            temp_carnation = carnation + rand_restock.Carnation;
        end

        // restock_valid baby breath
        if(baby_breath+rand_restock.Baby_Breath > 4095) begin
            golden_complete = 0;
            golden_warn_msg = Restock_Warn;
            temp_babybreath = 12'd4095;
        end
        else begin
            temp_babybreath = baby_breath + rand_restock.Baby_Breath;
        end

        golden_DRAM[65536+(rand_addr*8)+7] = temp_rose[11:4];
        golden_DRAM[65536+(rand_addr*8)+6] = {temp_rose[3:0], temp_lily[11:8]};
        golden_DRAM[65536+(rand_addr*8)+5] = temp_lily[7:0];
        golden_DRAM[65536+(rand_addr*8)+3] = temp_carnation[11:4];
        golden_DRAM[65536+(rand_addr*8)+2] = {temp_carnation[3:0], temp_babybreath[11:8]};
        golden_DRAM[65536+(rand_addr*8)+1] = temp_babybreath[7:0];

    end
    Check_Valid_Date: begin
        // date_valid
        if(month > rand_date.M) begin
            golden_complete = 0;
            golden_warn_msg = Date_Warn;
        end
        else if((month == rand_date.M) & (day > rand_date.D)) begin
            golden_complete = 0;
            golden_warn_msg = Date_Warn;
        end
    end
    endcase
end
endtask

task check_ans; 
begin
	i=0;
	while(inf.out_valid)
	begin
		if(i==1)
		begin
			display_fail;
			$display("                    output high over 1 cycles                  ");
			repeat(2)@(negedge clk);
			$finish;
		end

        // check answer
        if((inf.complete !== golden_complete) || (inf.warn_msg !== golden_warn_msg))
        begin
            display_fail;
            $display("                    Your complete is not correct, golden_complete is %d                  ", golden_complete);
            $display("                           Your warn_msg is %d, golden_warn_msg is %d                            ", inf.warn_msg, golden_warn_msg);
            repeat(2)@(negedge clk);
            $finish;
        end

		@(negedge clk);	
		i=i+1;
	end	
    
    if(i!=1)
    begin
        display_fail;
        $display("                    output should be high 1 cycles                  ");
        repeat(2)@(negedge clk);
        $finish;
    end
	//+++++++++++++++++++++++++++++++++++++++++++++++
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount ,wait_val_time);
	repeat({$random(SEED)} % 4)
    begin
		if((inf.out_valid !== 0) || (inf.complete !== 0) || (inf.warn_msg !== reset_warn))
		begin
			display_fail;
			$display("                    output should be rise once                   ");
			repeat(2)@(negedge clk);
			$finish;
		end
		@(negedge clk);
	end
end endtask
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
	$display("              execution cycles = %10d", total_latency);
	$display("**************************************************");
end endtask

endprogram
