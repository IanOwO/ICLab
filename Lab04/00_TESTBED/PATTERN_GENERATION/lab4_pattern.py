import numpy as np
import struct

def float_to_hex(f):
    """將浮點數轉換為 IEEE 754 32-bit 16 進制表示"""
    return format(struct.unpack('!I', struct.pack('!f', f))[0], '08X')

def hex_to_float(h):
    """將 IEEE 754 32-bit 16 進制轉換為浮點數"""
    return struct.unpack('!f', struct.pack('!I', int(h, 16)))[0]

def apply_ieee_conversion(matrix):
    """將矩陣轉換為 IEEE 754 格式後再轉回來"""
    return np.array([[hex_to_float(float_to_hex(value)) for value in row] for row in matrix])

def softmax(matrix):
    exp_matrix = np.exp(matrix - np.max(matrix))
    return exp_matrix / exp_matrix.sum(axis=1, keepdims=True)

def load_matrix(filename, rows_per_sample, num_samples):
    """從文件讀取矩陣，轉換回浮點數"""
    with open(filename, "r") as f:
        lines = [line.strip() for line in f.readlines() if line.strip()]  # 避免空行
    
    matrices = []
    for i in range(num_samples):
        sample_lines = lines[i * rows_per_sample:(i + 1) * rows_per_sample]
        matrix = np.array([[hex_to_float(value) for value in line.split()] for line in sample_lines])
        matrices.append(matrix)
        # print(i)
        # print(matrix)
    return matrices

def compute_matrices(pattern):
    # 載入矩陣，每筆測資 5*4，總共 100 筆
    in_str_samples = load_matrix("in_str.txt", 5, pattern)
    in_k_samples = load_matrix("in_k.txt", 4, pattern)
    in_q_samples = load_matrix("in_q.txt", 4, pattern)
    in_v_samples = load_matrix("in_v.txt", 4, pattern)
    weight_samples = load_matrix("in_weight.txt", 4, pattern)
    
    results = []
    
    for i in range(pattern):
        in_str = apply_ieee_conversion(in_str_samples[i])
        in_k = apply_ieee_conversion(in_k_samples[i].T)  # 轉置
        in_q = apply_ieee_conversion(in_q_samples[i].T)  # 轉置
        in_v = apply_ieee_conversion(in_v_samples[i].T)  # 轉置
        weight = apply_ieee_conversion(weight_samples[i].T)  # 轉置
        
        # 計算 K, Q, V
        K = apply_ieee_conversion(in_str @ in_k)
        Q = apply_ieee_conversion(in_str @ in_q)
        V = apply_ieee_conversion(in_str @ in_v)

        sqrt_2 = np.sqrt(2)

        # Score1 計算
        q12_k12T = apply_ieee_conversion(Q[:, :2] @ K[:, :2].T)
        aft1_sqrt2 = apply_ieee_conversion(q12_k12T / sqrt_2)
        exp1 = apply_ieee_conversion(np.exp(aft1_sqrt2))
        Score1 = apply_ieee_conversion(exp1/exp1.sum(axis=1, keepdims=True))
        head_out1 = apply_ieee_conversion(Score1 @ V[:, :2])

        # Score2 計算
        q34_k34t = apply_ieee_conversion(Q[:, 2:] @ K[:, 2:].T)
        aft2_sqrt2 = apply_ieee_conversion(q34_k34t / sqrt_2)
        exp2 = apply_ieee_conversion(np.exp(aft2_sqrt2))
        Score2 = apply_ieee_conversion(exp2/exp2.sum(axis=1, keepdims=True))
        head_out2 = apply_ieee_conversion(Score2 @ V[:, 2:])

        # 合併 head_out1 和 head_out2
        head_out = apply_ieee_conversion(np.hstack((head_out1, head_out2)))

        # 計算 Final_res
        Final_res = apply_ieee_conversion(head_out @ weight)
        
        results.append((q12_k12T, aft1_sqrt2, exp1, Score1, head_out1, q34_k34t, aft2_sqrt2, exp2, Score2, head_out2, Final_res, K, Q, V))
    
    # 將結果轉換回 IEEE 754 hex 並輸出
    with open("in_Final_res.txt", "w") as f3, open("in_read_ans.txt", "w") as f4, open("_q12_k12T.txt","w") as q1, open("_aft1_sqrt2.txt","w") as q2, open("_exp1.txt","w") as q10, open("_Score1.txt","w") as q3, open("_head_out1.txt","w") as q4, open("_q34_k34t.txt","w") as q5, open("_aft2_sqrt2.txt","w") as q6, open("_exp2.txt","w") as q11, open("_Score2.txt","w") as q7, open("_head_out2.txt","w") as q8, open("_bigK.txt","w") as kk, open("_bigQ.txt","w") as qq, open("_bigV.txt","w") as vv:
        for q12_k12T, aft1_sqrt2, exp1, Score1, head_out1, q34_k34t, aft2_sqrt2, exp2, Score2, head_out2, Final_res, K, Q, V in results:
            for row in q12_k12T:
                q1.write(" ".join(str(value) for value in row) + "\n")
            for row in aft1_sqrt2:
                q2.write(" ".join(str(value) for value in row) + "\n")
            for row in exp1:
                q10.write(" ".join(str(value) for value in row) + "\n")
            for row in Score1:
                q3.write(" ".join(str(value) for value in row) + "\n")
            for row in head_out1:
                q4.write(" ".join(str(value) for value in row) + "\n")
            for row in q34_k34t:
                q5.write(" ".join(str(value) for value in row) + "\n")
            for row in aft2_sqrt2:
                q6.write(" ".join(str(value) for value in row) + "\n")
            for row in exp2:
                q11.write(" ".join(str(value) for value in row) + "\n")
            for row in Score2:
                q7.write(" ".join(str(value) for value in row) + "\n")
            for row in head_out2:
                q8.write(" ".join(str(value) for value in row) + "\n")
            for row in Final_res:
                f3.write(" ".join(float_to_hex(value) for value in row) + "\n")
                f4.write(" ".join(str(value) for value in row) + "\n")
            for row in K:
                kk.write(" ".join(str(value) for value in row) + "\n")
            for row in Q:
                qq.write(" ".join(str(value) for value in row) + "\n")
            for row in V:
                vv.write(" ".join(str(value) for value in row) + "\n")
            f3.write("\n")
            f4.write("\n")
            
            q1.write("\n")
            q2.write("\n")
            q3.write("\n")
            q4.write("\n")
            q5.write("\n")
            q6.write("\n")
            q7.write("\n")
            q8.write("\n")
            q10.write("\n")
            q11.write("\n")

            kk.write("\n")
            qq.write("\n")
            vv.write("\n")
    
    print("計算完成，結果已寫入 Final_res.txt")

if __name__ == "__main__":
    pattern_num = 100
    compute_matrices(pattern_num)
