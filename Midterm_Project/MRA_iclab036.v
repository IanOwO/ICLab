//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32 ;

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output reg                   arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                   awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                    wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------
// memory register
reg [6:0] addr_map, addr_weight;
reg we_frame_map, we_weight_map;
reg [3:0] frame_out[0:31]; 
reg [3:0] weight_out[0:31]; 
reg [3:0] cur_input[0:31];
reg rvalid_m_inf_reg,rlast_m_inf_reg;

// input and sram variable
reg in_valid_flag;
reg [4:0] cur_frame;
reg [3:0] net_list[0:14];
reg [5:0] source_x[0:14];
reg [5:0] source_y[0:14];
reg [5:0] dest_x[0:14];
reg [5:0] dest_y[0:14];
reg [6:0] counter_sram;
reg [127:0] frame_temp;

// FSM
reg [2:0] P_cur;
reg [2:0] P_next;
parameter [2:0] S_IDLE = 3'd0, S_DRAM_FRAME = 3'd1, S_DRAM_WEIGHT = 3'd2, S_START_FILL = 3'd3, S_FILL = 3'd4, S_BACKTRACE = 3'd6, S_WRITE_DRAM = 3'd7;

// Calculation Variable definition
reg [4:0] counter_input;
reg [1:0] fill_map[0:63][0:63]; 
reg [1:0] fill_map_old[0:63][0:63]; 
reg [1:0] fill_sequence;
wire fill_done;
reg  fill_done_delay1;
wire backtrace_done;
reg  backtrace_done_delay1;
wire backtrace_direction;
reg [5:0] backtrace_x, backtrace_y;
reg [5:0] backtrace_x_old, backtrace_y_old;
reg backtrace_counter;

integer i,j;

// SRAM
SinglePort_128X128 frame_map   (.A0(addr_map[0]), .A1(addr_map[1]), .A2(addr_map[2]), .A3(addr_map[3]), .A4(addr_map[4]), .A5(addr_map[5]), .A6(addr_map[6]),
								.DO0(frame_out[0][0]),  .DO1(frame_out[0][1]),  .DO2(frame_out[0][2]),  .DO3(frame_out[0][3]),
								.DO4(frame_out[1][0]),  .DO5(frame_out[1][1]),  .DO6(frame_out[1][2]),  .DO7(frame_out[1][3]),
								.DO8(frame_out[2][0]),  .DO9(frame_out[2][1]),  .DO10(frame_out[2][2]), .DO11(frame_out[2][3]),
								.DO12(frame_out[3][0]), .DO13(frame_out[3][1]), .DO14(frame_out[3][2]), .DO15(frame_out[3][3]),
								.DO16(frame_out[4][0]), .DO17(frame_out[4][1]), .DO18(frame_out[4][2]), .DO19(frame_out[4][3]),
								.DO20(frame_out[5][0]), .DO21(frame_out[5][1]), .DO22(frame_out[5][2]), .DO23(frame_out[5][3]),
								.DO24(frame_out[6][0]), .DO25(frame_out[6][1]), .DO26(frame_out[6][2]), .DO27(frame_out[6][3]),
								.DO28(frame_out[7][0]), .DO29(frame_out[7][1]), .DO30(frame_out[7][2]), .DO31(frame_out[7][3]),
								.DO32(frame_out[8][0]), .DO33(frame_out[8][1]), .DO34(frame_out[8][2]), .DO35(frame_out[8][3]),
								.DO36(frame_out[9][0]), .DO37(frame_out[9][1]), .DO38(frame_out[9][2]), .DO39(frame_out[9][3]),
								.DO40(frame_out[10][0]),.DO41(frame_out[10][1]),.DO42(frame_out[10][2]),.DO43(frame_out[10][3]),
								.DO44(frame_out[11][0]),.DO45(frame_out[11][1]),.DO46(frame_out[11][2]),.DO47(frame_out[11][3]),
								.DO48(frame_out[12][0]),.DO49(frame_out[12][1]),.DO50(frame_out[12][2]),.DO51(frame_out[12][3]),
								.DO52(frame_out[13][0]),.DO53(frame_out[13][1]),.DO54(frame_out[13][2]),.DO55(frame_out[13][3]),
								.DO56(frame_out[14][0]),.DO57(frame_out[14][1]),.DO58(frame_out[14][2]),.DO59(frame_out[14][3]),
								.DO60(frame_out[15][0]),.DO61(frame_out[15][1]),.DO62(frame_out[15][2]),.DO63(frame_out[15][3]),
								.DO64(frame_out[16][0]), .DO65(frame_out[16][1]), .DO66(frame_out[16][2]), .DO67(frame_out[16][3]),
								.DO68(frame_out[17][0]), .DO69(frame_out[17][1]), .DO70(frame_out[17][2]), .DO71(frame_out[17][3]),
								.DO72(frame_out[18][0]), .DO73(frame_out[18][1]), .DO74(frame_out[18][2]), .DO75(frame_out[18][3]),
								.DO76(frame_out[19][0]), .DO77(frame_out[19][1]), .DO78(frame_out[19][2]), .DO79(frame_out[19][3]),
								.DO80(frame_out[20][0]), .DO81(frame_out[20][1]), .DO82(frame_out[20][2]), .DO83(frame_out[20][3]),
								.DO84(frame_out[21][0]), .DO85(frame_out[21][1]), .DO86(frame_out[21][2]), .DO87(frame_out[21][3]),
								.DO88(frame_out[22][0]), .DO89(frame_out[22][1]), .DO90(frame_out[22][2]), .DO91(frame_out[22][3]),
								.DO92(frame_out[23][0]), .DO93(frame_out[23][1]), .DO94(frame_out[23][2]), .DO95(frame_out[23][3]),
								.DO96(frame_out[24][0]), .DO97(frame_out[24][1]), .DO98(frame_out[24][2]), .DO99(frame_out[24][3]),
								.DO100(frame_out[25][0]),.DO101(frame_out[25][1]),.DO102(frame_out[25][2]),.DO103(frame_out[25][3]),
								.DO104(frame_out[26][0]),.DO105(frame_out[26][1]),.DO106(frame_out[26][2]),.DO107(frame_out[26][3]),
								.DO108(frame_out[27][0]),.DO109(frame_out[27][1]),.DO110(frame_out[27][2]),.DO111(frame_out[27][3]),
								.DO112(frame_out[28][0]),.DO113(frame_out[28][1]),.DO114(frame_out[28][2]),.DO115(frame_out[28][3]),
								.DO116(frame_out[29][0]),.DO117(frame_out[29][1]),.DO118(frame_out[29][2]),.DO119(frame_out[29][3]),
								.DO120(frame_out[30][0]),.DO121(frame_out[30][1]),.DO122(frame_out[30][2]),.DO123(frame_out[30][3]),
								.DO124(frame_out[31][0]),.DO125(frame_out[31][1]),.DO126(frame_out[31][2]),.DO127(frame_out[31][3]),
								.DI0(cur_input[0][0]),   .DI1(cur_input[0][1]),   .DI2(cur_input[0][2]),   .DI3(cur_input[0][3]),
								.DI4(cur_input[1][0]),   .DI5(cur_input[1][1]),   .DI6(cur_input[1][2]),   .DI7(cur_input[1][3]),
								.DI8(cur_input[2][0]),   .DI9(cur_input[2][1]),   .DI10(cur_input[2][2]),  .DI11(cur_input[2][3]),
								.DI12(cur_input[3][0]),  .DI13(cur_input[3][1]),  .DI14(cur_input[3][2]),  .DI15(cur_input[3][3]),
								.DI16(cur_input[4][0]),  .DI17(cur_input[4][1]),  .DI18(cur_input[4][2]),  .DI19(cur_input[4][3]),
								.DI20(cur_input[5][0]),  .DI21(cur_input[5][1]),  .DI22(cur_input[5][2]),  .DI23(cur_input[5][3]),
								.DI24(cur_input[6][0]),  .DI25(cur_input[6][1]),  .DI26(cur_input[6][2]),  .DI27(cur_input[6][3]),
								.DI28(cur_input[7][0]),  .DI29(cur_input[7][1]),  .DI30(cur_input[7][2]),  .DI31(cur_input[7][3]),
								.DI32(cur_input[8][0]),  .DI33(cur_input[8][1]),  .DI34(cur_input[8][2]),  .DI35(cur_input[8][3]),
								.DI36(cur_input[9][0]),  .DI37(cur_input[9][1]),  .DI38(cur_input[9][2]),  .DI39(cur_input[9][3]),
								.DI40(cur_input[10][0]), .DI41(cur_input[10][1]), .DI42(cur_input[10][2]), .DI43(cur_input[10][3]),
								.DI44(cur_input[11][0]), .DI45(cur_input[11][1]), .DI46(cur_input[11][2]), .DI47(cur_input[11][3]),
								.DI48(cur_input[12][0]), .DI49(cur_input[12][1]), .DI50(cur_input[12][2]), .DI51(cur_input[12][3]),
								.DI52(cur_input[13][0]), .DI53(cur_input[13][1]), .DI54(cur_input[13][2]), .DI55(cur_input[13][3]),
								.DI56(cur_input[14][0]), .DI57(cur_input[14][1]), .DI58(cur_input[14][2]), .DI59(cur_input[14][3]),
								.DI60(cur_input[15][0]), .DI61(cur_input[15][1]), .DI62(cur_input[15][2]), .DI63(cur_input[15][3]),
								.DI64(cur_input[16][0]), .DI65(cur_input[16][1]), .DI66(cur_input[16][2]), .DI67(cur_input[16][3]),
								.DI68(cur_input[17][0]), .DI69(cur_input[17][1]), .DI70(cur_input[17][2]), .DI71(cur_input[17][3]),
								.DI72(cur_input[18][0]), .DI73(cur_input[18][1]), .DI74(cur_input[18][2]), .DI75(cur_input[18][3]),
								.DI76(cur_input[19][0]), .DI77(cur_input[19][1]), .DI78(cur_input[19][2]), .DI79(cur_input[19][3]),
								.DI80(cur_input[20][0]), .DI81(cur_input[20][1]), .DI82(cur_input[20][2]), .DI83(cur_input[20][3]),
								.DI84(cur_input[21][0]), .DI85(cur_input[21][1]), .DI86(cur_input[21][2]), .DI87(cur_input[21][3]),
								.DI88(cur_input[22][0]), .DI89(cur_input[22][1]), .DI90(cur_input[22][2]), .DI91(cur_input[22][3]),
								.DI92(cur_input[23][0]), .DI93(cur_input[23][1]), .DI94(cur_input[23][2]), .DI95(cur_input[23][3]),
								.DI96(cur_input[24][0]), .DI97(cur_input[24][1]), .DI98(cur_input[24][2]), .DI99(cur_input[24][3]),
								.DI100(cur_input[25][0]), .DI101(cur_input[25][1]), .DI102(cur_input[25][2]), .DI103(cur_input[25][3]),
								.DI104(cur_input[26][0]), .DI105(cur_input[26][1]), .DI106(cur_input[26][2]), .DI107(cur_input[26][3]),
								.DI108(cur_input[27][0]), .DI109(cur_input[27][1]), .DI110(cur_input[27][2]), .DI111(cur_input[27][3]),
								.DI112(cur_input[28][0]), .DI113(cur_input[28][1]), .DI114(cur_input[28][2]), .DI115(cur_input[28][3]),
								.DI116(cur_input[29][0]), .DI117(cur_input[29][1]), .DI118(cur_input[29][2]), .DI119(cur_input[29][3]),
								.DI120(cur_input[30][0]), .DI121(cur_input[30][1]), .DI122(cur_input[30][2]), .DI123(cur_input[30][3]),
								.DI124(cur_input[31][0]), .DI125(cur_input[31][1]), .DI126(cur_input[31][2]), .DI127(cur_input[31][3]),
								.CK(clk), .WEB(we_frame_map), .OE(1'b1), .CS(1'b1));

SinglePort_128X128 weight_map   (.A0(addr_weight[0]), .A1(addr_weight[1]), .A2(addr_weight[2]), .A3(addr_weight[3]), .A4(addr_weight[4]), .A5(addr_weight[5]), .A6(addr_weight[6]),
								.DO0(weight_out[0][0]),  .DO1(weight_out[0][1]),  .DO2(weight_out[0][2]),  .DO3(weight_out[0][3]),
								.DO4(weight_out[1][0]),  .DO5(weight_out[1][1]),  .DO6(weight_out[1][2]),  .DO7(weight_out[1][3]),
								.DO8(weight_out[2][0]),  .DO9(weight_out[2][1]),  .DO10(weight_out[2][2]), .DO11(weight_out[2][3]),
								.DO12(weight_out[3][0]), .DO13(weight_out[3][1]), .DO14(weight_out[3][2]), .DO15(weight_out[3][3]),
								.DO16(weight_out[4][0]), .DO17(weight_out[4][1]), .DO18(weight_out[4][2]), .DO19(weight_out[4][3]),
								.DO20(weight_out[5][0]), .DO21(weight_out[5][1]), .DO22(weight_out[5][2]), .DO23(weight_out[5][3]),
								.DO24(weight_out[6][0]), .DO25(weight_out[6][1]), .DO26(weight_out[6][2]), .DO27(weight_out[6][3]),
								.DO28(weight_out[7][0]), .DO29(weight_out[7][1]), .DO30(weight_out[7][2]), .DO31(weight_out[7][3]),
								.DO32(weight_out[8][0]), .DO33(weight_out[8][1]), .DO34(weight_out[8][2]), .DO35(weight_out[8][3]),
								.DO36(weight_out[9][0]), .DO37(weight_out[9][1]), .DO38(weight_out[9][2]), .DO39(weight_out[9][3]),
								.DO40(weight_out[10][0]),.DO41(weight_out[10][1]),.DO42(weight_out[10][2]),.DO43(weight_out[10][3]),
								.DO44(weight_out[11][0]),.DO45(weight_out[11][1]),.DO46(weight_out[11][2]),.DO47(weight_out[11][3]),
								.DO48(weight_out[12][0]),.DO49(weight_out[12][1]),.DO50(weight_out[12][2]),.DO51(weight_out[12][3]),
								.DO52(weight_out[13][0]),.DO53(weight_out[13][1]),.DO54(weight_out[13][2]),.DO55(weight_out[13][3]),
								.DO56(weight_out[14][0]),.DO57(weight_out[14][1]),.DO58(weight_out[14][2]),.DO59(weight_out[14][3]),
								.DO60(weight_out[15][0]),.DO61(weight_out[15][1]),.DO62(weight_out[15][2]),.DO63(weight_out[15][3]),
								.DO64(weight_out[16][0]), .DO65(weight_out[16][1]), .DO66(weight_out[16][2]), .DO67(weight_out[16][3]),
								.DO68(weight_out[17][0]), .DO69(weight_out[17][1]), .DO70(weight_out[17][2]), .DO71(weight_out[17][3]),
								.DO72(weight_out[18][0]), .DO73(weight_out[18][1]), .DO74(weight_out[18][2]), .DO75(weight_out[18][3]),
								.DO76(weight_out[19][0]), .DO77(weight_out[19][1]), .DO78(weight_out[19][2]), .DO79(weight_out[19][3]),
								.DO80(weight_out[20][0]), .DO81(weight_out[20][1]), .DO82(weight_out[20][2]), .DO83(weight_out[20][3]),
								.DO84(weight_out[21][0]), .DO85(weight_out[21][1]), .DO86(weight_out[21][2]), .DO87(weight_out[21][3]),
								.DO88(weight_out[22][0]), .DO89(weight_out[22][1]), .DO90(weight_out[22][2]), .DO91(weight_out[22][3]),
								.DO92(weight_out[23][0]), .DO93(weight_out[23][1]), .DO94(weight_out[23][2]), .DO95(weight_out[23][3]),
								.DO96(weight_out[24][0]), .DO97(weight_out[24][1]), .DO98(weight_out[24][2]), .DO99(weight_out[24][3]),
								.DO100(weight_out[25][0]),.DO101(weight_out[25][1]),.DO102(weight_out[25][2]),.DO103(weight_out[25][3]),
								.DO104(weight_out[26][0]),.DO105(weight_out[26][1]),.DO106(weight_out[26][2]),.DO107(weight_out[26][3]),
								.DO108(weight_out[27][0]),.DO109(weight_out[27][1]),.DO110(weight_out[27][2]),.DO111(weight_out[27][3]),
								.DO112(weight_out[28][0]),.DO113(weight_out[28][1]),.DO114(weight_out[28][2]),.DO115(weight_out[28][3]),
								.DO116(weight_out[29][0]),.DO117(weight_out[29][1]),.DO118(weight_out[29][2]),.DO119(weight_out[29][3]),
								.DO120(weight_out[30][0]),.DO121(weight_out[30][1]),.DO122(weight_out[30][2]),.DO123(weight_out[30][3]),
								.DO124(weight_out[31][0]),.DO125(weight_out[31][1]),.DO126(weight_out[31][2]),.DO127(weight_out[31][3]),
								.DI0(cur_input[0][0]),   .DI1(cur_input[0][1]),   .DI2(cur_input[0][2]),   .DI3(cur_input[0][3]),
								.DI4(cur_input[1][0]),   .DI5(cur_input[1][1]),   .DI6(cur_input[1][2]),   .DI7(cur_input[1][3]),
								.DI8(cur_input[2][0]),   .DI9(cur_input[2][1]),   .DI10(cur_input[2][2]),  .DI11(cur_input[2][3]),
								.DI12(cur_input[3][0]),  .DI13(cur_input[3][1]),  .DI14(cur_input[3][2]),  .DI15(cur_input[3][3]),
								.DI16(cur_input[4][0]),  .DI17(cur_input[4][1]),  .DI18(cur_input[4][2]),  .DI19(cur_input[4][3]),
								.DI20(cur_input[5][0]),  .DI21(cur_input[5][1]),  .DI22(cur_input[5][2]),  .DI23(cur_input[5][3]),
								.DI24(cur_input[6][0]),  .DI25(cur_input[6][1]),  .DI26(cur_input[6][2]),  .DI27(cur_input[6][3]),
								.DI28(cur_input[7][0]),  .DI29(cur_input[7][1]),  .DI30(cur_input[7][2]),  .DI31(cur_input[7][3]),
								.DI32(cur_input[8][0]),  .DI33(cur_input[8][1]),  .DI34(cur_input[8][2]),  .DI35(cur_input[8][3]),
								.DI36(cur_input[9][0]),  .DI37(cur_input[9][1]),  .DI38(cur_input[9][2]),  .DI39(cur_input[9][3]),
								.DI40(cur_input[10][0]), .DI41(cur_input[10][1]), .DI42(cur_input[10][2]), .DI43(cur_input[10][3]),
								.DI44(cur_input[11][0]), .DI45(cur_input[11][1]), .DI46(cur_input[11][2]), .DI47(cur_input[11][3]),
								.DI48(cur_input[12][0]), .DI49(cur_input[12][1]), .DI50(cur_input[12][2]), .DI51(cur_input[12][3]),
								.DI52(cur_input[13][0]), .DI53(cur_input[13][1]), .DI54(cur_input[13][2]), .DI55(cur_input[13][3]),
								.DI56(cur_input[14][0]), .DI57(cur_input[14][1]), .DI58(cur_input[14][2]), .DI59(cur_input[14][3]),
								.DI60(cur_input[15][0]), .DI61(cur_input[15][1]), .DI62(cur_input[15][2]), .DI63(cur_input[15][3]),
								.DI64(cur_input[16][0]), .DI65(cur_input[16][1]), .DI66(cur_input[16][2]), .DI67(cur_input[16][3]),
								.DI68(cur_input[17][0]), .DI69(cur_input[17][1]), .DI70(cur_input[17][2]), .DI71(cur_input[17][3]),
								.DI72(cur_input[18][0]), .DI73(cur_input[18][1]), .DI74(cur_input[18][2]), .DI75(cur_input[18][3]),
								.DI76(cur_input[19][0]), .DI77(cur_input[19][1]), .DI78(cur_input[19][2]), .DI79(cur_input[19][3]),
								.DI80(cur_input[20][0]), .DI81(cur_input[20][1]), .DI82(cur_input[20][2]), .DI83(cur_input[20][3]),
								.DI84(cur_input[21][0]), .DI85(cur_input[21][1]), .DI86(cur_input[21][2]), .DI87(cur_input[21][3]),
								.DI88(cur_input[22][0]), .DI89(cur_input[22][1]), .DI90(cur_input[22][2]), .DI91(cur_input[22][3]),
								.DI92(cur_input[23][0]), .DI93(cur_input[23][1]), .DI94(cur_input[23][2]), .DI95(cur_input[23][3]),
								.DI96(cur_input[24][0]), .DI97(cur_input[24][1]), .DI98(cur_input[24][2]), .DI99(cur_input[24][3]),
								.DI100(cur_input[25][0]), .DI101(cur_input[25][1]), .DI102(cur_input[25][2]), .DI103(cur_input[25][3]),
								.DI104(cur_input[26][0]), .DI105(cur_input[26][1]), .DI106(cur_input[26][2]), .DI107(cur_input[26][3]),
								.DI108(cur_input[27][0]), .DI109(cur_input[27][1]), .DI110(cur_input[27][2]), .DI111(cur_input[27][3]),
								.DI112(cur_input[28][0]), .DI113(cur_input[28][1]), .DI114(cur_input[28][2]), .DI115(cur_input[28][3]),
								.DI116(cur_input[29][0]), .DI117(cur_input[29][1]), .DI118(cur_input[29][2]), .DI119(cur_input[29][3]),
								.DI120(cur_input[30][0]), .DI121(cur_input[30][1]), .DI122(cur_input[30][2]), .DI123(cur_input[30][3]),
								.DI124(cur_input[31][0]), .DI125(cur_input[31][1]), .DI126(cur_input[31][2]), .DI127(cur_input[31][3]),
								.CK(clk), .WEB(we_weight_map), .OE(1'b1), .CS(1'b1));


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) P_cur <= S_IDLE;
    else P_cur <= P_next;
end

// FSM
always @(*) begin
	case (P_cur)
	S_IDLE:
		if(in_valid) P_next = S_DRAM_FRAME;
		else P_next = S_IDLE;
	S_DRAM_FRAME: 
		if(rlast_m_inf_reg) P_next = S_DRAM_WEIGHT;
		else P_next = S_DRAM_FRAME;
	S_DRAM_WEIGHT: 
		if(rlast_m_inf) P_next = S_START_FILL;
		else P_next = S_DRAM_WEIGHT;
	S_START_FILL:
		P_next = S_FILL;
	S_FILL:
		if(fill_done) P_next = S_BACKTRACE;
		else P_next = S_FILL;
	S_BACKTRACE:
		if(backtrace_done_delay1) P_next = (counter_input == 2)? S_WRITE_DRAM: S_START_FILL;
		else P_next = S_BACKTRACE;
	S_WRITE_DRAM:
		if((!(|bresp_m_inf)) & bvalid_m_inf) P_next = S_IDLE;
		else P_next = S_WRITE_DRAM;
	default: P_next = S_IDLE;
	endcase
end

// signal for states
reg is_idle,is_dram_frame,is_dram_weight,is_start_fill,is_fill,is_backtrace,is_write_dram;
always @(*) begin
	is_idle = (P_cur == S_IDLE)? 1'b1:1'b0;
	is_dram_frame = (P_cur == S_DRAM_FRAME)? 1'b1:1'b0;
	is_dram_weight = (P_cur == S_DRAM_WEIGHT)? 1'b1:1'b0;
	is_start_fill = (P_cur == S_START_FILL)? 1'b1:1'b0;
	is_fill = (P_cur == S_FILL)? 1'b1:1'b0;
	is_backtrace = (P_cur == S_BACKTRACE)? 1'b1:1'b0;
	is_write_dram = (P_cur == S_WRITE_DRAM)? 1'b1:1'b0;
end

// AXI4 control
// READ (1)	axi read address channel 
assign arid_m_inf = 0; 
assign arburst_m_inf = 2'b01;
assign arsize_m_inf = 3'b100;
assign arlen_m_inf = 7'd127;
assign araddr_m_inf = (is_dram_frame)? {16'h0001,cur_frame,11'h000}:{16'h0002,cur_frame,11'h000};
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		arvalid_m_inf <= 1'b0;
	end
	else if(in_valid & (!in_valid_flag)) begin
		arvalid_m_inf <= 1'b1;
	end
	else if((is_dram_frame) & rlast_m_inf_reg) begin
		arvalid_m_inf <= 1'b1;
	end
	else if(arready_m_inf) begin
		arvalid_m_inf <= 1'b0;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rvalid_m_inf_reg <= 1'b0;
	end
	else if(is_dram_frame)begin
		rvalid_m_inf_reg <= rvalid_m_inf;
	end
end

always @(posedge clk) begin
	rlast_m_inf_reg <= rlast_m_inf;
end

// READ (2)	axi read data channel 
assign rready_m_inf = (is_dram_frame) | (is_dram_weight);

// WRITE (1) axi write address channel 
assign awid_m_inf = 0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b100;
assign awlen_m_inf = 7'd127;
assign awaddr_m_inf = {16'h0001,cur_frame,11'h000};
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awvalid_m_inf <= 1'b0;
	end
	else if(backtrace_done_delay1 & (P_next == S_WRITE_DRAM)) begin
		awvalid_m_inf <= 1'b1;
	end
	else if((is_write_dram) & awready_m_inf) begin
		awvalid_m_inf <= 1'b0;
	end
end

// WRITE (2) axi write data channel 
assign wdata_m_inf = (|(counter_sram))? {frame_out[31],frame_out[30],frame_out[29],frame_out[28],frame_out[27],frame_out[26],frame_out[25],frame_out[24],frame_out[23],frame_out[22],frame_out[21],frame_out[20],frame_out[19],frame_out[18],frame_out[17],frame_out[16],frame_out[15],frame_out[14],frame_out[13],frame_out[12],frame_out[11],frame_out[10],frame_out[9],frame_out[8],frame_out[7],frame_out[6],frame_out[5],frame_out[4],frame_out[3],frame_out[2],frame_out[1],frame_out[0]}
									   :frame_temp;
assign wlast_m_inf = (is_write_dram) & (&counter_sram);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		wvalid_m_inf <= 1'b0;
	end
	else if((is_write_dram) & awready_m_inf) begin
		wvalid_m_inf <= 1'b1;
	end
	else if(wlast_m_inf) begin
		wvalid_m_inf <= 1'b0;
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		frame_temp <= 0;
	end
	else if((is_dram_frame) & rvalid_m_inf) begin
		frame_temp <= rdata_m_inf;
	end
	else if(wready_m_inf) begin
		frame_temp <= 0;
	end
	else if((!(|frame_temp)) & (wvalid_m_inf & (!awready_m_inf))) begin
		frame_temp <= {frame_out[31],frame_out[30],frame_out[29],frame_out[28],frame_out[27],frame_out[26],frame_out[25],frame_out[24],frame_out[23],frame_out[22],frame_out[21],frame_out[20],frame_out[19],frame_out[18],frame_out[17],frame_out[16],frame_out[15],frame_out[14],frame_out[13],frame_out[12],frame_out[11],frame_out[10],frame_out[9],frame_out[8],frame_out[7],frame_out[6],frame_out[5],frame_out[4],frame_out[3],frame_out[2],frame_out[1],frame_out[0]};
	end
end

// WRITE (3) axi write response channel 
assign bready_m_inf = (is_write_dram);

// =========================================
// count the number of the net_id 
// =========================================
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter_input <= 5'd0;
	end
	else if(in_valid) begin
		counter_input <= counter_input + 1;
	end
	else if(backtrace_done_delay1 & is_backtrace) begin
		counter_input <= counter_input - 2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_valid_flag <= 1'b0;
	end
	else if(in_valid) begin
		in_valid_flag <= 1'b1;
	end
	else if(P_next == S_IDLE) begin
		in_valid_flag <= 1'b0;
	end
end

always @(posedge clk) begin
	if(in_valid & counter_input[0]) begin
		dest_x[counter_input[4:1]] <= loc_x;
		dest_y[counter_input[4:1]] <= loc_y;
	end
	else if(in_valid) begin
		source_x[counter_input[4:1]] <= loc_x;
		source_y[counter_input[4:1]] <= loc_y;
		net_list[counter_input[4:1]] <= net_id;
		cur_frame <= frame_id;
	end
	else if(backtrace_done_delay1 & is_backtrace) begin
		for(i = 0;i < 14;i = i + 1) begin
			source_x[i] <= source_x[i+1];
			source_y[i] <= source_y[i+1];
			dest_x[i] <= dest_x[i+1];
			dest_y[i] <= dest_y[i+1];
			net_list[i] <= net_list[i+1];
		end
	end
end

// always @(posedge clk) begin
// 	if(in_valid & (!counter_input[0])) begin
// 		net_list[counter_input[4:1]] <= net_id;
// 		cur_frame <= frame_id;
// 	end
// 	else if(backtrace_done_delay1 & is_backtrace) begin
// 		for(i = 0;i < 14;i = i + 1) begin
// 			net_list[i] <= net_list[i+1];
// 		end
// 	end
// end
// =========================================
// store to sram, input map & store path back
// =========================================
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter_sram <= 7'd0;
	end
	else if(rvalid_m_inf_reg) begin
		counter_sram <= counter_sram + 1;
	end
	else if((is_dram_weight) & rvalid_m_inf) begin
		counter_sram <= counter_sram + 1;
	end
	else if(wready_m_inf) begin
		counter_sram <= counter_sram + 1;
	end
	else begin
		counter_sram <= 0;
	end
end

always @(*) begin
	case(1)
	rvalid_m_inf_reg: begin
		we_frame_map = 1'b0;
		we_weight_map = 1'b1;
		for(i = 0;i < 32;i = i + 1) begin
			cur_input[i] = frame_temp[i*4+:4];
		end
	end
	(is_dram_weight) & rvalid_m_inf: begin
		we_frame_map = 1'b1;
		we_weight_map = 1'b0;
		for(j = 0;j < 32;j = j + 1) begin
			cur_input[j] = rdata_m_inf[j*4+:4];
		end
	end
	backtrace_counter: begin
		we_frame_map = 1'b0;
		we_weight_map = 1'b1;
		for(i = 0;i < 32;i = i + 1) begin
			cur_input[i] = ((i) == backtrace_x[4:0])? net_list[0]:frame_out[i];
		end
	end
	default: begin
		we_frame_map = 1'b1;
		we_weight_map = 1'b1;
		for(i = 0;i < 32;i = i + 1) begin
			cur_input[i] = 0;
		end
	end
	endcase
end


reg [6:0] addr_backtrace, addr_DRAM_to_SRAM;

always @(*) begin
	addr_backtrace = (backtrace_y) * 2 + backtrace_x[5];
	addr_map = (is_backtrace)? addr_backtrace:addr_DRAM_to_SRAM;
	addr_weight = (is_backtrace)? addr_backtrace:addr_DRAM_to_SRAM;
end

always @(*) begin
	if((rvalid_m_inf_reg) | ((is_dram_weight) & rvalid_m_inf)) begin
		addr_DRAM_to_SRAM = counter_sram;
	end
	else if((is_write_dram) & (wready_m_inf)) begin
		addr_DRAM_to_SRAM = counter_sram + 1;
	end
	else begin
		addr_DRAM_to_SRAM = 7'd0;
	end
end

// =======================================
// fill map
// =======================================
always @(posedge clk) begin
	for(i = 0;i < 64;i = i + 1) begin
		for(j = 0;j < 64;j = j + 1) begin
			fill_map_old[i][j] <= fill_map[i][j];
		end	
	end
end

assign fill_done = (is_fill) & (fill_map[dest_y[0]][dest_x[0]][1]);
// try to use backtrace_x_old to control
assign backtrace_done = (is_backtrace) & (source_x[0] == (backtrace_x)) & (source_y[0] == (backtrace_y));
assign backtrace_direction = (is_backtrace) & (!(backtrace_counter)); // backtrace_counter == 0

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		backtrace_done_delay1 <= 0;
		fill_done_delay1 <= 0;
	end
	else begin
		backtrace_done_delay1 <= backtrace_done;
		fill_done_delay1 <= fill_done;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fill_sequence <= 2'b00;
	end
	else if(is_start_fill) begin
		fill_sequence <= 2'b00;
	end
	else if((is_fill) & (!fill_done)) begin
		fill_sequence <= fill_sequence + 1;
	end
	else if(fill_done | (backtrace_direction)) begin //marker, remove !backtrace_done
		fill_sequence <= fill_sequence - 1;
	end
end

// =======================================
// backtrace path, fill_map_old
// =======================================
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		backtrace_x_old <= 6'd0;
		backtrace_y_old <= 6'd0;
	end
	else if(is_start_fill) begin
		backtrace_x_old <= 6'd0;
		backtrace_y_old <= 6'd0;
	end
	else begin
		backtrace_x_old <= backtrace_x;
		backtrace_y_old <= backtrace_y;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		backtrace_counter <= 1'b0;
	end
	else if((is_backtrace) & (!backtrace_done)) begin
		backtrace_counter <= !backtrace_counter;
	end
end

wire x_0,y_0,x_63,y_63;

assign x_0  = (backtrace_x_old == 6'd0)? 0:1;
assign y_0  = (backtrace_y_old == 6'd0)? 0:1;
assign x_63 = (backtrace_x_old == 6'd63)? 0:1;
assign y_63 = (backtrace_y_old == 6'd63)? 0:1;


always @(*) begin
	backtrace_x = backtrace_x_old;
	backtrace_y = backtrace_y_old;
	case(1)
	is_fill: begin
		backtrace_x = dest_x[0];
		backtrace_y = dest_y[0];
	end
	backtrace_direction: begin
		if(y_63 & (fill_map_old[(backtrace_y_old)+1][(backtrace_x_old)] == {1'b1,fill_sequence[1]})) begin // down
			backtrace_x = backtrace_x_old;
			backtrace_y = backtrace_y_old + 1;
		end
		else if(y_0 & (fill_map_old[(backtrace_y_old)-1][(backtrace_x_old)] == {1'b1,fill_sequence[1]})) begin // up
			backtrace_x = backtrace_x_old;
			backtrace_y = backtrace_y_old - 1;
		end
		else if(x_63 & (fill_map_old[(backtrace_y_old)][(backtrace_x_old)+1] == {1'b1,fill_sequence[1]})) begin // right
			backtrace_x = backtrace_x_old + 1;
			backtrace_y = backtrace_y_old;
		end
		else if(x_0 & (fill_map_old[(backtrace_y_old)][(backtrace_x_old)-1] == {1'b1,fill_sequence[1]})) begin // left
			backtrace_x = backtrace_x_old - 1;
			backtrace_y = backtrace_y_old;
		end
	end
	endcase
end

always @(*) begin
	for(i = 0;i < 64;i = i + 1) begin
		for(j = 0;j < 64;j = j + 1) begin
			fill_map[i][j] = fill_map_old[i][j];
		end
	end

	case(1)
	is_idle: begin
		for(i = 0;i < 64;i = i + 1) begin
			for(j = 0;j < 64;j = j + 1) begin
				fill_map[i][j] = 2'd00;
			end
		end
	end
	rvalid_m_inf_reg: begin // fill the fill_map, for later calculation use
		for(i = 0;i < 32;i = i + 1) begin
			fill_map[counter_sram[6:1]][(counter_sram[0]<<5)+i] = (|frame_temp[4*i+:4])? 2'b01:2'b00; // map shift right-down 1
		end
	end
	is_start_fill: begin
		for(i = 0;i < 64;i = i + 1) begin
			for(j = 0;j < 64;j = j + 1) begin
				fill_map[i][j] = (fill_map_old[i][j][1])? 2'b00:fill_map_old[i][j]; // clean the fill_map last time
			end
		end
		if(!rlast_m_inf_reg) begin
			fill_map[(backtrace_y_old)][(backtrace_x_old)] = 2'b01;
		end
		// fill_map[(backtrace_y_old)][(backtrace_x_old)] = (fill_map_old[(backtrace_y_old)][(backtrace_x_old)][1])? 2'b01:fill_map_old[(backtrace_y_old)][(backtrace_x_old)]; // clean the fill_map last time
		
		fill_map[source_y[0]][source_x[0]] = 2'b11; // mark source 3
		fill_map[dest_y[0]][dest_x[0]] = 2'b00; // mark dest 0, assignable
	end
	is_fill: begin
		// 4 corner
		fill_map[ 0][ 0] = ((~(|fill_map_old[ 0][ 0])) & (fill_map_old[ 0][ 1][1] | fill_map_old[ 1][ 0][1]))? {1'b1, fill_sequence[1]}: fill_map_old[ 0][ 0];
		fill_map[ 0][63] = ((~(|fill_map_old[ 0][63])) & (fill_map_old[ 0][62][1] | fill_map_old[ 1][63][1]))? {1'b1, fill_sequence[1]}: fill_map_old[ 0][63];
		fill_map[63][ 0] = ((~(|fill_map_old[63][ 0])) & (fill_map_old[63][ 1][1] | fill_map_old[62][ 0][1]))? {1'b1, fill_sequence[1]}: fill_map_old[63][ 0];
		fill_map[63][63] = ((~(|fill_map_old[63][63])) & (fill_map_old[63][62][1] | fill_map_old[62][63][1]))? {1'b1, fill_sequence[1]}: fill_map_old[63][63];
		// row 0, row 63, col 0, col 63
		for(i = 1;i < 63;i = i + 1) begin
			fill_map[ 0][ i] = ((~(|fill_map_old[ 0][ i])) & (fill_map_old[ 0][i+1][1] | fill_map_old[ 1][i][1] | fill_map_old[ 0][i-1][1]))? {1'b1, fill_sequence[1]}: fill_map_old[ 0][ i];
			fill_map[63][ i] = ((~(|fill_map_old[63][ i])) & (fill_map_old[63][i+1][1] | fill_map_old[62][i][1] | fill_map_old[63][i-1][1]))? {1'b1, fill_sequence[1]}: fill_map_old[63][ i];
			fill_map[ i][ 0] = ((~(|fill_map_old[ i][ 0])) & (fill_map_old[i-1][ 0][1] | fill_map_old[i][ 1][1] | fill_map_old[i+1][ 0][1]))? {1'b1, fill_sequence[1]}: fill_map_old[ i][ 0];
			fill_map[ i][63] = ((~(|fill_map_old[ i][63])) & (fill_map_old[i-1][63][1] | fill_map_old[i][62][1] | fill_map_old[i+1][63][1]))? {1'b1, fill_sequence[1]}: fill_map_old[ i][63];
		end
		// middle 62*62
		for(i = 1;i < 63;i = i + 1) begin
			for(j = 1;j < 63;j = j + 1) begin
				// fill_map is 0 and neighbor is filled
				fill_map[i][j] = ((~(|fill_map_old[i][j])) & (fill_map_old[i-1][j][1] | fill_map_old[i][j+1][1] | fill_map_old[i+1][j][1] | fill_map_old[i][j-1][1]))? {1'b1, fill_sequence[1]}: fill_map_old[i][j];
			end
		end
	end
	fill_done_delay1 | backtrace_counter: begin
		// fill_map[source_y[0]+1][source_x[0]+1] = (backtrace_done)?2'b01:fill_map_old[i][j]; // reset start point
		fill_map[(backtrace_y_old)][(backtrace_x_old)] = 2'b01;
	end
	endcase
end

// ====================================================
// output
// ====================================================
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cost <= 14'd0;
		busy <= 1'b0;
	end
	else if(is_idle) begin
		busy <= 1'b0;
		cost <= 14'd0;
	end
	else if(backtrace_counter) begin
		cost <= cost + weight_out[backtrace_x_old[4:0]];
	end
	else if(P_next == S_IDLE) begin // P_cur == S_WRITE_SRAM & P_next = S_IDLE
		busy <= 1'b0;
	end
	else if((!in_valid) & in_valid_flag) begin
		busy <= 1'b1;
	end
	
end

endmodule
