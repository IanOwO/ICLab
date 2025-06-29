module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

// rdata
//  Add one more register stage to rdata
always @(posedge rclk) begin
    rdata <= rdata_q;
end

wire [6:0] rptr_after_ndff,wptr_after_ndff;
reg [6:0] rptr_binary,wptr_binary;
reg [6:0] waddr,raddr;
reg [1:0] final_output;

NDFF_BUS_syn #(.WIDTH(7)) clk2_to_clk3(.D(wptr), .Q(wptr_after_ndff), .clk(rclk), .rst_n(rst_n));
NDFF_BUS_syn #(.WIDTH(7)) clk3_to_clk2(.D(rptr), .Q(rptr_after_ndff), .clk(wclk), .rst_n(rst_n));

DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(!winc),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr[0]),.A1(waddr[1]),.A2(waddr[2]),.A3(waddr[3]),.A4(waddr[4]),.A5(waddr[5]),
    .B0(raddr[0]),.B1(raddr[1]),.B2(raddr[2]),.B3(raddr[3]),.B4(raddr[4]),.B5(raddr[5]),
    .DIA0(wdata[0]),.DIA1(wdata[1]),.DIA2(wdata[2]),.DIA3(wdata[3]),.DIA4(wdata[4]),.DIA5(wdata[5]),.DIA6(wdata[6]),.DIA7(wdata[7]),
    .DIA8(wdata[8]),.DIA9(wdata[9]),.DIA10(wdata[10]),.DIA11(wdata[11]),.DIA12(wdata[12]),.DIA13(wdata[13]),.DIA14(wdata[14]),.DIA15(wdata[15]),
    .DIA16(wdata[16]),.DIA17(wdata[17]),.DIA18(wdata[18]),.DIA19(wdata[19]),.DIA20(wdata[20]),.DIA21(wdata[21]),.DIA22(wdata[22]),.DIA23(wdata[23]),
    .DIA24(wdata[24]),.DIA25(wdata[25]),.DIA26(wdata[26]),.DIA27(wdata[27]),.DIA28(wdata[28]),.DIA29(wdata[29]),.DIA30(wdata[30]),.DIA31(wdata[31]),
    // .DIB0(),.DIB1(),.DIB2(),.DIB3(),.DIB4(),.DIB5(),.DIB6(),.DIB7(),
    // .DIB8(),.DIB9(),.DIB10(),.DIB11(),.DIB12(),.DIB13(),.DIB14(),.DIB15(),
    // .DIB16(),.DIB17(),.DIB18(),.DIB19(),.DIB20(),.DIB21(),.DIB22(),.DIB23(),
    // .DIB24(),.DIB25(),.DIB26(),.DIB27(),.DIB28(),.DIB29(),.DIB30(),.DIB31(),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);

always @(*) begin
    wptr = waddr ^ (waddr >> 1);
    rptr = raddr ^ (raddr >> 1);
    
    rptr_binary[6] = rptr_after_ndff[6];
    rptr_binary[5] = rptr_after_ndff[5] ^ rptr_binary[6];
    rptr_binary[4] = rptr_after_ndff[4] ^ rptr_binary[5];
    rptr_binary[3] = rptr_after_ndff[3] ^ rptr_binary[4];
    rptr_binary[2] = rptr_after_ndff[2] ^ rptr_binary[3];
    rptr_binary[1] = rptr_after_ndff[1] ^ rptr_binary[2];
    rptr_binary[0] = rptr_after_ndff[0] ^ rptr_binary[1];

    wptr_binary[6] = wptr_after_ndff[6];
    wptr_binary[5] = wptr_after_ndff[5] ^ wptr_binary[6];
    wptr_binary[4] = wptr_after_ndff[4] ^ wptr_binary[5];
    wptr_binary[3] = wptr_after_ndff[3] ^ wptr_binary[4];
    wptr_binary[2] = wptr_after_ndff[2] ^ wptr_binary[3];
    wptr_binary[1] = wptr_after_ndff[1] ^ wptr_binary[2];
    wptr_binary[0] = wptr_after_ndff[0] ^ wptr_binary[1];

end

// ==================================
// write control
// ==================================

// always @(posedge wclk or negedge rst_n) begin
//     if(!rst_n) begin
//         wptr <= 7'b0;
//     end
//     else if(winc) begin
//         wptr <= waddr ^ (waddr >> 1);
//     end
// end

always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) begin
        waddr <= 7'b0;
    end
    else if(winc) begin
        waddr <= waddr + 1;
    end
end

assign wfull = ({~rptr_binary[6],rptr_binary[5:0]} == (waddr));

// ==================================
// read control
// ==================================

// always @(posedge rclk or negedge rst_n) begin
//     if(!rst_n) begin
//         rptr <= 7'b0;
//     end
//     else if(winc) begin
//         rptr <= raddr ^ (raddr >> 1);
//     end
// end

always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) begin
        raddr <= 7'b0;
    end
    else if(rinc & !fifo_clk3_flag1) begin
        raddr <= raddr + 1;
    end
end

always @(*) begin
    rempty = (wptr_binary == raddr);
end


endmodule
