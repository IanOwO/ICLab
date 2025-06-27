# Lab01 Huffman Coding

實作5個數字的huffman coding，每個數字分別是5 bits。只能使用組合電路。Clock period是固定的，因此performance只看面積而已。

## Grading Policy
- Function Validity : 70%
- Performance : area 30%
- cycle time固定20ns、只能使用組合電路

## 想法

這次只能使用組合電路進行設計，我並不確定是否能實作出min-heap priority queue來建構huffman tree。因此我在這次的lab中選擇用sorting配合窮舉法來設計這次的電路。在畫出樹狀圖後，我發現如果進行排序後，只會有4種樹的形狀，且能夠在各層的比較時順便得到樹的樣子。

 - Sorting
> 可以參考https://bertdobbelaere.github.io/sorting_networks.html。聽說以前有用到不只一次，但我只有在這次的lab用到而已。

在sorting前，我將原先給入的數字加上他們最終需要被shift的位數，在最後output時可以直接shift並將encode結果移到正確位置上。

 - Tree Construction
> 總共需要4次運算，才能建構出這5個數字的huffman tree。我透過設立2個flag來區分各種樹的長相
1. 可以直接給定最小的2個數字的最小一位encode結果和算出他們的總和
2. 用總和去比較第二大的數字，就能夠判斷這次要使用的兩個數字為何，接著再去給定encode結果和算出總和
3. 根據第二次計算的結果來決定這次應該用哪些數值進行比較
4. 用2個flag來給定最終的encode結果

## 心得

我在這堂課之前有不少verilog的經驗，因此在想好演算法的實作細節後，蠻快就能過01了。不過我是第一次使用工作站上的資源，因此花費了蠻多時間在熟悉各種工具，以及處裡latch的情況。建議沒用過的人可以在這次的lab的時間多多練習nWave。由於這次的lab只有組合電路而已，能進行的優化沒有想像中的多。大部分我的優化都是經過反覆嘗試得出的最優解。