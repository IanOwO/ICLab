module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;
reg [31:0] din_buffer;

NDFF_syn clk1_to_clk2 (.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn clk2_to_clk1 (.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

assign sidle = (!sreq) & (!sack);

always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
        sreq <= 1'b0;
        din_buffer <= 32'b0;
    end
    else if(sready) begin
        sreq <= 1'b1;
        din_buffer <= din;
    end
    else if(sack) begin
        sreq <= 1'b0;
    end
end

always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) begin
        dout <= 32'b0;
        dvalid <= 1'b0;
    end
    else if((dack == 1'b0) && dreq && !dbusy) begin
        dout <= din_buffer;
        dvalid <= 1'b1;
    end
    else if(dbusy) begin
        dvalid <= 1'b0;
    end
end

always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) begin
        dack <= 1'b0;
    end
    else begin
        dack <= dreq;
    end
end

endmodule