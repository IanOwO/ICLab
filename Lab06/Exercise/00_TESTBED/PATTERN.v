`ifdef RTL
    `define CYCLE_TIME 31.0
`endif
`ifdef GATE
    `define CYCLE_TIME 31.0
`endif
`define SEED_NUMBER 246897531 
module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_syndrome, 
    // Input signals
    out_valid, 
	out_location
);

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid;
output reg [3:0] in_syndrome;

input out_valid;
input [3:0] out_location;

//====================================== 
//      PARAMETERS & VARIABLES 
//======================================
real CYCLE = `CYCLE_TIME;

integer total_latency, i, wait_val_time;
integer in_read,out_read;
integer in_hold,out_hold;
integer patcount, testcnt;
integer SEED = `SEED_NUMBER;

reg [3:0] golden_ans[0:2];

//======================================
//              MAIN
//======================================
initial 
begin

	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	// Read file here (two statements)
	// in_L0_read = $fopen("../00_TESTBED/L0.txt", "r");
	// in_L1_read = $fopen("../00_TESTBED/L1.txt", "r");
	// in_MV_read = $fopen("../00_TESTBED/MV.txt", "r");
	// out_read = $fopen("../00_TESTBED/output.txt", "r");

    in_read = $fopen("../00_TESTBED/syndrome.txt", "r");
	out_read = $fopen("../00_TESTBED/location.txt", "r");
	
	//+++++++++++++++++++++++++++++++++++++++++++++++++++

	rst_n = 1'b1;
	in_valid = 1'b0;
	in_syndrome = 4'bx;
    
	force clk = 0;
 	total_latency = 0;
	reset_signal_task;

	// k = $fscanf(in_read, "%d", PATNUM);
	for(patcount=1; patcount<=576; patcount=patcount+1) 
	begin
		input_task;
        wait_out_valid;
        check_ans;
	end	
  	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end


//======================================
//              Clock
//======================================
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;
//======================================
//              TASKS
//======================================
task reset_signal_task; 
begin 
	#(5);  rst_n=0;
	#(100);
	if((out_valid !== 0)||(out_location !== 0)) 
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
    begin
        repeat({$random(SEED)} % 3 + 2)
		begin
			if(out_valid !== 0)
			begin
				display_fail;
				$display("                  out_valid high before in_valid                        ");
				repeat(2)@(negedge clk);
				$finish;
			end
            if(out_location !== 0)
			begin
				display_fail;
				$display("                  out_location high without out_valid                      ");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
    end		
    in_valid = 1'b1;
    for(i=0; i<6; i=i+1)
    begin
		if(out_valid !== 0 || out_location !== 0)
        begin
            display_fail;
            $display("                   out_valid or out_location high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        // in3_hold = $fscanf(in_MV_read,"%h",in_data);
        in_hold = $fscanf(in_read,"%d",in_syndrome);
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        @(negedge clk);
    end
	// Disable input
	in_valid = 1'b0;
	in_syndrome = 4'bx;
end endtask

task wait_out_valid; begin
    wait_val_time = 0;
    while(out_valid !== 1) begin
        if((out_location !== 0)) 
        begin
            display_fail;
            $display("                  out_location high without out_valid                      ");
            repeat(2)@(negedge clk);
            $finish;
        end
        if(wait_val_time == 2000)
        begin
            display_fail;
            $display("                    execution latency is over 2000 cycles                ");
            repeat(2)@(negedge clk);
            $finish;
        end
        wait_val_time = wait_val_time + 1;
        @(negedge clk);
    end
    total_latency = total_latency + wait_val_time;
end endtask

task check_ans; 
begin
	//++++++++++++++++++++++++++++++++++++++++++++++++
	// Check the answer here
    //+++++++++++++++++++++++++++++++++++++++++++++++++++
    out_hold = $fscanf(out_read,"%d",golden_ans[0]);
    out_hold = $fscanf(out_read,"%d",golden_ans[1]);
    out_hold = $fscanf(out_read,"%d",golden_ans[2]);
    //+++++++++++++++++++++++++++++++++++++++++++++++++++
	i=0;
	while(out_valid)
	begin
		if(i==3)
		begin
			display_fail;
			$display("                    output high over 3 cycles                  ");
			repeat(2)@(negedge clk);
			$finish;
		end
        if(out_location !== golden_ans[i])
        begin
            display_fail;
            $display("                    out_location NO. %d is not correct, answer is %d                  ", i, golden_ans[i]);
            $display("                           out_location answer is %d %d %d                            ", golden_ans[0], golden_ans[1], golden_ans[2]);
            repeat(2)@(negedge clk);
            $finish;
        end
		@(negedge clk);	
		i=i+1;
	end	
    if(i!=3)
    begin
        display_fail;
        $display("                    output should be high 3 cycles                  ");
        repeat(2)@(negedge clk);
        $finish;
    end
	//+++++++++++++++++++++++++++++++++++++++++++++++
	$display("\033[0;34mPASS image %4d PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount, testcnt ,wait_val_time);
	repeat({$random(SEED)} % 3 + 2)
    begin
		if(out_valid !== 0 || out_location !== 0)
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
	$display("              clock period = %4fns", CYCLE);
	$display("**************************************************");
end endtask
endmodule
