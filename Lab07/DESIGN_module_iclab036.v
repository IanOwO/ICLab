module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
        seed_out <= 32'b0;
    end
    else if(in_valid & out_idle) begin
        out_valid <= 1'b1;
        seed_out <= seed_in;
    end
    else begin
        out_valid <= 1'b0;
    end
end

// reg [31:0] seed_buffer;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         seed_buffer <= 32'b0;
//     end
//     else if(in_valid) begin
//         seed_buffer <= seed_in;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         seed_out <= 32'b0;
//         out_valid <= 1'b0;
//     end
//     else if(out_idle) begin
//         seed_out <= seed_buffer;
//         out_valid <= 1'b1;
//     end
//     else begin
//         seed_out <= 32'b0;
//         out_valid <= 1'b0;
//     end
// end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output reg out_valid;
output reg [31:0] rand_num;
output reg busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

output reg clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

reg [31:0] sl_a,sl_b,sl_c,sl_d,random_val;
reg [7:0] counter;
reg busy_delay;
reg busy_delay2;

reg counter_255_flag;

assign busy = busy_delay2;
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         clk2_fifo_flag1 <= 1'b0;            
//     end
//     else if(in_valid) begin
//         clk2_fifo_flag1 <= 1'b0;
//     end
//     else if(!clk2_fifo_flag1)begin
//         clk2_fifo_flag1 <= (&counter);            
//     end
// end

always @(*) begin
    sl_a = (busy)? rand_num:seed;
    sl_b = sl_a ^ (sl_a << 13);
    sl_c = sl_b ^ (sl_b >> 17);
    sl_d = sl_c ^ (sl_c << 5);
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        random_val <= 32'b0;
    end
    else if(fifo_full) begin
        random_val <= rand_num;
    end
    else begin
        random_val <= sl_d;
    end
end

always @(*) begin
    rand_num = random_val;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy_delay <= 1'b0;
        busy_delay2 <= 1'b0;
    end
    else begin
        busy_delay <= (|counter) | in_valid;
        busy_delay2 <= busy_delay;
    end
end

always @(*) begin
    if(busy & (!fifo_full)) begin
        out_valid = 1'b1;
    end
    else begin
        out_valid = 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 8'b0;
    end
    else if(busy & (!fifo_full)) begin
        counter <= (counter_255_flag)? 8'b0:counter + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_255_flag <= 1'b0;
    end
    else if(&counter) begin
        counter_255_flag <= 1'b1;
    end
    else if(in_valid) begin
        counter_255_flag <= 1'b0;
    end
end

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
output fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

reg fifo_empty_delay;
reg out_flag;

assign fifo_rinc = (!fifo_empty);
assign fifo_clk3_flag1 = (fifo_empty) & fifo_empty_delay;

// reg [7:0] counter;
// assign fifo_clk3_flag1 = (counter == 8'd254);
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         counter <= 8'b0;
//     end
//     else if(out_flag) begin
//         counter <= counter + 1;
//     end
// end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_empty_delay <= 1'b0;
    end
    else begin
        fifo_empty_delay <= !fifo_empty;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_flag <= 1'b0;
    end
    else if(fifo_empty_delay)begin
        out_flag <= 1'b1;
    end
    else begin
        out_flag <= 1'b0;
    end
end

always @(*) begin
    if(out_flag) begin
        out_valid = 1'b1;
        rand_num = fifo_rdata;
    end
    else begin
        out_valid = 1'b0;
        rand_num = 32'b0;
    end
end



endmodule