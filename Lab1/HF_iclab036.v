module HF(
    // Input signals
    input [24:0] symbol_freq,
    // Output signals
    output reg [19:0] out_encoded
);

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

// ==========================
// sorting part
// ==========================

wire [9:0] a_1 = {5'd16,symbol_freq[24:20]};
wire [9:0] b_1 = {5'd12,symbol_freq[19:15]};
wire [9:0] c_1 = {5'd8,symbol_freq[14:10]};
wire [9:0] d_1 = {5'd4,symbol_freq[ 9: 5]};
wire [9:0] e_1 = {5'd0,symbol_freq[ 4: 0]};

reg [9:0] a_2;
reg [9:0] b_2;

reg [9:0] a_3;
reg [9:0] b_3;
reg [9:0] c_3;

reg [9:0] a_4;
reg [9:0] b_4;
reg [9:0] c_4;
reg [9:0] d_4;

reg [4:0] a_sorted;
reg [4:0] b_sorted;
reg [4:0] c_sorted;
reg [4:0] d_sorted;
reg [4:0] e_sorted;

reg [4:0] a_sorted_index;
reg [4:0] b_sorted_index;
reg [4:0] c_sorted_index;
reg [4:0] d_sorted_index;
reg [4:0] e_sorted_index;

// ========================
// decoding part 
// ========================
reg [3:0] decode_a;
reg [3:0] decode_b;
reg [2:0] decode_c;
reg [2:0] decode_d;
reg [2:0] decode_e;

reg [5:0] sum_iter1;
reg [6:0] sum_iter2;
reg [6:0] sum_iter3;
reg flag_sum_iter2 = 1'b0;
reg flag_sum_iter3 = 1'b0;

// =============================
// decode finish, output part
// =============================
wire [19:0] decode_a_out;
wire [19:0] decode_b_out;
wire [18:0] decode_c_out;
wire [18:0] decode_d_out;
wire [18:0] decode_e_out;
//================================================================
//    DESIGN
//================================================================

always @(*) begin
    // 1'st iter
    if(b_1[4:0] < a_1[4:0]) begin
        a_2 = b_1;
        b_2 = a_1;
    end
    else begin
        a_2 = a_1;
        b_2 = b_1;
    end

    // 2'nd iter
    if(c_1[4:0] < a_2[4:0]) begin
        a_3 = c_1;
        b_3 = a_2;
        c_3 = b_2;
    end
    else if(c_1[4:0] < b_2[4:0]) begin
        a_3 = a_2;
        b_3 = c_1;
        c_3 = b_2;
    end
    else begin
        a_3 = a_2;
        b_3 = b_2;
        c_3 = c_1;
    end

    // 3'rd iter
    if(d_1[4:0] < a_3[4:0]) begin
        a_4 = d_1;
        b_4 = a_3;
        c_4 = b_3;
        d_4 = c_3;
    end
    else if(d_1[4:0] < b_3[4:0]) begin
        a_4 = a_3;
        b_4 = d_1;
        c_4 = b_3;
        d_4 = c_3;
    end
    else if(d_1[4:0] < c_3[4:0]) begin
        a_4 = a_3;
        b_4 = b_3;
        c_4 = d_1;
        d_4 = c_3;
    end
    else begin
        a_4 = a_3;
        b_4 = b_3;
        c_4 = c_3;
        d_4 = d_1;
    end

    // 4'th iter
    if(e_1[4:0] < a_4[4:0]) begin
        a_sorted = e_1[4:0];
        a_sorted_index = e_1[9:5];
        b_sorted = a_4[4:0];
        b_sorted_index = a_4[9:5];
        c_sorted = b_4[4:0];
        c_sorted_index = b_4[9:5];
        d_sorted = c_4[4:0];
        d_sorted_index = c_4[9:5];
        e_sorted = d_4[4:0];
        e_sorted_index = d_4[9:5];
    end
    else if(e_1[4:0] < b_4[4:0]) begin
        a_sorted = a_4[4:0];
        a_sorted_index = a_4[9:5];
        b_sorted = e_1[4:0];
        b_sorted_index = e_1[9:5];
        c_sorted = b_4[4:0];
        c_sorted_index = b_4[9:5];
        d_sorted = c_4[4:0];
        d_sorted_index = c_4[9:5];
        e_sorted = d_4[4:0];
        e_sorted_index = d_4[9:5];
    end
    else if(e_1[4:0] < c_4[4:0]) begin
        a_sorted = a_4[4:0];
        a_sorted_index = a_4[9:5];
        b_sorted = b_4[4:0];
        b_sorted_index = b_4[9:5];
        c_sorted = e_1[4:0];
        c_sorted_index = e_1[9:5];
        d_sorted = c_4[4:0];
        d_sorted_index = c_4[9:5];
        e_sorted = d_4[4:0];
        e_sorted_index = d_4[9:5];
    end
    else if(e_1[4:0] < d_4[4:0]) begin
        a_sorted = a_4[4:0];
        a_sorted_index = a_4[9:5];
        b_sorted = b_4[4:0];
        b_sorted_index = b_4[9:5];
        c_sorted = c_4[4:0];
        c_sorted_index = c_4[9:5];
        d_sorted = e_1[4:0];
        d_sorted_index = e_1[9:5];
        e_sorted = d_4[4:0];
        e_sorted_index = d_4[9:5];
    end
    else begin
        a_sorted = a_4[4:0];
        a_sorted_index = a_4[9:5];
        b_sorted = b_4[4:0];
        b_sorted_index = b_4[9:5];
        c_sorted = c_4[4:0];
        c_sorted_index = c_4[9:5];
        d_sorted = d_4[4:0];
        d_sorted_index = d_4[9:5];
        e_sorted = e_1[4:0];
        e_sorted_index = e_1[9:5];
    end
end

// start construction, iteration 1

always @(*) begin
    sum_iter1 = a_sorted + b_sorted;

    decode_a = 4'd0;
    decode_b = 4'd1;

    if(sum_iter1 > d_sorted) begin
        decode_c = 3'd0;
        decode_d = 3'd1;
        sum_iter2 = c_sorted + d_sorted;
        flag_sum_iter2 = 1;
    end
    else if(sum_iter1 > c_sorted) begin
        decode_c = 3'd0;
        decode_a[1] = 1'b1;
        decode_b[1] = 1'b1;
        sum_iter2 = sum_iter1 + c_sorted;
        flag_sum_iter2 = 0;

        decode_d = 3'd0; // prevent latch
    end
    else begin
        decode_c = 3'd1;
        decode_a[1] = 1'b0;
        decode_b[1] = 1'b0;
        sum_iter2 = sum_iter1 + c_sorted;
        flag_sum_iter2 = 0;

        decode_d = 3'd0; // prevent latch
    end

    if(flag_sum_iter2) begin
        if(sum_iter2 > e_sorted) begin
            if(sum_iter1 > e_sorted) begin
                decode_e = 3'd0;
                decode_a[1] = 1'b1;
                decode_b[1] = 1'b1;
            end
            else begin
                decode_e = 3'd1;
                decode_a[1] = 1'b0;
                decode_b[1] = 1'b0;
            end
            flag_sum_iter3 = 1;
            sum_iter3 = e_sorted + sum_iter1;
        end
        else begin
            decode_a[1] = 1'b0;
            decode_b[1] = 1'b0;
            decode_c[1] = 1'b1;
            decode_d[1] = 1'b1;
            sum_iter3 = sum_iter2 + sum_iter1;
            flag_sum_iter3 = 0;

            decode_e = 3'd0; // prevent latch
        end
    end
    else begin
        if(sum_iter2 > e_sorted) begin
            decode_d = 3'd0;
            decode_e = 3'd1;
            sum_iter3 = d_sorted + e_sorted;
            flag_sum_iter3 = 1;
        end
        else if(sum_iter2 > d_sorted) begin
            decode_d = 3'd0;
            decode_a[2] = 1'b1;
            decode_b[2] = 1'b1;
            decode_c[1] = 1'b1;
            sum_iter3 = sum_iter2 + d_sorted;
            flag_sum_iter3 = 0;

            decode_e = 3'd0; // prevent latch
        end
        else begin
            decode_d = 3'd1;
            decode_a[2] = 1'b0;
            decode_b[2] = 1'b0;
            decode_c[1] = 1'b0;
            sum_iter3 = sum_iter2 + d_sorted;
            flag_sum_iter3 = 0;

            decode_e = 3'd0; // prevent latch
        end
    end

    // output assignment
    if(flag_sum_iter3) begin
        if(flag_sum_iter2) begin
            if(sum_iter3 > sum_iter2) begin
                decode_a[2] = 1'b1;
                decode_b[2] = 1'b1;
                decode_c[1] = 1'b0;
                decode_d[1] = 1'b0;
                decode_e[1] = 1'b1;    
            end
            else begin
                decode_a[2] = 1'b0;
                decode_b[2] = 1'b0;
                decode_c[1] = 1'b1;
                decode_d[1] = 1'b1;
                decode_e[1] = 1'b0;
            end
        end
        else begin
            if(sum_iter3 > sum_iter2) begin
                decode_a[2] = 1'b0;
                decode_b[2] = 1'b0;
                decode_c[1] = 1'b0;    
                decode_d[1] = 1'b1;
                decode_e[1] = 1'b1;
            end
            else begin
                decode_a[2] = 1'b1;
                decode_b[2] = 1'b1;
                decode_c[1] = 1'b1;
                decode_d[1] = 1'b0;
                decode_e[1] = 1'b0;
            end
        end
    end
    else begin
        if(flag_sum_iter2) begin
            if(sum_iter3 > e_sorted) begin
                decode_e = 3'd0;
                decode_a[2] = 1'b1;
                decode_b[2] = 1'b1;
                decode_c[2] = 1'b1;
                decode_d[2] = 1'b1;    
            end
            else begin
                decode_e = 3'd1;
                decode_a[2] = 1'b0;
                decode_b[2] = 1'b0;
                decode_c[2] = 1'b0;
                decode_d[2] = 1'b0;
            end
        end
        else begin
            if(sum_iter3 > e_sorted) begin
                decode_e = 3'd0;
                decode_a[3] = 1'b1;
                decode_b[3] = 1'b1;
                decode_c[2] = 1'b1;
                decode_d[1] = 1'b1;    
            end
            else begin
                decode_e = 3'd1;
                decode_a[3] = 1'b0;
                decode_b[3] = 1'b0;
                decode_c[2] = 1'b0;
                decode_d[1] = 1'b0;
            end
        end
    end

end

assign decode_a_out = decode_a << {a_sorted_index};
assign decode_b_out = decode_b << {b_sorted_index};
assign decode_c_out = decode_c << {c_sorted_index};
assign decode_d_out = decode_d << {d_sorted_index};
assign decode_e_out = decode_e << {e_sorted_index};

always @(*) begin
    out_encoded = decode_a_out | decode_b_out | {1'b0, decode_c_out} | {1'b0, decode_d_out} | {1'b0, decode_e_out};
end

endmodule
