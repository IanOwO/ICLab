# Lab02 Maze

在一個17*17的迷宮中走到終點，其中會有牆壁、怪獸和劍。需要拿到劍後就能夠走過怪獸的格子。迷宮的牆壁只會在偶數格產生。測資中會確保一定有一條路能夠底達終點，但有可能會有怪獸阻擋在中間。若有怪獸阻擋在唯一路徑上，則會保證在能走到的範圍中一定有劍。這次的lab已經能加入fsm的設計和sequential的電路了。

## Grading Policy
- Function Validity : 70%
- Performance : latency * area 30%
- cycle time固定

## Pattern
這次開始就需要自己生測資了，不過還不用自己寫pattern。迷宮的測資確實不好生成，還需要去驗證圖的正確性，否則會導致測出來的不准。基本上以助教給的測資作為優化的一句最理想。最終算performance時latency並沒有偏差太多。

## 想法

我認為在verilog中並不適合使用bfs或dfs等等常見的迷宮演算法，因為對於資源的使用量很難進行控制。因此對於這次迷宮的解法，我選擇使用填死路配合摸牆法來走過正個迷宮。而為了避免超出17\*17的空間，因此我在外面一圈加上了牆，將17\*17的突變成19\*19的圖。在我的第一版設計中，我將填死路與走迷宮的部分分開。但實際上這兩個動作是可以同時進行的，因為填上的死路並非真的不能走，在助教的pattern中仍然能正常使用，因此，可以在填死路的同時在去走迷宮，便能減少latency。

 - 填死路
因為填死路需要花費不少的cycle數，因此我選擇同時對整張圖進行操作，每個cycle都會去比較整張圖中符合能夠刪掉的路並設成牆壁。
1. 四面中有三面以上是牆而自己是路或怪獸
2. 四面中有三面以上是牆而自己是劍，同時已經拿到了劍

 - 走迷宮
我透過二維陣列的方式，紀錄現在的XY座標，便可以在圖上移動。而摸牆法的關鍵是需要按照前進的方向決定探索的順序，e.x. 如果要以逆時針探索，而目前面向下面，則需要按照右下左的順序檢查。正好因為output的資料正是方向，因此不需要再額外開變數儲存。

## 未實作的優化想法
1. latency還是算高，仍有空間優化。我認為是在判斷要走那些格子時是使用封路前的圖，因此相比於先封路在判斷會需要多花兩個latency。

2. 可以嘗試不使用19\*19的圖，只不過在封路或走迷宮時需要做額外判斷，但無法確定這樣面積是否會更小。因為每格只需要2 bits的register而已。

## 心得

這次我是到最後一天與別人討論才發現可以同時封死路和走迷宮的，因此沒有非常多時間可以修改這個新版本的電路。不過這次的performance算蠻不錯的，跟其他人比起來有改到這個點差了不少。