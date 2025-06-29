import numpy as np
import time
from fractions import Fraction

def float_to_hex_combined(value):
    # print(value)
    num_hex = format(int(value), '04X')  # 4-byte hex
    den_hex = format(int((value - int(value))*256), '02X')  # 4-byte hex
    # print("----------", num_hex," ",den_hex)
    # time.sleep(1)
    return num_hex + den_hex  # 直接拼接

# 讀取 10 張 128x128 影像
def load_L_matrices(filename):
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f.readlines() if line.strip()]
    
    # 解析成 10 張 128x128 的影像
    images = []
    current_image = []
    for line in lines:
        row = list(map(int, line.split()))
        current_image.append(row)
        # print(row)
        # time.sleep(1)
        if len(current_image) == 128:  # 128 行後儲存一張影像
            
            images.append(np.array(current_image))
            current_image = []
    
    return images

# 讀取 MV.txt，將每 8 個數據作為一組 (x, y, 計算數值)
def load_MV(filename):
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f.readlines() if line.strip()]
    
    mv_data = []
    for line in lines:
        hex_values = line.split()
        
        for i in range(0, len(hex_values), 8):
            if i + 7 < len(hex_values):
                x1 = int(hex_values[i][:2], 16)
                y1 = int(hex_values[i+1][:2], 16)
                calc1 = int(hex_values[i], 16) % 16
                calc2 = int(hex_values[i+1], 16) % 16
                x2 = int(hex_values[i+2][:2], 16)
                y2 = int(hex_values[i+3][:2], 16)
                calc3 = int(hex_values[i+2], 16) % 16
                calc4 = int(hex_values[i+3], 16) % 16
                x3 = int(hex_values[i+4][:2], 16)
                y3 = int(hex_values[i+5][:2], 16)
                calc5 = int(hex_values[i+4], 16) % 16
                calc6 = int(hex_values[i+5], 16) % 16
                x4 = int(hex_values[i+6][:2], 16)
                y4 = int(hex_values[i+7][:2], 16)
                calc7 = int(hex_values[i+6], 16) % 16
                calc8 = int(hex_values[i+7], 16) % 16
                mv_data.append((x1, y1, calc1,calc2, x2, y2, calc3,calc4,x3, y3, calc5,calc6, x4, y4, calc7,calc8))
                # print(x1, y1, calc1,calc2, x2, y2, calc3,calc4)
                # time.sleep(1)

    return mv_data

# Bilinear interpolation 計算
def bilinear_interpolation(L_matrix, x, y, calc_value_x,calc_value_y):
    if x >= 127 or y >= 127:
        print("out range")
        return 0  # 避免超出邊界
    
    a = L_matrix[y, x]
    b = L_matrix[y, x+1]
    c = L_matrix[y+1, x]
    d = L_matrix[y+1, x+1]

    A1 = a + calc_value_x * (b - a) / 16
    A2 = c + calc_value_x * (d - c) / 16

    return A1 + calc_value_y * (A2 - A1) / 16

# 計算 10x10 區塊並找最小的 8x8 子區塊
def compute_10x10_block(L0_matrix, x, y, calc_value_x,calc_value_y,L1_matrix, x1, y1, calc_value_x1,calc_value_y1):
    block = np.zeros((10, 10))
    block1 = np.zeros((10, 10))
    for i in range(10):
        for j in range(10):
            block[i, j] = bilinear_interpolation(L0_matrix, x + j, y + i, calc_value_x,calc_value_y)
            block1[i, j] = bilinear_interpolation(L1_matrix, x1 + j, y1 + i, calc_value_x1,calc_value_y1)
    
    # 找出 8x8 的最小 SAD 子區塊
    min_sad = float('inf')
    min_block = None
    for i in range(3):
        for j in range(3):
            sub_block = block[j:j+8, i:i+8]
            sub_block1 = block1[(2-j):(2-j)+8, (2-i):(2-i)+8]
            # print("case:",i+j*3)
            # print("A")
            # print(sub_block)
            # print("b")
            # print(sub_block1)
            # time.sleep(1)
            sad = np.sum(np.abs(sub_block - sub_block1))
            if sad < min_sad:
                min_sad = sad
                min_block = i*3+j
    
    return min_block,min_sad,block,block1

# 計算並格式化結果
def process_data(L0_images, L1_images, MV_data):
    counter = 0
    results = []
    with open("output.txt", "w") as f, open("L0_point1_BI.txt", "w") as f1,open("L1_point1_BI.txt", "w") as f2,open("L0_point2_BI.txt", "w") as f3,open("L1_point2_BI.txt", "w") as f4:

        for i in range(1):
            counter = 0
            L0 = L0_images[i]
            L1 = L1_images[i]
            for x1, y1, calc1, calc2, x2, y2, calc3, calc4,x3, y3, calc5,calc6, x4, y4, calc7,calc8 in MV_data[i]:
                # 計算 L0 和 L1 的 10x10 區塊並找到 8x8 子區塊
                # if(counter == 0):
                #     print(x1, y1, calc1, calc2, x2, y2, calc3, calc4,x3, y3, calc5,calc6, x4, y4, calc7,calc8)
                block_num,L0_values,block_point1,block1_point1 = compute_10x10_block(L0, x1, y1, calc1,calc2,L1, x2, y2, calc3,calc4)
                block_num1,L1_values,block_point2,block1_point2 = compute_10x10_block(L0, x3, y3, calc5,calc6,L1, x4, y4, calc7,calc8)

                # 取 8x8 區塊內的均值來計算
                # L0_values = [int(np.mean(L0_block))]
                # L1_values = [int(np.mean(L1_block))]
                
                np.savetxt(f1, block_point1, fmt="%14.8f")
                np.savetxt(f2, block1_point1, fmt="%14.8f")
                np.savetxt(f3, block_point2, fmt="%14.8f")
                np.savetxt(f4, block1_point2, fmt="%14.8f")
                f1.write("\n")
                f2.write("\n")
                f3.write("\n")
                f4.write("\n")
                # print(block_point1)
                # time.sleep(1)

                # 轉換為 hex 並格式化
                hex_values_L0 = float_to_hex_combined(L0_values)
                hex_values_L1 = float_to_hex_combined(L1_values)
                point1 = format(block_num,'x')
                point2 = format(block_num1,'x')

                # 依據規則重新排列 hex
                final_hex = point2 + hex_values_L1 + point1+  hex_values_L0  # 前四筆放後面，後四筆放前面
                # print(L1_values,hex_values_L1, L0_values, hex_values_L0)
                # time.sleep(1)
                # results.append(final_hex)  # 合併 hex 值point2
                f.write(str(final_hex) + "\n")

                if counter == 63:
                    break
                else:
                    counter = counter + 1
    
    return results

# 主執行流程
L0_images = load_L_matrices("L0_max.txt")
L1_images = load_L_matrices("L1_min.txt")
MV_data = load_MV("MV.txt")

# for i in  range(64,128):
    # print(i,"--------------------------------------", i)
    # # print(L0_images[i])
    # # print(L1_images[i])
    # print(MV_data[i])
# print(type(MV_data[0]))
# print(len(MV_data))

groups = [MV_data[i:i+64] for i in range(0, len(MV_data), 64)]

# 測試輸出
print(groups[0])  # 查看第一組

# print(groups[0][0])  # 查看第一組

results = process_data(L0_images, L1_images, groups)

def convert_to_hex_formatted(input_file, output_file):
    with open(input_file, "r") as infile, open(output_file, "w") as outfile:
        decimal_data = infile.read().split()  # 讀取所有數據並按空格分割
        
        # 轉換為十六進制並去掉 '0x' 前綴
        hex_data = [format(int(num), '02x') for num in decimal_data]
        
        # 格式化輸出
        lines = []
        header = " ".join([f"{i:02X}" for i in range(128)])  # 第一行編號
        lines.append(header + "\n")
        
        for i in range(0, len(hex_data), 128):
            # line_number = f"{i//128:06d}:"  # 每行的行號
            line = " ".join(hex_data[i:i+128])
            lines.append(line)
            if (i // 128 + 1) % 128 == 0:
                lines.append("\n")  # 每 128 行加一個換行
        
        outfile.write("\n".join(lines))

# 使用範例
convert_to_hex_formatted("L0_max.txt", "L0_hex.txt")
convert_to_hex_formatted("L1_min.txt", "L1_hex.txt")

