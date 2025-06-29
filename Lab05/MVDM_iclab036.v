module MVDM(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    in_data,
    // output signals
    out_valid,
    out_sad
    );

input clk;
input rst_n;
input in_valid;
input in_valid2;
input [11:0] in_data;

output reg out_valid;
output reg out_sad;


//=======================================================
//                   Reg/Wire
//=======================================================
reg [10:0] address0, address1;
reg [10:0] address0_reg, address1_reg;
reg [7:0] counter;
reg write_enable_0, write_enable_1;
reg [7:0] data0_out[0:7]; 
reg [7:0] data1_out[0:7]; 
reg [7:0] cur_input[0:7]; // (point1) 0: L0_x, 1: L0_y 2: L1_x 3: L1_y  (point2) 4: L0_x, 5: L0_y 6: L1_x 7: L1_y
reg [3:0] fraction[0:7]; // (point1) 0: L0_x, 1: L0_y 2: L1_x 3: L1_y  (point2) 4: L0_x, 5: L0_y 6: L1_x 7: L1_y
reg in_valid2_flag;

// pipeline register
reg [10:0] start_addr0, start_addr1;
reg [1:0] cur_get_0,cur_get_1;
reg [4:0] calculate_counter;
reg [10:0] temp_addr0, temp_addr1;
wire get_0_done, get_1_done;
reg is_not_same_addr0, is_not_same_addr1;
reg [2:0] x_value0, x_value1;
reg [7:0] first_pipe_0[0:7];
reg [7:0] first_pipe_1[0:7];
reg [7:0] first_pipe_2[0:7];
reg [7:0] second_pipe_0[0:7];
reg [7:0] second_pipe_1[0:7];
reg [7:0] second_pipe_2[0:7];



reg done_point1,done_point2;
reg [27:0] min_point1;

integer i;
reg [9:0] counter_after_data_out;


MEM_2048X64 line0  (.A0(address0[0]), .A1(address0[1]), .A2(address0[2]), .A3(address0[3]), .A4(address0[4]), .A5(address0[5]), .A6(address0[6]), .A7(address0[7]), .A8(address0[8]), .A9(address0[9]), .A10(address0[10]),
                     .DO0(data0_out[0][0]), .DO1(data0_out[0][1]), .DO2(data0_out[0][2]), .DO3(data0_out[0][3]), .DO4(data0_out[0][4]), .DO5(data0_out[0][5]), .DO6(data0_out[0][6]), .DO7(data0_out[0][7]),
                     .DO8(data0_out[1][0]), .DO9(data0_out[1][1]),.DO10(data0_out[1][2]),.DO11(data0_out[1][3]),.DO12(data0_out[1][4]),.DO13(data0_out[1][5]),.DO14(data0_out[1][6]),.DO15(data0_out[1][7]),
                    .DO16(data0_out[2][0]),.DO17(data0_out[2][1]),.DO18(data0_out[2][2]),.DO19(data0_out[2][3]),.DO20(data0_out[2][4]),.DO21(data0_out[2][5]),.DO22(data0_out[2][6]),.DO23(data0_out[2][7]),
                    .DO24(data0_out[3][0]),.DO25(data0_out[3][1]),.DO26(data0_out[3][2]),.DO27(data0_out[3][3]),.DO28(data0_out[3][4]),.DO29(data0_out[3][5]),.DO30(data0_out[3][6]),.DO31(data0_out[3][7]),
                    .DO32(data0_out[4][0]),.DO33(data0_out[4][1]),.DO34(data0_out[4][2]),.DO35(data0_out[4][3]),.DO36(data0_out[4][4]),.DO37(data0_out[4][5]),.DO38(data0_out[4][6]),.DO39(data0_out[4][7]),
                    .DO40(data0_out[5][0]),.DO41(data0_out[5][1]),.DO42(data0_out[5][2]),.DO43(data0_out[5][3]),.DO44(data0_out[5][4]),.DO45(data0_out[5][5]),.DO46(data0_out[5][6]),.DO47(data0_out[5][7]),
                    .DO48(data0_out[6][0]),.DO49(data0_out[6][1]),.DO50(data0_out[6][2]),.DO51(data0_out[6][3]),.DO52(data0_out[6][4]),.DO53(data0_out[6][5]),.DO54(data0_out[6][6]),.DO55(data0_out[6][7]),
                    .DO56(data0_out[7][0]),.DO57(data0_out[7][1]),.DO58(data0_out[7][2]),.DO59(data0_out[7][3]),.DO60(data0_out[7][4]),.DO61(data0_out[7][5]),.DO62(data0_out[7][6]),.DO63(data0_out[7][7]),
                     .DI0(cur_input[0][0]), .DI1(cur_input[0][1]), .DI2(cur_input[0][2]), .DI3(cur_input[0][3]), .DI4(cur_input[0][4]), .DI5(cur_input[0][5]), .DI6(cur_input[0][6]), .DI7(cur_input[0][7]),
                     .DI8(cur_input[1][0]), .DI9(cur_input[1][1]),.DI10(cur_input[1][2]),.DI11(cur_input[1][3]),.DI12(cur_input[1][4]),.DI13(cur_input[1][5]),.DI14(cur_input[1][6]),.DI15(cur_input[1][7]),
                    .DI16(cur_input[2][0]),.DI17(cur_input[2][1]),.DI18(cur_input[2][2]),.DI19(cur_input[2][3]),.DI20(cur_input[2][4]),.DI21(cur_input[2][5]),.DI22(cur_input[2][6]),.DI23(cur_input[2][7]),
                    .DI24(cur_input[3][0]),.DI25(cur_input[3][1]),.DI26(cur_input[3][2]),.DI27(cur_input[3][3]),.DI28(cur_input[3][4]),.DI29(cur_input[3][5]),.DI30(cur_input[3][6]),.DI31(cur_input[3][7]),
                    .DI32(cur_input[4][0]),.DI33(cur_input[4][1]),.DI34(cur_input[4][2]),.DI35(cur_input[4][3]),.DI36(cur_input[4][4]),.DI37(cur_input[4][5]),.DI38(cur_input[4][6]),.DI39(cur_input[4][7]),
                    .DI40(cur_input[5][0]),.DI41(cur_input[5][1]),.DI42(cur_input[5][2]),.DI43(cur_input[5][3]),.DI44(cur_input[5][4]),.DI45(cur_input[5][5]),.DI46(cur_input[5][6]),.DI47(cur_input[5][7]),
                    .DI48(cur_input[6][0]),.DI49(cur_input[6][1]),.DI50(cur_input[6][2]),.DI51(cur_input[6][3]),.DI52(cur_input[6][4]),.DI53(cur_input[6][5]),.DI54(cur_input[6][6]),.DI55(cur_input[6][7]),
                    .DI56(cur_input[7][0]),.DI57(cur_input[7][1]),.DI58(cur_input[7][2]),.DI59(cur_input[7][3]),.DI60(cur_input[7][4]),.DI61(cur_input[7][5]),.DI62(cur_input[7][6]),.DI63(cur_input[7][7]),
                    .CK(clk), .WEB(write_enable_0), .OE(1'b1), .CS(1'b1));

MEM_2048X64 line1  (.A0(address1[0]), .A1(address1[1]), .A2(address1[2]), .A3(address1[3]), .A4(address1[4]), .A5(address1[5]), .A6(address1[6]), .A7(address1[7]), .A8(address1[8]), .A9(address1[9]), .A10(address1[10]),
                     .DO0(data1_out[0][0]), .DO1(data1_out[0][1]), .DO2(data1_out[0][2]), .DO3(data1_out[0][3]), .DO4(data1_out[0][4]), .DO5(data1_out[0][5]), .DO6(data1_out[0][6]), .DO7(data1_out[0][7]),
                     .DO8(data1_out[1][0]), .DO9(data1_out[1][1]),.DO10(data1_out[1][2]),.DO11(data1_out[1][3]),.DO12(data1_out[1][4]),.DO13(data1_out[1][5]),.DO14(data1_out[1][6]),.DO15(data1_out[1][7]),
                    .DO16(data1_out[2][0]),.DO17(data1_out[2][1]),.DO18(data1_out[2][2]),.DO19(data1_out[2][3]),.DO20(data1_out[2][4]),.DO21(data1_out[2][5]),.DO22(data1_out[2][6]),.DO23(data1_out[2][7]),
                    .DO24(data1_out[3][0]),.DO25(data1_out[3][1]),.DO26(data1_out[3][2]),.DO27(data1_out[3][3]),.DO28(data1_out[3][4]),.DO29(data1_out[3][5]),.DO30(data1_out[3][6]),.DO31(data1_out[3][7]),
                    .DO32(data1_out[4][0]),.DO33(data1_out[4][1]),.DO34(data1_out[4][2]),.DO35(data1_out[4][3]),.DO36(data1_out[4][4]),.DO37(data1_out[4][5]),.DO38(data1_out[4][6]),.DO39(data1_out[4][7]),
                    .DO40(data1_out[5][0]),.DO41(data1_out[5][1]),.DO42(data1_out[5][2]),.DO43(data1_out[5][3]),.DO44(data1_out[5][4]),.DO45(data1_out[5][5]),.DO46(data1_out[5][6]),.DO47(data1_out[5][7]),
                    .DO48(data1_out[6][0]),.DO49(data1_out[6][1]),.DO50(data1_out[6][2]),.DO51(data1_out[6][3]),.DO52(data1_out[6][4]),.DO53(data1_out[6][5]),.DO54(data1_out[6][6]),.DO55(data1_out[6][7]),
                    .DO56(data1_out[7][0]),.DO57(data1_out[7][1]),.DO58(data1_out[7][2]),.DO59(data1_out[7][3]),.DO60(data1_out[7][4]),.DO61(data1_out[7][5]),.DO62(data1_out[7][6]),.DO63(data1_out[7][7]),
                     .DI0(cur_input[0][0]), .DI1(cur_input[0][1]), .DI2(cur_input[0][2]), .DI3(cur_input[0][3]), .DI4(cur_input[0][4]), .DI5(cur_input[0][5]), .DI6(cur_input[0][6]), .DI7(cur_input[0][7]),
                     .DI8(cur_input[1][0]), .DI9(cur_input[1][1]),.DI10(cur_input[1][2]),.DI11(cur_input[1][3]),.DI12(cur_input[1][4]),.DI13(cur_input[1][5]),.DI14(cur_input[1][6]),.DI15(cur_input[1][7]),
                    .DI16(cur_input[2][0]),.DI17(cur_input[2][1]),.DI18(cur_input[2][2]),.DI19(cur_input[2][3]),.DI20(cur_input[2][4]),.DI21(cur_input[2][5]),.DI22(cur_input[2][6]),.DI23(cur_input[2][7]),
                    .DI24(cur_input[3][0]),.DI25(cur_input[3][1]),.DI26(cur_input[3][2]),.DI27(cur_input[3][3]),.DI28(cur_input[3][4]),.DI29(cur_input[3][5]),.DI30(cur_input[3][6]),.DI31(cur_input[3][7]),
                    .DI32(cur_input[4][0]),.DI33(cur_input[4][1]),.DI34(cur_input[4][2]),.DI35(cur_input[4][3]),.DI36(cur_input[4][4]),.DI37(cur_input[4][5]),.DI38(cur_input[4][6]),.DI39(cur_input[4][7]),
                    .DI40(cur_input[5][0]),.DI41(cur_input[5][1]),.DI42(cur_input[5][2]),.DI43(cur_input[5][3]),.DI44(cur_input[5][4]),.DI45(cur_input[5][5]),.DI46(cur_input[5][6]),.DI47(cur_input[5][7]),
                    .DI48(cur_input[6][0]),.DI49(cur_input[6][1]),.DI50(cur_input[6][2]),.DI51(cur_input[6][3]),.DI52(cur_input[6][4]),.DI53(cur_input[6][5]),.DI54(cur_input[6][6]),.DI55(cur_input[6][7]),
                    .DI56(cur_input[7][0]),.DI57(cur_input[7][1]),.DI58(cur_input[7][2]),.DI59(cur_input[7][3]),.DI60(cur_input[7][4]),.DI61(cur_input[7][5]),.DI62(cur_input[7][6]),.DI63(cur_input[7][7]),
                    .CK(clk), .WEB(write_enable_1), .OE(1'b1), .CS(1'b1));

//=======================================================
//                   Design
//=======================================================
// ============================

always @(*) begin
    address0 = (in_valid2_flag)? start_addr0: address0_reg;
    address1 = (in_valid2_flag)? start_addr1: address1_reg;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid2_flag <= 1'b0;
    end
    else if(in_valid2 & (counter[2:0] == 3)) begin
        in_valid2_flag <= 1'b1;
    end
    else if (done_point2) begin // marker
        in_valid2_flag <= 1'b0; 
    end
end

// counter for input data and check the location
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 8'd0;
    end
    else if(in_valid) begin
        counter <= counter + 1;
    end
    else if(in_valid2) begin
        counter <= counter + 1;
    end
    else begin
        counter <= 8'd0;
    end
end

// write enable
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_enable_0 <= 1'b1;
        write_enable_1 <= 1'b1;
    end
    else if(in_valid) begin
        write_enable_0 <= ((&counter[2:0]) & !counter[7])? 1'b0:1'b1; // write when counter is 8
        write_enable_1 <= ((&counter[2:0]) & counter[7])? 1'b0:1'b1; // write when counter is 16(0)
    end 
    else begin
        write_enable_0 <= 1'b1;
        write_enable_1 <= 1'b1;
    end
end

// ===================================
// read input
// ===================================
always @(posedge clk or negedge rst_n) begin // maybe need reset signal
    if(!rst_n) begin
        for(i = 0;i < 8;i = i + 1) begin
            cur_input[i] <= 0;
        end
    end
    else if(in_valid) begin
        cur_input[0] <= in_data[11:4]; 
        cur_input[1] <= cur_input[0]; 
        cur_input[2] <= cur_input[1]; 
        cur_input[3] <= cur_input[2]; 
        cur_input[4] <= cur_input[3]; 
        cur_input[5] <= cur_input[4]; 
        cur_input[6] <= cur_input[5]; 
        cur_input[7] <= cur_input[6];
    end
    else if(in_valid2) begin
       cur_input[counter[2:0]] <= in_data[11:4];  
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < 8;i = i + 1) begin
            fraction[i] <= 0;
        end
    end
    else if(in_valid2) begin
        fraction[counter[2:0]] <= in_data[3:0];
    end
end

// address 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        address0_reg <= 11'd0;
        address1_reg <= 11'd0;
    end
    else if(in_valid) begin
        address0_reg <= (!(|counter[2:0]) & (|counter[7:3]) & (counter < 129))? address0_reg + 1: address0_reg; // counter[2:0] = 8 & counter != 0 & counter < 129
        address1_reg <= (!(|counter[2:0]) & (counter > 128))? address1_reg + 1: // counter[2:0] = 8 & counter < 129
                                                ((|counter))? address1_reg: address0_reg; // counter == 0
    end
end

assign get_0_done = (cur_get_0 == 3);
assign get_1_done = (cur_get_1 == 3);

reg [3:0] fraction0x, fraction0y;
reg [3:0] fraction1x, fraction1y;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_after_data_out <= 0;
    end
    else if(in_valid2_flag) begin
        counter_after_data_out <= counter_after_data_out + 1;
    end
    else begin
        counter_after_data_out <= 0;
    end
end


// choose address to get output data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        calculate_counter <= 0;
        cur_get_0 <= 2'b0;
        cur_get_1 <= 2'b0;

        fraction0x <= 0;
        fraction0y <= 0;
        fraction1x <= 0;
        fraction1y <= 0;
        is_not_same_addr0 <= 0;
        is_not_same_addr1 <= 0;
        x_value0 <= 0;
        x_value1 <= 0;
        start_addr0 <= 0;
        start_addr1 <= 0;
        temp_addr0 <= 0;
        temp_addr1 <= 0;
    end
    else if(in_valid2 & (counter[3:0] == 4)) begin
        cur_get_0 <= 2'b1;
        cur_get_1 <= 2'b0;
        calculate_counter <= 0;
        is_not_same_addr0 <= cur_input[1][0];
        is_not_same_addr1 <= cur_input[3][0];
        x_value0 <= cur_input[0][2:0];
        x_value1 <= cur_input[2][2:0];
        fraction0x <= fraction[0];
        fraction0y <= fraction[1];
        fraction1x <= fraction[2];
        fraction1y <= fraction[3];

        start_addr0 <= (cur_input[1][0])? ((cur_input[1] + 1) / 2) * 16 + cur_input[0] / 8: ((cur_input[1]    ) / 2) * 16 + cur_input[0] / 8; // maybe use shift
        start_addr1 <= (cur_input[1][0])? ((cur_input[1]    ) / 2) * 16 + cur_input[0] / 8: ((cur_input[1]    ) / 2) * 16 + cur_input[0] / 8; // maybe use shift
        temp_addr0 <= (cur_input[3][0])? ((cur_input[3] + 1) / 2) * 16 + cur_input[2] / 8 + 1024: ((cur_input[3]    ) / 2) * 16 + cur_input[2] / 8 + 1024; // maybe use shift
        temp_addr1 <= (cur_input[3][0])? ((cur_input[3]    ) / 2) * 16 + cur_input[2] / 8 + 1024: ((cur_input[3]    ) / 2) * 16 + cur_input[2] / 8 + 1024; // maybe use shift
    end
    else if(in_valid2_flag) begin
        if((calculate_counter < 12) & get_1_done) begin
            cur_get_0 <= 2'b1;
            cur_get_1 <= 2'b0;
            calculate_counter <= calculate_counter + 1;
            // is_not_same_addr0 <= is_not_same_addr1;
            // is_not_same_addr1 <= is_not_same_addr0;
            // x_value0 <= x_value0;
            // x_value1 <= x_value1;
            if(calculate_counter == 5) begin
                is_not_same_addr0 <= cur_input[5][0];
                is_not_same_addr1 <= cur_input[7][0];
                x_value0 <= cur_input[4][2:0];
                x_value1 <= cur_input[6][2:0];
                fraction0x <= fraction[4];
                fraction0y <= fraction[5];
                fraction1x <= fraction[6];
                fraction1y <= fraction[7];

                start_addr0 <= (cur_input[5][0])? ((cur_input[5] + 1) / 2) * 16 + cur_input[4] / 8: ((cur_input[5]    ) / 2) * 16 + cur_input[4] / 8; // maybe use shift
                start_addr1 <= (cur_input[5][0])? ((cur_input[5]    ) / 2) * 16 + cur_input[4] / 8: ((cur_input[5]    ) / 2) * 16 + cur_input[4] / 8; // maybe use shift
                temp_addr0 <= (cur_input[7][0])? ((cur_input[7] + 1) / 2) * 16 + cur_input[6] / 8 + 1024: ((cur_input[7]    ) / 2) * 16 + cur_input[6] / 8 + 1024; // maybe use shift
                temp_addr1 <= (cur_input[7][0])? ((cur_input[7]    ) / 2) * 16 + cur_input[6] / 8 + 1024: ((cur_input[7]    ) / 2) * 16 + cur_input[6] / 8 + 1024; // maybe use shift
            end
            else begin
                start_addr0 <= temp_addr0 + 14;
                start_addr1 <= temp_addr1 + 14;
                temp_addr0 <= start_addr0 + 14;
                temp_addr1 <= start_addr1 + 14;
            end
        end
        else if(!get_0_done) begin
            cur_get_0 <= cur_get_0 + 1;
            start_addr0 <= start_addr0 + 1;
            start_addr1 <= start_addr1 + 1;
        end
        else if(cur_get_1 == 0) begin
            cur_get_1 <= cur_get_1 + 1;
            // is_not_same_addr0 <= is_not_same_addr1;
            // is_not_same_addr1 <= is_not_same_addr0;
            // x_value0 <= x_value0;
            // x_value1 <= x_value1;

            start_addr0 <= temp_addr0;
            start_addr1 <= temp_addr1;
            temp_addr0 <= start_addr0;
            temp_addr1 <= start_addr1;
        end
        else if(!get_1_done) begin
            cur_get_1 <= cur_get_1 + 1;
            start_addr0 <= start_addr0 + 1;
            start_addr1 <= start_addr1 + 1;
        end
    end
    else begin
        calculate_counter <= 0;
    end
end

// pipeline control signal
reg not_same_addr_data_sort;
reg [2:0] x_value_data_sort;
reg [3:0] fraction_x, fraction_y;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        not_same_addr_data_sort <= 1'b0;
    end
    else if((counter_after_data_out % 6) == 4) begin
        not_same_addr_data_sort <= is_not_same_addr1;
    end
    else if((counter_after_data_out % 3) == 1) begin
        not_same_addr_data_sort <= is_not_same_addr0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_value_data_sort <= 3'd0;
        fraction_x <= 4'd0;
        fraction_y <= 4'd0;
    end
    else if((counter_after_data_out % 6) == 5) begin
        x_value_data_sort <= x_value1;
        fraction_x <= fraction1x;
        fraction_y <= fraction1y;
    end
    else if((counter_after_data_out % 3) == 2) begin
        x_value_data_sort <= x_value0;
        fraction_x <= fraction0x;
        fraction_y <= fraction0y;
    end
end

// ============================================================
// data out part
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < 8;i = i + 1) begin
            first_pipe_0[i] <= 0;
            first_pipe_1[i] <= 0;
            first_pipe_2[i] <= 0;
            second_pipe_0[i] <= 0;
            second_pipe_1[i] <= 0;
            second_pipe_2[i] <= 0; 
        end
    end
    else begin
        first_pipe_0[0] <= data0_out[0]; first_pipe_0[1] <= data0_out[1]; first_pipe_0[2] <= data0_out[2]; first_pipe_0[3] <= data0_out[3]; first_pipe_0[4] <= data0_out[4]; first_pipe_0[5] <= data0_out[5]; first_pipe_0[6] <= data0_out[6]; first_pipe_0[7] <= data0_out[7]; 
        second_pipe_0[0] <= data1_out[0]; second_pipe_0[1] <= data1_out[1]; second_pipe_0[2] <= data1_out[2]; second_pipe_0[3] <= data1_out[3]; second_pipe_0[4] <= data1_out[4]; second_pipe_0[5] <= data1_out[5]; second_pipe_0[6] <= data1_out[6]; second_pipe_0[7] <= data1_out[7]; 

        if(not_same_addr_data_sort) begin
            first_pipe_1[0] <= second_pipe_0[0]; first_pipe_1[1] <= second_pipe_0[1]; first_pipe_1[2] <= second_pipe_0[2]; first_pipe_1[3] <= second_pipe_0[3]; first_pipe_1[4] <= second_pipe_0[4]; first_pipe_1[5] <= second_pipe_0[5]; first_pipe_1[6] <= second_pipe_0[6]; first_pipe_1[7] <= second_pipe_0[7]; 
            first_pipe_2[0] <= first_pipe_1[0]; first_pipe_2[1] <= first_pipe_1[1]; first_pipe_2[2] <= first_pipe_1[2]; first_pipe_2[3] <= first_pipe_1[3]; first_pipe_2[4] <= first_pipe_1[4]; first_pipe_2[5] <= first_pipe_1[5]; first_pipe_2[6] <= first_pipe_1[6]; first_pipe_2[7] <= first_pipe_1[7]; 

            second_pipe_1[0] <= first_pipe_0[0]; second_pipe_1[1] <= first_pipe_0[1]; second_pipe_1[2] <= first_pipe_0[2]; second_pipe_1[3] <= first_pipe_0[3]; second_pipe_1[4] <= first_pipe_0[4]; second_pipe_1[5] <= first_pipe_0[5]; second_pipe_1[6] <= first_pipe_0[6]; second_pipe_1[7] <= first_pipe_0[7]; 
            second_pipe_2[0] <= second_pipe_1[0]; second_pipe_2[1] <= second_pipe_1[1]; second_pipe_2[2] <= second_pipe_1[2]; second_pipe_2[3] <= second_pipe_1[3]; second_pipe_2[4] <= second_pipe_1[4]; second_pipe_2[5] <= second_pipe_1[5]; second_pipe_2[6] <= second_pipe_1[6]; second_pipe_2[7] <= second_pipe_1[7]; 
        end
        else begin
            first_pipe_1[0] <= first_pipe_0[0]; first_pipe_1[1] <= first_pipe_0[1]; first_pipe_1[2] <= first_pipe_0[2]; first_pipe_1[3] <= first_pipe_0[3]; first_pipe_1[4] <= first_pipe_0[4]; first_pipe_1[5] <= first_pipe_0[5]; first_pipe_1[6] <= first_pipe_0[6]; first_pipe_1[7] <= first_pipe_0[7]; 
            first_pipe_2[0] <= first_pipe_1[0]; first_pipe_2[1] <= first_pipe_1[1]; first_pipe_2[2] <= first_pipe_1[2]; first_pipe_2[3] <= first_pipe_1[3]; first_pipe_2[4] <= first_pipe_1[4]; first_pipe_2[5] <= first_pipe_1[5]; first_pipe_2[6] <= first_pipe_1[6]; first_pipe_2[7] <= first_pipe_1[7]; 

            second_pipe_1[0] <= second_pipe_0[0]; second_pipe_1[1] <= second_pipe_0[1]; second_pipe_1[2] <= second_pipe_0[2]; second_pipe_1[3] <= second_pipe_0[3]; second_pipe_1[4] <= second_pipe_0[4]; second_pipe_1[5] <= second_pipe_0[5]; second_pipe_1[6] <= second_pipe_0[6]; second_pipe_1[7] <= second_pipe_0[7]; 
            second_pipe_2[0] <= second_pipe_1[0]; second_pipe_2[1] <= second_pipe_1[1]; second_pipe_2[2] <= second_pipe_1[2]; second_pipe_2[3] <= second_pipe_1[3]; second_pipe_2[4] <= second_pipe_1[4]; second_pipe_2[5] <= second_pipe_1[5]; second_pipe_2[6] <= second_pipe_1[6]; second_pipe_2[7] <= second_pipe_1[7]; 
        end
    end
end

reg [7:0] actual_matrix5[0:10];
reg [7:0] actual_matrix6[0:10];
reg after_get_data_flag;
reg [3:0] fraction_x_pass, fraction_y_pass;
reg not_same_addr_data_sort_pass;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        after_get_data_flag <= 0;
    end
    else if(counter_after_data_out == 4) begin
        after_get_data_flag <= 1;
    end
    else if(counter_after_data_out == 76) begin
        after_get_data_flag <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fraction_x_pass <= 0;
        fraction_y_pass <= 0;
        not_same_addr_data_sort_pass <= 0;
    end
    else if((counter_after_data_out % 3) == 1) begin
        fraction_x_pass <= fraction_x;
        fraction_y_pass <= fraction_y;
        not_same_addr_data_sort_pass <= not_same_addr_data_sort;
    end
end


reg [3:0] fraction_x_bi, fraction_y_bi;

// get the 11 data needed
// use x_value1 to control
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fraction_x_bi <= 0;
        fraction_y_bi <= 0;
        for(i = 0;i < 11;i = i + 1) begin
            actual_matrix5[i] <= 0;
            actual_matrix6[i] <= 0;
        end
    end
    else if(after_get_data_flag & ((counter_after_data_out % 3) == 2)) begin
        fraction_x_bi <= fraction_x_pass;
        fraction_y_bi <= fraction_y_pass;
        case(x_value_data_sort) // assign actual matrix
            0: begin
                actual_matrix5[ 0] <= first_pipe_2[7];
                actual_matrix5[ 1] <= first_pipe_2[6];
                actual_matrix5[ 2] <= first_pipe_2[5];
                actual_matrix5[ 3] <= first_pipe_2[4];
                actual_matrix5[ 4] <= first_pipe_2[3];
                actual_matrix5[ 5] <= first_pipe_2[2];
                actual_matrix5[ 6] <= first_pipe_2[1];
                actual_matrix5[ 7] <= first_pipe_2[0];
                actual_matrix5[ 8] <= first_pipe_1[7];
                actual_matrix5[ 9] <= first_pipe_1[6];
                actual_matrix5[10] <= first_pipe_1[5];

                actual_matrix6[ 0] <= second_pipe_2[7];
                actual_matrix6[ 1] <= second_pipe_2[6];
                actual_matrix6[ 2] <= second_pipe_2[5];
                actual_matrix6[ 3] <= second_pipe_2[4];
                actual_matrix6[ 4] <= second_pipe_2[3];
                actual_matrix6[ 5] <= second_pipe_2[2];
                actual_matrix6[ 6] <= second_pipe_2[1];
                actual_matrix6[ 7] <= second_pipe_2[0];
                actual_matrix6[ 8] <= second_pipe_1[7];
                actual_matrix6[ 9] <= second_pipe_1[6];
                actual_matrix6[10] <= second_pipe_1[5];
            end
            1: begin
                actual_matrix5[ 0] <= first_pipe_2[6];
                actual_matrix5[ 1] <= first_pipe_2[5];
                actual_matrix5[ 2] <= first_pipe_2[4];
                actual_matrix5[ 3] <= first_pipe_2[3];
                actual_matrix5[ 4] <= first_pipe_2[2];
                actual_matrix5[ 5] <= first_pipe_2[1];
                actual_matrix5[ 6] <= first_pipe_2[0];
                actual_matrix5[ 7] <= first_pipe_1[7];
                actual_matrix5[ 8] <= first_pipe_1[6];
                actual_matrix5[ 9] <= first_pipe_1[5];
                actual_matrix5[10] <= first_pipe_1[4];

                actual_matrix6[ 0] <= second_pipe_2[6];
                actual_matrix6[ 1] <= second_pipe_2[5];
                actual_matrix6[ 2] <= second_pipe_2[4];
                actual_matrix6[ 3] <= second_pipe_2[3];
                actual_matrix6[ 4] <= second_pipe_2[2];
                actual_matrix6[ 5] <= second_pipe_2[1];
                actual_matrix6[ 6] <= second_pipe_2[0];
                actual_matrix6[ 7] <= second_pipe_1[7];
                actual_matrix6[ 8] <= second_pipe_1[6];
                actual_matrix6[ 9] <= second_pipe_1[5];
                actual_matrix6[10] <= second_pipe_1[4];
            end
            2: begin
                actual_matrix5[ 0] <= first_pipe_2[5];
                actual_matrix5[ 1] <= first_pipe_2[4];
                actual_matrix5[ 2] <= first_pipe_2[3];
                actual_matrix5[ 3] <= first_pipe_2[2];
                actual_matrix5[ 4] <= first_pipe_2[1];
                actual_matrix5[ 5] <= first_pipe_2[0];
                actual_matrix5[ 6] <= first_pipe_1[7];
                actual_matrix5[ 7] <= first_pipe_1[6];
                actual_matrix5[ 8] <= first_pipe_1[5];
                actual_matrix5[ 9] <= first_pipe_1[4];
                actual_matrix5[10] <= first_pipe_1[3];

                actual_matrix6[ 0] <= second_pipe_2[5];
                actual_matrix6[ 1] <= second_pipe_2[4];
                actual_matrix6[ 2] <= second_pipe_2[3];
                actual_matrix6[ 3] <= second_pipe_2[2];
                actual_matrix6[ 4] <= second_pipe_2[1];
                actual_matrix6[ 5] <= second_pipe_2[0];
                actual_matrix6[ 6] <= second_pipe_1[7];
                actual_matrix6[ 7] <= second_pipe_1[6];
                actual_matrix6[ 8] <= second_pipe_1[5];
                actual_matrix6[ 9] <= second_pipe_1[4];
                actual_matrix6[10] <= second_pipe_1[3];
            end
            3: begin
                actual_matrix5[ 0] <= first_pipe_2[4];
                actual_matrix5[ 1] <= first_pipe_2[3];
                actual_matrix5[ 2] <= first_pipe_2[2];
                actual_matrix5[ 3] <= first_pipe_2[1];
                actual_matrix5[ 4] <= first_pipe_2[0];
                actual_matrix5[ 5] <= first_pipe_1[7];
                actual_matrix5[ 6] <= first_pipe_1[6];
                actual_matrix5[ 7] <= first_pipe_1[5];
                actual_matrix5[ 8] <= first_pipe_1[4];
                actual_matrix5[ 9] <= first_pipe_1[3];
                actual_matrix5[10] <= first_pipe_1[2];

                actual_matrix6[ 0] <= second_pipe_2[4];
                actual_matrix6[ 1] <= second_pipe_2[3];
                actual_matrix6[ 2] <= second_pipe_2[2];
                actual_matrix6[ 3] <= second_pipe_2[1];
                actual_matrix6[ 4] <= second_pipe_2[0];
                actual_matrix6[ 5] <= second_pipe_1[7];
                actual_matrix6[ 6] <= second_pipe_1[6];
                actual_matrix6[ 7] <= second_pipe_1[5];
                actual_matrix6[ 8] <= second_pipe_1[4];
                actual_matrix6[ 9] <= second_pipe_1[3];
                actual_matrix6[10] <= second_pipe_1[2];
            end
            4: begin
                actual_matrix5[ 0] <= first_pipe_2[3];
                actual_matrix5[ 1] <= first_pipe_2[2];
                actual_matrix5[ 2] <= first_pipe_2[1];
                actual_matrix5[ 3] <= first_pipe_2[0];
                actual_matrix5[ 4] <= first_pipe_1[7];
                actual_matrix5[ 5] <= first_pipe_1[6];
                actual_matrix5[ 6] <= first_pipe_1[5];
                actual_matrix5[ 7] <= first_pipe_1[4];
                actual_matrix5[ 8] <= first_pipe_1[3];
                actual_matrix5[ 9] <= first_pipe_1[2];
                actual_matrix5[10] <= first_pipe_1[1];

                actual_matrix6[ 0] <= second_pipe_2[3];
                actual_matrix6[ 1] <= second_pipe_2[2];
                actual_matrix6[ 2] <= second_pipe_2[1];
                actual_matrix6[ 3] <= second_pipe_2[0];
                actual_matrix6[ 4] <= second_pipe_1[7];
                actual_matrix6[ 5] <= second_pipe_1[6];
                actual_matrix6[ 6] <= second_pipe_1[5];
                actual_matrix6[ 7] <= second_pipe_1[4];
                actual_matrix6[ 8] <= second_pipe_1[3];
                actual_matrix6[ 9] <= second_pipe_1[2];
                actual_matrix6[10] <= second_pipe_1[1];
            end
            5: begin
                actual_matrix5[ 0] <= first_pipe_2[2];
                actual_matrix5[ 1] <= first_pipe_2[1];
                actual_matrix5[ 2] <= first_pipe_2[0];
                actual_matrix5[ 3] <= first_pipe_1[7];
                actual_matrix5[ 4] <= first_pipe_1[6];
                actual_matrix5[ 5] <= first_pipe_1[5];
                actual_matrix5[ 6] <= first_pipe_1[4];
                actual_matrix5[ 7] <= first_pipe_1[3];
                actual_matrix5[ 8] <= first_pipe_1[2];
                actual_matrix5[ 9] <= first_pipe_1[1];
                actual_matrix5[10] <= first_pipe_1[0];

                actual_matrix6[ 0] <= second_pipe_2[2];
                actual_matrix6[ 1] <= second_pipe_2[1];
                actual_matrix6[ 2] <= second_pipe_2[0];
                actual_matrix6[ 3] <= second_pipe_1[7];
                actual_matrix6[ 4] <= second_pipe_1[6];
                actual_matrix6[ 5] <= second_pipe_1[5];
                actual_matrix6[ 6] <= second_pipe_1[4];
                actual_matrix6[ 7] <= second_pipe_1[3];
                actual_matrix6[ 8] <= second_pipe_1[2];
                actual_matrix6[ 9] <= second_pipe_1[1];
                actual_matrix6[10] <= second_pipe_1[0];
            end
            6: begin
                actual_matrix5[ 0] <= first_pipe_2[1];
                actual_matrix5[ 1] <= first_pipe_2[0];
                actual_matrix5[ 2] <= first_pipe_1[7];
                actual_matrix5[ 3] <= first_pipe_1[6];
                actual_matrix5[ 4] <= first_pipe_1[5];
                actual_matrix5[ 5] <= first_pipe_1[4];
                actual_matrix5[ 6] <= first_pipe_1[3];
                actual_matrix5[ 7] <= first_pipe_1[2];
                actual_matrix5[ 8] <= first_pipe_1[1];
                actual_matrix5[ 9] <= first_pipe_1[0];
                actual_matrix5[10] <= (not_same_addr_data_sort_pass)? second_pipe_0[7]: first_pipe_0[7];

                actual_matrix6[ 0] <= second_pipe_2[1];
                actual_matrix6[ 1] <= second_pipe_2[0];
                actual_matrix6[ 2] <= second_pipe_1[7];
                actual_matrix6[ 3] <= second_pipe_1[6];
                actual_matrix6[ 4] <= second_pipe_1[5];
                actual_matrix6[ 5] <= second_pipe_1[4];
                actual_matrix6[ 6] <= second_pipe_1[3];
                actual_matrix6[ 7] <= second_pipe_1[2];
                actual_matrix6[ 8] <= second_pipe_1[1];
                actual_matrix6[ 9] <= second_pipe_1[0];
                actual_matrix6[10] <= (not_same_addr_data_sort_pass)? first_pipe_0[7]: second_pipe_0[7];
            end
            7: begin
                actual_matrix5[ 0] <= first_pipe_2[0];
                actual_matrix5[ 1] <= first_pipe_1[7];
                actual_matrix5[ 2] <= first_pipe_1[6];
                actual_matrix5[ 3] <= first_pipe_1[5];
                actual_matrix5[ 4] <= first_pipe_1[4];
                actual_matrix5[ 5] <= first_pipe_1[3];
                actual_matrix5[ 6] <= first_pipe_1[2];
                actual_matrix5[ 7] <= first_pipe_1[1];
                actual_matrix5[ 8] <= first_pipe_1[0];
                actual_matrix5[ 9] <= (not_same_addr_data_sort_pass)? second_pipe_0[7]: first_pipe_0[7];
                actual_matrix5[10] <= (not_same_addr_data_sort_pass)? second_pipe_0[6]: first_pipe_0[6];

                actual_matrix6[ 0] <= second_pipe_2[0];
                actual_matrix6[ 1] <= second_pipe_1[7];
                actual_matrix6[ 2] <= second_pipe_1[6];
                actual_matrix6[ 3] <= second_pipe_1[5];
                actual_matrix6[ 4] <= second_pipe_1[4];
                actual_matrix6[ 5] <= second_pipe_1[3];
                actual_matrix6[ 6] <= second_pipe_1[2];
                actual_matrix6[ 7] <= second_pipe_1[1];
                actual_matrix6[ 8] <= second_pipe_1[0];
                actual_matrix6[ 9] <= (not_same_addr_data_sort_pass)? first_pipe_0[7]: second_pipe_0[7];
                actual_matrix6[10] <= (not_same_addr_data_sort_pass)? first_pipe_0[6]: second_pipe_0[6];
            end
        endcase
    end
end

reg [11:0] BI_x1[0:9];
reg [11:0] BI_x_last[0:9];
reg [11:0] BI_x_last_l0[0:9];
reg [11:0] BI_x_last_l1[0:9];
reg [15:0] BI_y[0:9];
reg [3:0] fraction_y_last,fraction_y_last_l0,fraction_y_last_l1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < 10;i = i + 1) begin
            BI_x1[i] <= 0;
            BI_y[i] <= 0;
            BI_x_last_l0[i] <= 0;
            BI_x_last_l1[i] <= 0;
        end
        fraction_y_last <= 0;
        fraction_y_last_l0 <= 0;
        fraction_y_last_l1 <= 0;
    end
    else if(counter_after_data_out > 5) begin
        if((counter_after_data_out % 3) == 0) begin
            BI_x1[0] <= (actual_matrix5[0] << 4) + (actual_matrix5[ 1] - actual_matrix5[0]) * fraction_x_bi;
            BI_x1[1] <= (actual_matrix5[1] << 4) + (actual_matrix5[ 2] - actual_matrix5[1]) * fraction_x_bi;
            BI_x1[2] <= (actual_matrix5[2] << 4) + (actual_matrix5[ 3] - actual_matrix5[2]) * fraction_x_bi;
            BI_x1[3] <= (actual_matrix5[3] << 4) + (actual_matrix5[ 4] - actual_matrix5[3]) * fraction_x_bi;
            BI_x1[4] <= (actual_matrix5[4] << 4) + (actual_matrix5[ 5] - actual_matrix5[4]) * fraction_x_bi;
            BI_x1[5] <= (actual_matrix5[5] << 4) + (actual_matrix5[ 6] - actual_matrix5[5]) * fraction_x_bi;
            BI_x1[6] <= (actual_matrix5[6] << 4) + (actual_matrix5[ 7] - actual_matrix5[6]) * fraction_x_bi;
            BI_x1[7] <= (actual_matrix5[7] << 4) + (actual_matrix5[ 8] - actual_matrix5[7]) * fraction_x_bi;
            BI_x1[8] <= (actual_matrix5[8] << 4) + (actual_matrix5[ 9] - actual_matrix5[8]) * fraction_x_bi;
            BI_x1[9] <= (actual_matrix5[9] << 4) + (actual_matrix5[10] - actual_matrix5[9]) * fraction_x_bi;

            for(i = 0;i < 10;i = i + 1) begin
                if((counter_after_data_out % 6) == 0) begin
                    BI_x_last[i] <= BI_x_last_l0[i]; 
                end
                else if((counter_after_data_out % 6) == 3) begin                    
                    BI_x_last[i] <= BI_x_last_l1[i];
                end
            end
            if((counter_after_data_out % 6) == 0) begin
                fraction_y_last <= fraction_y_last_l0; 
            end
            else if((counter_after_data_out % 6) == 3) begin                    
                fraction_y_last <= fraction_y_last_l1; 
            end
        end
        else begin
            BI_x1[0] <= (actual_matrix6[0] << 4) + (actual_matrix6[ 1] - actual_matrix6[0]) * fraction_x_bi;
            BI_x1[1] <= (actual_matrix6[1] << 4) + (actual_matrix6[ 2] - actual_matrix6[1]) * fraction_x_bi;
            BI_x1[2] <= (actual_matrix6[2] << 4) + (actual_matrix6[ 3] - actual_matrix6[2]) * fraction_x_bi;
            BI_x1[3] <= (actual_matrix6[3] << 4) + (actual_matrix6[ 4] - actual_matrix6[3]) * fraction_x_bi;
            BI_x1[4] <= (actual_matrix6[4] << 4) + (actual_matrix6[ 5] - actual_matrix6[4]) * fraction_x_bi;
            BI_x1[5] <= (actual_matrix6[5] << 4) + (actual_matrix6[ 6] - actual_matrix6[5]) * fraction_x_bi;
            BI_x1[6] <= (actual_matrix6[6] << 4) + (actual_matrix6[ 7] - actual_matrix6[6]) * fraction_x_bi;
            BI_x1[7] <= (actual_matrix6[7] << 4) + (actual_matrix6[ 8] - actual_matrix6[7]) * fraction_x_bi;
            BI_x1[8] <= (actual_matrix6[8] << 4) + (actual_matrix6[ 9] - actual_matrix6[8]) * fraction_x_bi;
            BI_x1[9] <= (actual_matrix6[9] << 4) + (actual_matrix6[10] - actual_matrix6[9]) * fraction_x_bi;

            BI_y[0] <= (BI_x_last[0] << 4) + (BI_x1[0] - BI_x_last[0]) * fraction_y_last;
            BI_y[1] <= (BI_x_last[1] << 4) + (BI_x1[1] - BI_x_last[1]) * fraction_y_last;
            BI_y[2] <= (BI_x_last[2] << 4) + (BI_x1[2] - BI_x_last[2]) * fraction_y_last;
            BI_y[3] <= (BI_x_last[3] << 4) + (BI_x1[3] - BI_x_last[3]) * fraction_y_last;
            BI_y[4] <= (BI_x_last[4] << 4) + (BI_x1[4] - BI_x_last[4]) * fraction_y_last;
            BI_y[5] <= (BI_x_last[5] << 4) + (BI_x1[5] - BI_x_last[5]) * fraction_y_last;
            BI_y[6] <= (BI_x_last[6] << 4) + (BI_x1[6] - BI_x_last[6]) * fraction_y_last;
            BI_y[7] <= (BI_x_last[7] << 4) + (BI_x1[7] - BI_x_last[7]) * fraction_y_last;
            BI_y[8] <= (BI_x_last[8] << 4) + (BI_x1[8] - BI_x_last[8]) * fraction_y_last;
            BI_y[9] <= (BI_x_last[9] << 4) + (BI_x1[9] - BI_x_last[9]) * fraction_y_last;

            for(i = 0;i < 10;i = i + 1) begin
                if((counter_after_data_out % 6) == 2) begin
                    BI_x_last_l0[i] <= BI_x1[i]; 
                end
                else if((counter_after_data_out % 6) == 5) begin                    
                    BI_x_last_l1[i] <= BI_x1[i]; 
                end
                BI_x_last[i] <= BI_x1[i];
            end
            if((counter_after_data_out % 6) == 2) begin
                fraction_y_last_l0 <= fraction_y_bi; 
            end
            else if((counter_after_data_out % 6) == 5) begin                    
                fraction_y_last_l1 <= fraction_y_bi; 
            end
            fraction_y_last <= fraction_y_bi; 
        end
    end
    else if(done_point2)begin // need comment
        for(i = 0;i < 10;i = i + 1) begin
            BI_x1[i] <= 0;
            BI_x_last[i] <= 0;
            BI_y[i] <= 0;
            fraction_y_last <= 0;
            fraction_y_last_l0 <= 0;
            fraction_y_last_l1 <= 0;
        end
    end
end

// start calculate sad
reg [15:0] BI0_buffer0[0:9]; // last number means the time to delete
reg [15:0] BI0_buffer1[0:9];
reg [15:0] BI0_buffer2[0:9]; 
reg [15:0] BI0_buffer3[0:9]; 
reg [15:0] BI1_buffer0[0:9];
reg [15:0] BI1_buffer1[0:9];
reg [21:0] sad[0:8];

reg [15:0] sad_temp0[0:7];
reg [15:0] sad_temp1[0:7];
reg [15:0] sad_temp2[0:7];
reg [15:0] sad_temp3[0:7];
reg [15:0] sad_temp4[0:7];
reg [15:0] sad_temp5[0:7];
reg [15:0] sad_temp6[0:7];
reg [15:0] sad_temp7[0:7];
reg [15:0] sad_temp8[0:7];

reg start_sad_buffer;
reg start_sad_cal;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_sad_buffer <= 1'b0;
    end
    else if(counter_after_data_out == 11) begin
        start_sad_buffer <= 1'b1;
    end
    else if(done_point2) begin
        start_sad_buffer <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < 10;i = i + 1) begin
            BI1_buffer1[i] <= 0;
            BI1_buffer0[i] <= 0;
        end
        for(i = 0;i < 10;i = i + 1) begin
            BI0_buffer3[i] <= 0;
            BI0_buffer2[i] <= 0;
            BI0_buffer1[i] <= 0;
            BI0_buffer0[i] <= 0;
        end
    end
    else if(counter_after_data_out == 10) begin
        for(i = 0;i < 10;i = i + 1) begin
            BI0_buffer3[i] <= BI_y[i];
        end
    end
    else if(start_sad_buffer) begin
        if((counter_after_data_out % 6 == 5) | (counter_after_data_out % 6 == 1)) begin
            for(i = 0;i < 10;i = i + 1) begin
                BI1_buffer1[i] <= BI_y[i];
                BI1_buffer0[i] <= BI1_buffer1[i];
            end
        end
        else if((counter_after_data_out % 6 == 2) | (counter_after_data_out % 6 == 3)) begin
            for(i = 0;i < 10;i = i + 1) begin
                BI0_buffer3[i] <= BI_y[i];
                BI0_buffer2[i] <= BI0_buffer3[i];
                BI0_buffer1[i] <= BI0_buffer2[i];
                BI0_buffer0[i] <= BI0_buffer1[i];
            end
        end
    end 
    else if(done_point2) begin // need comment
        for(i = 0;i < 10;i = i + 1) begin
            BI1_buffer1[i] <= 0;
            BI1_buffer0[i] <= 0;
        end
        for(i = 0;i < 10;i = i + 1) begin
            BI0_buffer3[i] <= 0;
            BI0_buffer2[i] <= 0;
            BI0_buffer1[i] <= 0;
            BI0_buffer0[i] <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_sad_cal <= 1'b0;
    end
    else if(counter_after_data_out == 15) begin
        start_sad_cal <= 1'b1;
    end
    else if(counter_after_data_out == 41) begin
        start_sad_cal <= 1'b0;
    end
    else if(counter_after_data_out == 51) begin
        start_sad_cal <= 1'b1;
    end
    else if(counter_after_data_out == 77) begin
        start_sad_cal <= 1'b0;
    end
end

always @(*) begin
    if((counter_after_data_out % 6) == 3) begin
        sad_temp2[0] = (BI0_buffer3[0] < BI1_buffer0[2])? BI1_buffer0[2] - BI0_buffer3[0]: BI0_buffer3[0] - BI1_buffer0[2];
        sad_temp2[1] = (BI0_buffer3[1] < BI1_buffer0[3])? BI1_buffer0[3] - BI0_buffer3[1]: BI0_buffer3[1] - BI1_buffer0[3];
        sad_temp2[2] = (BI0_buffer3[2] < BI1_buffer0[4])? BI1_buffer0[4] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer0[4];
        sad_temp2[3] = (BI0_buffer3[3] < BI1_buffer0[5])? BI1_buffer0[5] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer0[5];
        sad_temp2[4] = (BI0_buffer3[4] < BI1_buffer0[6])? BI1_buffer0[6] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer0[6];
        sad_temp2[5] = (BI0_buffer3[5] < BI1_buffer0[7])? BI1_buffer0[7] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer0[7];
        sad_temp2[6] = (BI0_buffer3[6] < BI1_buffer0[8])? BI1_buffer0[8] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer0[8];
        sad_temp2[7] = (BI0_buffer3[7] < BI1_buffer0[9])? BI1_buffer0[9] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer0[9];

        sad_temp5[0] = (BI0_buffer3[1] < BI1_buffer0[1])? BI1_buffer0[1] - BI0_buffer3[1]: BI0_buffer3[1] - BI1_buffer0[1];
        sad_temp5[1] = (BI0_buffer3[2] < BI1_buffer0[2])? BI1_buffer0[2] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer0[2];
        sad_temp5[2] = (BI0_buffer3[3] < BI1_buffer0[3])? BI1_buffer0[3] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer0[3];
        sad_temp5[3] = (BI0_buffer3[4] < BI1_buffer0[4])? BI1_buffer0[4] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer0[4];
        sad_temp5[4] = (BI0_buffer3[5] < BI1_buffer0[5])? BI1_buffer0[5] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer0[5];
        sad_temp5[5] = (BI0_buffer3[6] < BI1_buffer0[6])? BI1_buffer0[6] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer0[6];
        sad_temp5[6] = (BI0_buffer3[7] < BI1_buffer0[7])? BI1_buffer0[7] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer0[7];
        sad_temp5[7] = (BI0_buffer3[8] < BI1_buffer0[8])? BI1_buffer0[8] - BI0_buffer3[8]: BI0_buffer3[8] - BI1_buffer0[8];

        sad_temp8[0] = (BI0_buffer3[2] < BI1_buffer0[0])? BI1_buffer0[0] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer0[0];
        sad_temp8[1] = (BI0_buffer3[3] < BI1_buffer0[1])? BI1_buffer0[1] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer0[1];
        sad_temp8[2] = (BI0_buffer3[4] < BI1_buffer0[2])? BI1_buffer0[2] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer0[2];
        sad_temp8[3] = (BI0_buffer3[5] < BI1_buffer0[3])? BI1_buffer0[3] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer0[3];
        sad_temp8[4] = (BI0_buffer3[6] < BI1_buffer0[4])? BI1_buffer0[4] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer0[4];
        sad_temp8[5] = (BI0_buffer3[7] < BI1_buffer0[5])? BI1_buffer0[5] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer0[5];
        sad_temp8[6] = (BI0_buffer3[8] < BI1_buffer0[6])? BI1_buffer0[6] - BI0_buffer3[8]: BI0_buffer3[8] - BI1_buffer0[6];
        sad_temp8[7] = (BI0_buffer3[9] < BI1_buffer0[7])? BI1_buffer0[7] - BI0_buffer3[9]: BI0_buffer3[9] - BI1_buffer0[7];
    end
    else begin // counter_after_data_out % 6 == 4
        sad_temp2[0] = (BI0_buffer3[0] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer3[0]: BI0_buffer3[0] - BI1_buffer1[2];
        sad_temp2[1] = (BI0_buffer3[1] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer3[1]: BI0_buffer3[1] - BI1_buffer1[3];
        sad_temp2[2] = (BI0_buffer3[2] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer1[4];
        sad_temp2[3] = (BI0_buffer3[3] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer1[5];
        sad_temp2[4] = (BI0_buffer3[4] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer1[6];
        sad_temp2[5] = (BI0_buffer3[5] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer1[7];
        sad_temp2[6] = (BI0_buffer3[6] < BI1_buffer1[8])? BI1_buffer1[8] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer1[8];
        sad_temp2[7] = (BI0_buffer3[7] < BI1_buffer1[9])? BI1_buffer1[9] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer1[9];

        sad_temp5[0] = (BI0_buffer3[1] < BI1_buffer1[1])? BI1_buffer1[1] - BI0_buffer3[1]: BI0_buffer3[1] - BI1_buffer1[1];
        sad_temp5[1] = (BI0_buffer3[2] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer1[2];
        sad_temp5[2] = (BI0_buffer3[3] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer1[3];
        sad_temp5[3] = (BI0_buffer3[4] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer1[4];
        sad_temp5[4] = (BI0_buffer3[5] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer1[5];
        sad_temp5[5] = (BI0_buffer3[6] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer1[6];
        sad_temp5[6] = (BI0_buffer3[7] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer1[7];
        sad_temp5[7] = (BI0_buffer3[8] < BI1_buffer1[8])? BI1_buffer1[8] - BI0_buffer3[8]: BI0_buffer3[8] - BI1_buffer1[8];

        sad_temp8[0] = (BI0_buffer3[2] < BI1_buffer1[0])? BI1_buffer1[0] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer1[0];
        sad_temp8[1] = (BI0_buffer3[3] < BI1_buffer1[1])? BI1_buffer1[1] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer1[1];
        sad_temp8[2] = (BI0_buffer3[4] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer1[2];
        sad_temp8[3] = (BI0_buffer3[5] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer1[3];
        sad_temp8[4] = (BI0_buffer3[6] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer1[4];
        sad_temp8[5] = (BI0_buffer3[7] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer1[5];
        sad_temp8[6] = (BI0_buffer3[8] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer3[8]: BI0_buffer3[8] - BI1_buffer1[6];
        sad_temp8[7] = (BI0_buffer3[9] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer3[9]: BI0_buffer3[9] - BI1_buffer1[7];
    end
end

always @(*) begin
    if((counter_after_data_out % 6) == 0) begin
        sad_temp1[0] = (BI0_buffer2[0] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer2[0]: BI0_buffer2[0] - BI1_buffer1[2];
        sad_temp1[1] = (BI0_buffer2[1] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer2[1]: BI0_buffer2[1] - BI1_buffer1[3];
        sad_temp1[2] = (BI0_buffer2[2] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer2[2]: BI0_buffer2[2] - BI1_buffer1[4];
        sad_temp1[3] = (BI0_buffer2[3] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer2[3]: BI0_buffer2[3] - BI1_buffer1[5];
        sad_temp1[4] = (BI0_buffer2[4] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer2[4]: BI0_buffer2[4] - BI1_buffer1[6];
        sad_temp1[5] = (BI0_buffer2[5] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer2[5]: BI0_buffer2[5] - BI1_buffer1[7];
        sad_temp1[6] = (BI0_buffer2[6] < BI1_buffer1[8])? BI1_buffer1[8] - BI0_buffer2[6]: BI0_buffer2[6] - BI1_buffer1[8];
        sad_temp1[7] = (BI0_buffer2[7] < BI1_buffer1[9])? BI1_buffer1[9] - BI0_buffer2[7]: BI0_buffer2[7] - BI1_buffer1[9];

        sad_temp4[0] = (BI0_buffer2[1] < BI1_buffer1[1])? BI1_buffer1[1] - BI0_buffer2[1]: BI0_buffer2[1] - BI1_buffer1[1];
        sad_temp4[1] = (BI0_buffer2[2] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer2[2]: BI0_buffer2[2] - BI1_buffer1[2];
        sad_temp4[2] = (BI0_buffer2[3] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer2[3]: BI0_buffer2[3] - BI1_buffer1[3];
        sad_temp4[3] = (BI0_buffer2[4] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer2[4]: BI0_buffer2[4] - BI1_buffer1[4];
        sad_temp4[4] = (BI0_buffer2[5] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer2[5]: BI0_buffer2[5] - BI1_buffer1[5];
        sad_temp4[5] = (BI0_buffer2[6] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer2[6]: BI0_buffer2[6] - BI1_buffer1[6];
        sad_temp4[6] = (BI0_buffer2[7] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer2[7]: BI0_buffer2[7] - BI1_buffer1[7];
        sad_temp4[7] = (BI0_buffer2[8] < BI1_buffer1[8])? BI1_buffer1[8] - BI0_buffer2[8]: BI0_buffer2[8] - BI1_buffer1[8];

        sad_temp7[0] = (BI0_buffer2[2] < BI1_buffer1[0])? BI1_buffer1[0] - BI0_buffer2[2]: BI0_buffer2[2] - BI1_buffer1[0];
        sad_temp7[1] = (BI0_buffer2[3] < BI1_buffer1[1])? BI1_buffer1[1] - BI0_buffer2[3]: BI0_buffer2[3] - BI1_buffer1[1];
        sad_temp7[2] = (BI0_buffer2[4] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer2[4]: BI0_buffer2[4] - BI1_buffer1[2];
        sad_temp7[3] = (BI0_buffer2[5] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer2[5]: BI0_buffer2[5] - BI1_buffer1[3];
        sad_temp7[4] = (BI0_buffer2[6] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer2[6]: BI0_buffer2[6] - BI1_buffer1[4];
        sad_temp7[5] = (BI0_buffer2[7] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer2[7]: BI0_buffer2[7] - BI1_buffer1[5];
        sad_temp7[6] = (BI0_buffer2[8] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer2[8]: BI0_buffer2[8] - BI1_buffer1[6];
        sad_temp7[7] = (BI0_buffer2[9] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer2[9]: BI0_buffer2[9] - BI1_buffer1[7];
    end
    else begin // counter_after_data_out % 6 == 2
        sad_temp1[0] = (BI0_buffer3[0] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer3[0]: BI0_buffer3[0] - BI1_buffer1[2];
        sad_temp1[1] = (BI0_buffer3[1] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer3[1]: BI0_buffer3[1] - BI1_buffer1[3];
        sad_temp1[2] = (BI0_buffer3[2] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer1[4];
        sad_temp1[3] = (BI0_buffer3[3] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer1[5];
        sad_temp1[4] = (BI0_buffer3[4] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer1[6];
        sad_temp1[5] = (BI0_buffer3[5] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer1[7];
        sad_temp1[6] = (BI0_buffer3[6] < BI1_buffer1[8])? BI1_buffer1[8] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer1[8];
        sad_temp1[7] = (BI0_buffer3[7] < BI1_buffer1[9])? BI1_buffer1[9] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer1[9];

        sad_temp4[0] = (BI0_buffer3[1] < BI1_buffer1[1])? BI1_buffer1[1] - BI0_buffer3[1]: BI0_buffer3[1] - BI1_buffer1[1];
        sad_temp4[1] = (BI0_buffer3[2] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer1[2];
        sad_temp4[2] = (BI0_buffer3[3] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer1[3];
        sad_temp4[3] = (BI0_buffer3[4] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer1[4];
        sad_temp4[4] = (BI0_buffer3[5] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer1[5];
        sad_temp4[5] = (BI0_buffer3[6] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer1[6];
        sad_temp4[6] = (BI0_buffer3[7] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer1[7];
        sad_temp4[7] = (BI0_buffer3[8] < BI1_buffer1[8])? BI1_buffer1[8] - BI0_buffer3[8]: BI0_buffer3[8] - BI1_buffer1[8];

        sad_temp7[0] = (BI0_buffer3[2] < BI1_buffer1[0])? BI1_buffer1[0] - BI0_buffer3[2]: BI0_buffer3[2] - BI1_buffer1[0];
        sad_temp7[1] = (BI0_buffer3[3] < BI1_buffer1[1])? BI1_buffer1[1] - BI0_buffer3[3]: BI0_buffer3[3] - BI1_buffer1[1];
        sad_temp7[2] = (BI0_buffer3[4] < BI1_buffer1[2])? BI1_buffer1[2] - BI0_buffer3[4]: BI0_buffer3[4] - BI1_buffer1[2];
        sad_temp7[3] = (BI0_buffer3[5] < BI1_buffer1[3])? BI1_buffer1[3] - BI0_buffer3[5]: BI0_buffer3[5] - BI1_buffer1[3];
        sad_temp7[4] = (BI0_buffer3[6] < BI1_buffer1[4])? BI1_buffer1[4] - BI0_buffer3[6]: BI0_buffer3[6] - BI1_buffer1[4];
        sad_temp7[5] = (BI0_buffer3[7] < BI1_buffer1[5])? BI1_buffer1[5] - BI0_buffer3[7]: BI0_buffer3[7] - BI1_buffer1[5];
        sad_temp7[6] = (BI0_buffer3[8] < BI1_buffer1[6])? BI1_buffer1[6] - BI0_buffer3[8]: BI0_buffer3[8] - BI1_buffer1[6];
        sad_temp7[7] = (BI0_buffer3[9] < BI1_buffer1[7])? BI1_buffer1[7] - BI0_buffer3[9]: BI0_buffer3[9] - BI1_buffer1[7];
    end

end

always @(*) begin
    if((counter_after_data_out % 6) == 5) begin
        sad_temp0[0] = (BI0_buffer0[0] < BI_y[2])? BI_y[2] - BI0_buffer0[0]: BI0_buffer0[0] - BI_y[2];
        sad_temp0[1] = (BI0_buffer0[1] < BI_y[3])? BI_y[3] - BI0_buffer0[1]: BI0_buffer0[1] - BI_y[3];
        sad_temp0[2] = (BI0_buffer0[2] < BI_y[4])? BI_y[4] - BI0_buffer0[2]: BI0_buffer0[2] - BI_y[4];
        sad_temp0[3] = (BI0_buffer0[3] < BI_y[5])? BI_y[5] - BI0_buffer0[3]: BI0_buffer0[3] - BI_y[5];
        sad_temp0[4] = (BI0_buffer0[4] < BI_y[6])? BI_y[6] - BI0_buffer0[4]: BI0_buffer0[4] - BI_y[6];
        sad_temp0[5] = (BI0_buffer0[5] < BI_y[7])? BI_y[7] - BI0_buffer0[5]: BI0_buffer0[5] - BI_y[7];
        sad_temp0[6] = (BI0_buffer0[6] < BI_y[8])? BI_y[8] - BI0_buffer0[6]: BI0_buffer0[6] - BI_y[8];
        sad_temp0[7] = (BI0_buffer0[7] < BI_y[9])? BI_y[9] - BI0_buffer0[7]: BI0_buffer0[7] - BI_y[9];

        sad_temp3[0] = (BI0_buffer0[1] < BI_y[1])? BI_y[1] - BI0_buffer0[1]: BI0_buffer0[1] - BI_y[1];
        sad_temp3[1] = (BI0_buffer0[2] < BI_y[2])? BI_y[2] - BI0_buffer0[2]: BI0_buffer0[2] - BI_y[2];
        sad_temp3[2] = (BI0_buffer0[3] < BI_y[3])? BI_y[3] - BI0_buffer0[3]: BI0_buffer0[3] - BI_y[3];
        sad_temp3[3] = (BI0_buffer0[4] < BI_y[4])? BI_y[4] - BI0_buffer0[4]: BI0_buffer0[4] - BI_y[4];
        sad_temp3[4] = (BI0_buffer0[5] < BI_y[5])? BI_y[5] - BI0_buffer0[5]: BI0_buffer0[5] - BI_y[5];
        sad_temp3[5] = (BI0_buffer0[6] < BI_y[6])? BI_y[6] - BI0_buffer0[6]: BI0_buffer0[6] - BI_y[6];
        sad_temp3[6] = (BI0_buffer0[7] < BI_y[7])? BI_y[7] - BI0_buffer0[7]: BI0_buffer0[7] - BI_y[7];
        sad_temp3[7] = (BI0_buffer0[8] < BI_y[8])? BI_y[8] - BI0_buffer0[8]: BI0_buffer0[8] - BI_y[8];

        sad_temp6[0] = (BI0_buffer0[2] < BI_y[0])? BI_y[0] - BI0_buffer0[2]: BI0_buffer0[2] - BI_y[0];
        sad_temp6[1] = (BI0_buffer0[3] < BI_y[1])? BI_y[1] - BI0_buffer0[3]: BI0_buffer0[3] - BI_y[1];
        sad_temp6[2] = (BI0_buffer0[4] < BI_y[2])? BI_y[2] - BI0_buffer0[4]: BI0_buffer0[4] - BI_y[2];
        sad_temp6[3] = (BI0_buffer0[5] < BI_y[3])? BI_y[3] - BI0_buffer0[5]: BI0_buffer0[5] - BI_y[3];
        sad_temp6[4] = (BI0_buffer0[6] < BI_y[4])? BI_y[4] - BI0_buffer0[6]: BI0_buffer0[6] - BI_y[4];
        sad_temp6[5] = (BI0_buffer0[7] < BI_y[5])? BI_y[5] - BI0_buffer0[7]: BI0_buffer0[7] - BI_y[5];
        sad_temp6[6] = (BI0_buffer0[8] < BI_y[6])? BI_y[6] - BI0_buffer0[8]: BI0_buffer0[8] - BI_y[6];
        sad_temp6[7] = (BI0_buffer0[9] < BI_y[7])? BI_y[7] - BI0_buffer0[9]: BI0_buffer0[9] - BI_y[7];    
    end
    else begin // counter_after_data_out % 6 == 1
        sad_temp0[0] = (BI0_buffer1[0] < BI_y[2])? BI_y[2] - BI0_buffer1[0]: BI0_buffer1[0] - BI_y[2];
        sad_temp0[1] = (BI0_buffer1[1] < BI_y[3])? BI_y[3] - BI0_buffer1[1]: BI0_buffer1[1] - BI_y[3];
        sad_temp0[2] = (BI0_buffer1[2] < BI_y[4])? BI_y[4] - BI0_buffer1[2]: BI0_buffer1[2] - BI_y[4];
        sad_temp0[3] = (BI0_buffer1[3] < BI_y[5])? BI_y[5] - BI0_buffer1[3]: BI0_buffer1[3] - BI_y[5];
        sad_temp0[4] = (BI0_buffer1[4] < BI_y[6])? BI_y[6] - BI0_buffer1[4]: BI0_buffer1[4] - BI_y[6];
        sad_temp0[5] = (BI0_buffer1[5] < BI_y[7])? BI_y[7] - BI0_buffer1[5]: BI0_buffer1[5] - BI_y[7];
        sad_temp0[6] = (BI0_buffer1[6] < BI_y[8])? BI_y[8] - BI0_buffer1[6]: BI0_buffer1[6] - BI_y[8];
        sad_temp0[7] = (BI0_buffer1[7] < BI_y[9])? BI_y[9] - BI0_buffer1[7]: BI0_buffer1[7] - BI_y[9];

        sad_temp3[0] = (BI0_buffer1[1] < BI_y[1])? BI_y[1] - BI0_buffer1[1]: BI0_buffer1[1] - BI_y[1];
        sad_temp3[1] = (BI0_buffer1[2] < BI_y[2])? BI_y[2] - BI0_buffer1[2]: BI0_buffer1[2] - BI_y[2];
        sad_temp3[2] = (BI0_buffer1[3] < BI_y[3])? BI_y[3] - BI0_buffer1[3]: BI0_buffer1[3] - BI_y[3];
        sad_temp3[3] = (BI0_buffer1[4] < BI_y[4])? BI_y[4] - BI0_buffer1[4]: BI0_buffer1[4] - BI_y[4];
        sad_temp3[4] = (BI0_buffer1[5] < BI_y[5])? BI_y[5] - BI0_buffer1[5]: BI0_buffer1[5] - BI_y[5];
        sad_temp3[5] = (BI0_buffer1[6] < BI_y[6])? BI_y[6] - BI0_buffer1[6]: BI0_buffer1[6] - BI_y[6];
        sad_temp3[6] = (BI0_buffer1[7] < BI_y[7])? BI_y[7] - BI0_buffer1[7]: BI0_buffer1[7] - BI_y[7];
        sad_temp3[7] = (BI0_buffer1[8] < BI_y[8])? BI_y[8] - BI0_buffer1[8]: BI0_buffer1[8] - BI_y[8];

        sad_temp6[0] = (BI0_buffer1[2] < BI_y[0])? BI_y[0] - BI0_buffer1[2]: BI0_buffer1[2] - BI_y[0];
        sad_temp6[1] = (BI0_buffer1[3] < BI_y[1])? BI_y[1] - BI0_buffer1[3]: BI0_buffer1[3] - BI_y[1];
        sad_temp6[2] = (BI0_buffer1[4] < BI_y[2])? BI_y[2] - BI0_buffer1[4]: BI0_buffer1[4] - BI_y[2];
        sad_temp6[3] = (BI0_buffer1[5] < BI_y[3])? BI_y[3] - BI0_buffer1[5]: BI0_buffer1[5] - BI_y[3];
        sad_temp6[4] = (BI0_buffer1[6] < BI_y[4])? BI_y[4] - BI0_buffer1[6]: BI0_buffer1[6] - BI_y[4];
        sad_temp6[5] = (BI0_buffer1[7] < BI_y[5])? BI_y[5] - BI0_buffer1[7]: BI0_buffer1[7] - BI_y[5];
        sad_temp6[6] = (BI0_buffer1[8] < BI_y[6])? BI_y[6] - BI0_buffer1[8]: BI0_buffer1[8] - BI_y[6];
        sad_temp6[7] = (BI0_buffer1[9] < BI_y[7])? BI_y[7] - BI0_buffer1[9]: BI0_buffer1[9] - BI_y[7];
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < 9;i = i + 1) begin
            sad[i] <= 0;
        end
    end
    else if(start_sad_cal) begin
        if((counter_after_data_out == 17) | (counter_after_data_out == 53)) begin
            sad[0] <= 0;
            sad[3] <= 0;
            sad[6] <= 0;
        end
        else if((counter_after_data_out == 40) | (counter_after_data_out == 76)) begin
            sad[2] <= sad[2];
            sad[5] <= sad[5];
            sad[8] <= sad[8];
        end
        else if((counter_after_data_out % 6 == 0) | (counter_after_data_out % 6 == 2)) begin
            sad[1] <= sad_temp1[0] + sad_temp1[1] + sad_temp1[2] + sad_temp1[3] + sad_temp1[4] + sad_temp1[5] + sad_temp1[6] + sad_temp1[7] + sad[1];
            sad[4] <= sad_temp4[0] + sad_temp4[1] + sad_temp4[2] + sad_temp4[3] + sad_temp4[4] + sad_temp4[5] + sad_temp4[6] + sad_temp4[7] + sad[4];
            sad[7] <= sad_temp7[0] + sad_temp7[1] + sad_temp7[2] + sad_temp7[3] + sad_temp7[4] + sad_temp7[5] + sad_temp7[6] + sad_temp7[7] + sad[7];
        end
        else if((counter_after_data_out % 6 == 3) | (counter_after_data_out % 6 == 4)) begin
            sad[2] <= sad_temp2[0] + sad_temp2[1] + sad_temp2[2] + sad_temp2[3] + sad_temp2[4] + sad_temp2[5] + sad_temp2[6] + sad_temp2[7] + sad[2];
            sad[5] <= sad_temp5[0] + sad_temp5[1] + sad_temp5[2] + sad_temp5[3] + sad_temp5[4] + sad_temp5[5] + sad_temp5[6] + sad_temp5[7] + sad[5];
            sad[8] <= sad_temp8[0] + sad_temp8[1] + sad_temp8[2] + sad_temp8[3] + sad_temp8[4] + sad_temp8[5] + sad_temp8[6] + sad_temp8[7] + sad[8];
        end
        else begin // counter_after_data_out % 6 == 5 or 1
            sad[0] <= sad_temp0[0] + sad_temp0[1] + sad_temp0[2] + sad_temp0[3] + sad_temp0[4] + sad_temp0[5] + sad_temp0[6] + sad_temp0[7] + sad[0];
            sad[3] <= sad_temp3[0] + sad_temp3[1] + sad_temp3[2] + sad_temp3[3] + sad_temp3[4] + sad_temp3[5] + sad_temp3[6] + sad_temp3[7] + sad[3];
            sad[6] <= sad_temp6[0] + sad_temp6[1] + sad_temp6[2] + sad_temp6[3] + sad_temp6[4] + sad_temp6[5] + sad_temp6[6] + sad_temp6[7] + sad[6];
        end
    end
    // else if(counter_after_data_out == 42) begin // stall for sort
    //     for(i = 0;i < 9;i = i + 1) begin
    //         sad[i] <= sad[i];
    //     end
    // end
    else begin
        for(i = 0;i < 9;i = i + 1) begin
            sad[i] <= 0;
        end
    end
end

reg [27:0] min_point1_012, min_point1_345, min_point1_678;
reg [27:0] min_point1_012_prev, min_point1_345_prev, min_point1_678_prev;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        min_point1_012_prev <= 0;
        min_point1_345_prev <= 0;
        min_point1_678_prev <= 0;
    end
    else begin
        min_point1_012_prev <= min_point1_012;
        min_point1_345_prev <= min_point1_345;
        min_point1_678_prev <= min_point1_678; 
    end
end

always @(*) begin
    if(sad[1] > sad[2]) begin
        if(sad[0] > sad[2]) begin
            min_point1_012 = {4'h2,2'b00,sad[2]};
        end
        else begin
            min_point1_012 = {4'h0,2'b00,sad[0]};
        end
    end
    else begin
        if(sad[0] > sad[1]) begin
            min_point1_012 = {4'h1,2'b00,sad[1]};
        end
        else begin
            min_point1_012 = {4'h0,2'b00,sad[0]};
        end
    end

    if(sad[4] > sad[5]) begin
        if(sad[3] > sad[5]) begin
            min_point1_345 = {4'h5,2'b00,sad[5]};
        end
        else begin
            min_point1_345 = {4'h3,2'b00,sad[3]};
        end
    end
    else begin
        if(sad[3] > sad[4]) begin
            min_point1_345 = {4'h4,2'b00,sad[4]};
        end
        else begin
            min_point1_345 = {4'h3,2'b00,sad[3]};
        end
    end

    if(sad[7] > sad[8]) begin
        if(sad[6] > sad[8]) begin
            min_point1_678 = {4'h8,2'b00,sad[8]};
        end
        else begin
            min_point1_678 = {4'h6,2'b00,sad[6]};
        end
    end
    else begin
        if(sad[6] > sad[7]) begin
            min_point1_678 = {4'h7,2'b00,sad[7]};
        end
        else begin
            min_point1_678 = {4'h6,2'b00,sad[6]};
        end
    end
end


reg [4:0] counter_output;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        done_point1 <= 1'b0;
    end
    else if(counter_after_data_out == 43) begin
        done_point1 <= 1'b1;
    end
    else if(counter_output == 27) begin
        done_point1 <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        done_point2 <= 1'b0;
    end
    else if(counter_after_data_out == 79) begin
        done_point2 <= 1'b1;
    end
    else if(counter_output == 27) begin
        done_point2 <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        min_point1 <= 0;
    end
    else if((counter_after_data_out == 43) | (counter_after_data_out == 79)) begin
        // pretend min is 036
        if(min_point1_345_prev[21:0] > min_point1_678_prev[21:0]) begin
            if(min_point1_012_prev[21:0] > min_point1_678_prev[21:0]) begin
                min_point1 <= min_point1_678_prev;
            end
            else begin
                min_point1 <= min_point1_012_prev;
            end
        end
        else begin
            if(min_point1_012_prev[21:0] > min_point1_345_prev[21:0]) begin
                min_point1 <= min_point1_345_prev;
            end
            else begin
                min_point1 <= min_point1_012_prev;
            end
        end
    end
    else if((counter_after_data_out > 51) | done_point2) begin
        min_point1 <= min_point1 >> 1; 
    end
    else if(done_point1) begin
        min_point1 <= min_point1;
    end
    else begin
        min_point1 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_output <= 5'd0;
    end
    else if(counter_output == 28) begin
        counter_output <= 5'd0;
    end
    else if(done_point2) begin
        counter_output <= counter_output + 1;
    end
end

// ===================================
// output  
// ===================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_sad <= 1'b0;
        out_valid <= 1'b0;
    end
    else if((counter_after_data_out > 51) | done_point2) begin
        out_sad <= min_point1[0];
        out_valid <= 1'b1;
    end
    else begin
        out_sad <= 1'b0;
        out_valid <= 1'b0;
    end
end

endmodule