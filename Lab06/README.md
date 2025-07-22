# Lab06 BCH Codes Decoder

這次要做BCH的decoder，找出input的syndrome中錯誤的位置，總共要在15個位置中找出最多三個位置的錯誤。
特別要說明的是，這次的運算是要基於Galois field(GF 2^4)，因此會需要理解自己所在的field以及計算的方式。
我們需要自己寫一個多項式division的soft IP，要能夠處理最多6階方程式的相除並輸出商。在soft IP function correctness
的分數中會測試2階到6階的方程式相除並分段給分。而由於需要寫成combinational的形式，需要依靠generate才能做到調整長度。
在decoder中，我們需要做輾轉相除法把syndrome polynomial轉成error locator polynomial，再透過Chien Search
取得對應的error location。

## Grading Policy
- Function Validity : 50%
- Performance : area \* latency \* clock period 30%
- Soft IP function correctness : 20%

## 想法

- Division Soft IP

1. Pattern :這次需要檢查從2階到6階方程式的除法，且除數的次方有可能會小於給定的階數，因此需要特別去檢查。
2. 

- BCH Decoder

1. Pattern : 
這次有提供簡易生成syndrome的方式，而由於只會在15個位置中有最多3個error location，
因此可以直接窮舉全部的情況來保證最後計算的正確性。

## 心得

這次的lab有點麻煩，我們一定需要用到division的soft IP，但是IP的output卻只有商沒有餘數，導致如果在deocder的輾轉相除法中要使用
IP的話，會需要再多進行運算來回推餘數。助教並沒有解釋為什麼會是這樣的設計。我自己是選擇使用IP並計算餘數，就不需要為了decoder重新設計一次division。
不過我需要特別說明，這導致我的面積稍大，latency也較高，如果想要提高performance，可以考慮寫一個新的division，IP只用於最後一階的除法即可。
另外GF(2^4)的運算實在有點痛苦，而且在GF(2^4)的0需要用15，導致某些地方需要特別寫判斷式。
這次還跟midtern project以及期中考重疊，因此我建議可以速速寫完，花更多的時間在project跟期中考對於成績來說比較划算。