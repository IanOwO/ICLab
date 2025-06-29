# Lab03 Static Timing Analysis

這次需要寫sta的程式碼，模擬計算給定的電路的critical path和worst delay。input會是16個gate的delay值和32條wire。測資會確保不會出現wire loop，且會確保給定的邊經過多步最終都會回到1，且0不會有邊指向他，1不會有邊連出去。而我們需要計算從第0點到第1點的critical path。這題可以理解為將給定的點和邊透過按照topology order的方式去計算其中最長的路徑為何。

## Grading Policy
- Function Validity : 50%
- Pattern : 25%
- Performance : latency \* area \* clock period 25%

## 想法

這次開始需要連pattern都要自己寫，而且這次有特別要求需要
由於按照測資的規定，可以確保

## 心得

我在這堂課之前有不少verilog的經驗，因此在想好演算法的實作細節後，蠻快就能過01了。不過我是第一次使用工作站上的資源，因此花費了蠻多時間在熟悉各種工具，以及處裡latch的情況。建議沒用過的人可以在這次的lab的時間多多練習nWave。由於這次的lab只有組合電路而已，能進行的優化沒有想像中的多。大部分我的優化都是經過反覆嘗試得出的最優解。