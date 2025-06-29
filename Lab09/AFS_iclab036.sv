//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/4
//		Version		: v1.0
//   	File Name   : AFS.sv
//   	Module Name : AFS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module AFS(input clk, INF.AFS_inf inf);
import usertype::*;
    //==============================================//
    //              logic declaration               //
    // ============================================ //

typedef enum logic  [2:0] { S_IDLE = 3'h0,
							S_PURCHASE = 3'h1,
							S_RESTOCK = 3'h2,
							S_CHECKDATE = 3'h3,
                            S_WAIT_DRAM = 3'h4,
                            S_WRITEBACK = 3'h5
}  States; 

Action input_action;
States P_cur,P_next;
Strategy_Type purchase_strategy;
Mode purchase_mode;
Date input_date;
// Data_No input_addr;
// logic [9:0] rose_count,lily_count,carnation_count,babybreath_count;
logic [1:0] counter_restock;
logic [3:0] write_month;
logic [4:0] write_day;
logic [11:0] write_rose,write_lily,write_carnation,write_babybreath;

// logic [11:0] rose_dram,lily_dram,carnation_dram,babybreath_dram;
logic [11:0] rose_stock,lily_stock,carnation_stock,babybreath_stock;

logic write_flag;
logic dram_read_flag;
logic stock_flag;

// output
Warn_Msg warn_out,warn_restock;
logic complete_restock;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        counter_restock <= 2'b00;
    end
    else begin
        counter_restock <= counter_restock + inf.restock_valid;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        stock_flag <= 1'b0;
    end
    else begin
        if((counter_restock == 2'd3) & inf.restock_valid) begin
            stock_flag <= 1'b1;
        end
        else if(stock_flag & dram_read_flag) begin
            stock_flag <= 1'b0;
        end
    end
end

// ===============================
// Finite state machine
// ===============================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        P_cur <= S_IDLE;
    end
    else begin
        P_cur <= P_next;
    end
end

always_comb begin  
    case(P_cur)
        S_IDLE: begin        
            if(inf.sel_action_valid) begin
                case(inf.D.d_act[0])
                    Purchase: P_next = S_PURCHASE;
                    Restock: P_next = S_RESTOCK;
                    Check_Valid_Date: P_next = S_CHECKDATE;
                    default: P_next = S_IDLE;
                endcase
            end
            else begin
                P_next = S_IDLE;
            end
        end
        S_PURCHASE: begin
            if(inf.data_no_valid) begin
                P_next = S_WAIT_DRAM;
            end
            else begin
                P_next = S_PURCHASE;
            end
        end
        S_RESTOCK: begin
            if(stock_flag & dram_read_flag) begin
                P_next = S_WRITEBACK;
            end
            else begin
                P_next = S_RESTOCK;
            end
        end
        S_CHECKDATE: begin
            if(inf.data_no_valid) begin
                P_next = S_WAIT_DRAM;
            end
            else begin
                P_next = S_CHECKDATE;
            end
        end
        S_WAIT_DRAM: begin
            if(dram_read_flag) begin
                if(write_flag) P_next = S_WRITEBACK;
                else begin
                    P_next = S_IDLE;
                end
            end
            else begin
                P_next = S_WAIT_DRAM;
            end
        end
        S_WRITEBACK: begin
            if(inf.B_VALID) begin
                P_next = S_IDLE;
            end
            else begin
                P_next = S_WRITEBACK;
            end
        end
        default: P_next = S_IDLE;
    endcase
end

// ===============================
// Dram control interface
// ===============================
always_comb begin
    if(inf.W_VALID) inf.W_DATA = {write_rose,write_lily,4'b0000,write_month,write_carnation,write_babybreath,3'b000,write_day};
    else inf.W_DATA = 0;
end

always_comb begin
    // if(inf.AW_VALID) inf.AW_ADDR = inf.AR_ADDR;
    // else inf.W_DATA = 0;
    inf.AW_ADDR = inf.AR_ADDR;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        // read address
        inf.AR_ADDR <= 17'b0;
        inf.AR_VALID <= 1'b0;

        // read data
        inf.R_READY <= 1'b0;

        // write address
        // inf.AW_ADDR <= 17'b0;
        inf.AW_VALID <= 1'b0;

        // write data
        inf.W_VALID <= 1'b0;

        // write response
        inf.B_READY <= 1'b0;
    end
    else begin
        // read address
        if(inf.data_no_valid) begin
            inf.AR_ADDR <= {6'b100000,inf.D.d_data_no[0],3'b000};
            inf.AR_VALID <= 1'b1;
        end
        else if(inf.AR_READY) begin
            inf.AR_VALID <= 1'b0;
        end

        // read data
        if(inf.AR_READY) begin
            inf.R_READY <= 1'b1;
        end
        else if(inf.R_VALID) begin
            inf.R_READY <= 1'b0;
        end

        // write address
        if(inf.AW_READY) begin
            inf.AW_VALID <= 1'b0;
        end
        else if(dram_read_flag & write_flag) begin
            inf.AW_VALID <= 1'b1;
        end
        

        // write data
        if(inf.AW_READY) begin
            inf.W_VALID <= 1'b1;
        end
        else if(inf.W_READY) begin
            inf.W_VALID <= 1'b0;
        end
        
        // write response
        if(inf.AW_READY) begin
            inf.B_READY <= 1'b1;
        end
        else if(inf.B_VALID) begin
            inf.B_READY <= 1'b0;
        end

        // inf.AW_ADDR <= inf.AR_ADDR;
    end
end

// ===============================
// main part
// ===============================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.out_valid <= 1'b0;
        inf.warn_msg <= No_Warn;
        inf.complete <= 1'b0;

        input_date <= 0;
        complete_restock <= 1'b0;
        warn_restock <= No_Warn;
    end
    else begin
        if(inf.date_valid) input_date <= inf.D.d_date[0];
        case(P_cur)
            S_IDLE: begin
                inf.out_valid <= 1'b0;
                inf.warn_msg <= No_Warn;
                inf.complete <= 1'b0;

                if(inf.sel_action_valid) begin
                    input_action <= inf.D.d_act[0];                    
                end
            end
            S_PURCHASE: begin
                if(inf.strategy_valid) begin
                    purchase_strategy <= inf.D.d_strategy[0];
                end
                else if(inf.mode_valid) begin
                    purchase_mode <= inf.D.d_mode[0];
                end
            end
            S_RESTOCK: begin
                if(stock_flag & dram_read_flag) begin
                    warn_restock <= warn_out;
                    complete_restock <= (warn_out == No_Warn);
                end
            end
            S_WAIT_DRAM: begin
                if(input_action == Purchase) begin
                    if(dram_read_flag) begin
                        if(warn_out == No_Warn) begin
                            warn_restock <= No_Warn;
                            complete_restock <= 1'b1;
                        end
                        else begin
                            inf.out_valid <= 1'b1;
                            inf.warn_msg <= warn_out;
                            inf.complete <= 0;
                        end
                    end
                end
                else begin
                    if(dram_read_flag) begin
                        inf.out_valid <= 1'b1;
                        inf.warn_msg <= warn_out;
                        inf.complete <= (warn_out == No_Warn);
                    end
                end
            end
            S_WRITEBACK: begin
                if(inf.B_VALID) begin
                    inf.out_valid <= 1'b1;
                    inf.warn_msg <= warn_restock;
                    inf.complete <= complete_restock;
                end
            end
        endcase
    end
end

logic warn_flower,warn_date;
logic max_rose,max_lily,max_carnation,max_babybreath;

always_comb begin
    warn_date = ({input_date.M,input_date.D} < {write_month,write_day});
    warn_flower = (rose_stock > write_rose) | (lily_stock > write_lily) | (carnation_stock > write_carnation) | (babybreath_stock > write_babybreath);

    max_rose = (write_rose + rose_stock > 13'd4095);
    max_lily = (write_lily + lily_stock > 13'd4095);
    max_carnation = (write_carnation + carnation_stock > 13'd4095);
    max_babybreath = (write_babybreath + babybreath_stock > 13'd4095);
end

always_comb begin
    warn_out = No_Warn;
    write_flag = 0;
    case (input_action)
        Purchase: begin
            if(warn_date) warn_out = Date_Warn;
            else if(warn_flower) warn_out = Stock_Warn;
            else write_flag = 1;         
        end
        Restock: begin
            if(stock_flag & dram_read_flag) begin
                write_flag = 1;
                if(max_rose | max_lily | max_carnation | max_babybreath) warn_out = Restock_Warn;
            end
        end
        Check_Valid_Date: begin
            if(warn_date) warn_out = Date_Warn;
        end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        write_month <= 4'b0;
        write_day <= 5'b0;
        write_rose <= 12'b0;
        write_lily <= 12'b0;
        write_carnation <= 12'b0;
        write_babybreath <= 12'b0;
    end
    else begin
        if(inf.R_VALID) begin
            write_rose <= inf.R_DATA[63:52];
            write_lily <= inf.R_DATA[51:40];
            write_carnation <= inf.R_DATA[31:20];
            write_babybreath <= inf.R_DATA[19:8];
            write_month <= inf.R_DATA[35:32];
            write_day <= inf.R_DATA[4:0];
        end
        else begin
            if(inf.AW_READY) begin
                case (input_action)
                    Purchase: begin
                        // if(inf.R_VALID) begin 
                        //     write_month <= inf.R_DATA[35:32];
                        //     write_day <= inf.R_DATA[4:0];
                        // end
                        write_rose <= write_rose - rose_stock;
                        write_lily <= write_lily - lily_stock;
                        write_carnation <= write_carnation - carnation_stock;
                        write_babybreath <= write_babybreath - babybreath_stock;
                    end
                    Restock: begin
                        if(max_rose) begin
                            write_rose <= 12'd4095;
                        end
                        else begin
                            write_rose <= write_rose + rose_stock;
                        end
                    
                        if(max_lily) begin
                            write_lily <= 12'd4095;
                        end
                        else begin
                            write_lily <= write_lily + lily_stock;
                        end
                    
                        if(max_carnation) begin
                            write_carnation <= 12'd4095;
                        end
                        else begin
                            write_carnation <= write_carnation + carnation_stock;
                        end
                    
                        if(max_babybreath) begin
                            write_babybreath <= 12'd4095;
                        end
                        else begin
                            write_babybreath <= write_babybreath + babybreath_stock;
                        end
                        write_month <= input_date.M;
                        write_day <= input_date.D;
                    end
                    // Check_Valid_Date: begin
                    //     if(inf.R_VALID) begin
                    //         write_month <= inf.R_DATA[35:32];
                    //         write_day <= inf.R_DATA[4:0];
                    //     end
                    // end
                endcase 
            end 
        end
    end
end


always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        // rose_dram <= 12'b0;
        // lily_dram <= 12'b0;
        // carnation_dram <= 12'b0;
        // babybreath_dram <= 12'b0;
        dram_read_flag <= 1'b0;
    end
    else begin
        if(inf.R_VALID) begin
            // rose_dram <= inf.R_DATA[63:52];
            // lily_dram <= inf.R_DATA[51:40];
            // carnation_dram <= inf.R_DATA[31:20];
            // babybreath_dram <= inf.R_DATA[19:8];
            dram_read_flag <= 1'b1;
        end
        else if(inf.AW_READY | (P_cur == S_IDLE)) begin
            // rose_dram <= 12'b0;
            // lily_dram <= 12'b0;
            // carnation_dram <= 12'b0;
            // babybreath_dram <= 12'b0;
            dram_read_flag <= 1'b0;
        end
    end
end

// always_ff @(posedge clk or negedge inf.rst_n) begin
//     if(!inf.rst_n) begin
//         dram_read_flag <= 1'b0;
//     end
//     else begin
//         if(inf.R_VALID) begin
//             dram_read_flag <= 1'b1;
//         end
//         else if(P_cur == S_IDLE) begin
//             dram_read_flag <= 1'b0;
//         end
//     end
// end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        rose_stock <= 12'b0;
        lily_stock <= 12'b0;
        carnation_stock <= 12'b0;
        babybreath_stock <= 12'b0;
    end
    else if(inf.restock_valid)begin
        if(counter_restock == 0) begin
            rose_stock <= inf.D.d_stock[0];
        end
        else if(counter_restock == 1) begin
            lily_stock <= inf.D.d_stock[0];
        end
        else if(counter_restock == 2) begin
            carnation_stock <= inf.D.d_stock[0];
        end
        else begin
            babybreath_stock <= inf.D.d_stock[0];
        end
    end
    else if(input_action == Purchase) begin
        case(purchase_strategy)
            Strategy_A: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd120;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                Group_Order: begin
                    rose_stock <= 12'd480;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                Event: begin
                    rose_stock <= 12'd960;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                endcase
            end
            Strategy_B: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd120;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                Group_Order: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd480;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                Event: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd960;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                endcase
            end
            Strategy_C: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd120;
                    babybreath_stock <= 12'd0;
                end
                Group_Order: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd480;
                    babybreath_stock <= 12'd0;
                end
                Event: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd960;
                    babybreath_stock <= 12'd0;
                end
                endcase
            end
            Strategy_D: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd120;
                end
                Group_Order: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd480;
                end
                Event: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd960;
                end
                endcase
            end
            Strategy_E: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd60;
                    lily_stock <= 12'd60;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                Group_Order: begin
                    rose_stock <= 12'd240;
                    lily_stock <= 12'd240;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                Event: begin
                    rose_stock <= 12'd480;
                    lily_stock <= 12'd480;
                    carnation_stock <= 12'd0;
                    babybreath_stock <= 12'd0;
                end
                endcase
            end
            Strategy_F: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd60;
                    babybreath_stock <= 12'd60;
                end
                Group_Order: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd240;
                    babybreath_stock <= 12'd240;
                end
                Event: begin
                    rose_stock <= 12'd0;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd480;
                    babybreath_stock <= 12'd480;
                end
                endcase
            end
            Strategy_G: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd60;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd60;
                    babybreath_stock <= 12'd0;
                end
                Group_Order: begin
                    rose_stock <= 12'd240;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd240;
                    babybreath_stock <= 12'd0;
                end
                Event: begin
                    rose_stock <= 12'd480;
                    lily_stock <= 12'd0;
                    carnation_stock <= 12'd480;
                    babybreath_stock <= 12'd0;
                end
                endcase
            end
            Strategy_H: begin
                case(purchase_mode)
                Single: begin
                    rose_stock <= 12'd30;
                    lily_stock <= 12'd30;
                    carnation_stock <= 12'd30;
                    babybreath_stock <= 12'd30;
                end
                Group_Order: begin
                    rose_stock <= 12'd120;
                    lily_stock <= 12'd120;
                    carnation_stock <= 12'd120;
                    babybreath_stock <= 12'd120;
                end
                Event: begin
                    rose_stock <= 12'd240;
                    lily_stock <= 12'd240;
                    carnation_stock <= 12'd240;
                    babybreath_stock <= 12'd240;
                end
                endcase
            end
        endcase
    end
end

// logic [11:0] _dram_1_rose,_dram_2_lily,_dram_3_carnation,_dram_4_babybreath;
// logic [7:0] _dram_5_month,_dram_6_day;

// always_comb begin
//     _dram_1_rose = inf.R_DATA[63:52];
//     _dram_2_lily = inf.R_DATA[51:40];
//     _dram_3_carnation = inf.R_DATA[31:20];
//     _dram_4_babybreath = inf.R_DATA[19:8];
//     _dram_5_month = inf.R_DATA[39:32];
//     _dram_6_day = inf.R_DATA[7:0];
// end

// ===============================
// Output
// ===============================
// always_ff @(posedge clk or negedge inf.rst_n) begin
//     if(!inf.rst_n) begin
//         inf.out_valid <= 1'b0;
//         inf.warn_msg <= No_Warn;
//         inf.complete <= 1'b0;
//     end
//     else if(output_flag) begin
//         inf.out_valid <= 1'b1;
//         inf.warn_msg <= warn_out;
//         inf.complete <= (warn_out == No_Warn);
//     end
//     else begin
//         inf.out_valid <= 1'b0;
//         inf.warn_msg <= No_Warn;
//         inf.complete <= 1'b0;
//     end
// end


endmodule



