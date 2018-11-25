---
title: youtube-dl網路影片下載器
date: 2018-11-25 11:38:01
categories:
- tools
tags:
---
# 簡介
當我們要下載網路影片時，通常會去使用browser上的套件來下載，其實除了browser套件外，我們也可以使用command-line的方式，也就是這篇要介紹的youtube-dl。

youtube-dl功能十分強大，也有很多參數可以調整，能下載的網站不只是youtube，也可以是其他熱門網站，例如Facebook等等，更重要的是這個工具有多個平台可以使用(Windows、Mac、Linux)。

除了[指令youtube-dl](https://rg3.github.io/youtube-dl/index.html)以外，我們也可以用GUI的介面的工具[youtube-DLG](https://github.com/MrS0m30n3/youtube-dl-gui)，使用上更為方便，詳請可參考[最強的網路影片下載器　Youtube-dl-gui 只要有網址就能幫你搞定](https://www.kocpc.com.tw/archives/162438)。

# 安裝
## MAC
```
brew install youtube-dl
# 如果有需要後續轉檔的話
brew install ffmpeg
```
## Ubuntu
```
sudo apt-get install youtube-dl
# 如果需要後續轉檔的話
sudo apt-get install ffmpeg
```
## Python
其實更好的方法是使用Python的pip來安裝，因為youtube-dl本身就是使用Python所寫成的，而由於影片的網站更新很快，所以可能要隨時更新到最新版的youtube-dl才行，OS distribution不一定會出的那麼快。
```
pip install --upgrade youtube_dl
# 如果使用python3的話
pip3 install --upgrade youtube_dl
```

# 使用
這邊介紹一些常用的指令

## 支援
* 確定有支援下載哪些影片網站，相關列表也可以從[官網](https://github.com/rg3/youtube-dl/blob/master/docs/supportedsites.md)查詢
```
youtube-dl --extractor-descriptions
```
## 格式
如果我們沒有指定格式的話，通常youtube-dl會幫我們挑最好的

* 指定下載的影片格式
```
# 先查詢有哪些格式可下載
youtube-dl -F [URL]
# 指定下載格式
youtube-dl -f mp4 [URL]
# 或是用format code
youtube-dl -f [列表中的format code] [URL]
```

## 輸出格式
由於官方的輸出格式預設有帶ID(`%(title)s-%(id)s.%(ext)s`)，我們可以將其去除
```
youtube-dl -o '%(title)s.%(ext)s' [URL]
```

## 字幕
* 選擇嵌入特定字幕
  - `--write-sub`代表下載字幕
  - `--embed-sub`代表嵌入字幕
  - `--sub-lang`代表要選擇的字幕
```
# 先列出可下載的字幕列表
youtube-dl --list-subs [URL]
# 嵌入想要的字幕
youtube-dl --write-sub --embed-sub --sub-lang [字幕] [URL]
```
* 直接嵌入所有字幕
  - `--all-subs`選擇所有字幕
```
youtube-dl --write-sub --embed-sub --all-subs [URL]
```

## 轉為音樂格式
如果我們要下載音樂格式的話，基本上需要有ffmpeg的輔助

* 選擇要下載的音樂格式，例如mp3、m4a、flac等等
```
youtube-dl -x --audio-format [音樂格式] [URL]
```
* 可以用`--audio-quality`強迫ffmpeg轉換較高品質的音樂，0是最好，9是最差
```
youtube-dl -x --audio-format [音樂格式] --audio-quality [音樂品質] [URL]
```
* 下載時附上封面(使用youtube截圖)和音樂資訊(作曲者等等)
```
youtube-dl -x --audio-format [音樂格式] --embed-thumbnail --add-metadata [URL]
```

## 下載播放清單
* 其實只要把[URL]換成播放清單的網址即可，不過我們也可以指定開始和結束位址
  - `--playlist-start`：開始
  - `--playlist-end`：結束，也就是倒數第幾個影片
```
youtube-dl --playlist-start [開始位置] --playlist-end [結束位置] [URL]
```

## 常用
我這邊直接列出常用的指令，如果要使用可以直接copy比較快

* 下載mp4影片並加上字幕
```
youtube-dl -f mp4 --write-sub --embed-sub --all-subs -o '%(title)s.%(ext)s' [URL]
```
* 下載mp3音樂，並加上封面
```
youtube-dl -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata [URL]
```

# 參考
* [youtube-dl：下載 YouTube 影片的指令工具（支援 Windows、Linux 與 Mac OS X）](https://blog.gtwang.org/useful-tools/youtube-dl/)
* [Youtube-dl濃縮教學筆記](https://yogapan.github.io/2017/08/16/Youtube-dl%E6%BF%83%E7%B8%AE%E6%95%99%E5%AD%B8%E7%AD%86%E8%A8%98/)