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


module ATTN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter sqare_root_2 = 32'b00111111101101010000010011110011;

parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter OUT = 3'd3;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] in_str, q_weight, k_weight, v_weight, out_weight;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

integer i;
//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [31:0] in_str_11, in_str_12, in_str_13, in_str_14;
reg [31:0] in_str_21, in_str_22, in_str_23, in_str_24;
reg [31:0] in_str_31, in_str_32, in_str_33, in_str_34;
reg [31:0] in_str_41, in_str_42, in_str_43, in_str_44;
reg [31:0] in_str_51, in_str_52, in_str_53, in_str_54;

// little q & head_1
reg [31:0] q_mat_11, q_mat_12, q_mat_13, q_mat_14, q_mat_15;
reg [31:0] q_mat_21, q_mat_22, q_mat_23, q_mat_24, q_mat_25;
reg [31:0] q_mat_31, q_mat_32, q_mat_33, q_mat_34, q_mat_35;
reg [31:0] q_mat_41, q_mat_42, q_mat_43, q_mat_44, q_mat_45;
reg [31:0] q_mat_51, q_mat_52, q_mat_53, q_mat_54, q_mat_55;

// big Q
reg [31:0] Q_mat_11, Q_mat_12, Q_mat_13, Q_mat_14;
reg [31:0] Q_mat_21, Q_mat_22, Q_mat_23, Q_mat_24;
reg [31:0] Q_mat_31, Q_mat_32, Q_mat_33, Q_mat_34;
reg [31:0] Q_mat_41, Q_mat_42, Q_mat_43, Q_mat_44;
reg [31:0] Q_mat_51, Q_mat_52, Q_mat_53, Q_mat_54;

// little k & head_2
reg [31:0] k_mat_11, k_mat_12, k_mat_13, k_mat_14, k_mat_15;
reg [31:0] k_mat_21, k_mat_22, k_mat_23, k_mat_24, k_mat_25;
reg [31:0] k_mat_31, k_mat_32, k_mat_33, k_mat_34, k_mat_35;
reg [31:0] k_mat_41, k_mat_42, k_mat_43, k_mat_44, k_mat_45;
reg [31:0] k_mat_51, k_mat_52, k_mat_53, k_mat_54, k_mat_55;

// big K
reg [31:0] K_mat_11, K_mat_12, K_mat_13, K_mat_14;
reg [31:0] K_mat_21, K_mat_22, K_mat_23, K_mat_24;
reg [31:0] K_mat_31, K_mat_32, K_mat_33, K_mat_34;
reg [31:0] K_mat_41, K_mat_42, K_mat_43, K_mat_44;
reg [31:0] K_mat_51, K_mat_52, K_mat_53, K_mat_54;

reg [31:0] k_mat_sum_exp_row2;

// little v
reg [31:0] v_mat_11, v_mat_12, v_mat_13, v_mat_14;
reg [31:0] v_mat_21, v_mat_22, v_mat_23, v_mat_24;
reg [31:0] v_mat_31, v_mat_32, v_mat_33, v_mat_34;
reg [31:0] v_mat_41, v_mat_42, v_mat_43, v_mat_44;

// // big V
// reg [31:0] V_mat_11, V_mat_12, V_mat_13, V_mat_14;
// reg [31:0] V_mat_21, V_mat_22, V_mat_23, V_mat_24;
// reg [31:0] V_mat_31, V_mat_32, V_mat_33, V_mat_34;
// reg [31:0] V_mat_41, V_mat_42, V_mat_43, V_mat_44;
// reg [31:0] V_mat_51, V_mat_52, V_mat_53, V_mat_54;

// out_weight
reg [31:0] out_weight_mat_11, out_weight_mat_12, out_weight_mat_13, out_weight_mat_14;
reg [31:0] out_weight_mat_21, out_weight_mat_22, out_weight_mat_23, out_weight_mat_24;
reg [31:0] out_weight_mat_31, out_weight_mat_32, out_weight_mat_33, out_weight_mat_34;
reg [31:0] out_weight_mat_41, out_weight_mat_42, out_weight_mat_43, out_weight_mat_44;


reg [5:0] counter;

reg [31:0] select_dot1_ac[0:15];
reg [31:0] select_dot1_bd[0:15];
wire [31:0] result_dot1[0:7];
reg [31:0] select_add1_a[0:3];
reg [31:0] select_add1_b[0:3];
wire [31:0] result_add1[0:3];

reg [31:0] select_dot2_ac[0:15];
reg [31:0] select_dot2_bd[0:15];
wire [31:0] result_dot2[0:7];
reg [31:0] select_add2_a[0:3];
reg [31:0] select_add2_b[0:3];
wire [31:0] result_add2[0:3];

reg [31:0] result_pipe_div1[0:4];
reg [31:0] result_pipe_exp[0:4];
reg [31:0] result_pipe_div2[0:4];

reg [31:0] calculate_answer_add[0:1];
reg [31:0] calculate_answer;
reg in_flag;
//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------
// ex.
// Q matrix muliplication
DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot1 (  .a(select_dot1_ac[0]),  .b(select_dot1_bd[0]),  .c(select_dot1_ac[1]), .d(select_dot1_bd[1]), .rnd(3'b000), .z(result_dot1[0]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot2 (  .a(select_dot1_ac[2]),  .b(select_dot1_bd[2]),  .c(select_dot1_ac[3]), .d(select_dot1_bd[3]), .rnd(3'b000), .z(result_dot1[1]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot3 (  .a(select_dot1_ac[4]),  .b(select_dot1_bd[4]),  .c(select_dot1_ac[5]), .d(select_dot1_bd[5]), .rnd(3'b000), .z(result_dot1[2]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot4 (  .a(select_dot1_ac[6]),  .b(select_dot1_bd[6]),  .c(select_dot1_ac[7]), .d(select_dot1_bd[7]), .rnd(3'b000), .z(result_dot1[3]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot5 (  .a(select_dot1_ac[8]),  .b(select_dot1_bd[8]),  .c(select_dot1_ac[9]), .d(select_dot1_bd[9]), .rnd(3'b000), .z(result_dot1[4]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot6 ( .a(select_dot1_ac[10]), .b(select_dot1_bd[10]), .c(select_dot1_ac[11]), .d(select_dot1_bd[11]), .rnd(3'b000), .z(result_dot1[5]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot7 ( .a(select_dot1_ac[12]), .b(select_dot1_bd[12]), .c(select_dot1_ac[13]), .d(select_dot1_bd[13]), .rnd(3'b000), .z(result_dot1[6]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Qmat_dot8 ( .a(select_dot1_ac[14]), .b(select_dot1_bd[14]), .c(select_dot1_ac[15]), .d(select_dot1_bd[15]), .rnd(3'b000), .z(result_dot1[7]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Qmat_add1 (  .a(select_add1_a[0]),  .b(select_add1_b[0]), .rnd(3'b000), .z(result_add1[0]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Qmat_add2 (  .a(select_add1_a[1]),  .b(select_add1_b[1]), .rnd(3'b000), .z(result_add1[1]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Qmat_add3 (  .a(select_add1_a[2]),  .b(select_add1_b[2]), .rnd(3'b000), .z(result_add1[2]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Qmat_add4 (  .a(select_add1_a[3]),  .b(select_add1_b[3]), .rnd(3'b000), .z(result_add1[3]), .status());

// K matrix muliplication
DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot1 (  .a(select_dot2_ac[0]),  .b(select_dot2_bd[0]),  .c(select_dot2_ac[1]), .d(select_dot2_bd[1]), .rnd(3'b000), .z(result_dot2[0]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot2 (  .a(select_dot2_ac[2]),  .b(select_dot2_bd[2]),  .c(select_dot2_ac[3]), .d(select_dot2_bd[3]), .rnd(3'b000), .z(result_dot2[1]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot3 (  .a(select_dot2_ac[4]),  .b(select_dot2_bd[4]),  .c(select_dot2_ac[5]), .d(select_dot2_bd[5]), .rnd(3'b000), .z(result_dot2[2]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot4 (  .a(select_dot2_ac[6]),  .b(select_dot2_bd[6]),  .c(select_dot2_ac[7]), .d(select_dot2_bd[7]), .rnd(3'b000), .z(result_dot2[3]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot5 (  .a(select_dot2_ac[8]),  .b(select_dot2_bd[8]),  .c(select_dot2_ac[9]), .d(select_dot2_bd[9]), .rnd(3'b000), .z(result_dot2[4]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot6 ( .a(select_dot2_ac[10]), .b(select_dot2_bd[10]), .c(select_dot2_ac[11]), .d(select_dot2_bd[11]), .rnd(3'b000), .z(result_dot2[5]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot7 ( .a(select_dot2_ac[12]), .b(select_dot2_bd[12]), .c(select_dot2_ac[13]), .d(select_dot2_bd[13]), .rnd(3'b000), .z(result_dot2[6]), .status());

DW_fp_dp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
Kmat_dot8 ( .a(select_dot2_ac[14]), .b(select_dot2_bd[14]), .c(select_dot2_ac[15]), .d(select_dot2_bd[15]), .rnd(3'b000), .z(result_dot2[7]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Kmat_add1 (  .a(select_add2_a[0]),  .b(select_add2_b[0]), .rnd(3'b000), .z(result_add2[0]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Kmat_add2 (  .a(select_add2_a[1]),  .b(select_add2_b[1]), .rnd(3'b000), .z(result_add2[1]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Kmat_add3 (  .a(select_add2_a[2]),  .b(select_add2_b[2]), .rnd(3'b000), .z(result_add2[2]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
Kmat_add4 (  .a(select_add2_a[3]),  .b(select_add2_b[3]), .rnd(3'b000), .z(result_add2[3]), .status());

// pipeline part
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div1 (  .a(k_mat_51),  .b(sqare_root_2), .rnd(3'b000), .z(result_pipe_div1[0]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div2 (  .a(k_mat_52),  .b(sqare_root_2), .rnd(3'b000), .z(result_pipe_div1[1]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div3 (  .a(k_mat_53),  .b(sqare_root_2), .rnd(3'b000), .z(result_pipe_div1[2]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div4 (  .a(k_mat_54),  .b(sqare_root_2), .rnd(3'b000), .z(result_pipe_div1[3]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div5 (  .a(k_mat_55),  .b(sqare_root_2), .rnd(3'b000), .z(result_pipe_div1[4]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
pipe_exp1 (  .a(k_mat_41), .z(result_pipe_exp[0]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
pipe_exp2 (  .a(k_mat_42), .z(result_pipe_exp[1]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
pipe_exp3 (  .a(k_mat_43), .z(result_pipe_exp[2]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
pipe_exp4 (  .a(k_mat_44), .z(result_pipe_exp[3]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
pipe_exp5 (  .a(k_mat_45), .z(result_pipe_exp[4]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div6 (  .a(k_mat_21),  .b(k_mat_sum_exp_row2), .rnd(3'b000), .z(result_pipe_div2[0]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div7 (  .a(k_mat_22),  .b(k_mat_sum_exp_row2), .rnd(3'b000), .z(result_pipe_div2[1]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div8 (  .a(k_mat_23),  .b(k_mat_sum_exp_row2), .rnd(3'b000), .z(result_pipe_div2[2]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div9 (  .a(k_mat_24),  .b(k_mat_sum_exp_row2), .rnd(3'b000), .z(result_pipe_div2[3]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
pipe_div10 (  .a(k_mat_25),  .b(k_mat_sum_exp_row2), .rnd(3'b000), .z(result_pipe_div2[4]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
pipe_add_answer (  .a(calculate_answer_add[0]),  .b(calculate_answer_add[1]), .rnd(3'b000), .z(calculate_answer), .status());

//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------
// input and calculate matrix multiplication

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_flag <= 0;
    end
    else if(in_valid) begin
        in_flag <= 1;
    end
    else if(in_flag & (counter < 48)) begin
        in_flag <= 1;
    end
    else begin
        in_flag <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 6'b000000;
    end
    else if(in_valid) begin
        counter <= counter + 1;
    end
    else if(in_flag & (counter < 48)) begin
        counter <= counter + 1;    
    end
    else begin
        counter <= 6'b000000;
    end
    
end

always @(posedge clk) begin
    if(in_valid) begin
        in_str_11 <= in_str_12;
        in_str_12 <= in_str_13;
        in_str_13 <= in_str_14;
        in_str_14 <= in_str_21;
        in_str_21 <= in_str_22;
        in_str_22 <= in_str_23;
        in_str_23 <= in_str_24;
        in_str_24 <= in_str_31;
        in_str_31 <= in_str_32;
        in_str_32 <= in_str_33;
        in_str_33 <= in_str_34;
        in_str_34 <= in_str_41;
        in_str_41 <= in_str_42;
        in_str_42 <= in_str_43;
        in_str_43 <= in_str_44;
        in_str_44 <= in_str_51;
        in_str_51 <= in_str_52;
        in_str_52 <= in_str_53;
        in_str_53 <= in_str_54;
        in_str_54 <= in_str;
    end
    else if(counter >= 21 && counter <= 25) begin // store big V
        in_str_11 <= in_str_21; in_str_12 <= in_str_22; in_str_13 <= in_str_23; in_str_14 <= in_str_24;
        in_str_21 <= in_str_31; in_str_22 <= in_str_32; in_str_23 <= in_str_33; in_str_24 <= in_str_34;
        in_str_31 <= in_str_41; in_str_32 <= in_str_42; in_str_33 <= in_str_43; in_str_34 <= in_str_44;
        in_str_41 <= in_str_51; in_str_42 <= in_str_52; in_str_43 <= in_str_53; in_str_44 <= in_str_54;
        in_str_51 <= result_add2[0]; in_str_52 <= result_add2[1]; in_str_53 <= result_add2[2]; in_str_54 <= result_add2[3];
    end
end

// always @(posedge clk) begin
//     if(counter >= 21 && counter <= 25) begin
//         V_mat_11 <= V_mat_21; V_mat_12 <= V_mat_22; V_mat_13 <= V_mat_23; V_mat_14 <= V_mat_24;
//         V_mat_21 <= V_mat_31; V_mat_22 <= V_mat_32; V_mat_23 <= V_mat_33; V_mat_24 <= V_mat_34;
//         V_mat_31 <= V_mat_41; V_mat_32 <= V_mat_42; V_mat_33 <= V_mat_43; V_mat_34 <= V_mat_44;
//         V_mat_41 <= V_mat_51; V_mat_42 <= V_mat_52; V_mat_43 <= V_mat_53; V_mat_44 <= V_mat_54;
//         V_mat_51 <= result_add2[0]; V_mat_52 <= result_add2[1]; V_mat_53 <= result_add2[2]; V_mat_54 <= result_add2[3];
//     end
// end

always @(posedge clk) begin
    if(in_valid & (!counter[4])) begin
        q_mat_11 <= q_mat_12;
        q_mat_12 <= q_mat_13;
        q_mat_13 <= q_mat_14;
        q_mat_14 <= q_mat_21;
        q_mat_15 <= 32'b0;
        q_mat_21 <= q_mat_22;
        q_mat_22 <= q_mat_23;
        q_mat_23 <= q_mat_24;
        q_mat_24 <= q_mat_31;
        q_mat_25 <= 32'b0;
        q_mat_31 <= q_mat_32;
        q_mat_32 <= q_mat_33;
        q_mat_33 <= q_mat_34;
        q_mat_34 <= q_mat_41;
        q_mat_35 <= 32'b0;
        q_mat_41 <= q_mat_42;
        q_mat_42 <= q_mat_43;
        q_mat_43 <= q_mat_44;
        q_mat_44 <= q_weight;
        q_mat_45 <= 32'b0;
        q_mat_51 <= 32'b0;
        q_mat_52 <= 32'b0;
        q_mat_53 <= 32'b0;
        q_mat_54 <= 32'b0;
        q_mat_55 <= 32'b0;
    end
    else if(counter >= 26 & counter <= 35)begin // Score1
        q_mat_11 <= q_mat_13; q_mat_12 <= q_mat_14; q_mat_13 <= q_mat_21; q_mat_14 <= q_mat_22;
        q_mat_21 <= q_mat_23; q_mat_22 <= q_mat_24; q_mat_23 <= q_mat_31; q_mat_24 <= q_mat_32;
        q_mat_31 <= q_mat_33; q_mat_32 <= q_mat_34; q_mat_33 <= q_mat_41; q_mat_34 <= q_mat_42;
        q_mat_41 <= q_mat_43; q_mat_42 <= q_mat_44; q_mat_43 <= q_mat_51; q_mat_44 <= q_mat_52;
        // calculate score(after softmax) * V
        q_mat_51 <= q_mat_53; q_mat_52 <= q_mat_54; q_mat_53 <= result_add2[1]; q_mat_54 <= result_add2[3];
    end
end

always @(posedge clk) begin
    if(counter <= 20 && counter >= 16) begin
        Q_mat_11 <= Q_mat_21; Q_mat_12 <= Q_mat_22; Q_mat_13 <= Q_mat_23; Q_mat_14 <= Q_mat_24;
        Q_mat_21 <= Q_mat_31; Q_mat_22 <= Q_mat_32; Q_mat_23 <= Q_mat_33; Q_mat_24 <= Q_mat_34;
        Q_mat_31 <= Q_mat_41; Q_mat_32 <= Q_mat_42; Q_mat_33 <= Q_mat_43; Q_mat_34 <= Q_mat_44;
        Q_mat_41 <= Q_mat_51; Q_mat_42 <= Q_mat_52; Q_mat_43 <= Q_mat_53; Q_mat_44 <= Q_mat_54;
        Q_mat_51 <= result_add1[0]; Q_mat_52 <= result_add1[1]; Q_mat_53 <= result_add1[2]; Q_mat_54 <= result_add1[3];
    end
end

always @(posedge clk) begin
    if(in_valid & (!counter[4])) begin
        k_mat_11 <= k_mat_12;
        k_mat_12 <= k_mat_13;
        k_mat_13 <= k_mat_14;
        k_mat_14 <= k_mat_21;
        k_mat_15 <= 32'b0;
        k_mat_21 <= k_mat_22;
        k_mat_22 <= k_mat_23;
        k_mat_23 <= k_mat_24;
        k_mat_24 <= k_mat_31;
        k_mat_25 <= 32'b0;
        k_mat_31 <= k_mat_32;
        k_mat_32 <= k_mat_33;
        k_mat_33 <= k_mat_34;
        k_mat_34 <= k_mat_41;
        k_mat_35 <= 32'b0;
        k_mat_41 <= k_mat_42;
        k_mat_42 <= k_mat_43;
        k_mat_43 <= k_mat_44;
        k_mat_44 <= k_weight;
        k_mat_35 <= 32'b0;
        k_mat_51 <= 32'b0;
        k_mat_52 <= 32'b0;
        k_mat_53 <= 32'b0;
        k_mat_54 <= 32'b0;
        k_mat_55 <= 32'b0;
    end
    else if(counter >= 21 & counter <= 34)begin // Score2
        // calculate exp_score divide by sum of exp_score
        k_mat_11 <= result_pipe_div2[0]; k_mat_12 <= result_pipe_div2[1]; k_mat_13 <= result_pipe_div2[2]; k_mat_14 <= result_pipe_div2[3]; k_mat_15 <= result_pipe_div2[4];
        // calculate sum of exp_score
        k_mat_21 <= k_mat_31; k_mat_22 <= k_mat_32; k_mat_23 <= k_mat_33; k_mat_24 <= k_mat_34; k_mat_25 <= k_mat_35; k_mat_sum_exp_row2 <= result_add1[3];
        // calculate exp_score
        k_mat_31 <= result_pipe_exp[0]; k_mat_32 <= result_pipe_exp[1]; k_mat_33 <= result_pipe_exp[2]; k_mat_34 <= result_pipe_exp[3]; k_mat_35 <= result_pipe_exp[4];
        // calculate score divide by square root 2
        k_mat_41 <= result_pipe_div1[0]; k_mat_42 <= result_pipe_div1[1]; k_mat_43 <= result_pipe_div1[2]; k_mat_44 <= result_pipe_div1[3]; k_mat_45 <= result_pipe_div1[4];
        // calculate Q*K
        k_mat_51 <= result_dot1[0]; k_mat_52 <= result_dot1[1]; k_mat_53 <= result_dot1[2]; k_mat_54 <= result_dot1[3]; k_mat_55 <= result_dot1[4];
    end
end

always @(posedge clk) begin
    if(counter <= 20 && counter >= 16) begin
        K_mat_11 <= K_mat_21; K_mat_12 <= K_mat_22; K_mat_13 <= K_mat_23; K_mat_14 <= K_mat_24;
        K_mat_21 <= K_mat_31; K_mat_22 <= K_mat_32; K_mat_23 <= K_mat_33; K_mat_24 <= K_mat_34;
        K_mat_31 <= K_mat_41; K_mat_32 <= K_mat_42; K_mat_33 <= K_mat_43; K_mat_34 <= K_mat_44;
        K_mat_41 <= K_mat_51; K_mat_42 <= K_mat_52; K_mat_43 <= K_mat_53; K_mat_44 <= K_mat_54;
        K_mat_51 <= result_add2[0]; K_mat_52 <= result_add2[1]; K_mat_53 <= result_add2[2]; K_mat_54 <= result_add2[3];
    end
end

always @(posedge clk) begin
    if(in_valid & (!counter[4])) begin
        v_mat_11 <= v_mat_12;
        v_mat_12 <= v_mat_13;
        v_mat_13 <= v_mat_14;
        v_mat_14 <= v_mat_21;
        v_mat_21 <= v_mat_22;
        v_mat_22 <= v_mat_23;
        v_mat_23 <= v_mat_24;
        v_mat_24 <= v_mat_31;
        v_mat_31 <= v_mat_32;
        v_mat_32 <= v_mat_33;
        v_mat_33 <= v_mat_34;
        v_mat_34 <= v_mat_41;
        v_mat_41 <= v_mat_42;
        v_mat_42 <= v_mat_43;
        v_mat_43 <= v_mat_44;
        v_mat_44 <= v_weight;
    end
end

always @(posedge clk) begin
    if(in_valid & (!counter[4])) begin
        out_weight_mat_11 <= out_weight_mat_12;
        out_weight_mat_12 <= out_weight_mat_13;
        out_weight_mat_13 <= out_weight_mat_14;
        out_weight_mat_14 <= out_weight_mat_21;
        out_weight_mat_21 <= out_weight_mat_22;
        out_weight_mat_22 <= out_weight_mat_23;
        out_weight_mat_23 <= out_weight_mat_24;
        out_weight_mat_24 <= out_weight_mat_31;
        out_weight_mat_31 <= out_weight_mat_32;
        out_weight_mat_32 <= out_weight_mat_33;
        out_weight_mat_33 <= out_weight_mat_34;
        out_weight_mat_34 <= out_weight_mat_41;
        out_weight_mat_41 <= out_weight_mat_42;
        out_weight_mat_42 <= out_weight_mat_43;
        out_weight_mat_43 <= out_weight_mat_44;
        out_weight_mat_44 <= out_weight;
    end
end

// dot1 AC selector
always @(*) begin
    for(i = 0;i < 16;i = i + 1) begin
        select_dot1_ac[i] = 32'd0;
    end

    case(counter)
        16: begin
            select_dot1_ac[0] = in_str_21;  select_dot1_ac[1] = in_str_22;  select_dot1_ac[2] = in_str_23;  select_dot1_ac[3] = in_str_24;
            select_dot1_ac[4] = in_str_21;  select_dot1_ac[5] = in_str_22;  select_dot1_ac[6] = in_str_23;  select_dot1_ac[7] = in_str_24;
            select_dot1_ac[8] = in_str_21;  select_dot1_ac[9] = in_str_22;  select_dot1_ac[10] = in_str_23; select_dot1_ac[11] = in_str_24;
            select_dot1_ac[12] = in_str_21; select_dot1_ac[13] = in_str_22; select_dot1_ac[14] = in_str_23; select_dot1_ac[15] = in_str_24;
        end
        17: begin
            select_dot1_ac[0] = in_str_24;  select_dot1_ac[1] = in_str_31;  select_dot1_ac[2] = in_str_32;  select_dot1_ac[3] = in_str_33;
            select_dot1_ac[4] = in_str_24;  select_dot1_ac[5] = in_str_31;  select_dot1_ac[6] = in_str_32;  select_dot1_ac[7] = in_str_33;
            select_dot1_ac[8] = in_str_24;  select_dot1_ac[9] = in_str_31;  select_dot1_ac[10] = in_str_32; select_dot1_ac[11] = in_str_33;
            select_dot1_ac[12] = in_str_24; select_dot1_ac[13] = in_str_31; select_dot1_ac[14] = in_str_32; select_dot1_ac[15] = in_str_33;
        end
        18: begin
            select_dot1_ac[0] = in_str_33;  select_dot1_ac[1] = in_str_34;  select_dot1_ac[2] = in_str_41;  select_dot1_ac[3] = in_str_42;
            select_dot1_ac[4] = in_str_33;  select_dot1_ac[5] = in_str_34;  select_dot1_ac[6] = in_str_41;  select_dot1_ac[7] = in_str_42;
            select_dot1_ac[8] = in_str_33;  select_dot1_ac[9] = in_str_34;  select_dot1_ac[10] = in_str_41; select_dot1_ac[11] = in_str_42;
            select_dot1_ac[12] = in_str_33; select_dot1_ac[13] = in_str_34; select_dot1_ac[14] = in_str_41; select_dot1_ac[15] = in_str_42;
        end
        19: begin
            select_dot1_ac[0] = in_str_42;  select_dot1_ac[1] = in_str_43;  select_dot1_ac[2] = in_str_44;  select_dot1_ac[3] = in_str_51;
            select_dot1_ac[4] = in_str_42;  select_dot1_ac[5] = in_str_43;  select_dot1_ac[6] = in_str_44;  select_dot1_ac[7] = in_str_51;
            select_dot1_ac[8] = in_str_42;  select_dot1_ac[9] = in_str_43;  select_dot1_ac[10] = in_str_44; select_dot1_ac[11] = in_str_51;
            select_dot1_ac[12] = in_str_42; select_dot1_ac[13] = in_str_43; select_dot1_ac[14] = in_str_44; select_dot1_ac[15] = in_str_51;
        end
        20: begin
            select_dot1_ac[0] = in_str_51;  select_dot1_ac[1] = in_str_52;  select_dot1_ac[2] = in_str_53;  select_dot1_ac[3] = in_str_54;
            select_dot1_ac[4] = in_str_51;  select_dot1_ac[5] = in_str_52;  select_dot1_ac[6] = in_str_53;  select_dot1_ac[7] = in_str_54;
            select_dot1_ac[8] = in_str_51;  select_dot1_ac[9] = in_str_52;  select_dot1_ac[10] = in_str_53; select_dot1_ac[11] = in_str_54;
            select_dot1_ac[12] = in_str_51; select_dot1_ac[13] = in_str_52; select_dot1_ac[14] = in_str_53; select_dot1_ac[15] = in_str_54;
        end
        21: begin // head 1 row 1
            select_dot1_ac[0] = Q_mat_11; select_dot1_ac[1] = Q_mat_12;
            select_dot1_ac[2] = Q_mat_11; select_dot1_ac[3] = Q_mat_12;
            select_dot1_ac[4] = Q_mat_11; select_dot1_ac[5] = Q_mat_12;
            select_dot1_ac[6] = Q_mat_11; select_dot1_ac[7] = Q_mat_12;
            select_dot1_ac[8] = Q_mat_11; select_dot1_ac[9] = Q_mat_12;
        end
        22: begin // head 2 row 1
            select_dot1_ac[0] = Q_mat_13; select_dot1_ac[1] = Q_mat_14;
            select_dot1_ac[2] = Q_mat_13; select_dot1_ac[3] = Q_mat_14;
            select_dot1_ac[4] = Q_mat_13; select_dot1_ac[5] = Q_mat_14;
            select_dot1_ac[6] = Q_mat_13; select_dot1_ac[7] = Q_mat_14;
            select_dot1_ac[8] = Q_mat_13; select_dot1_ac[9] = Q_mat_14;
        end
        23: begin // head 1 row 2
            select_dot1_ac[0] = Q_mat_21; select_dot1_ac[1] = Q_mat_22;
            select_dot1_ac[2] = Q_mat_21; select_dot1_ac[3] = Q_mat_22;
            select_dot1_ac[4] = Q_mat_21; select_dot1_ac[5] = Q_mat_22;
            select_dot1_ac[6] = Q_mat_21; select_dot1_ac[7] = Q_mat_22;
            select_dot1_ac[8] = Q_mat_21; select_dot1_ac[9] = Q_mat_22;
        end
        24: begin // head 2 row 2
            select_dot1_ac[0] = Q_mat_23; select_dot1_ac[1] = Q_mat_24;
            select_dot1_ac[2] = Q_mat_23; select_dot1_ac[3] = Q_mat_24;
            select_dot1_ac[4] = Q_mat_23; select_dot1_ac[5] = Q_mat_24;
            select_dot1_ac[6] = Q_mat_23; select_dot1_ac[7] = Q_mat_24;
            select_dot1_ac[8] = Q_mat_23; select_dot1_ac[9] = Q_mat_24;
        end
        25: begin // head 1 row 3
            select_dot1_ac[0] = Q_mat_31; select_dot1_ac[1] = Q_mat_32;
            select_dot1_ac[2] = Q_mat_31; select_dot1_ac[3] = Q_mat_32;
            select_dot1_ac[4] = Q_mat_31; select_dot1_ac[5] = Q_mat_32;
            select_dot1_ac[6] = Q_mat_31; select_dot1_ac[7] = Q_mat_32;
            select_dot1_ac[8] = Q_mat_31; select_dot1_ac[9] = Q_mat_32;
        end
        26: begin // head 2 row 3
            select_dot1_ac[0] = Q_mat_33; select_dot1_ac[1] = Q_mat_34;
            select_dot1_ac[2] = Q_mat_33; select_dot1_ac[3] = Q_mat_34;
            select_dot1_ac[4] = Q_mat_33; select_dot1_ac[5] = Q_mat_34;
            select_dot1_ac[6] = Q_mat_33; select_dot1_ac[7] = Q_mat_34;
            select_dot1_ac[8] = Q_mat_33; select_dot1_ac[9] = Q_mat_34;
        end
        27: begin // head 1 row 4
            select_dot1_ac[0] = Q_mat_41; select_dot1_ac[1] = Q_mat_42;
            select_dot1_ac[2] = Q_mat_41; select_dot1_ac[3] = Q_mat_42;
            select_dot1_ac[4] = Q_mat_41; select_dot1_ac[5] = Q_mat_42;
            select_dot1_ac[6] = Q_mat_41; select_dot1_ac[7] = Q_mat_42;
            select_dot1_ac[8] = Q_mat_41; select_dot1_ac[9] = Q_mat_42;
        end
        28: begin // head 2 row 4
            select_dot1_ac[0] = Q_mat_43; select_dot1_ac[1] = Q_mat_44;
            select_dot1_ac[2] = Q_mat_43; select_dot1_ac[3] = Q_mat_44;
            select_dot1_ac[4] = Q_mat_43; select_dot1_ac[5] = Q_mat_44;
            select_dot1_ac[6] = Q_mat_43; select_dot1_ac[7] = Q_mat_44;
            select_dot1_ac[8] = Q_mat_43; select_dot1_ac[9] = Q_mat_44;
            
            // calculate Final_res(out) head row 1
            select_dot1_ac[10] = q_mat_51; select_dot1_ac[11] = q_mat_52;
                select_dot1_ac[12] = q_mat_53; select_dot1_ac[13] = q_mat_54;
        end
        29: begin // head 1 row 5
            select_dot1_ac[0] = Q_mat_51; select_dot1_ac[1] = Q_mat_52;
            select_dot1_ac[2] = Q_mat_51; select_dot1_ac[3] = Q_mat_52;
            select_dot1_ac[4] = Q_mat_51; select_dot1_ac[5] = Q_mat_52;
            select_dot1_ac[6] = Q_mat_51; select_dot1_ac[7] = Q_mat_52;
            select_dot1_ac[8] = Q_mat_51; select_dot1_ac[9] = Q_mat_52;

            // calculate Final_res(out) head row 1
            select_dot1_ac[10] = q_mat_43; select_dot1_ac[11] = q_mat_44;
                select_dot1_ac[12] = q_mat_51; select_dot1_ac[13] = q_mat_52;
        end
        30: begin // head 2 row 5
            select_dot1_ac[0] = Q_mat_53; select_dot1_ac[1] = Q_mat_54;
            select_dot1_ac[2] = Q_mat_53; select_dot1_ac[3] = Q_mat_54;
            select_dot1_ac[4] = Q_mat_53; select_dot1_ac[5] = Q_mat_54;
            select_dot1_ac[6] = Q_mat_53; select_dot1_ac[7] = Q_mat_54;
            select_dot1_ac[8] = Q_mat_53; select_dot1_ac[9] = Q_mat_54;

            // calculate Final_res(out) head row 1
            select_dot1_ac[10] = q_mat_41; select_dot1_ac[11] = q_mat_42;
                select_dot1_ac[12] = q_mat_43; select_dot1_ac[13] = q_mat_44;
        end
        31: begin
            // calculate Final_res(out) head row 1
            select_dot1_ac[10] = q_mat_33; select_dot1_ac[11] = q_mat_34;
                select_dot1_ac[12] = q_mat_41; select_dot1_ac[13] = q_mat_42;
        end
        32: begin
            // calculate Final_res(out) head row 2
            select_dot1_ac[10] = q_mat_41; select_dot1_ac[11] = q_mat_42;
                select_dot1_ac[12] = q_mat_43; select_dot1_ac[13] = q_mat_44;
        end
        33: begin
            // calculate Final_res(out) head row 2
            select_dot1_ac[10] = q_mat_33; select_dot1_ac[11] = q_mat_34;
                select_dot1_ac[12] = q_mat_41; select_dot1_ac[13] = q_mat_42;
        end
        34: begin
            // calculate Final_res(out) head row 2
            select_dot1_ac[10] = q_mat_31; select_dot1_ac[11] = q_mat_32;
                select_dot1_ac[12] = q_mat_33; select_dot1_ac[13] = q_mat_34;
        end
        35: begin
            // calculate Final_res(out) head row 2
            select_dot1_ac[10] = q_mat_23; select_dot1_ac[11] = q_mat_24;
                select_dot1_ac[12] = q_mat_31; select_dot1_ac[13] = q_mat_32;
        end
        36,37,38,39: begin
            // calculate Final_res(out) head row 3
            select_dot1_ac[10] = q_mat_31; select_dot1_ac[11] = q_mat_32;
                select_dot1_ac[12] = q_mat_33; select_dot1_ac[13] = q_mat_34;
        end
        40,41,42,43: begin
            // calculate Final_res(out) head row 4
            select_dot1_ac[10] = q_mat_41; select_dot1_ac[11] = q_mat_42;
                select_dot1_ac[12] = q_mat_43; select_dot1_ac[13] = q_mat_44;
        end
        44,45,46,47: begin
            // calculate Final_res(out) head row 5
            select_dot1_ac[10] = q_mat_51; select_dot1_ac[11] = q_mat_52;
                select_dot1_ac[12] = q_mat_53; select_dot1_ac[13] = q_mat_54;
        end
    endcase
end

// dot2 AC selector
always @(*) begin
    for(i = 0;i < 16;i = i + 1) begin
        select_dot2_ac[i] = 32'd0;
    end

    case(counter)
        16: begin
            select_dot2_ac[0] = in_str_21;  select_dot2_ac[1] = in_str_22;  select_dot2_ac[2] = in_str_23;  select_dot2_ac[3] = in_str_24;
            select_dot2_ac[4] = in_str_21;  select_dot2_ac[5] = in_str_22;  select_dot2_ac[6] = in_str_23;  select_dot2_ac[7] = in_str_24;
            select_dot2_ac[8] = in_str_21;  select_dot2_ac[9] = in_str_22;  select_dot2_ac[10] = in_str_23; select_dot2_ac[11] = in_str_24;
            select_dot2_ac[12] = in_str_21; select_dot2_ac[13] = in_str_22; select_dot2_ac[14] = in_str_23; select_dot2_ac[15] = in_str_24;
        end
        17: begin
            select_dot2_ac[0] = in_str_24;  select_dot2_ac[1] = in_str_31;  select_dot2_ac[2] = in_str_32;  select_dot2_ac[3] = in_str_33;
            select_dot2_ac[4] = in_str_24;  select_dot2_ac[5] = in_str_31;  select_dot2_ac[6] = in_str_32;  select_dot2_ac[7] = in_str_33;
            select_dot2_ac[8] = in_str_24;  select_dot2_ac[9] = in_str_31;  select_dot2_ac[10] = in_str_32; select_dot2_ac[11] = in_str_33;
            select_dot2_ac[12] = in_str_24; select_dot2_ac[13] = in_str_31; select_dot2_ac[14] = in_str_32; select_dot2_ac[15] = in_str_33;
        end
        18: begin
            select_dot2_ac[0] = in_str_33;  select_dot2_ac[1] = in_str_34;  select_dot2_ac[2] = in_str_41;  select_dot2_ac[3] = in_str_42;
            select_dot2_ac[4] = in_str_33;  select_dot2_ac[5] = in_str_34;  select_dot2_ac[6] = in_str_41;  select_dot2_ac[7] = in_str_42;
            select_dot2_ac[8] = in_str_33;  select_dot2_ac[9] = in_str_34;  select_dot2_ac[10] = in_str_41; select_dot2_ac[11] = in_str_42;
            select_dot2_ac[12] = in_str_33; select_dot2_ac[13] = in_str_34; select_dot2_ac[14] = in_str_41; select_dot2_ac[15] = in_str_42;
        end
        19: begin
            select_dot2_ac[0] = in_str_42;  select_dot2_ac[1] = in_str_43;  select_dot2_ac[2] = in_str_44;  select_dot2_ac[3] = in_str_51;
            select_dot2_ac[4] = in_str_42;  select_dot2_ac[5] = in_str_43;  select_dot2_ac[6] = in_str_44;  select_dot2_ac[7] = in_str_51;
            select_dot2_ac[8] = in_str_42;  select_dot2_ac[9] = in_str_43;  select_dot2_ac[10] = in_str_44; select_dot2_ac[11] = in_str_51;
            select_dot2_ac[12] = in_str_42; select_dot2_ac[13] = in_str_43; select_dot2_ac[14] = in_str_44; select_dot2_ac[15] = in_str_51;
        end
        20: begin
            select_dot2_ac[0] = in_str_51;  select_dot2_ac[1] = in_str_52;  select_dot2_ac[2] = in_str_53;  select_dot2_ac[3] = in_str_54;
            select_dot2_ac[4] = in_str_51;  select_dot2_ac[5] = in_str_52;  select_dot2_ac[6] = in_str_53;  select_dot2_ac[7] = in_str_54;
            select_dot2_ac[8] = in_str_51;  select_dot2_ac[9] = in_str_52;  select_dot2_ac[10] = in_str_53; select_dot2_ac[11] = in_str_54;
            select_dot2_ac[12] = in_str_51; select_dot2_ac[13] = in_str_52; select_dot2_ac[14] = in_str_53; select_dot2_ac[15] = in_str_54;
        end
        21,22,23,24,25: begin // calulate big V
            select_dot2_ac[0] = in_str_11;  select_dot2_ac[1] = in_str_12;  select_dot2_ac[2] = in_str_13;  select_dot2_ac[3] = in_str_14;
            select_dot2_ac[4] = in_str_11;  select_dot2_ac[5] = in_str_12;  select_dot2_ac[6] = in_str_13;  select_dot2_ac[7] = in_str_14;
            select_dot2_ac[8] = in_str_11;  select_dot2_ac[9] = in_str_12;  select_dot2_ac[10] = in_str_13; select_dot2_ac[11] = in_str_14;
            select_dot2_ac[12] = in_str_11; select_dot2_ac[13] = in_str_12; select_dot2_ac[14] = in_str_13; select_dot2_ac[15] = in_str_14;
        end
        // 22: begin // calulate big V
        //     select_dot2_ac[0] = in_str_21;  select_dot2_ac[1] = in_str_22;  select_dot2_ac[2] = in_str_23;  select_dot2_ac[3] = in_str_24;
        //     select_dot2_ac[4] = in_str_21;  select_dot2_ac[5] = in_str_22;  select_dot2_ac[6] = in_str_23;  select_dot2_ac[7] = in_str_24;
        //     select_dot2_ac[8] = in_str_21;  select_dot2_ac[9] = in_str_22;  select_dot2_ac[10] = in_str_23; select_dot2_ac[11] = in_str_24;
        //     select_dot2_ac[12] = in_str_21; select_dot2_ac[13] = in_str_22; select_dot2_ac[14] = in_str_23; select_dot2_ac[15] = in_str_24;
        // end
        // 23: begin // calulate big V
        //     select_dot2_ac[0] = in_str_31;  select_dot2_ac[1] = in_str_32;  select_dot2_ac[2] = in_str_33;  select_dot2_ac[3] = in_str_34;
        //     select_dot2_ac[4] = in_str_31;  select_dot2_ac[5] = in_str_32;  select_dot2_ac[6] = in_str_33;  select_dot2_ac[7] = in_str_34;
        //     select_dot2_ac[8] = in_str_31;  select_dot2_ac[9] = in_str_32;  select_dot2_ac[10] = in_str_33; select_dot2_ac[11] = in_str_34;
        //     select_dot2_ac[12] = in_str_31; select_dot2_ac[13] = in_str_32; select_dot2_ac[14] = in_str_33; select_dot2_ac[15] = in_str_34;
        // end
        // 24: begin // calulate big V
        //     select_dot2_ac[0] = in_str_41;  select_dot2_ac[1] = in_str_42;  select_dot2_ac[2] = in_str_43;  select_dot2_ac[3] = in_str_44;
        //     select_dot2_ac[4] = in_str_41;  select_dot2_ac[5] = in_str_42;  select_dot2_ac[6] = in_str_43;  select_dot2_ac[7] = in_str_44;
        //     select_dot2_ac[8] = in_str_41;  select_dot2_ac[9] = in_str_42;  select_dot2_ac[10] = in_str_43; select_dot2_ac[11] = in_str_44;
        //     select_dot2_ac[12] = in_str_41; select_dot2_ac[13] = in_str_42; select_dot2_ac[14] = in_str_43; select_dot2_ac[15] = in_str_44;
        // end
        // 25: begin // calulate big V
        //     select_dot2_ac[0] = in_str_51;  select_dot2_ac[1] = in_str_52;  select_dot2_ac[2] = in_str_53;  select_dot2_ac[3] = in_str_54;
        //     select_dot2_ac[4] = in_str_51;  select_dot2_ac[5] = in_str_52;  select_dot2_ac[6] = in_str_53;  select_dot2_ac[7] = in_str_54;
        //     select_dot2_ac[8] = in_str_51;  select_dot2_ac[9] = in_str_52;  select_dot2_ac[10] = in_str_53; select_dot2_ac[11] = in_str_54;
        //     select_dot2_ac[12] = in_str_51; select_dot2_ac[13] = in_str_52; select_dot2_ac[14] = in_str_53; select_dot2_ac[15] = in_str_54;
        // end
        26,27,28,29,30,31,32,33,34,35: begin // head 1 row 1 * V
            select_dot2_ac[0] = k_mat_11;  select_dot2_ac[1] = k_mat_12;  select_dot2_ac[2] = k_mat_13;
                select_dot2_ac[3] = k_mat_14;  select_dot2_ac[4] = k_mat_15;  select_dot2_ac[5] = 32'h00000000;
            select_dot2_ac[6] = k_mat_11;  select_dot2_ac[7] = k_mat_12;  select_dot2_ac[8] = k_mat_13;
                select_dot2_ac[9] = k_mat_14; select_dot2_ac[10] = k_mat_15; select_dot2_ac[11] = 32'h00000000;
        end
    endcase
end

// dot1 BD selector
always @(*) begin
    for(i = 0;i < 16;i = i + 1) begin
        select_dot1_bd[i] = 32'd0;
    end

    case(counter)
        16,17,18,19,20: begin
            select_dot1_bd[0] = q_mat_11; select_dot1_bd[4] = q_mat_21;  select_dot1_bd[8] = q_mat_31; select_dot1_bd[12] = q_mat_41;
            select_dot1_bd[1] = q_mat_12; select_dot1_bd[5] = q_mat_22;  select_dot1_bd[9] = q_mat_32; select_dot1_bd[13] = q_mat_42;
            select_dot1_bd[2] = q_mat_13; select_dot1_bd[6] = q_mat_23; select_dot1_bd[10] = q_mat_33; select_dot1_bd[14] = q_mat_43;
            select_dot1_bd[3] = q_mat_14; select_dot1_bd[7] = q_mat_24; select_dot1_bd[11] = q_mat_34; select_dot1_bd[15] = q_mat_44;
        end
        21,23,25,27: begin
            select_dot1_bd[0] = K_mat_11; select_dot1_bd[1] = K_mat_12;
            select_dot1_bd[2] = K_mat_21; select_dot1_bd[3] = K_mat_22;
            select_dot1_bd[4] = K_mat_31; select_dot1_bd[5] = K_mat_32;
            select_dot1_bd[6] = K_mat_41; select_dot1_bd[7] = K_mat_42;
            select_dot1_bd[8] = K_mat_51; select_dot1_bd[9] = K_mat_52;
        end
        22,24,26: begin
            select_dot1_bd[0] = K_mat_13; select_dot1_bd[1] = K_mat_14;
            select_dot1_bd[2] = K_mat_23; select_dot1_bd[3] = K_mat_24;
            select_dot1_bd[4] = K_mat_33; select_dot1_bd[5] = K_mat_34;
            select_dot1_bd[6] = K_mat_43; select_dot1_bd[7] = K_mat_44;
            select_dot1_bd[8] = K_mat_53; select_dot1_bd[9] = K_mat_54;
        end
        28: begin
            select_dot1_bd[0] = K_mat_13; select_dot1_bd[1] = K_mat_14;
            select_dot1_bd[2] = K_mat_23; select_dot1_bd[3] = K_mat_24;
            select_dot1_bd[4] = K_mat_33; select_dot1_bd[5] = K_mat_34;
            select_dot1_bd[6] = K_mat_43; select_dot1_bd[7] = K_mat_44;
            select_dot1_bd[8] = K_mat_53; select_dot1_bd[9] = K_mat_54;

            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_11; select_dot1_bd[11] = out_weight_mat_12;
                select_dot1_bd[12] = out_weight_mat_13; select_dot1_bd[13] = out_weight_mat_14;
        end
        29: begin
            select_dot1_bd[0] = K_mat_11; select_dot1_bd[1] = K_mat_12;
            select_dot1_bd[2] = K_mat_21; select_dot1_bd[3] = K_mat_22;
            select_dot1_bd[4] = K_mat_31; select_dot1_bd[5] = K_mat_32;
            select_dot1_bd[6] = K_mat_41; select_dot1_bd[7] = K_mat_42;
            select_dot1_bd[8] = K_mat_51; select_dot1_bd[9] = K_mat_52;

            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_21; select_dot1_bd[11] = out_weight_mat_22;
                select_dot1_bd[12] = out_weight_mat_23; select_dot1_bd[13] = out_weight_mat_24;
        end
        30: begin
            select_dot1_bd[0] = K_mat_13; select_dot1_bd[1] = K_mat_14;
            select_dot1_bd[2] = K_mat_23; select_dot1_bd[3] = K_mat_24;
            select_dot1_bd[4] = K_mat_33; select_dot1_bd[5] = K_mat_34;
            select_dot1_bd[6] = K_mat_43; select_dot1_bd[7] = K_mat_44;
            select_dot1_bd[8] = K_mat_53; select_dot1_bd[9] = K_mat_54;

            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_31; select_dot1_bd[11] = out_weight_mat_32;
                select_dot1_bd[12] = out_weight_mat_33; select_dot1_bd[13] = out_weight_mat_34;
        end
        31: begin
            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_41; select_dot1_bd[11] = out_weight_mat_42;
                select_dot1_bd[12] = out_weight_mat_43; select_dot1_bd[13] = out_weight_mat_44;
        end
        32,36,40,44:begin
            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_11; select_dot1_bd[11] = out_weight_mat_12;
                select_dot1_bd[12] = out_weight_mat_13; select_dot1_bd[13] = out_weight_mat_14;
        end
        33,37,41,45:begin
            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_21; select_dot1_bd[11] = out_weight_mat_22;
                select_dot1_bd[12] = out_weight_mat_23; select_dot1_bd[13] = out_weight_mat_24;
        end
        34,38,42,46:begin
            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_31; select_dot1_bd[11] = out_weight_mat_32;
                select_dot1_bd[12] = out_weight_mat_33; select_dot1_bd[13] = out_weight_mat_34;
        end
        35,39,43,47:begin
            // calculate Final_res(out)
            select_dot1_bd[10] = out_weight_mat_41; select_dot1_bd[11] = out_weight_mat_42;
                select_dot1_bd[12] = out_weight_mat_43; select_dot1_bd[13] = out_weight_mat_44;
        end
    endcase
end

// dot2 BD selector
always @(*) begin
    for(i = 0;i < 16;i = i + 1) begin
        select_dot2_bd[i] = 32'd0;
    end

    case(counter)
        16,17,18,19,20: begin
            select_dot2_bd[0] = k_mat_11; select_dot2_bd[4] = k_mat_21;  select_dot2_bd[8] = k_mat_31; select_dot2_bd[12] = k_mat_41;
            select_dot2_bd[1] = k_mat_12; select_dot2_bd[5] = k_mat_22;  select_dot2_bd[9] = k_mat_32; select_dot2_bd[13] = k_mat_42;
            select_dot2_bd[2] = k_mat_13; select_dot2_bd[6] = k_mat_23; select_dot2_bd[10] = k_mat_33; select_dot2_bd[14] = k_mat_43;
            select_dot2_bd[3] = k_mat_14; select_dot2_bd[7] = k_mat_24; select_dot2_bd[11] = k_mat_34; select_dot2_bd[15] = k_mat_44;
        end
        21,22,23,24,25: begin
            // calculate big V
            select_dot2_bd[0] = v_mat_11; select_dot2_bd[4] = v_mat_21;  select_dot2_bd[8] = v_mat_31; select_dot2_bd[12] = v_mat_41;
            select_dot2_bd[1] = v_mat_12; select_dot2_bd[5] = v_mat_22;  select_dot2_bd[9] = v_mat_32; select_dot2_bd[13] = v_mat_42;
            select_dot2_bd[2] = v_mat_13; select_dot2_bd[6] = v_mat_23; select_dot2_bd[10] = v_mat_33; select_dot2_bd[14] = v_mat_43;
            select_dot2_bd[3] = v_mat_14; select_dot2_bd[7] = v_mat_24; select_dot2_bd[11] = v_mat_34; select_dot2_bd[15] = v_mat_44;
        end
        26,28,30,32,34: begin // marker V_mat -> in_str
            // head 1 row 1 * V
            select_dot2_bd[0] = in_str_11; select_dot2_bd[6] = in_str_12;
            select_dot2_bd[1] = in_str_21; select_dot2_bd[7] = in_str_22;
            select_dot2_bd[2] = in_str_31; select_dot2_bd[8] = in_str_32;
            select_dot2_bd[3] = in_str_41; select_dot2_bd[9] = in_str_42;
            select_dot2_bd[4] = in_str_51; select_dot2_bd[10] = in_str_52;
            select_dot2_bd[5] = 32'h00000000; select_dot2_bd[11] = 32'h00000000;
            // select_dot2_bd[0] = V_mat_11; select_dot2_bd[6] = V_mat_12;
            // select_dot2_bd[1] = V_mat_21; select_dot2_bd[7] = V_mat_22;
            // select_dot2_bd[2] = V_mat_31; select_dot2_bd[8] = V_mat_32;
            // select_dot2_bd[3] = V_mat_41; select_dot2_bd[9] = V_mat_42;
            // select_dot2_bd[4] = V_mat_51; select_dot2_bd[10] = V_mat_52;
            // select_dot2_bd[5] = 32'h00000000; select_dot2_bd[11] = 32'h00000000;
        end
        27,29,31,33,35: begin
            // head 2 row 1 * V
            select_dot2_bd[0] = in_str_13; select_dot2_bd[6] = in_str_14;
            select_dot2_bd[1] = in_str_23; select_dot2_bd[7] = in_str_24;
            select_dot2_bd[2] = in_str_33; select_dot2_bd[8] = in_str_34;
            select_dot2_bd[3] = in_str_43; select_dot2_bd[9] = in_str_44;
            select_dot2_bd[4] = in_str_53; select_dot2_bd[10] = in_str_54;
            select_dot2_bd[5] = 32'h00000000; select_dot2_bd[11] = 32'h00000000;
            // select_dot2_bd[0] = V_mat_13; select_dot2_bd[6] = V_mat_14;
            // select_dot2_bd[1] = V_mat_23; select_dot2_bd[7] = V_mat_24;
            // select_dot2_bd[2] = V_mat_33; select_dot2_bd[8] = V_mat_34;
            // select_dot2_bd[3] = V_mat_43; select_dot2_bd[9] = V_mat_44;
            // select_dot2_bd[4] = V_mat_53; select_dot2_bd[10] = V_mat_54;
            // select_dot2_bd[5] = 32'h00000000; select_dot2_bd[11] = 32'h00000000;
        end
    endcase
end

// ADD selector
always @(*) begin
    for(i = 0;i < 4;i = i + 1) begin
        select_add1_a[i] = 32'd0;
        select_add1_b[i] = 32'd0;
    end
    for(i = 0;i < 4;i = i + 1) begin
        select_add2_a[i] = 32'd0;
        select_add2_b[i] = 32'd0;
    end

    case(counter)
        16,17,18,19,20: begin
            select_add1_a[0] = result_dot1[0]; select_add1_a[1] = result_dot1[2]; select_add1_a[2] = result_dot1[4]; select_add1_a[3] = result_dot1[6];
            select_add1_b[0] = result_dot1[1]; select_add1_b[1] = result_dot1[3]; select_add1_b[2] = result_dot1[5]; select_add1_b[3] = result_dot1[7];

            select_add2_a[0] = result_dot2[0]; select_add2_a[1] = result_dot2[2]; select_add2_a[2] = result_dot2[4]; select_add2_a[3] = result_dot2[6];
            select_add2_b[0] = result_dot2[1]; select_add2_b[1] = result_dot2[3]; select_add2_b[2] = result_dot2[5]; select_add2_b[3] = result_dot2[7];
        end
        21,22,23: begin
            // calculate big V
            select_add2_a[0] = result_dot2[0]; select_add2_a[1] = result_dot2[2]; select_add2_a[2] = result_dot2[4]; select_add2_a[3] = result_dot2[6];
            select_add2_b[0] = result_dot2[1]; select_add2_b[1] = result_dot2[3]; select_add2_b[2] = result_dot2[5]; select_add2_b[3] = result_dot2[7];
        end
        24,25: begin
            // calculate sum of exp_score
            select_add1_a[0] = k_mat_31; select_add1_a[1] = k_mat_33; select_add1_a[2] = k_mat_35; select_add1_a[3] = result_add1[1];
            select_add1_b[0] = k_mat_32; select_add1_b[1] = k_mat_34; select_add1_b[2] = result_add1[0]; select_add1_b[3] = result_add1[2];

            // calculate big V
            select_add2_a[0] = result_dot2[0]; select_add2_a[1] = result_dot2[2]; select_add2_a[2] = result_dot2[4]; select_add2_a[3] = result_dot2[6];
            select_add2_b[0] = result_dot2[1]; select_add2_b[1] = result_dot2[3]; select_add2_b[2] = result_dot2[5]; select_add2_b[3] = result_dot2[7];
        end
        26,27,28,29,30,31,32,33,34: begin
            // calculate sum of exp_score
            select_add1_a[0] = k_mat_31; select_add1_a[1] = k_mat_33; select_add1_a[2] = k_mat_35; select_add1_a[3] = result_add1[1];
            select_add1_b[0] = k_mat_32; select_add1_b[1] = k_mat_34; select_add1_b[2] = result_add1[0]; select_add1_b[3] = result_add1[2];
            // head 1 row 1 * V // head 2 row 1 * V // head 1 row 2 * V // head 2 row 2 * V // head 1 row 3 * V // head 2 row 3 * V // head 1 row 4 * V // head 2 row 4 * V // head 1 row 5 * V
            select_add2_a[0] = result_dot2[0]; select_add2_a[1] = result_dot2[1]; select_add2_a[2] = result_dot2[3]; select_add2_a[3] = result_dot2[4];
            select_add2_b[0] = result_dot2[2]; select_add2_b[1] = result_add2[0]; select_add2_b[2] = result_dot2[5]; select_add2_b[3] = result_add2[2];
        end
        35: begin
            // head 2 row 5 * V
            select_add2_a[0] = result_dot2[0]; select_add2_a[1] = result_dot2[1]; select_add2_a[2] = result_dot2[3]; select_add2_a[3] = result_dot2[4];
            select_add2_b[0] = result_dot2[2]; select_add2_b[1] = result_add2[0]; select_add2_b[2] = result_dot2[5]; select_add2_b[3] = result_add2[2];
        end
    endcase
end

always @(*) begin    
    calculate_answer_add[0] = 32'd0;
    calculate_answer_add[1] = 32'd0;

    case(counter)
        28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47: begin
            calculate_answer_add[0] = result_dot1[5];
            calculate_answer_add[1] = result_dot1[6];
        end
    endcase
end
  
// ===============================================
// output part
// ===============================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 32'b0;
    end
    else if(counter >= 28 && counter <= 47) begin
        out_valid <= 1;
        out <= calculate_answer;
    end
    else begin
        out_valid <= 0;
        out <= 32'b0;
    end
end


endmodule
