# Lab04 Two Head Attention

這次的lab是要做two head attetion，實際上就是進行許多的矩陣運算，
包含矩陣的乘法、scaling、softmax。因此對於這種形式的運算，就需要進行pipeline的處理。
在這次的矩陣中，我們需要進行的運算是floating point，因此需要透過使用符合ieee規格的
floating point DesignWare IP。因為這部分的電路很大，需要共用這些IP才能避免超出面積的最大限制。

## Grading Policy
- Function Validity : 70%
- Performance : area \* latency \* clock period 30%

## 想法

- 因為需要進行pipeline才能有好的performance，因此我建議先畫pipeline diagram來確定自己的datapath。
這樣才能方便的計算所需要的IP數量和共用的可能性。由於會需要共用IP，因此我認為透過用case去管理IP的input和output
比較方便，可以快速配置IP空閒的cycle。

- 我發現這次的許多數值在運算過後就不會再次被用到，所以我進行register的共用來省一些面積。這次的數值是32個bit的多個矩陣，
因此在面積上會省到滿多的。另外我有透過傳遞變數，讓我可以從固定一個位置來取得需要進入IP計算的數值。

- 合成需要蠻多時間的，因此可以先確保自己03過了之後再來修改。如果03一直fail，可以考慮將所有變數都進行reset，簡單的排除這個部分的問題。
我在這次的lab之後大部分03 error都是因為reset的問題。

## 未實作優化想法

可以提早在input矩陣就開始計算，減少後面除法IP的loading，才能在不影響latency情況下減少除法IP的使用。

## 心得

我認為這次難度有比上次還高，也很難提供夠多具體的想法。概述就是進行pipeline和資源共用，但有許多實作上的細節需要處理。
由於這次合成需要花蠻多時間的，因此也很難有太多時間去嘗試不同的寫法。我自己是嘗試我最初的想法，沒有做非常細的pipeline，
一次對一排進行運算，並且想辦法只使用5個除法IP。這部分是汲取考古的心得，知道除法IP面積很大。幸好我寫完後面積並沒有爆掉。
不過最後沒有再壓clock period的原因是因為面積逼進極限了，也許做更細的pipeline便可以減少面積，就能有空間去壓低clock period。
我後來有想一個更細的pipeline，能夠減少乘法跟加法IP的個數，但是會稍微提升一點latency，因此在performance上只會提升一點點，
沒辦法像best code一樣能夠減少除法IP的個數。
