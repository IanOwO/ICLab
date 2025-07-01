# Lab03 Static Timing Analysis

這次需要寫sta的程式碼，模擬計算給定的電路的critical path和worst delay。
input會是16個gate的delay值和32條wire。測資會確保不會出現wire loop，
且會確保給定的邊經過多步最終都會回到1，且0不會有邊指向他，1不會有邊連出去。
而我們需要計算從第0點到第1點的critical path。這題可以理解為將給定的點和邊
透過topology order的方式去計算其中最長的路徑為何。這次開始需要自己寫pattern，
測試自己電路的正確性。同時這次的pattern有額外要求需要找出助教電路中的對應錯誤來拿到分數，
因此無法透過吃檔案給input跟正確答案直接做比對。

## Grading Policy
- Function Validity : 50%
- Pattern : 25%
- Performance : latency \* area \* clock period 25%

## 想法

- pattern

這次開始需要連pattern都要自己寫，可以先透過完成pattern並通過助教的測試來確保pattern的正確性。
我選擇用較接近c的寫法在pattern中計算最大的delay。在驗證路徑的正確性時透過將output的路徑吃下來
，實際走過一樣的路徑並計算輸出路徑的delay總和與一開始給的delay總和是否一樣。透過這樣則不需要將全部最長的路徑
存起來，任意一條的最長路徑都能被檢查。計算最大delay的方式算蠻標準的演算法，就不特別解釋了。

- rtl

我覺得在這次的電路中最關鍵的是將給入的source & destination 反過來使用，也就是將原本開始點0變成結束點，
而結束點1變成開始點。透過這樣的處理便可以在current node到達0時確保全部的路都被走過。只需要走訪全部的點時
紀錄每個點的parent node。就可以在後面從0一步一步走到1，同時輸出這條路徑。最開始需要將start node以外的
node都設定成無限大，而按照給定邊數及大小會發現255是不可能正常產生的delay，因此便可以使用255來當作無限大的值。

對於graph的處理我選擇使用一個16/*16的adjacency matrix，我認為這是由於verilog的特性，並不會像是一般c
在時間複雜度上會變成n/*n，同時動態調整也不適合verilog。我透過將gate delay作為edge weight，舉例來說：
node0到node1這條edge的weight是node1的delay。最後只需要將start node的delay加上去就能得到最大的delay。

## 心得

這次的lab在想好實作的細節後就變得相對簡單一些，比較大的難點是需要去處理輸出最長路徑的方式，以及一開始traversal和計算delay的方式。
我認為在這次的lab中我想到的方式相當不錯。如果在對critical path做額外處理並嘗試去修改的話，也許還能在performance上有一些進步。
這次是我第一次寫pattern，印象中我給reset訊號的時間過短，導致我在某些clock period會出現意外的03 setup time violation。
建議大家如果遇到一樣的狀況也能去檢查一下。在寫pattern時只有這次跟lab10需要寫的比較完整，其他幾個lab都能透過寫高階語言產生對應的input file
和answer，可以減少一些loading，也蠻方便的。這次助教的pattern有一些測資是會在out valid拉下來之後的下一個cycle馬上給input。雖然我沒有特別處理，
但並沒有因此出現error。不過我有幾個朋友遇到了這個問題，最後是在助教討論過後決定扣5分。在寫程式碼時可以稍微注意一下。