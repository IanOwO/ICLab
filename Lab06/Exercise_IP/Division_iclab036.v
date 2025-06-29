//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : Division_IP.v
//   	Module Name : Division_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module Division_IP #(parameter IP_WIDTH = 7) (
    // Input signals
    IN_Dividend, IN_Divisor,
    // Output signals
    OUT_Quotient
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_Dividend;
input [IP_WIDTH*4-1:0]  IN_Divisor;

output [IP_WIDTH*4-1:0] OUT_Quotient;

// ========================
// definition
// ========================
parameter MAX_BIT = IP_WIDTH * 4;

 
reg [IP_WIDTH*4-1:0] dividend[0:IP_WIDTH];
reg [IP_WIDTH*4-1:0] divisor[0:IP_WIDTH];
reg [IP_WIDTH*4-1:0] quotient[0:IP_WIDTH];
reg [3:0] shift_bit[0:IP_WIDTH];
reg [3:0] divisor_bit;

wire [IP_WIDTH*4-1:0] first_shift[0:IP_WIDTH];
wire [3:0] first_shift_bit[0:IP_WIDTH];

wire [IP_WIDTH*4-1:0] quotient_exp;
// ===============================================================
// Design
// ================================================================
genvar i;
generate
    wire [IP_WIDTH*4-1:0] mask = ({4'b1111, {(IP_WIDTH-1){4'b0}}});
    for(i = 0;i < IP_WIDTH;i = i + 1) begin
        if(i == 0) begin
            assign first_shift[i] = ((IN_Divisor & mask) == mask)? (IN_Divisor << 4) | 4'b1111: IN_Divisor;
            assign first_shift_bit[i] = ((IN_Divisor & mask) == mask)? 1: 0;
            // if(|(IN_Divisor & ({4'b1111, {(IP_WIDTH-1){4'b0}}}))) begin
            //     assign first_shift[i] = IN_Divisor;
            // end
            // else begin
            //     assign first_shift[i] = IN_Divisor << 4;
            // end
        end
        else begin
            assign first_shift[i] = ((first_shift[i-1] & mask) == mask)? (first_shift[i-1] << 4) | 4'b1111:first_shift[i-1];
            assign first_shift_bit[i] = ((first_shift[i-1] & mask) == mask)? first_shift_bit[i-1] + 1:first_shift_bit[i-1];
            // if(|(first_shift[i-1] & ({4'b1111, {(IP_WIDTH-1){4'b0}}}))) begin
            //     assign first_shift[i] = first_shift[i-1];
            // end
            // else begin
            //     assign first_shift[i] = first_shift[i-1] << 4;
            // end
        end
    end

    always @(*) begin
        dividend[0] = IN_Dividend;
        divisor[0] = first_shift[IP_WIDTH-1];
        quotient[0] = {4*IP_WIDTH{1'b0}};
        shift_bit[0] = first_shift_bit[IP_WIDTH-1];
        divisor_bit = IP_WIDTH - first_shift_bit[IP_WIDTH-1];
    end
endgenerate

reg [3:0] temp_quo_int;
wire [3:0] temp_quo_exp;

generate
    for(i = 0;i < IP_WIDTH-1;i = i + 1) begin: divisor_count
        if(i == 0) begin
            gf_div#(.IP_WIDTH(IP_WIDTH), .CUR_WIDTH(IP_WIDTH-i)) div_1(.in_div1(dividend[0]), .in_div2(divisor[0]), .in_quo(quotient[0]), .in_shift_bit(shift_bit[0]), .out_div1(dividend[1][4*(IP_WIDTH-i-1)-1:0]), .out_div2(divisor[1][4*(IP_WIDTH-i-1)-1:0]), .out_quo(quotient[1]), .out_shift_bit(shift_bit[1]));
        end
        else begin
            gf_div#(.IP_WIDTH(IP_WIDTH), .CUR_WIDTH(IP_WIDTH-i)) div_2(.in_div1(dividend[i][4*(IP_WIDTH-i)-1:0]), .in_div2(divisor[i][4*(IP_WIDTH-i)-1:0]), .in_quo(quotient[i]), .in_shift_bit(shift_bit[i]), .out_div1(dividend[i+1][4*(IP_WIDTH-i-1)-1:0]), .out_div2(divisor[i+1][4*(IP_WIDTH-i-1)-1:0]), .out_quo(quotient[i+1]), .out_shift_bit(shift_bit[i+1]));
        end
    end
    assign temp_quo_exp = (dividend[IP_WIDTH-1][3:0] == 4'd15)? 4'd15: 
                          (divisor[IP_WIDTH-1][3:0] > dividend[IP_WIDTH-1][3:0])? 15-(divisor[IP_WIDTH-1][3:0]-dividend[IP_WIDTH-1][3:0]):dividend[IP_WIDTH-1][3:0]-divisor[IP_WIDTH-1][3:0];
    always @(*) begin
        case (temp_quo_exp)
            0:  temp_quo_int = 1;
            1:  temp_quo_int = 2;
            2:  temp_quo_int = 4;
            3:  temp_quo_int = 8;
            4:  temp_quo_int = 3;
            5:  temp_quo_int = 6;
            6:  temp_quo_int = 12;
            7:  temp_quo_int = 11;
            8:  temp_quo_int = 5;
            9:  temp_quo_int = 10;
            10:  temp_quo_int = 7;
            11:  temp_quo_int = 14;
            12:  temp_quo_int = 15;
            13:  temp_quo_int = 13;
            14:  temp_quo_int = 9;
            15:  temp_quo_int = 0;
            default:  temp_quo_int = 0;
        endcase
        quotient[IP_WIDTH] = quotient[IP_WIDTH-1] ^ temp_quo_int;
    end
    gf_int_to_exp#(.IP_WIDTH(IP_WIDTH)) int_to_exp1(.int_in(quotient[IP_WIDTH]), .exp_output(quotient_exp));
endgenerate

assign OUT_Quotient = quotient_exp;

endmodule

module gf_div #(parameter IP_WIDTH = 7, CUR_WIDTH = 7) (
    input [CUR_WIDTH*4-1:0] in_div1,
    input [CUR_WIDTH*4-1:0] in_div2,
    input [ IP_WIDTH*4-1:0] in_quo,
    input [3:0] in_shift_bit,
    output reg [CUR_WIDTH*4-1-4:0] out_div1,
    output reg [CUR_WIDTH*4-1-4:0] out_div2,
    output reg [ IP_WIDTH*4-1:0] out_quo,
    output reg [3:0] out_shift_bit
);

// dividend max & divisor max == 0 => fill 0
// dividend < divisor => no calculation
// dividend > divisor => dividend[cur_width - 1:cur_width - divisor_wide]
wire [3:0] max_in_div1 = in_div1[CUR_WIDTH*4-1:CUR_WIDTH*4-4];
wire [3:0] max_in_div2 = in_div2[CUR_WIDTH*4-1:CUR_WIDTH*4-4];
wire [CUR_WIDTH*4-1-4:0] temp_remainder;
wire [3:0] temp_coefficient_int;

genvar cal_i;
generate
    for(cal_i = 1;cal_i <= (CUR_WIDTH-1);cal_i = cal_i + 1) begin: first_gen
        gf_cal gf_div_cal(.exp_div1(max_in_div1), .exp_div2(max_in_div2), .exp_dividend(in_div1[4*(CUR_WIDTH-1-cal_i)+3:4*(CUR_WIDTH-1-cal_i)]), .exp_div_mid(in_div2[4*(CUR_WIDTH-1-cal_i)+3:4*(CUR_WIDTH-1-cal_i)]), .exp_out(temp_remainder[4*(CUR_WIDTH-1-cal_i)+3:4*(CUR_WIDTH-1-cal_i)]), .coefficient_int(temp_coefficient_int));
    end
endgenerate




always @(*) begin
    if((max_in_div1 == 15) & (max_in_div2 == 15)) begin // max is all zero, not sure if it happens
        out_div1 = in_div1;
        out_div2 = in_div2;
        out_quo = in_quo;
        out_shift_bit = in_shift_bit;
    end
    else if((max_in_div1 == 15) & (max_in_div2 != 15) & (in_shift_bit == 0)) begin // divisor is shift to last
        out_div1 = {(CUR_WIDTH-1){4'b1111}};
        out_div2 = {(CUR_WIDTH-1){4'b1111}};
        out_quo = in_quo ^ (4'b0000 << (in_shift_bit*4));
        out_shift_bit = 0;
    end
    else if((max_in_div1 == 15) & (max_in_div2 != 15) & (in_shift_bit != 0)) begin // divisor shift back
        out_div1 = in_div1;
        out_div2 = (in_div2 >> 4);
        out_quo = in_quo ^ (4'b0000 << (in_shift_bit*4));
        out_shift_bit = in_shift_bit - 1;
    end
    else if((max_in_div1 != 15) & (max_in_div2 != 15) & (in_shift_bit == 0)) begin // max_in_div1 != 15 & max_in_div2 != 15 & 
        out_div1 = {(CUR_WIDTH-1){4'b1111}};
        out_div2 = {(CUR_WIDTH-1){4'b1111}};
        out_quo = in_quo ^ (temp_coefficient_int << (in_shift_bit*4));
        out_shift_bit = 0;
    end
    else begin  // max_in_div1 != 15 & max_in_div2 != 15 & in_shift_bit == 0
        out_div1 = temp_remainder;
        out_div2 = (in_div2 >> 4);
        out_quo = in_quo ^ (temp_coefficient_int << (in_shift_bit*4));
        out_shift_bit = in_shift_bit - 1;
    end
end
endmodule

module gf_cal (
    input [3:0] exp_div1,
    input [3:0] exp_div2,
    input [3:0] exp_dividend,
    input [3:0] exp_div_mid,
    output reg [3:0] exp_out,
    output reg [3:0] coefficient_int
);
reg [3:0] int_dividend,int_mid;
reg [3:0] exp_coefficient;
reg [3:0] exp_remainder;
always @(*) begin
    case (exp_dividend)
        0:  int_dividend = 1;
        1:  int_dividend = 2;
        2:  int_dividend = 4;
        3:  int_dividend = 8;
        4:  int_dividend = 3;
        5:  int_dividend = 6;
        6:  int_dividend = 12;
        7:  int_dividend = 11;
        8:  int_dividend = 5;
        9:  int_dividend = 10;
        10:  int_dividend = 7;
        11:  int_dividend = 14;
        12:  int_dividend = 15;
        13:  int_dividend = 13;
        14:  int_dividend = 9;
        15:  int_dividend = 0;
        default:  int_dividend = 0;
    endcase
    exp_coefficient = (exp_div1 >= exp_div2)? exp_div1 - exp_div2: 15 - (exp_div2 - exp_div1);
    exp_remainder = (exp_div_mid == 4'b1111)? exp_div_mid:(exp_div_mid + exp_coefficient) % 15;

    case (exp_remainder)
        0:  int_mid = 1;
        1:  int_mid = 2;
        2:  int_mid = 4;
        3:  int_mid = 8;
        4:  int_mid = 3;
        5:  int_mid = 6;
        6:  int_mid = 12;
        7:  int_mid = 11;
        8:  int_mid = 5;
        9:  int_mid = 10;
        10:  int_mid = 7;
        11:  int_mid = 14;
        12:  int_mid = 15;
        13:  int_mid = 13;
        14:  int_mid = 9;
        15:  int_mid = 0;
        default:  int_mid = 0;
    endcase

    case (exp_coefficient)
        0:  coefficient_int = 1;
        1:  coefficient_int = 2;
        2:  coefficient_int = 4;
        3:  coefficient_int = 8;
        4:  coefficient_int = 3;
        5:  coefficient_int = 6;
        6:  coefficient_int = 12;
        7:  coefficient_int = 11;
        8:  coefficient_int = 5;
        9:  coefficient_int = 10;
        10:  coefficient_int = 7;
        11:  coefficient_int = 14;
        12:  coefficient_int = 15;
        13:  coefficient_int = 13;
        14:  coefficient_int = 9;
        15:  coefficient_int = 0;
        default:  coefficient_int = 0;
    endcase

    case ((int_dividend ^ int_mid))
        0:  exp_out = 15;
        1:  exp_out = 0;
        2:  exp_out = 1;
        3:  exp_out = 4;
        4:  exp_out = 2;
        5:  exp_out = 8;
        6:  exp_out = 5;
        7:  exp_out = 10;
        8:  exp_out = 3;
        9:  exp_out = 14;
        10:  exp_out = 9;
        11:  exp_out = 7;
        12:  exp_out = 6;
        13:  exp_out = 13;
        14:  exp_out = 11;
        15:  exp_out = 12;
        default:  exp_out = 0;
    endcase
end
endmodule

module gf_int_to_exp #(parameter IP_WIDTH = 7) (
    input [IP_WIDTH*4-1:0] int_in,
    output [IP_WIDTH*4-1:0] exp_output
);

wire [3:0] check_list[0:15] = {15,0,1,4,2,8,5,10,3,14,9,7,6,13,11,12};


genvar i;
generate
    for (i = 0;i < IP_WIDTH;i = i + 1) begin
        assign exp_output[4*(IP_WIDTH-i-1)+3:4*(IP_WIDTH-i-1)] = check_list[int_in[4*(IP_WIDTH-i-1)+3:4*(IP_WIDTH-i-1)]];
    end
endgenerate

// always @(*) begin
//     case (int_in)
//         0:  exp_out = 15;
//         1:  exp_out = 0;
//         2:  exp_out = 1;
//         3:  exp_out = 4;
//         4:  exp_out = 2;
//         5:  exp_out = 8;
//         6:  exp_out = 5;
//         7:  exp_out = 10;
//         8:  exp_out = 3;
//         9:  exp_out = 14;
//         10:  exp_out = 9;
//         11:  exp_out = 7;
//         12:  exp_out = 6;
//         13:  exp_out = 13;
//         14:  exp_out = 11;
//         15:  exp_out = 12;
//         default:  exp_out = 0;
//     endcase 
// end
    
endmodule


// module gf_exp_to_int (
//     input [3:0] exp_in,
//     output reg [3:0] int_out
// );
// always @(*) begin
//     case (exp_in)
//         0:  int_out = 1;
//         1:  int_out = 2;
//         2:  int_out = 4;
//         3:  int_out = 8;
//         4:  int_out = 3;
//         5:  int_out = 6;
//         6:  int_out = 12;
//         7:  int_out = 11;
//         8:  int_out = 5;
//         9:  int_out = 10;
//         10:  int_out = 7;
//         11:  int_out = 14;
//         12:  int_out = 15;
//         13:  int_out = 13;
//         14:  int_out = 9;
//         15:  int_out = 0;
//         default:  int_out = 0;
//     endcase
// end
// endmodule