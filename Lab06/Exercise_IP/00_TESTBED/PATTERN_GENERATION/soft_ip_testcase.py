import numpy as np
import time
import random

gf16_int_to_exp = [15, 0, 1, 4, 2, 8, 5, 10, 3, 14, 9, 7, 6, 13, 11, 12]
gf16_exp_to_int = [1, 2, 4, 8, 3, 6, 12, 11, 5, 10, 7, 14, 15, 13, 9, 0]

def gf16_mul(a, b):
    """GF(2^4) 內的乘法"""
    a = gf16_exp_to_int[a]
    b = gf16_exp_to_int[b]
    if a == 0 or b == 0:
        return 0
    log_a = gf16_int_to_exp[a]
    log_b = gf16_int_to_exp[b]
    return gf16_exp_to_int[(log_a + log_b) % 15]

def gf16_div(a, b):
    """GF(2^4) 內的除法"""
    a = gf16_exp_to_int[a]
    b = gf16_exp_to_int[b]
    if b == 0:
        raise ValueError("Division by zero in GF(2^4)")
    if a == 0:
        return 0
    log_a = gf16_int_to_exp[a]
    log_b = gf16_int_to_exp[b]
    return (log_a - log_b) % 15

def poly_div(dividend, divisor):
    """在 GF(2^4) 內進行多項式除法，返回商"""
    dividend = dividend[:]
    
    quotient = [15] * (len(dividend) - len(divisor) + 1)
    print("dividend: ",dividend)
    print("divisor: ",divisor)

    for i in range(len(quotient)):
        if gf16_exp_to_int[dividend[i]] != 0:
            quotient[i] = gf16_div(dividend[i], divisor[0])
            print("quotient[",i,"]: ", quotient[i])
            for j in range(len(divisor)):
                dividend[i + j] = gf16_int_to_exp[gf16_exp_to_int[dividend[i + j]] ^ gf16_mul(quotient[i], divisor[j])]
    
    return quotient

divisor_list = []
dividend_list = []
quotient_list = []

pattern_num = 500
ip_width = 6
for i in range(pattern_num):
    cur_ip_width = random.randint(2,6)

    divisor_width = int(i/100)+2
    # print(i)
    # 生成隨機的被除數與除數（6 次方多項式）
    
    dividend = np.random.randint(0, 16, cur_ip_width).tolist()  # 0 次方到 6 次方

    divisor = np.random.randint(0, 15, divisor_width).tolist()  # 0 次方到 3 次方

    # if i == 0:
    #     dividend = [0,15,15,15,15,15,15]
    #     divisor = [5,10,0,10,0,0]
    # if i == 1:
    #     dividend = [5,10,0,10,0,0]
    #     divisor = [10,15,5,0]

    # 計算商
    quotient = poly_div(dividend, divisor)    
    while len(dividend) < ip_width:
        dividend.insert(0, 15)
    while len(divisor) < ip_width:
        divisor.insert(0, 15)
    while len(quotient) < ip_width:
        quotient.insert(0, 15)

    dividend_list.append(dividend)
    divisor_list.append(divisor)
    quotient_list.append(quotient)

# 將被除數與除數存入 div.txt
with open("div6_3.txt", "w") as f, open("div6_3_ans.txt", "w") as ans:
    for i in range(pattern_num):
        # f.write(" ".join(map(str, dividend_list[i])) + "\n")
        f.write(" ".join(f"{x:2}" for x in dividend_list[i]) + "\n")
        # f.write(" ".join(map(str, divisor_list[i])) + "\n")
        f.write(" ".join(f"{x:2}" for x in divisor_list[i]) + "\n")
        # ans.write( " ".join(map(str, quotient_list[i])) + "\n")
        ans.write( " ".join(f"{x:2}" for x in quotient_list[i]) + "\n")