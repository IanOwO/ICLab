# Lab05 Motion Vector Difference Matching

這次要計算兩張圖片中特定區域的Bilinear Interpolation(BI)，接著計算兩張圖片特定區域
的Sum of Absolute Difference(SAD)，並找出最小的一個SAD值輸出他的編號以及數值。以演算法
的角度來看，這次很簡單，同時也很好理解。難點在於要將兩張圖片都load進電路並且存入sram中，
每張圖片分別是128\*128 pixels，每個pixel有8bit的data。因此，
在存取時就需要考慮一次能從sram讀出的區域大小。而在給定的sram規格下，一定會遇到有情況是需要跨
entry存取。另外要特別說明，這次的lab會在lab11再次被用到，到時候需要用這次的電路去進行apr，
以我的經驗而言，這次performance好的也比較容易在lab11好。

## Grading Policy
- Function Validity : 70%
- Performance : area ^ 2 \* latency \* clock period 30%

## 想法

- sram處理

1. 由於已經知道這次的電路會在後面需要進行apr，因此我有刻意讓sram比較方正一點，確保之後apr時能比較輕鬆。
2. 每次計算需要存取11個pixel，以我自己使用的64bit entry為例，一次能讀8個pixel，理想情況下能夠在兩次讀取完成。
可是如果起始的pixel是落在第一次讀取sram data時的後面2個，就會需要讀取3次。我自己的處理方式是每次都花3個cycle去處理，
統一每次計算的所需的cycle數。
3. 由於計算BI值時需要兩排的資訊，如果我將一張圖片存在一個sram裡的話，計算一排的BI值需要存取sram 6次。
我透過將圖片的奇數和偶數列分別存在兩個sram裡，就能在3次存取sram後開始計算BI值了。

- pipeline方式

- 取最小值

因為這次不需要排序。只需要找出最小值。因此我並沒有用lab01的sorting法，而是讓三個一組比較，第一個cycle比較三組中的三個最小值，下一個cycle就能取得全部最小的值。
由於我認為這次其他地方的loading已經很大，所以就沒有減少這邊使用的比較器。

## 未實作優化想法

可以想辦法去控制讀取sram的次數，我自己的實作方法是固定讀取次數，讓讀取一排pixel全部都是3次讀取。如果需要去控制的話要考慮在兩張圖片取得特定區域會有4種
可能性，需要讓電路能夠對全部情況都能正常處理。

## 心得

這次的lab難度真的很高，雖然從演算法的角度而言很好理解，但是實作細節上有很多需要處理的地方，尤其是在pipeline的部分。
這是由於計算SAD值的方式時並不能按照BI值出來的順序使用，需要特別的使用順序才能減少使用的BI buffer數量。
最終我使用6排的BI buffer完成全部的計算。另外，這次lab學習到的sram相當實用，在下個lab以及兩個project都會用到，
因此這部分蠻需要熟悉的。
