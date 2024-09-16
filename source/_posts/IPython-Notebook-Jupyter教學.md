---
title: IPython Notebook - Jupyter教學
date: 2018-12-02 22:03:13
categories:
- 技術
tags:
- tools
---
# 簡介
[Jupyter Notebook](https://ipython.org/notebook.html)，過去被稱為ipython notebook，是ipython內的強大工具。

Jupyter最常用在學習資料處理上面，因為輸入指令後就可以產生相對應的圖形結果，做到資料視覺化的功能。而且更重要的是我們可以將自己的結果輸出成html或上傳Github，分享給其他人進行討論。

# 安裝
## MAC
如果有安裝python-pip了，可以直接用如下指令安裝。要是遇到權限問題可以再加上sudo。
```
pip install "ipython[notebook]"
```

# 使用
## 基本操作
* 創造一個資料夾，然後在裡面開啟jupyter notebook
```
mkdir ipython_notebook && cd ipython_notebook
jupyter notebook
# 原本是可以用ipython notebook，但是未來可能會被捨棄
```
* 如果要在別的port開啟
```
jupyter notebook --port 8080
```
接下來在web上應該可以直接連線Jupyter。

選擇New->python3後就可以在web新創一個notebook，值得注意的是這個notebook的副檔名是`.ipynb`，存放位置就是在我們當前的目錄，也就是`ipython_notebook`

## 登入機制
jupyter notebook其實是有登出機制的，在右上角logout後，就要用密碼或token才能登入。

這時候其實可以直接重啟server，或是輸入`jupyter notebook list`來查看token，就可以再次登入了。

## 編輯方式
在Jupyter中，進入notebook後會看到一個可以輸入值的空間，這個叫做cell。cell上面輸入python語法後，按下shift+enter就會產生執行結果。而我們可以增加或減少這些cell。

特別注意原本cell是藍色的，代表在command mode，但是如果點選cell後就會變成綠色，代表進入edit mode。從edit mode跳回command mode只要按下ESC即可。

另外可以注意每個cell可以選擇不同屬性，最常用的還是Code和Markdown。Code就是python的部分，而Markdown則是可以寫上相關的文字敘述。

## 常用快捷鍵
主要可以點選Help->Keyboard Shortcuts來看目前快速鍵怎麼使用(或是按ESC+h更快)

常用快速鍵如下所示：

* `c`：複製當前的cell
* `x`：剪下當前的cell
* `v`：貼上剪貼簿的cell
* `dd`：刪除當前cell
* `a`：在上方插入新的cell
* `b`：在下方插入新的cell
* `shift+enter`：執行當前cell並跳到下一個cell
* `ctrl+enter`：執行當前cell
* `shift+tab`：可以顯示當前函式的使用方法

## 分享
我們除了可以把當前notebook下載成html外，也可以push到Github上並且利用[nbviewer](https://nbviewer.jupyter.org/)這個網站來分享。

舉個例子，[A gallery of interesting Jupyter Notebooks](https://github.com/jupyter/jupyter/wiki/A-gallery-of-interesting-Jupyter-Notebooks)就收集了不少有趣的Juypter Notebook範例。

只要有ipynb上傳到Github，我們就可以看到輸出結果，就像[這個GitHub](https://github.com/lrhgit/uqsa_tutorials/blob/master/preliminaries.ipynb)的結果可以被[nbviewer](http://nbviewer.jupyter.org/github/lrhgit/uqsa_tutorials/blob/master/preliminaries.ipynb)顯示出來。

# 參考
* [ipython notebook安裝教學](https://ericjhang.github.io/archives/e300480b.html)
* [[Day02]Jupyter Notebook操作介紹！](https://ithelp.ithome.com.tw/articles/10192614)
* [[資料分析&機器學習] 第1.2講：Jupyter Notebook介紹](https://medium.com/@yehjames/%E8%B3%87%E6%96%99%E5%88%86%E6%9E%90-%E6%A9%9F%E5%99%A8%E5%AD%B8%E7%BF%92-%E7%AC%AC1-2%E8%AC%9B-jupyter-notebook%E4%BB%8B%E7%B4%B9-705f023e3720)