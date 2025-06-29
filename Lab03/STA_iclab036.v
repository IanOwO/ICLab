/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: STA
// FILE NAME: STA.v
// VERSRION: 1.0
// DATE: 2025/02/26
// AUTHOR: Yu-Hao Cheng, NYCU IEE
// DESCRIPTION: ICLAB 2025 Spring / LAB3 / STA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module STA(
	//INPUT
	rst_n,
	clk,
	in_valid,
	delay,
	source,
	destination,
	//OUTPUT
	out_valid,
	worst_delay,
	path
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[3:0]	delay;
input		[3:0]	source;
input		[3:0]	destination;

output reg			out_valid;
output reg	[7:0]	worst_delay;
output reg	[3:0]	path;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer i,j;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [5:0] counter;
reg [3:0] delay_list[0:15];
reg [3:0] in_degree_next[0:15];
reg [3:0] in_degree[0:15];
reg adjacent_list[0:15][0:15];
reg [15:0] visited_list_next;
reg [15:0] visited_list;
// reg visited_list[0:15];
reg [7:0] calculate_delay[0:15];
reg [3:0] calculate_delay_parent[0:15];

reg [3:0] cur_node;

reg path_flag;

wire cur_node_adjacent;

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
assign cur_node_adjacent = adjacent_list[cur_node][0] & adjacent_list[cur_node][1] & adjacent_list[cur_node][2] & adjacent_list[cur_node][3] & adjacent_list[cur_node][4] & adjacent_list[cur_node][5] & adjacent_list[cur_node][6] & adjacent_list[cur_node][7] & adjacent_list[cur_node][8] & adjacent_list[cur_node][9] & adjacent_list[cur_node][10] & adjacent_list[cur_node][11] & adjacent_list[cur_node][12] & adjacent_list[cur_node][13] & adjacent_list[cur_node][14] & adjacent_list[cur_node][15];

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter <= 6'b0;
	end
	else if(in_valid) begin
		counter <= counter + 1;
	end
	else if(!out_valid)begin
		counter <= counter;
	end
	else begin
		counter <= 6'd0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0;i < 16;i = i + 1) begin
			delay_list[i] <= 4'd0;
		end
	end
	else if(in_valid & (!counter[4])) begin
		delay_list[counter] <= delay;
	end
end

always @(posedge clk) begin
	if(in_valid) begin
		in_degree[source] <= in_degree[source] + 1;
	end
	else if(counter[5] & (!(&visited_list))) begin // has not visit every node 
		for(i = 0;i < 16;i = i + 1) begin
			in_degree[i] <= in_degree_next[i];
		end
	end
	else begin
		for(i = 0;i < 16;i = i + 1) begin
			in_degree[i] <= 4'd0;
		end
	end
end

always @(*) begin
	for(i = 0;i < 16;i = i + 1) begin
		in_degree_next[i] = in_degree[i];
	end

	if(counter[5] & (!(&visited_list))) begin // has not visit every node 
		// try case(1) when finished
		for(i = 0;i < 16;i = i + 1) begin
			if(adjacent_list[cur_node][i]) begin
				in_degree_next[i] = in_degree[i] - 1;
			end
		end
	end
end

// reverse source and destination so that we can easily output value after calculation
always @(posedge clk) begin
	if(in_valid) begin
		// in_degree[source] <= in_degree[source] + 1;
		adjacent_list[destination][source] <= 1'b1;

		calculate_delay[0] <= 8'b11111111;
		calculate_delay[1] <= 8'd0;
		calculate_delay[2] <= 8'b11111111;
		calculate_delay[3] <= 8'b11111111;
		calculate_delay[4] <= 8'b11111111;
		calculate_delay[5] <= 8'b11111111;
		calculate_delay[6] <= 8'b11111111;
		calculate_delay[7] <= 8'b11111111;
		calculate_delay[8] <= 8'b11111111;
		calculate_delay[9] <= 8'b11111111;
		calculate_delay[10] <= 8'b11111111;
		calculate_delay[11] <= 8'b11111111;
		calculate_delay[12] <= 8'b11111111;
		calculate_delay[13] <= 8'b11111111;
		calculate_delay[14] <= 8'b11111111;
		calculate_delay[15] <= 8'b11111111;

		for(i = 0;i < 16;i = i + 1) begin
			calculate_delay_parent[i] <= 4'd0;
		end
	end
	else if(counter[5] & (!(&visited_list_next))) begin // has not visit every node 
		// try case(1) when finished
		for(i = 0;i < 16;i = i + 1) begin
			if(adjacent_list[cur_node][i]) begin
				calculate_delay[i] <= ((calculate_delay[i] < (calculate_delay[cur_node] + delay_list[i])) || (&calculate_delay[i]))? calculate_delay[cur_node] + delay_list[i]: calculate_delay[i];
				calculate_delay_parent[i] <= ((calculate_delay[i] < (calculate_delay[cur_node] + delay_list[i])) || (&calculate_delay[i]))? cur_node: calculate_delay_parent[i];
			end 
			else begin
				calculate_delay[i] <= calculate_delay[i];
				calculate_delay_parent[i] <= calculate_delay_parent[i];
			end
			adjacent_list[cur_node][i] <= 1'b0;
		end
	end
	else begin
		for(i = 0;i < 16;i = i + 1) begin
			for(j = 0;j < 16;j = j + 1) begin
				adjacent_list[i][j] <= 1'b0;
			end
		end
	end
	
end

always @(*) begin
	visited_list_next = visited_list;
	if(counter[5] & (!(&visited_list))) begin
		visited_list_next[cur_node] = 1'b1;
	end
	else if(&visited_list) begin
		visited_list_next = visited_list;
	end
	else begin
		visited_list_next = 16'd0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		visited_list <= 16'd0;
	end
	else if(counter[5] & (!(&visited_list))) begin
		visited_list <= visited_list_next;
	end
	else if(cur_node == 4'd1) begin
		visited_list <= 16'd0;
	end
	else begin
		visited_list <= visited_list_next;
	end
end

always @(posedge clk) begin
	if(in_valid) begin
		cur_node <= 4'd1;
	end
	else if(counter[5] & (!(&visited_list_next))) begin
		case(1)
			(!in_degree_next[0]) & (!visited_list_next[0]): cur_node <= 4'd0;
			// (!in_degree[1]) & (!visited_list[1]): cur_node <= 4'd1;
			(!in_degree_next[2]) & (!visited_list_next[2]): cur_node <= 4'd2;
			(!in_degree_next[3]) & (!visited_list_next[3]): cur_node <= 4'd3;
			(!in_degree_next[4]) & (!visited_list_next[4]): cur_node <= 4'd4;
			(!in_degree_next[5]) & (!visited_list_next[5]): cur_node <= 4'd5;
			(!in_degree_next[6]) & (!visited_list_next[6]): cur_node <= 4'd6;
			(!in_degree_next[7]) & (!visited_list_next[7]): cur_node <= 4'd7;
			(!in_degree_next[8]) & (!visited_list_next[8]): cur_node <= 4'd8;
			(!in_degree_next[9]) & (!visited_list_next[9]): cur_node <= 4'd9;
			(!in_degree_next[10]) & (!visited_list_next[10]): cur_node <= 4'd10;
			(!in_degree_next[11]) & (!visited_list_next[11]): cur_node <= 4'd11;
			(!in_degree_next[12]) & (!visited_list_next[12]): cur_node <= 4'd12;
			(!in_degree_next[13]) & (!visited_list_next[13]): cur_node <= 4'd13;
			(!in_degree_next[14]) & (!visited_list_next[14]): cur_node <= 4'd14;
			(!in_degree_next[15]) & (!visited_list_next[15]): cur_node <= 4'd15;
			default: cur_node <= cur_node;
		endcase
	end
	else if(&visited_list_next) begin
		cur_node <= calculate_delay_parent[cur_node];
	end
	else begin
		cur_node <= 4'd1;
	end
end

always @(*) begin // not sure reset nessessary? 
	if(&visited_list_next) begin
		out_valid = 1'b1;
		worst_delay = (cur_node)? 4'd0:calculate_delay[0] + delay_list[1];
		path = cur_node;
	end
	else begin
		out_valid = 1'b0;
		worst_delay = 8'd0;
		path = 4'd0;
	end
end

endmodule
