# Mid Project Maze Router Accelerator (MRA)

這次mid project是要做一個迷宮繞線的加速器。目的是要把圖上相同編號的兩塊macro透過演算法來連線並算出總共的cost。
我們需要按照input給定的順序將不同編號的macro連線起來。而所有的更動都需要回傳到dram上，最後再輸出路徑總共的cost。
給定需要連線的macro可能會有相鄰的，因此需要特別檢查，我也是在測試多的pattern時才檢查到這個問題。
Dram跟我們的MRA會透過AXI-4的協定進行溝通，且會有隨機的delay，因此需要特別留意。
由於這次的maze一樣很大，每張圖有64*64的格子，每格是4bit，因此也會需要用到memory compiler來產生sram。
我在思考過後是用兩個sram來存maze跟cost map，避免重複去跟dram溝通。在運算時，我也是64*64的maze同時進行運算，
也因此對於面積的需求量很高，在最後也花了很多時間去優化才把面積壓到規定的2,500,000內。

## Grading Policy
- Sample case : 20%
- Function Validity : 50%
- Performance : latency ^ 2 * clock period 30%

## 想法

這次的演算法可以分為下面的4個部分，並且會重覆執行到所有的block都被連接起來。

 - Filling Map
   
   1. 要先從起始點往外按照sequence的值填入直到遇到終點。填入的方式在示意圖中會像是wave一樣擴散，但在實作上相當簡單，只要對每個點檢查周遭是否被填入過，並且填入當前的sequence就好。
      > 這裡按照spec的1,2,3 sequence 的話會導致圖需要3 bits，這會使得面積變得很大。
      > 可以改成使用0,0,1,1 sequence，在往回追蹤時只要按照sequence順序以及上下左右的優先級便能找到一樣的路經，不會需要額外處理。
      
  2. 往回追蹤直到回到起始點。sequencec會按照剛剛填入的sequence反向進行。舉例而言，填入時sequence正在0,0,1，則往回追蹤會是1,0,0，接著則是1,1,0,0。


## 心得


這次由於初版的電路面積超過限制，花了很多時間在壓面積，同時也有期中考試以及上機，是我認為這堂課中最累的一個時候。
我認為裡面應該還有很多可以優化的地方，看排名也可以發現這次有很多人有更好的performance。不過我也從中學習到很多東西。
最明顯的應該是不要把一個大的register array放在if-else的條件裡。這在合成時會把整個register array一起合進去，導致會產生比想像中更大的面積。

