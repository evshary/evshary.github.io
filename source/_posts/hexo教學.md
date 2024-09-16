---
title: hexo 教學
date: 2017-09-09 15:22:14
categories:
- 技術
tags:
- tools
---
我之前一直想要自己寫 blog，可以留下些記錄，但是一方面不想要自己架 server，管理有點麻煩
另一方面又希望可以有 markdown 的功能，而這是 Google 的 blogger 所欠缺的，後來發現可以使用 hexo+Github 架設自己的 blog，對我而言是最佳選擇
Github 讓我不用自己架 server，hexo 讓我可以快速有個漂亮的介面，而且還可以用 markdown 來寫 blog

# 第一次安裝

這邊一開始要先安裝好 git 和 npm，兩者的使用就不在這邊多提了。

1. 先在 GitHub 上創立一個新的 repo，像我的話就是 `evshary.github.io`
2. clone 下來並且創立 main 和 source 兩個 branch，這兩個 branch 分別有不同用途，main 用來放顯示的網頁，source 用來放產生網頁的原始檔
3. 首先先切到 source 的 branch，然後開始安裝 hexo (當然要先裝好 npm)
```
# 安裝 hexo command line tool
npm install -g hexo-cli
# 安裝 deployer
npm install hexo-deployer-git --save
# 初始化
hexo init
npm install
```
4. 修改 `_config.yml` 的 deploy 參數，branch 改為 main，這個代表的意思是我們會把產生的網頁放到 main 這個 branch 上
5. 執行 `hexo g` 來產生顯示的網頁
6. 當我們修改好 blog，就可以把 source 的 branch commit 並且 push 上 GitHub
7. 最後執行 `hexo d` 就可以上傳網頁了，這個動作代表著把 main push 上 GitHub
8. 未來的使用都是在 source 的 branch 下 commit 並 push，然後才用`hexo d` 上傳

備註：`hexo d`的上傳可以用 GitHub Action 取代，只要 source branch 有更新，就會自動在 main branch 產生 blog 結果。相關設定可以參考[這邊的範例](https://github.com/evshary/evshary.github.io/blob/source/.github/workflows/deploy.yaml)

# 重裝

未來要在新電腦重建環境就不用像第一次那麼麻煩了

1. 首先在新電腦把 blog 的 repo clone 下來並切到 source 的 branch，如下面指令
```
git clone -b source git@github.com:[你的github帳號]/[repo名稱].git
```
2. 重新安裝相依套件，然後就可以直接開始使用了
```
npm install -g hexo-cli
npm install
```

# 使用

* 建立新文章
  一開始最重要的事怎麼建立新文章
```
hexo n "文章主題"
```
  這時候會在`source/_posts/`底下新增一個md檔案，打開它就可以開始寫blog了

* 根據 markdown 產生 html 頁面
```
hexo g
```
  產生結果會在 `public` 資料夾下

* local 端預覽
  寫完之後的當然要產生頁面來看自己寫的如何，下面這個指令可以建立測試的 server
```
hexo s
```
  這時候開瀏覽器連線 `http://localhost:4000` 應該就可以連上

* push 到 GitHub 上
```
hexo d
```

# 主題

使用 hexo 當然最重要的是漂亮的主題囉，hexo 的 GitHub 上已經有提供許多主題推薦，可以參考 [Themes](https://github.com/hexojs/hexo/wiki/Themes)
不過我個人覺得 [theme-next/hexo-theme-next](https://github.com/theme-next/hexo-theme-next) 比較好看，所以就用這個了
[官網推薦的安裝方法有兩種](https://theme-next.js.org/docs/getting-started/installation) ，一個是用 npm，另一個是直接 clone repo，為了方便未來升級管理，這邊使用 npm 的方式

1. 用 npm 下載 hexo-theme-next，套件會出現在 node_modules 中
```
npm install hexo-theme-next@latest
```
2. 設定檔的部份會先找當前目錄下的 `_config.next.yml`，所以我們先複製一份設定檔出來
```
cp node_modules/hexo-theme-next/_config.yml _config.next.yml
```
3. 接著在 hexo 的設定檔 `_config.yml` 修改 theme 關鍵字，也就是剛剛命名的 next，這樣就順利完成了
```
theme: next
```

# 設定檔

主要會修改到的設定檔有兩個：

* hexo: 位於 `_config.yml`
  - [hexo 官方設定教學](https://hexo.io/docs/configuration)
* hexo-theme-next: `_config.next.yml`
  - [hexo-theme-next 官方教學](https://theme-next.js.org/docs/getting-started/configuration.html)

# 套件

當然 hexo 提供很多套件，我目前用到的是下面這兩個

## google analytics

可參考 [如何讓google analytics追踪你的Hexo Blog](https://blog.marsen.me/2016/08/25/add_google_analytics_to_hexo_blog_1/)
使用方法很簡單，這個功能在 theme 中已經內建，只要開啟即可

1. 先打開 `_config.next.yml`
2. 找到下列字串
```
google_analytics:
  tracking_id: 
```
在 tracking_id 後面填上自己申請的 google analytics ID 就可以了。

## Disqus的留言板功能

可參考 [[Hexo] 加入 Disqus 讓 Blog多個留言功能](https://blog.ivanwei.co/2016/01/03/2016-01-03-add-disqus-to-blog-by-hexo/)
部署在 GitHub 的 hexo 沒有讓訪客留言的功能，所以這時候就需要第三方的整合型留言板 Disqus 了
這個也是跟 theme 綁一起的

1. 開啟 `_config.next.yml`
2. 找到下列字串
```
disqus:
  enable: true
  shortname: evshary
```
3. 確認 enable 為 true，然後在 shortname 填上自己在Disquz註冊的short name就可以囉！

## LocalSearch 的搜尋功能

我們如果要 blog 支援搜尋功能，可參考 [Hexo博客添加搜索功能](https://www.itfanr.cc/2017/10/27/add-search-function-to-hexo-blog/) ，下面列出應該要做的步驟

1. 首先要安裝 `hexo-generator-searchdb` 套件
```
npm install hexo-generator-searchdb --save
```
2. 接著在 `_config.yml` 新增如下設定
```
# Search
search:
  path: search.xml
  field: post
```
3. 開啟`_config.next.yml`，修改 enable 設定
```
# Local search
local_search:
  enable: true
```
4. 最後重新生成啟動即可
```
hexo clean
hexo s -g
```

### 如果搜尋功能不斷轉圈圈

通常會有一種情況搜尋功能會有問題，就是產生的search.xml有文字編碼錯誤

1. 先檢查 search.xml 的語法，可使用 [Validate an XML file](https://www.xmlvalidation.com/) 這個線上網站
2. 網站會告訴你哪邊有錯誤的編碼，可以直接進去修改
3. 如果使用 vscode 的話可以從設定啟動 renderControlCharacters，就會顯示錯誤的字元了
4. 如果有必要可以直接把該字元複製並且使用全域搜尋並修正(因為我們沒辦法打出該字元)

詳情可參考 [HEXO-NexT的Local Search轉圈圈問題](https://guahsu.io/2017/12/Hexo-Next-LocalSearch-cant-work/)

## RSS

如果要在 hexo 上加上 RSS 訂閱，需要使用 hexo-generator-feed 套件

1. 先安裝 hexo-generator-feed
```
npm install hexo-generator-feed --save
```
2. 在 `_config.yml` 內加上如下內容
```
# RSS
feed:
  type: atom
  path: atom.xml
  limit: 10
  hub:
  content:
  content_limit:
  content_limit_delim: ' '
```
3. 最後重新生成啟動即可
```
hexo g
hexo s
```

可參考 [为hexo博客添加RSS订阅功能](https://segmentfault.com/a/1190000012647294)

## 增加 live2d

1. 先安裝必要的 npm 包
```
npm install hexo-helper-live2d --save
npm install live2d-widget-model-shizuku --save
```
2. 設定 `_config.yml`
```
# live2d
# https://github.com/EYHN/hexo-helper-live2d
live2d:
  enable: true
  scriptFrom: local
  pluginRootPath: live2dw/
  pluginJsPath: lib/
  pluginModelPath: assets/
  tagMode: false
  debug: false
  model:
    use: live2d-widget-model-shizuku
  display:
    position: left
```
3. 最後重新生成啟動即可
```
hexo g
hexo s
```

可參考 [用Live2D让看板喵入住你的Hexo博客吧\(^o^)/~](https://bearbeargo.com/posts/how-to-play-with-live2d-on-hexo/)

不過這邊提一下，[EYHN/hexo-helper-live2d](https://github.com/EYHN/hexo-helper-live2d) 已經沒有再更新了，如果上到 GitHub，可能會有些套件安全疑慮，以後可能需要找些替代套件了。
