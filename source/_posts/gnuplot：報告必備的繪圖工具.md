---
title: gnuplot：報告必備的繪圖工具
date: 2018-12-02 10:15:18
categories:
- 技術
tags:
- tools
---
# 簡介
當我們要製作報告或論文的圖表時，除了excel以外，其實也可以使用gnuplot這套工具。[gnuplot](http://www.gnuplot.info/)非常的強大，除了可以畫各種圖表以外，還可以跨不同平台使用。

我們這邊簡單紀錄一些常用圖表怎麼繪畫。

# 安裝
## MAC
如果我們要正常顯示圖表的話需要有x11，這部分可以安裝APPLE的[XQuartz](https://www.xquartz.org/)即可，這樣啟動gnuplot的時候就會自動啟動XQuartz了，可參考[Can't plot with gnuplot on my Mac](https://apple.stackexchange.com/questions/103814/cant-plot-with-gnuplot-on-my-mac)

接下來安裝gnuplot的時候要特別注意，如果沒有加上`--with-x11`的話，可能會造成`Terminal type set to 'unknown'`的warning，可參考[Can't find x11 terminal in gnuplot Octave on Mac OS](https://stackoverflow.com/questions/24721305/cant-find-x11-terminal-in-gnuplot-octave-on-mac-os)
```
brew install gnuplot --with-x11
```

# 使用
## 基本操作
```
# 啟動
gnuplot
# 畫出sin(x)的圖
plot sin(x)
# 設定範圍，x軸是-10到10，y軸是0到2的cos(x)
plot [x=-10:10] [0:2] cos(x)
# 清空之前的設定
reset
# 結束
exit
```
## 讀取檔案
我們可以把多筆資料先存成檔案，然後再讓gnuplot來讀

我們先存資料到data.txt，中間用空格隔開
```
1 5
2 10
3 15
4 10
5 5
```
執行gnuplot就會看到有許多一點一點資料散佈在plot上
```
gnuplot
plot "data.txt"
```
如果要開啟多個檔案
```
plot "data1.txt", "data2.txt", "data3.txt"
```
## 存成程式
每次都要自己一個個輸入指令說實在太麻煩了，我們可以存成.plt檔，以下面為例存成plot.plt
```
plot "data.txt"
```
進入gnuplot後輸入如下指令即可
```
load "plot.plt"
```
## 圖表上的文字
圖表上面總是要有些文字說明，可參考如下設定
```
# 設定標題
set title "pic_title"
# x軸說明
set xlabel "x(unit)"
# y軸說明
set ylabel "y(unit)"
# 設定線條說明外框
set key box
# 不要線條說明
set nokey
# 如果要修改線條說明
plot "data1.txt" title "title 1", "data2.txt" title "title 2"
```
## 圖表的顯示
也許我們會想改變圖表上面的顯示
```
# 增加格線
set grid
# 數據連成一條線
set style data lines
# x軸的範圍
set xrange [-10:10]
# y軸的範圍
set yrange [-10:10]
# X軸的單位
set xtics x: 每次x軸都增加x
```
plot上其實也可以做一些操作
```
# 使用data.txt，並且畫成線，linestyle為1，linewidth也為1
plot "data.txt" with lines linestyle 1 linewidth 1
# 使用data.txt，pointtype為1，pointsize也為1
plot "data.txt" with point pointtype 1 pointsize 1
# 如果線和點都要的話
plot "data.txt" with linespoints
# 如果要變成長條圖的話
plot "data.txt" with boxes
```
## 儲存成圖片
```
# 要存成png檔案
set terminal png
# 可以加上size資訊
set terminal png size 1200,800
# 輸出圖片，這個指令會等待後續的plot
set output "output.png"
# 輸出圖片
plot .....
# 記得要再改回x11
set terminal x11
```
## 常用
* 折線圖
  - 先產生出data.txt
  - 使用在gnuplot中load如下plt檔
```
reset
set title "pic_title"
set xlabel "x(unit)"
set ylabel "y(unit)"
set terminal png
set output "output.png"
plot "data.txt" with linespoints title "title 1"
```
* 長條圖
  - 先產生出data.txt
  - 使用在gnuplot中load如下plt檔
```
reset
set title "pic_title"
set xlabel "x(unit)"
set ylabel "y(unit)"
set terminal png
set output "output.png"
# 設定長條圖的size
set boxwidth 0.3
plot "data.txt" with boxes title "title 1"
```
# 參考
* [實驗基本數據製圖指令 gnuplot](http://applezulab.netdpi.net/08-useful-tools/gnuplot_basic)
* [Gnuplot 簡單數據繪圖](https://ithelp.ithome.com.tw/articles/10158860)
* [gnuplot 語法解說和示範](https://hackmd.io/s/Skwp-alOg)