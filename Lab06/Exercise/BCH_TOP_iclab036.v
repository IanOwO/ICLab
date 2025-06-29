//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025
//		Version		: v1.0
//   	File Name   : BCH_TOP.v
//   	Module Name : BCH_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Division_IP.v"

module BCH_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_syndrome, 
    // Output signals
    out_valid, 
	out_location
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_syndrome;

output reg out_valid;
output reg [3:0] out_location;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg [3:0] quotient_exp[0:5];
reg [3:0] trash;
reg [3:0] divisor_exp[0:5];
reg [3:0] dividend_exp[0:6];
reg [3:0] dividend_int[0:6];
reg [3:0] remainder_int[0:5];

reg [2:0] remainder_flag;


reg [3:0] omega_exp[0:3];
reg [3:0] omega_prev_exp[0:3];
reg [3:0] omega_cal_temp_int[0:3];

reg [3:0] exp_to_int[0:15];
reg [3:0] int_to_exp[0:15];

integer i,j;
// ===============================================================
// Design
// d for integer, b for exponential
// ===============================================================
Division_IP #(.IP_WIDTH(7)) my_ip( 
    .IN_Dividend({dividend_exp[0],dividend_exp[1],dividend_exp[2],dividend_exp[3],dividend_exp[4],dividend_exp[5],dividend_exp[6]}),
    .IN_Divisor({4'hf, divisor_exp[0], divisor_exp[1], divisor_exp[2], divisor_exp[3], divisor_exp[4], divisor_exp[5]}),
    .OUT_Quotient({trash, quotient_exp[0], quotient_exp[1], quotient_exp[2], quotient_exp[3], quotient_exp[4], quotient_exp[5]}));

always @(posedge clk) begin
    exp_to_int[0] <= 4'd1;
    exp_to_int[1] <= 4'd2;
    exp_to_int[2] <= 4'd4;
    exp_to_int[3] <= 4'd8;
    exp_to_int[4] <= 4'd3;
    exp_to_int[5] <= 4'd6;
    exp_to_int[6] <= 4'd12;
    exp_to_int[7] <= 4'd11;
    exp_to_int[8] <= 4'd5;
    exp_to_int[9] <= 4'd10;
    exp_to_int[10] <= 4'd7;
    exp_to_int[11] <= 4'd14;
    exp_to_int[12] <= 4'd15;
    exp_to_int[13] <= 4'd13;
    exp_to_int[14] <= 4'd9;
    exp_to_int[15] <= 4'd0;

    int_to_exp[0] <= 4'b1111;
    int_to_exp[1] <= 4'b0000;
    int_to_exp[2] <= 4'b0001;
    int_to_exp[3] <= 4'b0100;
    int_to_exp[4] <= 4'b0010;
    int_to_exp[5] <= 4'b1000;
    int_to_exp[6] <= 4'b0101;
    int_to_exp[7] <= 4'b1010;
    int_to_exp[8] <= 4'b0011;
    int_to_exp[9] <= 4'b1110;
    int_to_exp[10] <= 4'b1001;
    int_to_exp[11] <= 4'b0111;
    int_to_exp[12] <= 4'b0110;
    int_to_exp[13] <= 4'b1101;
    int_to_exp[14] <= 4'b1011;
    int_to_exp[15] <= 4'b1100;
end
reg [3:0] input_counter;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        input_counter <= 0;
    end
    else if(in_valid) begin
        input_counter <= input_counter + 1;
    end
    else begin
        input_counter <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        remainder_flag <= 3'd0;
    end
    else if(in_valid) begin
        remainder_flag <= ((!(|(remainder_int[0] | remainder_int[1] | remainder_int[2]))) & (input_counter == 6))? 3'd2:3'd1;
    end
    else if(remainder_flag == 1) begin
        remainder_flag <= remainder_flag + !(|(remainder_int[0] | remainder_int[1] | remainder_int[2]));
    end
    else if(remainder_flag == 3'd4) begin
        remainder_flag <= 3'd0;
    end
    else if(remainder_flag != 0) begin
        remainder_flag <= remainder_flag + 1;
    end
end

always @(posedge clk) begin
    if(in_valid) begin
        divisor_exp[5] <= divisor_exp[4];
        divisor_exp[4] <= divisor_exp[3];
        divisor_exp[3] <= divisor_exp[2];
        divisor_exp[2] <= divisor_exp[1];
        divisor_exp[1] <= divisor_exp[0];
        divisor_exp[0] <= in_syndrome;

        dividend_exp[6] <= 4'b1111;
        dividend_exp[5] <= 4'b1111;
        dividend_exp[4] <= 4'b1111;
        dividend_exp[3] <= 4'b1111;
        dividend_exp[2] <= 4'b1111;
        dividend_exp[1] <= 4'b1111;
        dividend_exp[0] <= 4'b0000;

        dividend_int[6] <= 4'd0;
        dividend_int[5] <= 4'd0;
        dividend_int[4] <= 4'd0;
        dividend_int[3] <= 4'd0;
        dividend_int[2] <= 4'd0;
        dividend_int[1] <= 4'd0;
        dividend_int[0] <= 4'd1;

        omega_exp[3] <= 4'b1111;
        omega_exp[2] <= 4'b1111;
        omega_exp[1] <= 4'b1111;
        omega_exp[0] <= 4'b0000;

        omega_prev_exp[3] <= 4'b1111;
        omega_prev_exp[2] <= 4'b1111;
        omega_prev_exp[1] <= 4'b1111;
        omega_prev_exp[0] <= 4'b1111;
    end
    else if(remainder_flag == 1) begin
        if((|(remainder_int[0] | remainder_int[1] | remainder_int[2]))) begin
            divisor_exp[5] <= int_to_exp[remainder_int[5]];
            divisor_exp[4] <= int_to_exp[remainder_int[4]];
            divisor_exp[3] <= int_to_exp[remainder_int[3]];
            divisor_exp[2] <= int_to_exp[remainder_int[2]];
            divisor_exp[1] <= int_to_exp[remainder_int[1]];
            divisor_exp[0] <= int_to_exp[remainder_int[0]];

            dividend_exp[6] <= divisor_exp[5];
            dividend_exp[5] <= divisor_exp[4];
            dividend_exp[4] <= divisor_exp[3];
            dividend_exp[3] <= divisor_exp[2];
            dividend_exp[2] <= divisor_exp[1];
            dividend_exp[1] <= divisor_exp[0];
            dividend_exp[0] <= 4'b1111;

            dividend_int[6] <= exp_to_int[divisor_exp[5]];
            dividend_int[5] <= exp_to_int[divisor_exp[4]];
            dividend_int[4] <= exp_to_int[divisor_exp[3]];
            dividend_int[3] <= exp_to_int[divisor_exp[2]];
            dividend_int[2] <= exp_to_int[divisor_exp[1]];
            dividend_int[1] <= exp_to_int[divisor_exp[0]];
            dividend_int[0] <= 4'd0;
        end

        omega_exp[3] <= int_to_exp[omega_cal_temp_int[3]];
        omega_exp[2] <= int_to_exp[omega_cal_temp_int[2]];
        omega_exp[1] <= int_to_exp[omega_cal_temp_int[1]];
        omega_exp[0] <= int_to_exp[omega_cal_temp_int[0]];

        omega_prev_exp[3] <= omega_exp[3];
        omega_prev_exp[2] <= omega_exp[2];
        omega_prev_exp[1] <= omega_exp[1];
        omega_prev_exp[0] <= omega_exp[0];
    end
    // else if(remainder_flag == 2) begin
    //     omega_exp[3] <= int_to_exp[omega_cal_temp_int[3]];
    //     omega_exp[2] <= int_to_exp[omega_cal_temp_int[2]];
    //     omega_exp[1] <= int_to_exp[omega_cal_temp_int[1]];
    //     omega_exp[0] <= int_to_exp[omega_cal_temp_int[0]];

    //     omega_prev_exp[3] <= omega_exp[3];
    //     omega_prev_exp[2] <= omega_exp[2];
    //     omega_prev_exp[1] <= omega_exp[1];
    //     omega_prev_exp[0] <= omega_exp[0];
    // end
end

reg [3:0] deg1[0:1];
reg [3:0] deg2[0:2];
reg [3:0] deg3[0:3];
reg [3:0] deg4[0:4];
reg [3:0] deg5[0:5];

always @(*) begin
    deg1[0] = ((&divisor_exp[4]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((divisor_exp[4] + quotient_exp[5]) % 15)];
    deg1[1] = ((&divisor_exp[5]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((divisor_exp[5] + quotient_exp[4]) % 15)];

    deg2[0] = ((&divisor_exp[3]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((divisor_exp[3] + quotient_exp[5]) % 15)];
    deg2[1] = ((&divisor_exp[4]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((divisor_exp[4] + quotient_exp[4]) % 15)];
    deg2[2] = ((&divisor_exp[5]) | (&quotient_exp[3]))? 4'd0:exp_to_int[((divisor_exp[5] + quotient_exp[3]) % 15)];

    deg3[0] = ((&divisor_exp[2]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((divisor_exp[2] + quotient_exp[5]) % 15)];
    deg3[1] = ((&divisor_exp[3]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((divisor_exp[3] + quotient_exp[4]) % 15)];
    deg3[2] = ((&divisor_exp[4]) | (&quotient_exp[3]))? 4'd0:exp_to_int[((divisor_exp[4] + quotient_exp[3]) % 15)];
    deg3[3] = ((&divisor_exp[5]) | (&quotient_exp[2]))? 4'd0:exp_to_int[((divisor_exp[5] + quotient_exp[2]) % 15)];

    deg4[0] = ((&divisor_exp[1]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((divisor_exp[1] + quotient_exp[5]) % 15)];
    deg4[1] = ((&divisor_exp[2]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((divisor_exp[2] + quotient_exp[4]) % 15)];
    deg4[2] = ((&divisor_exp[3]) | (&quotient_exp[3]))? 4'd0:exp_to_int[((divisor_exp[3] + quotient_exp[3]) % 15)];
    deg4[3] = ((&divisor_exp[4]) | (&quotient_exp[2]))? 4'd0:exp_to_int[((divisor_exp[4] + quotient_exp[2]) % 15)];
    deg4[4] = ((&divisor_exp[5]) | (&quotient_exp[1]))? 4'd0:exp_to_int[((divisor_exp[5] + quotient_exp[1]) % 15)];

    deg5[0] = ((&divisor_exp[0]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((divisor_exp[0] + quotient_exp[5]) % 15)];
    deg5[1] = ((&divisor_exp[1]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((divisor_exp[1] + quotient_exp[4]) % 15)];
    deg5[2] = ((&divisor_exp[2]) | (&quotient_exp[3]))? 4'd0:exp_to_int[((divisor_exp[2] + quotient_exp[3]) % 15)];
    deg5[3] = ((&divisor_exp[3]) | (&quotient_exp[2]))? 4'd0:exp_to_int[((divisor_exp[3] + quotient_exp[2]) % 15)];
    deg5[4] = ((&divisor_exp[4]) | (&quotient_exp[1]))? 4'd0:exp_to_int[((divisor_exp[4] + quotient_exp[1]) % 15)];
    deg5[5] = ((&divisor_exp[5]) | (&quotient_exp[0]))? 4'd0:exp_to_int[((divisor_exp[5] + quotient_exp[0]) % 15)];
    
    remainder_int[5] = ((&divisor_exp[5]) | (&quotient_exp[5]))? 4'd0 ^ dividend_int[6]:exp_to_int[((divisor_exp[5] + quotient_exp[5]) % 15)]  ^ dividend_int[6];
    remainder_int[4] = dividend_int[5] ^ deg1[0] ^ deg1[1];
    remainder_int[3] = dividend_int[4] ^ deg2[0] ^ deg2[1] ^ deg2[2];
    remainder_int[2] = dividend_int[3] ^ deg3[0] ^ deg3[1] ^ deg3[2] ^ deg3[3];
    remainder_int[1] = dividend_int[2] ^ deg4[0] ^ deg4[1] ^ deg4[2] ^ deg4[3] ^ deg4[4];
    remainder_int[0] = dividend_int[1] ^ deg5[0] ^ deg5[1] ^ deg5[2] ^ deg5[3] ^ deg5[4] ^ deg5[5];

end

reg [3:0] omega_deg0;
reg [3:0] omega_deg1[0:1];
reg [3:0] omega_deg2[0:2];
reg [3:0] omega_deg3[0:3];

always @(*) begin
    omega_deg0    = ((&omega_exp[0]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((omega_exp[0] + quotient_exp[5]) % 15)];
    omega_deg1[0] = ((&omega_exp[1]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((omega_exp[1] + quotient_exp[5]) % 15)];
    omega_deg1[1] = ((&omega_exp[0]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((omega_exp[0] + quotient_exp[4]) % 15)];

    omega_deg2[0] = ((&omega_exp[2]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((omega_exp[2] + quotient_exp[5]) % 15)];
    omega_deg2[1] = ((&omega_exp[1]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((omega_exp[1] + quotient_exp[4]) % 15)];
    omega_deg2[2] = ((&omega_exp[0]) | (&quotient_exp[3]))? 4'd0:exp_to_int[((omega_exp[0] + quotient_exp[3]) % 15)];

    omega_deg3[0] = ((&omega_exp[3]) | (&quotient_exp[5]))? 4'd0:exp_to_int[((omega_exp[3] + quotient_exp[5]) % 15)];
    omega_deg3[1] = ((&omega_exp[2]) | (&quotient_exp[4]))? 4'd0:exp_to_int[((omega_exp[2] + quotient_exp[4]) % 15)];
    omega_deg3[2] = ((&omega_exp[1]) | (&quotient_exp[3]))? 4'd0:exp_to_int[((omega_exp[1] + quotient_exp[3]) % 15)];
    omega_deg3[3] = ((&omega_exp[0]) | (&quotient_exp[2]))? 4'd0:exp_to_int[((omega_exp[0] + quotient_exp[2]) % 15)];

    omega_cal_temp_int[0] = exp_to_int[omega_prev_exp[0]] ^ omega_deg0;
    omega_cal_temp_int[1] = exp_to_int[omega_prev_exp[1]] ^ omega_deg1[0] ^ omega_deg1[1];
    omega_cal_temp_int[2] = exp_to_int[omega_prev_exp[2]] ^ omega_deg2[0] ^ omega_deg2[1] ^ omega_deg2[2];
    omega_cal_temp_int[3] = exp_to_int[omega_prev_exp[3]] ^ omega_deg3[0] ^ omega_deg3[1] ^ omega_deg3[2] ^ omega_deg3[3];
end

reg visited[0:14];
reg is_zero[0:14];
reg [3:0] selector;
reg [3:0] omega_exp_temp3[0:14];
reg [3:0] omega_exp_temp2[0:14];
reg [3:0] omega_exp_temp1[0:14];
reg [3:0] omega_exp_temp0[0:14];

always @(*) begin
    for(i = 0;i < 15;i = i + 1) begin
        omega_exp_temp3[i] = (&omega_exp[3])? 4'd0:exp_to_int[(omega_exp[3]+(15-i)*3)%15];
        omega_exp_temp2[i] = (&omega_exp[2])? 4'd0:exp_to_int[(omega_exp[2]+(15-i)*2)%15];
        omega_exp_temp1[i] = (&omega_exp[1])? 4'd0:exp_to_int[(omega_exp[1]+(15-i)*1)%15];
        omega_exp_temp0[i] = (&omega_exp[0])? 4'd0:exp_to_int[omega_exp[0]];
        if((omega_exp_temp3[i] ^ omega_exp_temp2[i] ^ omega_exp_temp1[i] ^ omega_exp_temp0[i]) == 0) begin
            is_zero[i] = 1;
        end
        else begin
            is_zero[i] = 0;
        end
    end
    selector = 4'b1111;
    for(i = 0;i < 15;i = i + 1) begin
        if((!visited[i]) & is_zero[i] & (&selector)) begin
            selector = i;
        end
    end
end

always @(posedge clk) begin
    if(remainder_flag == 1) begin
        for(i = 0;i < 15;i = i + 1)
            visited[i] <= 0;
    end
    else begin
        for(i = 0;i < 15;i = i + 1) begin
            if(selector == i) visited[i] <= 1;
            else visited[i] <= visited[i];
        end
    end
end

always @(*) begin
    if(remainder_flag > 1) begin
        out_valid = 1'b1;
        out_location = selector;
    end
    else begin
        out_valid = 1'b0;
        out_location = 3'd0;
    end
end

endmodule