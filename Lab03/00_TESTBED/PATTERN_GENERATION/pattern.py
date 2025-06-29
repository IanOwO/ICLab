import random
from collections import deque

def read_input(file_path):
    with open(file_path, 'r') as f:
        data = list(map(int, f.read().split()))
    
    test_cases = []
    index = 0
    num_cases = data[index]  # 讀取測資數
    index += 1
    
    for _ in range(num_cases):
        if index >= len(data):  # 確保還有資料
            break
        
        test_case_id = data[index]  # 測資編號
        index += 1
        
        if index + 64 > len(data):  # 確保有 32 條邊
            break
        edges = [(data[i], data[i+1]) for i in range(index, index + 64, 2)]  # 32條有向邊
        index += 64
        
        weights = [random.randint(0, 15) for _ in range(16)]  # 隨機生成 16 個節點的權重
        
        test_cases.append((test_case_id, weights, edges))
    
    return test_cases

def read_output_input(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    test_cases = []
    index = 0
    
    while index < len(lines):
        test_case_id = int(lines[index].strip())  # 測資編號
        index += 1
        
        weights = list(map(int, lines[index].strip().split()))  # 16個點的權重
        index += 1
        
        edges = []
        while index < len(lines) and lines[index].strip():  # 讀取有向邊
            src, dest = map(int, lines[index].strip().split())
            edges.append((src, dest))
            index += 1
        index += 1  # 跳過空行
        
        test_cases.append((test_case_id, weights, edges))
    
    return test_cases

def build_graph(weights, edges):
    graph = {i: [] for i in range(16)}
    in_degree = {i: 0 for i in range(16)}
    
    for src, dest in edges:
        graph[src].append(dest)
        in_degree[dest] += 1
    
    return graph, in_degree

def topological_sort(graph, in_degree):
    queue = deque([node for node in in_degree if in_degree[node] == 0])
    topo_order = []
    
    while queue:
        node = queue.popleft()
        topo_order.append(node)
        for neighbor in graph[node]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
    
    return topo_order

def find_longest_path(weights, edges):
    graph, in_degree = build_graph(weights, edges)
    topo_order = topological_sort(graph, in_degree)
    
    dist = [-float('inf')] * 16
    dist[0] = weights[0]
    parent = [-1] * 16
    
    for node in topo_order:
        for neighbor in graph[node]:
            if dist[neighbor] < dist[node] + weights[neighbor]:
                dist[neighbor] = dist[node] + weights[neighbor]
                parent[neighbor] = node
    
    path = []
    node = 1
    while node != -1:
        path.append(node)
        node = parent[node]
    path.reverse()
    
    return dist[1], path

if __name__ == "__main__":
    test_cases = read_input("input.txt")
    
    # 清空 output.txt 和 output_input.txt
    open("output.txt", "w").close()
    open("output_input.txt", "w").close()
    
    with open("output.txt", "w") as f, open("output_input.txt", "w") as out_f:
        if not test_cases:
            f.write("Error: Invalid or incomplete input data.\n")
            out_f.write("Error: Invalid or incomplete input data.\n")
        else:
            for i, (test_case_id, weights, edges) in enumerate(test_cases):
                longest_distance, longest_path = find_longest_path(weights, edges)
                
                # 寫入 output.txt
                f.write(f"Test Case {i+1}:\n")
                f.write(f"Total Weight: {longest_distance}\n")
                f.write(f"Longest Path from 0 to 1: {longest_path}\n\n ")
                
                # 寫入 output_input.txt (測資編號獨立一行)
                # out_f.write(f"{test_case_id}\n")
                out_f.write(" ".join(map(str, weights)) + "\n")
                out_f.write(f"{longest_distance}\n")
                # for src, dest in edges:
                #     out_f.write(f"{src} {dest}\n")
                out_f.write("\n")

    # test_cases = read_output_input("output_input.txt")
    
    # # 清空 output.txt 和 output_input.txt
    # open("output_output.txt", "w").close()
    
    # with open("output_output.txt", "w") as f:
    #     if not test_cases:
    #         f.write("Error: Invalid or incomplete input data.\n")
    #     else:
    #         f.write("1000\n\n")
    #         for i, (test_case_id, weights, edges) in enumerate(test_cases):
    #             longest_distance, longest_path = find_longest_path(weights, edges)
                
    #             # 寫入 output.txt
    #             f.write(f"{i}\n")
    #             f.write(f"{longest_distance}\n")
    #             # f.write(" ".join(map(str, longest_path)) + "\n\n")
                