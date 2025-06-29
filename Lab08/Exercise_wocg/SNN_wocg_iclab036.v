module SNN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	img,
	ker,
	weight,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [6:0] counter;
reg [7:0] image [0:14];
reg [7:0] ker_list [0:8];
reg [7:0] weight_list [0:3];
reg flag_feature;
reg flag_max_pool;
reg flag_swap;
reg flag_dist;
reg flag_output;

// calculation
reg [7:0] feature_map[0:5];
reg [7:0] max_pool_map;
reg [7:0] quant2_map[0:3];
reg [7:0] quant2_cal[0:1];
reg [9:0] sum_l1;
reg [9:0] dist_l1;
wire feature_flag;
wire quant2_flag;
wire feature_pass;
wire max_pool_flag;

reg [7:0] feature_max,max_temp1,max_temp2;


//==============================================//
//                  design                      //
//==============================================//

// ======================================
// counter & flags
// ======================================
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter <= 7'd0;
	end
	else if(in_valid) begin
		counter <= counter + 1;
	end
	else if(out_valid) begin
		counter <= 0;
	end
	else if(flag_feature) begin
		counter <= counter + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag_feature <= 1'b0;
	end
	else if(in_valid) begin
		flag_feature <= 1'b1;
	end
	else if(out_valid) begin
		flag_feature <= 1'b0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag_max_pool <= 1'b0;
	end
	else if(out_valid) begin
		flag_max_pool <= 1'b0;
	end
	else if(counter == 22) begin
		flag_max_pool <= 1'b1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag_swap <= 1'b0;
	end
	else if(counter == 48) begin
		flag_swap <= 1'b1;
	end
	else begin
		flag_swap <= 1'b0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		flag_dist <= 1'b0;
	end
	else if((counter == 60) | (counter == 72)) begin
		flag_dist <= 1'b1;
	end
	else begin
		flag_dist <= 1'b0;
	end
end

// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		flag_output <= 1'b0;
// 	end
// 	else if(counter == 73) begin
// 		flag_output <= 1'b1;
// 	end
// 	else begin
// 		flag_output <= 1'b0;
// 	end
// end

always @(*) begin
	if(counter == 74) begin
		flag_output = 1'b1;
	end
	else begin
		flag_output = 1'b0;
	end
end

// ======================================
// input
// ======================================
always @(posedge clk) begin
	if(in_valid) begin
		if(counter < 4) begin
			weight_list[counter] <= weight;
		end
	end
end

always @(posedge clk) begin
	if(in_valid) begin
		if(counter < 9) begin
			ker_list[counter] <= ker;
		end
	end
end

always @(posedge clk) begin
	image[0] <= image[1];
	image[1] <= image[2];
	image[2] <= image[3];
	image[3] <= image[4];
	image[4] <= image[5];
	image[5] <= image[6];
	image[6] <= image[7];
	image[7] <= image[8];
	image[8] <= image[9];
	image[9] <= image[10];
	image[10] <= image[11];
	image[11] <= image[12];
	image[12] <= image[13];
	image[13] <= image[14];
	image[14] <= img;
end

reg [7:0] sel_image [0:8];
// reg [7:0] sel_ker [0:8];

always @(*) begin
	case(counter)
		15,16,17,18,21,22,23,24,27,28,29,30,33,34,35,36: begin
			sel_image[0] = image[0];
			sel_image[1] = image[1];
			sel_image[2] = image[2];
			sel_image[3] = image[6];
			sel_image[4] = image[7];
			sel_image[5] = image[8];
			sel_image[6] = image[12];
			sel_image[7] = image[13];
			sel_image[8] = image[14];
			// sel_ker[0] = ker_list[0];
			// sel_ker[1] = ker_list[1];
			// sel_ker[2] = ker_list[2];
			// sel_ker[3] = ker_list[3];
			// sel_ker[4] = ker_list[4];
			// sel_ker[5] = ker_list[5];
			// sel_ker[6] = ker_list[6];
			// sel_ker[7] = ker_list[7];
			// sel_ker[8] = ker_list[8];
		end
		51,52,53,54,57,58,59,60,63,64,65,66,69,70,71,72: begin
			sel_image[0] = image[0];
			sel_image[1] = image[1];
			sel_image[2] = image[2];
			sel_image[3] = image[6];
			sel_image[4] = image[7];
			sel_image[5] = image[8];
			sel_image[6] = image[12];
			sel_image[7] = image[13];
			sel_image[8] = image[14];
			// sel_ker[0] = ker_list[0];
			// sel_ker[1] = ker_list[1];
			// sel_ker[2] = ker_list[2];
			// sel_ker[3] = ker_list[3];
			// sel_ker[4] = ker_list[4];
			// sel_ker[5] = ker_list[5];
			// sel_ker[6] = ker_list[6];
			// sel_ker[7] = ker_list[7];
			// sel_ker[8] = ker_list[8];
		end
		default: begin
			sel_image[0] = feature_map[5];
			sel_image[1] = feature_map[5];
			sel_image[2] = feature_map[5];
			sel_image[3] = feature_map[5];
			sel_image[4] = feature_map[5];
			sel_image[5] = feature_map[5];
			sel_image[6] = feature_map[5];
			sel_image[7] = feature_map[5];
			sel_image[8] = feature_map[5];
			// sel_ker[0] = quant2_map[0];
			// sel_ker[1] = quant2_map[0];
			// sel_ker[2] = quant2_map[0];
			// sel_ker[3] = quant2_map[0];
			// sel_ker[4] = quant2_map[0];
			// sel_ker[5] = quant2_map[0];
			// sel_ker[6] = quant2_map[0];
			// sel_ker[7] = quant2_map[0];
			// sel_ker[8] = quant2_map[0];
		end
	endcase
end

// ======================================
// convolution & quantization
// ======================================
// wire feature_flag = (counter > 14) & (counter % 6 != 1) & (counter % 6 != 2);
assign feature_flag = ((counter > 14) & (counter < 19)) | ((counter > 20) & (counter < 25)) | ((counter > 26) & (counter < 31)) | ((counter > 32) & (counter < 37)) | ((counter > 50) & (counter < 55)) | ((counter > 56) & (counter < 61)) | ((counter > 62) & (counter < 67)) | ((counter > 68) & (counter < 73));
assign quant2_flag = (counter == 25) | (counter == 37) | (counter == 61) | (counter == 73);

assign feature_pass = ((counter > 15) & (counter < 20)) | ((counter > 21) & (counter < 25)) | ((counter > 27) & (counter < 32)) | ((counter > 33) & (counter < 37)) | ((counter > 51) & (counter < 56)) | ((counter > 57) & (counter < 61)) | ((counter > 63) & (counter < 68)) | ((counter > 69) & (counter < 73));

always @(posedge clk) begin
	feature_map[5] <= (sel_image[0] * ker_list[0] + sel_image[1] * ker_list[1] + sel_image[2] * ker_list[2] + 
					sel_image[3] * ker_list[3] + sel_image[4] * ker_list[4] + sel_image[5] * ker_list[5] + 
					sel_image[6] * ker_list[6] + sel_image[7] * ker_list[7] + sel_image[8] * ker_list[8]) / 'd2295;

end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		feature_map[0] <= 0;
		feature_map[1] <= 0;
		feature_map[2] <= 0;
		feature_map[3] <= 0;
		feature_map[4] <= 0;
	end
	else begin
		if(feature_pass) begin
			feature_map[0] <= feature_map[1];
			feature_map[1] <= feature_map[2];
			feature_map[2] <= feature_map[3];
			feature_map[3] <= feature_map[4];
			feature_map[4] <= feature_map[5];
		end
		else begin
			feature_map[0] <= feature_map[0];
			feature_map[1] <= feature_map[1];
			feature_map[2] <= feature_map[2];
			feature_map[3] <= feature_map[3];
			feature_map[4] <= feature_map[4];
		end
	end
end


// ======================================
// max-pooling & fully connected & L1 distance
// ======================================
always @(*) begin
	max_temp1 = (feature_map[0] > feature_map[1])? feature_map[0]:feature_map[1];
	max_temp2 = (max_temp1 > feature_map[4])? max_temp1: feature_map[4];
	feature_max = (max_temp2 > feature_map[5])? max_temp2: feature_map[5];
end

assign max_pool_flag = (counter == 23) | (counter == 29) | (counter == 35) | (counter == 41) | (counter == 53) | (counter == 59) | (counter == 65) | (counter == 71);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		max_pool_map <= 0;
	end
	else begin
		if(max_pool_flag) begin
			max_pool_map <= feature_max;
		end
	end
end

reg [7:0] sel_weight[0:3];
always @(*) begin
	if(flag_dist | quant2_flag) begin
		sel_weight[0] = weight_list[0];
		sel_weight[1] = weight_list[1];
		sel_weight[2] = weight_list[2];
		sel_weight[3] = weight_list[3];
	end
	else begin
		sel_weight[0] = feature_map[1];
		sel_weight[1] = feature_map[1];
		sel_weight[2] = feature_map[1];
		sel_weight[3] = feature_map[1];
	end
end

always @(*) begin
	quant2_cal[0] = (max_pool_map * sel_weight[0] + feature_max * sel_weight[2]) / 'd510;
	quant2_cal[1] = (max_pool_map * sel_weight[1] + feature_max * sel_weight[3]) / 'd510;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		quant2_map[0] <= 0;
		quant2_map[1] <= 0;
		quant2_map[2] <= 0;
		quant2_map[3] <= 0;
	end
	else begin
		if(flag_dist) begin
			quant2_map[0] <= (quant2_cal[0] > quant2_map[2])? quant2_cal[0] - quant2_map[2]: quant2_map[2] - quant2_cal[0];
			quant2_map[1] <= (quant2_cal[1] > quant2_map[3])? quant2_cal[1] - quant2_map[3]: quant2_map[3] - quant2_cal[1];
			quant2_map[2] <= quant2_map[0];
			quant2_map[3] <= quant2_map[1];
		end
		else if(flag_swap) begin
			quant2_map[0] <= quant2_map[2];
			quant2_map[1] <= quant2_map[3];
			quant2_map[2] <= quant2_map[0];
			quant2_map[3] <= quant2_map[1];
		end
		else if(quant2_flag) begin
			quant2_map[0] <= quant2_map[2];
			quant2_map[1] <= quant2_map[3];
			quant2_map[2] <= quant2_cal[0];
			quant2_map[3] <= quant2_cal[1];
		end
	end
end


always @(*) begin
	sum_l1 = quant2_map[0] + quant2_map[1] + quant2_map[2] + quant2_map[3];
	dist_l1 = (sum_l1 < 16)? 0:sum_l1;
end

// always @(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		out_valid <= 1'b0;
// 		out_data <= 10'd0;
// 	end
// 	else if(flag_output) begin
// 		out_valid <= 1'b1;
// 		out_data <= dist_l1;
// 	end
// 	else begin
// 		out_valid <= 1'b0;
// 		out_data <= 10'd0;
// 	end
// end

always @(*) begin
	if(flag_output) begin
		out_valid = 1'b1;
		out_data = dist_l1;
	end
	else begin
		out_valid = 1'b0;
		out_data = 10'h000;
	end
end

endmodule