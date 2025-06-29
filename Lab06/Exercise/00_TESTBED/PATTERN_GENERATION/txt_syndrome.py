import numpy as np
import itertools
import time

def generate_test_data(length=15, min_ones=1, max_ones=3):
    """生成所有可能的測試數據，每筆數據有15個數字，至少有1個1，最多3個1，其他為0"""
    data = []
    for num_ones in range(min_ones, max_ones + 1):
        for ones_positions in itertools.combinations(range(length), num_ones):
            sample = [0] * length
            for pos in ones_positions:
                sample[pos] = 1
            data.append(sample)
    return np.array(data)

# GF(2^4) 對應表
gf16_int_to_exp = [15, 0, 1, 4, 2, 8, 5, 10, 3, 14, 9, 7, 6, 13, 11, 12]
gf16_exp_to_int = [1, 2, 4, 8, 3, 6, 12, 11, 5, 10, 7, 14, 15, 13, 9, 0]

def gf16_mul(a, b):
    """GF(2^4) 內的乘法，基於表達式對應"""
    if a == 0 or b == 0:
        return 0

    return a * b

def generate_parity_check_matrix():
    """生成 6x15 的 parity check 矩陣"""
    H = np.zeros((6, 15), dtype=int)
    for i in range(6):
        for j in range(15):
            H[i, j] = gf16_exp_to_int[(j * (i + 1)) % 15]
    return H

def compute_syndrome(test_data, H):
    """計算 Syndrome = H * data^T (GF(2^4) 內的運算)"""
    syndromes = []
    for sample in test_data:
        print(sample)
        print(H)
        time.sleep(1)
        syndrome = np.zeros(6, dtype=int)
        for i in range(6):
            for j in range(15):
                syndrome[i] ^= gf16_mul(H[i, j], sample[j])  # GF(2^4) 內的加法即 XOR
            syndrome[i] = gf16_int_to_exp[syndrome[i]]
            # print(syndrome[i])
        syndromes.append(syndrome)
    return np.array(syndromes)

def mark_positions(test_data):
    """標示 test_data 中 1 的位置，若少於 3 個則補上 15"""
    positions = []
    for sample in test_data:
        ones_positions = [i for i, val in enumerate(sample) if val == 1]
        while len(ones_positions) < 3:
            ones_positions.append(15)
        positions.append(ones_positions[:3])
    return np.array(positions)

# 產生測試數據
test_data = generate_test_data()

# 生成 parity check matrix
H = generate_parity_check_matrix()
# print(H)

# 計算 Syndrome
syndromes = compute_syndrome(test_data, H)

# 標示 1 的位置
positions = mark_positions(test_data)

# 輸出測試數據與 Syndrome
print("Test Data:")
print(positions)
print("\nSyndromes:")
print(len(positions))

# 將 Syndrome 存入檔案
with open("syndrome.txt", "w") as f, open("location.txt","w") as p:
    for syndrome in syndromes:
        f.write(" ".join(map(str, syndrome)) + "\n")
    for position in positions:
        p.write(" ".join(map(str, position)) + "\n")
