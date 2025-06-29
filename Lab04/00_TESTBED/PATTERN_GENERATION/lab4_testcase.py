import numpy as np
import struct

def float_to_hex(f):
    """將浮點數轉換為 IEEE 754 32-bit 16 進制表示"""
    return format(struct.unpack('!I', struct.pack('!f', f))[0], '08X')

def generate_and_save_matrices():
    filenames = ["in_str.txt", "in_k.txt", "in_q.txt", "in_v.txt", "in_weight.txt"]
    
    # 開啟所有文件，準備寫入
    files = {name: open(name, "w") for name in filenames}
    
    for _ in range(100):  # 產生 100 組測試數據
        matrices = {
            "in_str.txt": np.random.uniform(-0.5, 0.5, (5, 4)),
            "in_k.txt": np.random.uniform(-0.5, 0.5, (4, 4)),
            "in_q.txt": np.random.uniform(-0.5, 0.5, (4, 4)),
            "in_v.txt": np.random.uniform(-0.5, 0.5, (4, 4)),
            "in_weight.txt": np.random.uniform(-0.5, 0.5, (4, 4))
        }
        
        # 逐行寫入對應文件
        for filename, matrix in matrices.items():
            for row in matrix:
                hex_values = [float_to_hex(value) for value in row]
                files[filename].write(" ".join(hex_values) + "\n")
            files[filename].write("\n")
    # 關閉所有文件
    for f in files.values():
        f.close()

if __name__ == "__main__":
    generate_and_save_matrices()
    print("測試數據已成功寫入檔案。")
