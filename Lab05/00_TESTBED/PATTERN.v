`define CYCLE_TIME 11
`define SEED_NUMBER     246897531
module PATTERN(
    clk,
    rst_n,
    in_valid,
    in_valid2,
    in_data,
    out_valid,
    out_sad
);
output reg clk, rst_n, in_valid, in_valid2;
output reg [11:0] in_data;
input out_valid;
input out_sad;

//======================================
//      PARAMETERS & VARIABLES
//======================================
real CYCLE = `CYCLE_TIME;

integer total_latency, i, wait_val_time;
integer in_L0_read,in_L1_read,in_MV_read,out_read;
integer in1_hold,in2_hold,in3_hold,out_hold;
integer patcount, testcnt;
integer SEED = `SEED_NUMBER;

reg [55:0] golden_ans;
reg [7:0] in_data_temp;

//======================================
//              MAIN
//======================================
initial 
begin

	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	// Read file here (two statements)
	in_L0_read = $fopen("../00_TESTBED/L0.txt", "r");
	in_L1_read = $fopen("../00_TESTBED/L1.txt", "r");
	in_MV_read = $fopen("../00_TESTBED/MV.txt", "r");
	out_read = $fopen("../00_TESTBED/output.txt", "r");
	
	//+++++++++++++++++++++++++++++++++++++++++++++++++++

	rst_n = 1'b1;
	in_valid = 1'b0;
	in_valid2 = 1'b0;
	in_data = 32'bx;
    
	force clk = 0;
 	total_latency = 0;
	reset_signal_task;

	// k = $fscanf(in_read, "%d", PATNUM);
	for(patcount=1; patcount<=10; patcount=patcount+1) 
	begin
		input_image_task;
        for(testcnt=1; testcnt<=64;testcnt=testcnt+1)
        begin
            input_task;
            wait_out_valid;
            check_ans;
        end
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
	if((out_valid !== 0)||(out_sad !== 0)) 
	begin
		display_fail;
		$display("                    Reset FAIL                   ");
		$finish;
	end
	#(1);  rst_n=1;
	#(5);  release clk;
end 
endtask

task input_image_task; 
begin	
	// Inputs start from second negtive edge after the begining of clock
	if(patcount=='d1)
		repeat(({$random(SEED)} % 3 + 3))
		begin
			if(out_valid !== 0)
			begin
				display_fail;
				$display("                  out_valid high before in_valid                        ");
				repeat(2)@(negedge clk);
				$finish;
			end
            if(out_sad !== 0)
			begin
				display_fail;
				$display("                  out_sad high without out_valid                      ");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	// Set in_valid and input the data
    in_valid = 1'b1;
    for(i=0; i<16384; i=i+1)
    begin
		if(out_valid !== 0 || out_sad !== 0)
        begin
            display_fail;
            $display("                     out_valid or out_sad high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        in1_hold = $fscanf(in_L0_read,"%d",in_data_temp);
        in_data = {in_data_temp, 4'bx};
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        @(negedge clk);
    end
	for(i=0; i<16384; i=i+1)
    begin
		if(out_valid !== 0 || out_sad !== 0)
        begin
            display_fail;
            $display("                     out_valid or out_sad high when in_valid high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        in2_hold = $fscanf(in_L1_read,"%d",in_data_temp);
        in_data = {in_data_temp, 4'bx};
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        @(negedge clk);
    end
	// Disable input
	in_valid = 1'b0;
	in_data = 12'bx;
end endtask

task input_task; 
begin	
	// Inputs start from second negtive edge after the begining of clock
    if(testcnt=='d1)
    begin
        repeat(({$random(SEED)} % 3 + 3))
		begin
			if(out_valid !== 0)
			begin
				display_fail;
				$display("                  out_valid high before in_valid2                        ");
				repeat(2)@(negedge clk);
				$finish;
			end
            if(out_sad !== 0)
			begin
				display_fail;
				$display("                  out_sad high without out_valid                      ");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
    end		

    if(out_valid !== 0)
    begin
        display_fail;
        $display("                  out_valid high before in_valid2                        ");
        repeat(2)@(negedge clk);
        $finish;
    end
    if(out_sad !== 0)
    begin
        display_fail;
        $display("                  out_sad high without out_valid                      ");
        repeat(2)@(negedge clk);
        $finish;
    end
    @(negedge clk);

    in_valid2 = 1'b1;
    for(i=0; i<8; i=i+1)
    begin
		if(out_valid !== 0 || out_sad !== 0)
        begin
            display_fail;
            $display("                     out_valid or out_sad high when in_valid2 high                  ");
            repeat(2)@(negedge clk);
            $finish;
        end
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        in3_hold = $fscanf(in_MV_read,"%h",in_data);
        //+++++++++++++++++++++++++++++++++++++++++++++++++++
        @(negedge clk);
    end
	// Disable input
	in_valid2 = 1'b0;
	in_data = 12'bx;
end endtask

task wait_out_valid; begin
    wait_val_time = 0;
    while(out_valid !== 1) begin
        if((out_sad !== 0)) 
        begin
            display_fail;
            $display("                  out_sad high without out_valid                      ");
            repeat(2)@(negedge clk);
            $finish;
        end
        wait_val_time = wait_val_time + 1;
        if(wait_val_time == 1000)
        begin
            display_fail;
            $display("                    execution latency is over 1000 cycles                ");
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
    //+++++++++++++++++++++++++++++++++++++++++++++++++++
    out_hold = $fscanf(out_read,"%h",golden_ans);
    //+++++++++++++++++++++++++++++++++++++++++++++++++++
	i=0;
	while(out_valid)
	begin
		if(i==56)
		begin
			display_fail;
			$display("                    output high over 56 cycles                  ");
			repeat(2)@(negedge clk);
			$finish;
		end
        if(out_sad !== golden_ans[i])
        begin
            display_fail;
            $display("                    out_sad NO. %4d is not correct, answer is %b                  ", i, golden_ans[i]);
            $display("                    correct output of point2 is %h                  ", golden_ans[55:28]);
            if(i<28)
            begin
                $display("                    correct output of point1 is %h                  ", golden_ans[27:0]);
            end
            else
            begin
                $display("                    correct output of point2 is %h                  ", golden_ans[55:28]);
            end
            repeat(2)@(negedge clk);
            $finish;
        end
		@(negedge clk);	
		i=i+1;
	end	
    if(i!=56)
    begin
        display_fail;
        $display("                    output should be high 56 cycles                  ");
        repeat(2)@(negedge clk);
        $finish;
    end
	//+++++++++++++++++++++++++++++++++++++++++++++++
	$display("\033[0;34mPASS image %4d PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount, testcnt ,wait_val_time);
	repeat(({$random(SEED)} % 3 + 3))
    begin
		if(out_valid !== 0 || out_sad !== 0)
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
