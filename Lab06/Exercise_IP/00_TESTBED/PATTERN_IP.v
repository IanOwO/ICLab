`ifdef RTL
    `define CYCLE_TIME 50.0
`endif
`ifdef GATE
    `define CYCLE_TIME 50.0
`endif

module PATTERN #(parameter IP_WIDTH = 7)(
    //Output Port
    IN_Dividend,
	IN_Divisor,
    //Input Port
	OUT_Quotient
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_Dividend;
output reg [IP_WIDTH*4-1:0] IN_Divisor;

input [IP_WIDTH*4-1:0] OUT_Quotient;

// ========================================
// Parameter & clock
// ========================================
parameter PAT_NUM = 200;

integer i;
integer in_div,out_ans;
integer patcount;

integer k;

reg [3:0] dividend[0:IP_WIDTH-1];
reg [3:0] divisor[0:IP_WIDTH-1];
// reg [3:0] golden_ans[0:IP_WIDTH-1];
reg [3:0] golden_ans;
reg [IP_WIDTH*4-1:0] golden_ans_combine;


//======================================
//              Clock
//======================================
reg clk;
real	CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//======================================
//              MAIN
//======================================
initial
begin

	//+++++++++++++++++++++++++++++++++++++++++++++++++++
	// Read file here (two statements)
	in_div = $fopen("../00_TESTBED/div2.txt", "r");
	out_ans = $fopen("../00_TESTBED/div2_ans.txt", "r");

	//+++++++++++++++++++++++++++++++++++++++++++++++++++

	IN_Dividend = {IP_WIDTH*4{1'bx}};
    IN_Divisor = {IP_WIDTH*4{1'bx}};

	// k = $fscanf(in_read, "%d", PATNUM);
	for(patcount=1; patcount<=PAT_NUM; patcount=patcount+1)
	begin
        input_task;
        repeat(1) @(negedge clk);
        check_ans;
		repeat($urandom_range(2, 4)) @(negedge clk);
	end
  	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end


//======================================
//              TASKS
//======================================
task input_task;
begin
	// Inputs start from second negtive edge after the begining of clock
    for( i = 0; i < IP_WIDTH; i=i+1) begin
        k = $fscanf(in_div, "%d", dividend[i]);
    end
    for( i = 0; i < IP_WIDTH; i=i+1) begin
        k = $fscanf(in_div, "%d", divisor[i]);
    end
    IN_Dividend = 0;
    IN_Divisor = 0;
    for( i = 0; i < IP_WIDTH; i=i+1) begin
        // $display ("----------------------- %d ---------------------", 4*i+3);
        IN_Dividend = (IN_Dividend << 4) | dividend[i];
        IN_Divisor = (IN_Divisor << 4) | divisor[i];
    end
end endtask

task check_ans;
begin
	//++++++++++++++++++++++++++++++++++++++++++++++++
	// Check the answer here
    //+++++++++++++++++++++++++++++++++++++++++++++++++++
    golden_ans_combine = 0;
    for( i = 0; i < IP_WIDTH; i=i+1) begin
        k = $fscanf(out_ans, "%d", golden_ans);
        golden_ans_combine = (golden_ans_combine << 4) | golden_ans;
    end
    // $display ("------------------ %h -------------------------",golden_ans_combine);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++
    for(i = 0;i < IP_WIDTH;i = i + 1) begin
        if (golden_ans_combine !== OUT_Quotient) begin
            display_fail;
            $display ("-------------------------------------------------------------------");
            $display ("                                 FAIL                              ");
            $display("*                      PATTERN NO.%4d       	                      ", patcount);
            $display ("             Output should be : %h , your answer is : %h           ", golden_ans_combine, OUT_Quotient);
            $display ("-------------------------------------------------------------------");
            #(200);
            $finish ;
        end
    end

    $display ("             \033[0;32mPass Pattern NO. %d\033[m         ", patcount);

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
	$display("**************************************************");
end endtask


endmodule