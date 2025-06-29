import numpy as np

def generate_and_save_arrays():
    with open("L0.txt", "w") as l0_file, open("L1.txt", "w") as l1_file:
        for i in range(10):
            # 生成 128x128 的隨機整數數據，範圍 0 到 255
            array_L0 = np.random.randint(0, 256, (128, 128))
            array_L1 = np.random.randint(0, 256, (128, 128))
            random_offset = np.random.randint(0, 6, size=(8000,))            
            
            # 確保 L1 的前 8000 筆數據在 L0 的 0 到 5 之間，且不超過 255
            flat_L0 = array_L0.flatten()
            flat_L1 = array_L1.flatten()
            
            mask = flat_L0[:8000] <= 250  # 只修改 L0 <= 250 的數據
            flat_L1[:8000][mask] = np.minimum(flat_L0[:8000][mask] + random_offset[mask], 255)
            
            array_L1 = flat_L1.reshape(128, 128)
            
            # 寫入數據到同一個文件，每組數據為 128x128，數字間用空格隔開，測資間用換行隔開
            np.savetxt(l0_file, array_L0, fmt='%d', delimiter=' ')
            l0_file.write('\n')
            np.savetxt(l1_file, array_L1, fmt='%d', delimiter=' ')
            l1_file.write('\n')
            
            print(f"Added set {i+1} to L0.txt and L1.txt")

if __name__ == "__main__":
    generate_and_save_arrays()