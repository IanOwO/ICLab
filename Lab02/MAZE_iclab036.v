    module MAZE(
    // input
    input clk,
    input rst_n,
	input in_valid,
	input [1:0] in,

    // output
    output reg out_valid,
    output reg [1:0] out
);
// --------------------------------------------------------------
// Reg & Wire
// --------------------------------------------------------------

reg [1:0] graph[0:18][0:18];
parameter [1:0] ROAD = 2'b00, WALL = 2'b01, SWORD = 2'b10, MONSTER = 2'b11;
parameter [1:0] MOVE_RIGHT = 2'b00, MOVE_DOWN = 2'b01, MOVE_LEFT = 2'b10, MOVE_UP = 2'b11;

// FSM
reg P_cur;
reg P_next;
parameter S_IDLE = 1'd0, S_DELETE_ROAD = 1'd1;

// data in
wire data_in_available;

// delete blind alley
reg delete_flag_counter;

// move to end
wire reach_endpoint;
wire move_with_sword;
reg sword_available;

// reg [4:0] counter_i,counter_j;
reg [4:0] counter_i_move,counter_j_move;
integer i,j;

// testing signal
// reg test_graph;
// --------------------------------------------------------------
// Design
// --------------------------------------------------------------
// data in
assign data_in_available = (P_cur == S_IDLE) & in_valid;

// move to end
assign reach_endpoint = (counter_i_move == 5'd17) & (counter_j_move == 5'd17);
assign move_with_sword = (sword_available);

// =============================
// FSM
// =============================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) P_cur <= S_IDLE;
    else P_cur <= P_next;
end

always @(*) begin 
    if(!rst_n) P_next = S_IDLE;
    else begin
        case (P_cur)
        S_IDLE:
            if((counter_i_move == 5'd17) & (counter_j_move == 5'd17)) P_next = S_DELETE_ROAD;
            else if(in_valid) P_next = S_IDLE;
            else P_next = S_IDLE;
        S_DELETE_ROAD:
            if((counter_i_move == 5'd17) & (counter_j_move == 5'd17)) P_next = S_IDLE;
            else P_next = S_DELETE_ROAD;
        default: P_next = S_IDLE;
        endcase
    end
end

// ==================================
// counter, input, delete blind alley
// ==================================
always @(posedge clk) begin
    if(data_in_available) begin
        graph[counter_i_move][counter_j_move] <= in;
        for(i = 0;i < 19;i = i + 1) begin
            graph[i][0] <= 2'b01;
            graph[i][18] <= 2'b01;
        end
        for(j = 1;j < 18;j = j + 1) begin
            graph[0][j] <= 2'b01;
            graph[18][j] <= 2'b01;
        end
    end
    else begin
        // (1,2) ~ (1,17)
        for(j = 2;j < 18;j = j + 1) begin
            if(!graph[1][j]) begin
                casez({graph[1][j-1], graph[1][j+1], graph[2][j]})
                    6'b0101??,6'b01??01,6'b??0101: begin
                        graph[1][j] <= 2'd1;
                    end
                    default: begin
                        graph[1][j] <= graph[1][j];
                    end
                endcase
            end
        end
        //  (2,1)
        //    |  
        // (16,1)
        for(i = 2;i < 17;i = i + 1) begin
            if(!graph[i][1]) begin
                casez({graph[i-1][1], graph[i][2], graph[i+1][1]})
                    6'b0101??,6'b01??01,6'b??0101: begin
                        graph[i][1] <= 2'd1;
                    end
                    default: begin
                        graph[i][1] <= graph[i][1];
                    end
                endcase
            end
        end 
        //  (2,2) ~ (2,16)
        //    |       |
        // (16,2) ~ (16,16)
        for(i = 2;i < 17;i = i + 1) begin
            for(j = 2;j < 17;j = j + 1) begin
                if(!graph[i][j]) begin
                    casez({graph[i][j-1], graph[i-1][j], graph[i][j+1], graph[i+1][j]})
                        8'b010101??,8'b0101??01,8'b01??0101,8'b??010101: begin
                            graph[i][j] <= 2'd1;
                        end
                        default: begin
                            graph[i][j] <= graph[i][j];
                        end
                    endcase
                end
            end
        end
        //  (2,17)
        //    |  
        // (16,17)
        for(i = 2;i < 17;i = i + 1) begin
            if(!graph[i][17]) begin
                casez({graph[i-1][17], graph[i][16], graph[i+1][17]})
                    6'b0101??,6'b01??01,6'b??0101: begin
                        graph[i][17] <= 2'd1;
                    end
                    default: begin
                        graph[i][17] <= graph[i][17];
                    end
                endcase
            end
        end 
        // (17,1) ~ (17,16)
        for(j = 1;j < 17;j = j + 1) begin
            if(!graph[17][j]) begin
                casez({graph[17][j-1], graph[16][j], graph[17][j+1]})
                    6'b0101??,6'b01??01,6'b??0101: begin
                        graph[17][j] <= 2'd1;
                    end
                    default: begin
                        graph[17][j] <= graph[17][j];
                    end
                endcase
            end
        end 
    end
end

// =========================
// move to the end
// =========================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_i_move <= 5'd1;
        counter_j_move <= 5'd1;
        sword_available <= 1'b0;

        out <= 2'd0;
        out_valid <= 1'b0;
    end
    else if(data_in_available) begin
        if((counter_j_move == 5'd17) & (counter_i_move == 5'd17)) begin
            counter_i_move <= 5'd1;
            counter_j_move <= 5'd1;
            if(graph[1][1] == SWORD) begin
                sword_available <= 1'b1;
            end
            else begin
                sword_available <= 1'b0;
            end
        end
        else if(counter_j_move == 5'd17) begin
            counter_i_move <= counter_i_move + 1;
            counter_j_move <= 5'd1;
        end 
        else begin
            counter_i_move <= counter_i_move;
            counter_j_move <= counter_j_move + 1;
        end
    end
    else if((P_cur == S_DELETE_ROAD) & (!reach_endpoint)) begin
        if(move_with_sword) begin
            if(out == MOVE_RIGHT) begin
                if((graph[counter_i_move - 1][counter_j_move] != WALL)) begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move + 1] != WALL)) begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move + 1][counter_j_move] != WALL)) begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
                else begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
            end
            else if(out == MOVE_DOWN) begin
                if((graph[counter_i_move][counter_j_move + 1] != WALL)) begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move + 1][counter_j_move] != WALL)) begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move - 1] != WALL)) begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
                else begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
            end
            else if(out == MOVE_LEFT) begin
                if((graph[counter_i_move + 1][counter_j_move] != WALL)) begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move - 1] != WALL)) begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move - 1][counter_j_move] != WALL)) begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
                else begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
            end
            else begin // out == MOVE_UP
                if((graph[counter_i_move][counter_j_move - 1] != WALL)) begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move - 1][counter_j_move] != WALL)) begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move + 1] != WALL)) begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
                else begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
            end
        end
        else begin
            if(out == MOVE_RIGHT) begin
                if((graph[counter_i_move - 1][counter_j_move] == ROAD) | (graph[counter_i_move - 1][counter_j_move] == SWORD)) begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= (graph[counter_i_move - 1][counter_j_move] == SWORD)?1'b1:sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move + 1] == ROAD) | (graph[counter_i_move][counter_j_move + 1] == SWORD)) begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= (graph[counter_i_move][counter_j_move + 1] == SWORD)?1'b1:sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move + 1][counter_j_move] == ROAD) | (graph[counter_i_move + 1][counter_j_move] == SWORD)) begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= (graph[counter_i_move + 1][counter_j_move] == SWORD)?1'b1:sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
                else begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
            end
            else if(out == MOVE_DOWN) begin
                if((graph[counter_i_move][counter_j_move + 1] == ROAD) | (graph[counter_i_move][counter_j_move + 1] == SWORD)) begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= (graph[counter_i_move][counter_j_move + 1] == SWORD)?1'b1:sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move + 1][counter_j_move] == ROAD) | (graph[counter_i_move + 1][counter_j_move] == SWORD)) begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= (graph[counter_i_move + 1][counter_j_move] == SWORD)?1'b1:sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move - 1] == ROAD) | (graph[counter_i_move][counter_j_move - 1] == SWORD)) begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= (graph[counter_i_move][counter_j_move - 1] == SWORD)?1'b1:sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
                else begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
            end
            else if(out == MOVE_LEFT) begin
                if((graph[counter_i_move + 1][counter_j_move] == ROAD) | (graph[counter_i_move + 1][counter_j_move] == SWORD)) begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= (graph[counter_i_move + 1][counter_j_move] == SWORD)?1'b1:sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move - 1] == ROAD) | (graph[counter_i_move][counter_j_move - 1] == SWORD)) begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= (graph[counter_i_move][counter_j_move - 1] == SWORD)?1'b1:sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move - 1][counter_j_move] == ROAD) | (graph[counter_i_move - 1][counter_j_move] == SWORD)) begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= (graph[counter_i_move - 1][counter_j_move] == SWORD)?1'b1:sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
                else begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
            end
            else begin // out == MOVE_UP
                if((graph[counter_i_move][counter_j_move - 1] == ROAD) | (graph[counter_i_move][counter_j_move - 1] == SWORD)) begin // try to move left
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move - 1;
                    sword_available <= (graph[counter_i_move][counter_j_move - 1] == SWORD)?1'b1:sword_available;

                    out <= MOVE_LEFT; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move - 1][counter_j_move] == ROAD) | (graph[counter_i_move - 1][counter_j_move] == SWORD)) begin // try to move up
                    counter_i_move <= counter_i_move - 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= (graph[counter_i_move - 1][counter_j_move] == SWORD)?1'b1:sword_available;

                    out <= MOVE_UP; 
                    out_valid <= 1'b1;
                end
                else if((graph[counter_i_move][counter_j_move + 1] == ROAD) | (graph[counter_i_move][counter_j_move + 1] == SWORD)) begin // try to move right
                    counter_i_move <= counter_i_move;
                    counter_j_move <= counter_j_move + 1;
                    sword_available <= (graph[counter_i_move][counter_j_move + 1] == SWORD)?1'b1:sword_available;

                    out <= MOVE_RIGHT; 
                    out_valid <= 1'b1;
                end
                else begin // try to move down
                    counter_i_move <= counter_i_move + 1;
                    counter_j_move <= counter_j_move;
                    sword_available <= sword_available;

                    out <= MOVE_DOWN; 
                    out_valid <= 1'b1;
                end
            end
        end
    end
    else begin
        counter_i_move <= 5'd1;
        counter_j_move <= 5'd1;
        sword_available <= 1'b0;

        out <= 2'd0;
        out_valid <= 1'b0;
    end
end

endmodule