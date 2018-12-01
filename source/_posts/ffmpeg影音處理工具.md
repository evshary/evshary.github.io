---
title: ffmpeg影音處理工具
date: 2018-12-01 10:16:12
categories:
- tools
tags:
---
# 簡介
有時候需要對影片、音樂做各種處理，例如轉檔、切割等等，這時候可以使用很強大的影音處理神器ffmpeg來做這些操作。

這邊不會細談調整編碼等細節，只是記錄日常常用到的操作指令而已。

# 安裝
## MAC
```
brew install ffmpeg
```

# 使用
## 轉檔
-f代表format
```
ffmpeg -i [要轉的檔案] -f [目標格式] [輸出檔名]
```
有哪些格式可選可用如下指令
```
ffmpeg -formats
```
## 裁減影片
-ss代表從何時開始，-t代表維持時間，-to代表停止的時間
```
# 從5秒開始後的30秒
ffmpeg -i [要轉的檔案] -ss 00:00:05 -t 00:00:30 [輸出檔名]
# 從5秒到25秒
ffmpeg -i [要轉的檔案] -ss 00:00:05 -to 00:00:25 [輸出檔名]
```
## 顛倒影像
-vf代表vedio filter，可以讓影片經過處理，轉換影片角度有下面三種常用

* hflip：水平翻轉
* vflip：垂直翻轉
* transpose=1：順時針轉90度
```
# 水平翻轉
ffmpeg -i [要轉的檔案] -vf hflip [輸出檔名]
# 垂直翻轉
ffmpeg -i [要轉的檔案] -vf vflip [輸出檔名]
# 順時針轉90度
ffmpeg -i [要轉的檔案] -vf transpose=1 [輸出檔名]
# 逆時針轉90度
ffmpeg -i [要轉的檔案] -vf transpose=2 [輸出檔名]
```

## 影片截圖
-an代表不需要聲音，-vframes代表要抓幾張圖，-r代表每秒抓幾張圖
```
ffmpeg -i [要轉的檔案] -an -ss [抓取時間] -vframes [幾張圖] -r [幾張圖] [輸出圖檔]
# 在開始的時間抓一張圖
ffmpeg -i [要轉的檔案] -an -ss 00:00:00 -vframes 1 cover.jpg
# 從頭開始，每10秒抓一張圖
ffmpeg -i [要轉的檔案] -an -ss 00:00:00 -vframes 1 -r 0.1 tmp-%d.jpg
```

## 調整音量大小
-vol代表聲音大小，256是正常
```
ffmpeg -i [要轉的檔案] -n [聲音大小] [輸出檔名]
```

## 播放影音
在ffmpeg內有一個tool是ffplay，可以簡單用來播放影音

雖然沒有進度條，但是如果按著右鍵左右移動也會有進度條的效果

```
ffplay [影片名稱]
```

* 如果只想要播放音樂
```
ffplay -vn [影片名稱]
```
* 如果只想要播放影片
```
ffplay -an [影片名稱]
```
* 重複循環，0代表無限次
```
ffplay -loop [次數] [影片名稱]
```

## 常用
* 影片轉音樂
```
ffmpeg -i [要轉的檔案] -f mp3 [輸出檔名]
```
* 轉換成mp4
```
ffmpeg -i [要轉的檔案] -f mp4 [輸出檔名]
```
* 裁減影片
```
ffmpeg -i [要轉的檔案] -ss [開始時間] -to [結束時間] [輸出檔名]
```
* 抓截圖
```
ffmpeg -i [要轉的檔案] -an -ss 00:00:00 -vframes 1 cover.jpg
```
* 聲音調整
```
# 調大聲音
ffmpeg -i [要轉的檔案] -vol 300 [輸出檔名]
# 調小聲音
ffmpeg -i [要轉的檔案] -vol 200 [輸出檔名]
```
* 手機拍攝如果是反的情況
```
# 順時針
ffmpeg -i [要轉的檔案] -vf transpose=1 [輸出檔名]
# 逆時針
ffmpeg -i [要轉的檔案] -vf transpose=2 [輸出檔名]
```

# 參考
* [FFmepg — 開源且功能強大的影音處理框架](https://medium.com/@NorthBei/ffmepg-%E9%96%8B%E6%BA%90%E4%B8%94%E5%8A%9F%E8%83%BD%E5%BC%B7%E5%A4%A7%E7%9A%84%E5%BD%B1%E9%9F%B3%E8%99%95%E7%90%86%E6%A1%86%E6%9E%B6-568f19388103) - 針對ffmepg的架構進行介紹
* [FFmpeg 常用選項功能說明](https://www.mobile01.com/topicdetail.php?f=510&t=4487488)
* [ffplay常用命令](https://hk.saowen.com/a/ef089cf4a8cf6dab94c276a8ee0fb38c13e25d9549c8d3cc89f0c4a9e7bf0b9b)
* [ffmpeg常用指令介紹](http://wilsbur.pixnet.net/blog/post/146836324-ffmpeg%E5%B8%B8%E7%94%A8%E6%8C%87%E4%BB%A4%E4%BB%8B%E7%B4%B9)