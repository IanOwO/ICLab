//############################################################################
//   2025 ICLAB Spring Course
//   Sparse Matrix Multiplier (SMM)
//############################################################################

module SMM(
  // Input Port
  clk,
  rst_n,
  in_valid_size,
  in_size,
  in_valid_a,
  in_row_a,
  in_col_a,
  in_val_a,
  in_valid_b,
  in_row_b,
  in_col_b,
  in_val_b,
  // Output Port
  out_valid,
  out_row,
  out_col,
  out_val
);



//==============================================//
//                   PARAMETER                  //
//==============================================//



//==============================================//
//                   I/O PORTS                  //
//==============================================//
input             clk, rst_n, in_valid_size, in_valid_a, in_valid_b;
input             in_size;
input      [4:0]  in_row_a, in_col_a, in_row_b, in_col_b;
input      [3:0]  in_val_a, in_val_b;
output reg        out_valid;
output reg [4:0]  out_row, out_col;
output reg [8:0] out_val;


//==============================================//
//            reg & wire declaration            //
//==============================================//
reg [3:0] matrix_a[0:31];
reg [4:0] row_a[0:31];
reg [4:0] col_a[0:31];
reg [3:0] matrix_b[0:31];
reg [4:0] row_b[0:31];
reg [4:0] col_b[0:31];

reg [8:0] matrix_result[0:47];
reg [4:0] matrix_result_row[0:47];
reg [4:0] matrix_result_col[0:47];
reg [5:0] nonzero_a;
reg [5:0] nonzero_b;
reg [5:0] nonzero_result;
reg matrix_size;
reg in_a_flag, in_b_flag, in_size_flag;

reg [4:0] temp_col,temp_row;
reg [8:0] temp_val;

reg [6:0] output_count;
reg [2:0] flag;


reg [4:0] cur_row,cur_col;

integer i,j,k;

//==============================================//
//                   Design                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    matrix_size <= 0;
    in_size_flag <= 0;
  end
  else if(in_valid_size) begin
    matrix_size <= in_size;
    in_size_flag <= 1;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    nonzero_a <= 0;
    in_a_flag <= 0;
  end
  else if(in_valid_size) begin
    nonzero_a <= 0;
    in_a_flag <= 0;
  end
  else if(in_valid_a) begin
    nonzero_a <= nonzero_a + 1;
    in_a_flag <= 1;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    nonzero_b <= 0;
    in_b_flag <= 0;
  end
  else if(in_valid_size) begin
    nonzero_b <= 0;
    in_b_flag <= 0;
  end
  else if(in_valid_b) begin
    nonzero_b <= nonzero_b + 1;
    in_b_flag <= 1;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    for(i = 0;i < 32;i = i + 1) begin
      matrix_a[i] <= 0;
      row_a[i] <= 0;
      col_a[i] <= 0;
    end
  end
  else if(in_valid_a) begin
    matrix_a[nonzero_a] <= in_val_a;
    row_a[nonzero_a] <= in_row_a;
    col_a[nonzero_a] <= in_col_a;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    for(i = 0;i < 32;i = i + 1) begin
      matrix_b[i] <= 0;
      row_b[i] <= 0;
      col_b[i] <= 0;
    end
  end
  else if(in_valid_b) begin
    matrix_b[nonzero_b] <= in_val_b;
    row_b[nonzero_b] <= in_row_b;
    col_b[nonzero_b] <= in_col_b;
  end
end
wire [5:0]check_rowb_cur_row = row_b[cur_row];
wire [5:0]check_cola_cur_col = col_a[cur_col];

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    for(i = 0;i < 48;i = i + 1) begin
      matrix_result[i] <= 0;
      matrix_result_row[i] <= 0;
      matrix_result_col[i] <= 0;
    end
    cur_row <= 0;
    cur_col <= 0;
    nonzero_result <= 0;
  end
  else if(in_valid_size | in_valid_a | in_valid_b) begin
    for(i = 0;i < 48;i = i + 1) begin
      matrix_result[i] <= 0;
      matrix_result_row[i] <= 0;
      matrix_result_col[i] <= 0;
    end
    nonzero_result <= 0;
    cur_row <= 0;
    cur_col <= 0;
  end
  else if((!in_valid_a) & (!in_valid_b) & (!in_valid_size) & (in_a_flag & in_b_flag & in_size_flag) & ((cur_col < nonzero_a))) begin
    if(cur_row == (nonzero_b - 1)) begin
      cur_col <= cur_col + 1;
      cur_row <= 0;
    end
    else cur_row <= cur_row + 1;

    if((row_b[cur_row] == col_a[cur_col])) begin
      for(i = 0;i < 48;i = i + 1) begin
        if(i < nonzero_result) begin
          if((matrix_result_row[i] == row_a[cur_col]) & (matrix_result_col[i] == col_b[cur_row]) & (flag == 1)) begin
            matrix_result[i] <= matrix_result[i] + matrix_a[cur_col] * matrix_b[cur_row];
          end
        end
        else if((i == nonzero_result) & (flag == 2)) begin
          nonzero_result <= nonzero_result + 1;
          matrix_result[i] <= matrix_a[cur_col] * matrix_b[cur_row];
          matrix_result_row[i] <= row_a[cur_col];
          matrix_result_col[i] <= col_b[cur_row];
        end
      end
    end
  end
end

always @(*) begin
  flag = 0;
  if((!in_valid_a) & (!in_valid_b) & (!in_valid_size) & (in_a_flag & in_b_flag & in_size_flag) & ((cur_col < nonzero_a))) begin
    // flag = 3;
    if((row_b[cur_row] == col_a[cur_col])) begin
      for(i = 0;i < 48;i = i + 1) begin
        if(i < nonzero_result) begin
          if((matrix_result_row[i] == row_a[cur_col]) & (matrix_result_col[i] == col_b[cur_row])) begin
            flag = 1;
          end
        end
        else if((i == nonzero_result) & (flag == 0)) begin
          flag = 2;
        end
      end
    end
  end
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    output_count <= 0;
  end
  else if(in_valid_size | in_valid_a | in_valid_b) begin
    output_count <= 0;
  end
  else if((cur_col == nonzero_a) & (output_count < nonzero_result)) begin
    output_count <= output_count + 1;
  end
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    out_valid <= 0;
    out_row <= 0;
    out_col <= 0;
    out_val <= 0;
  end
  else if((cur_col == nonzero_a) & (output_count < nonzero_result)) begin
    out_valid <= 1;
    out_row <= matrix_result_row[output_count];
    out_col <= matrix_result_col[output_count];
    out_val <= matrix_result[output_count];
  end
  else begin
    out_valid <= 0;
    out_row <= 0;
    out_col <= 0;
    out_val <= 0;
  end
end

endmodule