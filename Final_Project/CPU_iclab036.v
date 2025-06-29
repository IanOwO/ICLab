//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
       bready_m_inf,
                    
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
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  reg  [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  reg  [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  reg  [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  reg  [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  reg  [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  reg  [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
// cache variable
reg cache_type;
reg [6:0]  cache_addr;
reg [15:0] cache_data_in;
reg [15:0] cache_data_out;
reg cache_we;

reg [3:0] inst_tag;
reg [3:0] data_tag;

// datapath
reg [10:0] PC;
reg [10:0] PC_add_1; // maybe try to use wire
reg [3:0] rs_addr,rt_addr,rd_addr;
reg signed [15:0] rs_data,rt_data; 
reg signed [4:0] immediate;
reg [2:0] op_code;
reg func_code;

reg [2:0] op_code_delay;
reg [3:0] rd_addr_delay;

reg signed [15:0] alu_in_1, alu_in_2, alu_result;
reg signed [15:0] alu_add, alu_sub, alu_slt, alu_mem_addr;
wire signed [15:0] alu_mul_msb,alu_mul;

// control
reg inst_cache_miss;
reg data_cache_miss;
reg counter_decode;
reg counter_exe;
reg is_mul_exe;
reg prefetch_done;
reg [10:0] exe_cal_pc;
reg mem_load;
reg store_done;

reg [1:0] rlast_reg, rvalid_reg;

MEMORY_256X16 Cache   (.A0(cache_addr[0]), .A1(cache_addr[1]), .A2(cache_addr[2]), .A3(cache_addr[3]), .A4(cache_addr[4]), .A5(cache_addr[5]), .A6(cache_addr[6]), .A7(cache_type),
              .DO0(cache_data_out[0]),   .DO1(cache_data_out[1]),   .DO2(cache_data_out[2]),  .DO3(cache_data_out[3]),
              .DO4(cache_data_out[4]),   .DO5(cache_data_out[5]),   .DO6(cache_data_out[6]),  .DO7(cache_data_out[7]),
              .DO8(cache_data_out[8]),   .DO9(cache_data_out[9]),   .DO10(cache_data_out[10]), .DO11(cache_data_out[11]),
              .DO12(cache_data_out[12]), .DO13(cache_data_out[13]), .DO14(cache_data_out[14]), .DO15(cache_data_out[15]),
              .DI0(cache_data_in[0]),   .DI1(cache_data_in[1]),   .DI2(cache_data_in[2]),  .DI3(cache_data_in[3]),
              .DI4(cache_data_in[4]),   .DI5(cache_data_in[5]),   .DI6(cache_data_in[6]),  .DI7(cache_data_in[7]),
              .DI8(cache_data_in[8]),   .DI9(cache_data_in[9]),   .DI10(cache_data_in[10]), .DI11(cache_data_in[11]),
              .DI12(cache_data_in[12]), .DI13(cache_data_in[13]), .DI14(cache_data_in[14]), .DI15(cache_data_in[15]),
              .CK(clk), .WEB(cache_we), .OE(1'b1), .CS(1'b1));

// ========================================
// Finite state machine
// ========================================
parameter [2:0] S_INST_CACHE_MISS = 0, S_FETCH = 1, S_DECODE = 2, S_EXE = 3, S_MEM = 4, S_DATA_CACHE_MISS = 5, S_WRITEBACK = 6, S_STORE_WRITE_THROUGH = 7;
reg [2:0] P_cur, P_next;
reg is_fetch, is_dec, is_exe, is_writeback, is_inst_cache_miss, is_data_cache_miss, is_mem, is_store;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) P_cur <= S_FETCH;
    else P_cur <= P_next;
end

always @(*) begin
	case (P_cur)
	S_INST_CACHE_MISS:
		if(rlast_reg[1]) P_next = S_FETCH;
		else P_next = S_INST_CACHE_MISS;
	S_FETCH: 
		if(inst_cache_miss) P_next = S_INST_CACHE_MISS;
        else if(prefetch_done) P_next = S_DECODE;
		else P_next = S_FETCH;
	S_DECODE: 
		// if(counter_decode) P_next = S_EXE;
        // else P_next = S_DECODE;
        if(op_code == 3'b101) P_next = S_WRITEBACK;
        else P_next = S_EXE;
        // P_next = S_EXE;
    S_EXE:
        // if(op_code[2]) P_next = S_FETCH; // maybe try minus one lat to go to fetch directly
        // else 
        if(op_code[1:0] == 2'b10) P_next = S_MEM;
        else if(op_code[1:0] == 2'b11) P_next = S_STORE_WRITE_THROUGH;
        else if(is_mul_exe & !counter_exe) P_next = S_EXE;
        else P_next = S_WRITEBACK;
    S_MEM:
        // if(op_code_delay[1:0] == 2'b11) P_next = S_STORE_WRITE_THROUGH;
        // else 
        if(data_cache_miss) P_next = S_DATA_CACHE_MISS;
        else if((~mem_load) & (op_code_delay[1:0] == 2'b10)) P_next = S_MEM;
		else P_next = S_WRITEBACK;
    S_DATA_CACHE_MISS:
        if(rlast_reg[0]) P_next = S_MEM;
		else P_next = S_DATA_CACHE_MISS;
    S_WRITEBACK: 
        P_next = S_FETCH;
    S_STORE_WRITE_THROUGH:
        if(bvalid_m_inf) P_next = S_FETCH;
        else P_next = S_STORE_WRITE_THROUGH;
	default: P_next = S_FETCH;
	endcase
end

always @(*) begin
	is_fetch = (P_cur == S_FETCH)? 1'b1:1'b0;
    is_dec = (P_cur == S_DECODE)? 1'b1:1'b0;
    is_exe = (P_cur == S_EXE)? 1'b1:1'b0;
    is_writeback = (P_cur == S_WRITEBACK)? 1'b1:1'b0;
    is_inst_cache_miss = (P_cur == S_INST_CACHE_MISS)? 1'b1: 1'b0;
    is_data_cache_miss = (P_cur == S_DATA_CACHE_MISS)? 1'b1: 1'b0;
    is_mem = (P_cur == S_MEM)? 1'b1: 1'b0;
    is_store = (P_cur == S_STORE_WRITE_THROUGH)? 1'b1: 1'b0;
end

// ========================================
// AXI4 control
// ========================================
// READ (1)	axi read address channel 
assign arid_m_inf = 8'd0; // master
assign arburst_m_inf = 4'b0101; // INCR
assign arsize_m_inf = 6'b001001; // 2 byte
assign arlen_m_inf = 14'b11111111111111; // max read
assign araddr_m_inf = {20'h00001,inst_tag,8'h00, 20'h00001,data_tag,8'h00};
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		arvalid_m_inf <= 2'b00;
	end
	else if(inst_cache_miss & is_fetch) begin
		arvalid_m_inf <= 2'b10;
	end
    else if(data_cache_miss & is_mem & (op_code_delay[1:0] == 2'b10)) begin
        arvalid_m_inf <= 2'b01;
    end
	else if(arready_m_inf) begin
		arvalid_m_inf <= 2'b00;
	end
end


// READ (2)	axi read data channel 
assign rready_m_inf = 2'b11;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rlast_reg <= 2'b00;
        rvalid_reg <= 2'b00;
    end
    else begin
        rlast_reg <= rlast_m_inf;
        rvalid_reg <= rvalid_m_inf;
    end
end

// WRITE (1) axi write address channel 
assign awid_m_inf = 0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b001;
assign awlen_m_inf = 7'd0;
assign awaddr_m_inf = {20'h00001, alu_result[11:1],1'b0};
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		awvalid_m_inf <= 1'b0;
	end
	else if(is_exe & (op_code[1:0] == 2'b11)) begin
		awvalid_m_inf <= 1'b1;
	end
	else if(awready_m_inf) begin
		awvalid_m_inf <= 1'b0;
	end
end

// WRITE (2) axi write data channel 
assign wdata_m_inf = alu_in_2;
// assign wlast_m_inf = wready_m_inf;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		wvalid_m_inf <= 1'b0;
        wlast_m_inf <= 1'b0;
	end
    else if(wready_m_inf == 1'b1) begin
		wvalid_m_inf <= 1'b0;
        wlast_m_inf <= 1'b0;
	end
	else if(awready_m_inf == 1'b1) begin
		wvalid_m_inf <= 1'b1;
        wlast_m_inf <= 1'b1;
	end
end

// WRITE (3) axi write response channel 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		bready_m_inf <= 1'b0;
	end
	else if(awready_m_inf) begin
		bready_m_inf <= 1'b1;
	end
	else if(bvalid_m_inf) begin
		bready_m_inf <= 1'b0;
	end
end

// ========================================
// Output
// ========================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        IO_stall <= 1'b1;
    end
    else begin
        if(is_writeback | bvalid_m_inf) begin
            IO_stall <= 1'b0;
        end
        else begin
            IO_stall <= 1'b1;
        end
    end
end

// ========================================
// Program Counter
// ========================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        PC <= 11'd0;
    end
    else begin
        if(is_exe) begin
            // if(op_code == 3'b101) PC <= {rs_addr[3:0],rt_addr,rd_addr};
            // else if((op_code == 3'b100) & (alu_in_1 == alu_in_2)) PC <= alu_add[10:0];
            // else PC <= PC_add_1;
            PC <= exe_cal_pc;
        end
        else if(is_dec & (op_code== 3'b101)) PC <= {rs_addr[3:0],rt_addr,rd_addr};
    end
end

always @(*) begin
    if(is_exe) begin
        // if(op_code == 3'b101) exe_cal_pc = {rs_addr[3:0],rt_addr,rd_addr};
        // else 
        if((op_code == 3'b100) & (alu_in_1 == alu_in_2)) exe_cal_pc = alu_add[10:0];
        else exe_cal_pc = PC_add_1;
    end
    else begin
        exe_cal_pc = 11'd0;
    end
end

// ========================================
// Fetch
// ========================================
// datapath
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        PC_add_1 <= 12'd0;
    end
    else begin
        if(is_fetch & !is_inst_cache_miss) begin
            PC_add_1 <= PC + 1;
        end
    end
end

// control
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        inst_tag <= 4'b0;
    end
    else begin
        if(is_fetch & inst_cache_miss) begin // maybe no_need this if
            inst_tag <= PC[10:7];
        end
    end
end

// ========================================
// Decode
// ========================================
// datapath
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_code <= 3'd0;
        rs_addr <= 4'd0;
        rt_addr <= 4'd0;
        rd_addr <= 4'd0;
        func_code <= 1'd0;
        immediate <= 5'd0;
    end
    else begin
        // if(prefetch_done) begin
            op_code <= cache_data_out[15:13];
            rs_addr <= cache_data_out[12:9];
            rt_addr <= cache_data_out[8:5];
            rd_addr <= cache_data_out[4:1];
            func_code <= cache_data_out[0];
            immediate <= cache_data_out[4:0];
        // end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        alu_in_1 <= 16'd0;
        alu_in_2 <= 16'd0;
    end
    else begin
        if(is_dec) begin
            alu_in_1 <= rs_data;
            alu_in_2 <= rt_data;
            // if(cache_data_out[14]) begin
            //     alu_in_2 <= {{11{cache_data_out[4]}}, cache_data_out[4:0]};
            // end
            // else begin
            //     alu_in_2 <= rt_data;
            // end
        end
        // else if(mem_load) begin
        //     alu_in_1 <= cache_data_out; // maybe can try alu_in_2
        // end
    end
end
// wire [3:0] AAA_wtf = cache_data_out[8:5];
always @(*) begin
    rs_data = 16'd0;
    rt_data = 16'd0;
    if(is_dec) begin
        case(rs_addr)
            4'd0:  rs_data = core_r0;
            4'd1:  rs_data = core_r1;
            4'd2:  rs_data = core_r2;
            4'd3:  rs_data = core_r3;
            4'd4:  rs_data = core_r4;
            4'd5:  rs_data = core_r5;
            4'd6:  rs_data = core_r6;
            4'd7:  rs_data = core_r7;
            4'd8:  rs_data = core_r8;
            4'd9:  rs_data = core_r9;
            4'd10: rs_data = core_r10;
            4'd11: rs_data = core_r11;
            4'd12: rs_data = core_r12;
            4'd13: rs_data = core_r13;
            4'd14: rs_data = core_r14;
            4'd15: rs_data = core_r15;
        endcase

        case(rt_addr)
            4'd0:  rt_data = core_r0;
            4'd1:  rt_data = core_r1;
            4'd2:  rt_data = core_r2;
            4'd3:  rt_data = core_r3;
            4'd4:  rt_data = core_r4;
            4'd5:  rt_data = core_r5;
            4'd6:  rt_data = core_r6;
            4'd7:  rt_data = core_r7;
            4'd8:  rt_data = core_r8;
            4'd9:  rt_data = core_r9;
            4'd10: rt_data = core_r10;
            4'd11: rt_data = core_r11;
            4'd12: rt_data = core_r12;
            4'd13: rt_data = core_r13;
            4'd14: rt_data = core_r14;
            4'd15: rt_data = core_r15;
        endcase
    end
end

// control
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        is_mul_exe <= 1'd0;
    end
    else begin
        if(is_dec) begin
            is_mul_exe <= (op_code == 3'b001) & func_code;
        end
    end
end
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         counter_decode <= 1'b0;
//     end
//     else begin
//         if(is_dec) begin
//             counter_decode <= ~counter_decode;
//         end
//     end
// end

// ========================================
// Execute
// ========================================
// datapath
DW02_mult_2_stage #(16, 16) mult_inst(.A(alu_in_1), .B(alu_in_2), .TC(1'b1), .CLK(clk), .PRODUCT({alu_mul_msb,alu_mul}));

reg signed [15:0] alu_in_1_mux,alu_in_2_mux;
always @(*) begin
    alu_in_1_mux = (op_code[2])? PC_add_1: alu_in_1;
    alu_in_2_mux = (op_code[2] | op_code[1])? {{11{immediate[4]}}, immediate[4:0]}:alu_in_2;
end

always @(*) begin
    alu_add = alu_in_1_mux + alu_in_2_mux;
    alu_sub = alu_in_1 - alu_in_2;
    alu_slt = (alu_in_1 < alu_in_2)? 16'd1: 16'd0;
    alu_mem_addr = alu_add << 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        alu_result <= 16'd0;
    end
    else begin
        if(is_exe) begin
            if(op_code == 3'b000) begin
                alu_result <= (func_code)? alu_sub:alu_add;
            end
            else if(op_code == 3'b001) begin
                alu_result <= (func_code)? alu_mul:alu_slt;
            end
            else if(op_code[1]) begin
                alu_result <= alu_mem_addr;
            end
        end
    end
end
// control
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_exe <= 1'b0;
    end
    else begin
        if(is_exe & is_mul_exe) begin
            counter_exe <= ~counter_exe;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_cache_miss <= 1'b1;
    end
    else begin
        if(is_exe & (op_code[1:0] == 2'b10) & !data_cache_miss) begin // check op_code
            data_cache_miss <= (alu_mem_addr[11:8] != data_tag);
        end
        else if(rlast_reg[0]) begin
            data_cache_miss <= 1'b0;
        end
    end
end

// store to data cache
// reg store_cache;
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         store_cache <= 1'b0;
//     end
//     else begin
//         if(is_exe & (op_code[1:0] == 2'b11)) begin // check op_code
//             store_cache <= (alu_mem_addr[11:8] == data_tag);
//         end
//         else if(is_writeback) begin
//             store_cache <= 1'b0;
//         end
//     end
// end

// pass to mem and wb stage
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_code_delay <= 3'd0;
        rd_addr_delay <= 4'd0;
    end
    else begin
        if(is_dec) begin
            op_code_delay <= op_code;
            rd_addr_delay <= (op_code[1:0] == 2'b10)?rt_addr:rd_addr;
        end
    end
end

// ========================================
// Memory
// ========================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_tag <= 4'd0;
    end
    else begin
        if(is_mem) begin // maybe no_need this if
            data_tag <= alu_result[11:8];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem_load <= 1'b0;
    end
    else begin
        if(is_mem & !data_cache_miss) begin
            mem_load <= ~mem_load;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        store_done <= 1'b0;
    end
    else begin
        if(wready_m_inf) begin
            store_done <= 1'b1;
        end
        else if(bvalid_m_inf) begin
            store_done <= 1'b0;
        end
    end
end

// ========================================
// Writeback
// ========================================
// datapath
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        core_r0 <= 16'b0;
        core_r1 <= 16'b0;
        core_r2 <= 16'b0;
        core_r3 <= 16'b0;
        core_r4 <= 16'b0;
        core_r5 <= 16'b0;
        core_r6 <= 16'b0;
        core_r7 <= 16'b0;
        core_r8 <= 16'b0;
        core_r9 <= 16'b0;
        core_r10 <= 16'b0;
        core_r11 <= 16'b0;
        core_r12 <= 16'b0;
        core_r13 <= 16'b0;
        core_r14 <= 16'b0;
        core_r15 <= 16'b0;
    end
    else begin
        if(is_writeback) begin
            if(op_code_delay[2:1] == 2'b00) begin
                case(rd_addr_delay)
                    4'd0:  core_r0 <= alu_result;
                    4'd1:  core_r1 <= alu_result;
                    4'd2:  core_r2 <= alu_result;
                    4'd3:  core_r3 <= alu_result;
                    4'd4:  core_r4 <= alu_result;
                    4'd5:  core_r5 <= alu_result;
                    4'd6:  core_r6 <= alu_result;
                    4'd7:  core_r7 <= alu_result;
                    4'd8:  core_r8 <= alu_result;
                    4'd9:  core_r9 <= alu_result;
                    4'd10: core_r10 <= alu_result;
                    4'd11: core_r11 <= alu_result;
                    4'd12: core_r12 <= alu_result;
                    4'd13: core_r13 <= alu_result;
                    4'd14: core_r14 <= alu_result;
                    4'd15: core_r15 <= alu_result;
                endcase
            end
            else if(op_code_delay == 3'b010) begin
                case(rd_addr_delay)
                    4'd0:  core_r0 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd1:  core_r1 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd2:  core_r2 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd3:  core_r3 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd4:  core_r4 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd5:  core_r5 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd6:  core_r6 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd7:  core_r7 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd8:  core_r8 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd9:  core_r9 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd10: core_r10 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd11: core_r11 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd12: core_r12 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd13: core_r13 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd14: core_r14 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                    4'd15: core_r15 <= {op_code,rs_addr,rt_addr,rd_addr,func_code};
                endcase
            end
        end
    end
end

// control
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        inst_cache_miss <= 1'b1;
    end
    else begin
        if(is_writeback | is_store) begin
            inst_cache_miss <= (PC[10:7] != inst_tag);
        end
        else if(rlast_reg[1]) begin
            inst_cache_miss <= 1'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        prefetch_done <= 1'b0;
    end
    else begin
        if(inst_cache_miss | is_dec) begin
            prefetch_done <= 1'b0;
        end
        else if(is_fetch | is_writeback | is_store) begin
            prefetch_done <= 1'b1;
        end
    end
end

// ====================================
// Cache write
// ====================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cache_addr <= 7'd0;
    end
    else begin
        if(rlast_reg[1]) begin // after inst cache miss, request the required PC
            cache_addr <= PC;
        end
        else if(rlast_reg[0]) begin // after data cache miss, request the required data address
            cache_addr <= alu_result[7:1];
        end
        else if(rvalid_reg) begin // read from dram and write to cache
            cache_addr <= cache_addr + 1;
        end
        else if(is_dec & (op_code == 3'b101)) begin
            cache_addr <= {rt_addr[3:0],rd_addr};
        end
        else if(is_store & (!store_done)) begin
            cache_addr <= alu_result[7:1];
        end
        else if(is_exe) begin
            if(op_code[1]) cache_addr <= alu_mem_addr[7:1];
            else cache_addr <= exe_cal_pc;
        end
        else if(inst_cache_miss) begin
            cache_addr <= 7'd0;
        end
        else if(data_cache_miss) begin
            cache_addr <= 7'd0;
        end
        else begin
            cache_addr <= PC;
        end
        
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cache_data_in <= 32'd0;
        // cache_we <= 1'b1;
    end
    else begin
        if(is_inst_cache_miss) begin
            cache_data_in <= rdata_m_inf[31:16];
            // cache_we <= 1'b0;
        end
        else if(is_data_cache_miss) begin
            cache_data_in <= rdata_m_inf[15:0];
            // cache_we <= 1'b0;
        end
        else if(awready_m_inf & (alu_result[11:8] == data_tag)) begin 
            cache_data_in <= alu_in_2;
            // cache_we <= 1'b0;
        end
        else begin
            cache_data_in <= 16'd0;
            // cache_we <= 1'b1;
        end
    end
end

wire AAA_check = (alu_result[11:8] == data_tag);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cache_we <= 1'b1;
    end
    else begin
        if(is_inst_cache_miss & !rlast_reg[1]) begin
            cache_we <= 1'b0;
        end
        else if(is_data_cache_miss & !rlast_reg[0]) begin
            cache_we <= 1'b0;
        end
        else if(awready_m_inf & (alu_result[11:8] == data_tag)) begin 
            cache_we <= 1'b0;
        end
        else begin
            cache_we <= 1'b1;
        end
    end
end

always @(*) begin
    // if(is_inst_cache_miss) begin
    //     cache_data_in = rdata_m_inf[31:16];
    //     cache_we = 1'b0;
    // end
    // else if(is_data_cache_miss) begin
    //     cache_data_in = rdata_m_inf[15:0];
    //     cache_we = 1'b0;
    // end
    // else if(wvalid_m_inf & (alu_result[11:8] == data_tag)) begin 
    //     cache_data_in = alu_in_2;
    //     cache_we = 1'b0;
    // end
    // else begin
    //     cache_data_in = 16'd0;
    //     cache_we = 1'b1;
    // end

    if(is_data_cache_miss | is_mem | (is_store & !store_done)) begin
        cache_type = 1'b1;
    end
    else begin
        cache_type = 1'b0;
    end
end

// ==================================== check pattern
// reg [16:0] AAA_wtf;
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         AAA_wtf <= 17'b0;
//     end
//     else begin
//         if(is_writeback) begin
//             AAA_wtf <= AAA_wtf + 1;
//         end
//     end
// end

endmodule


