---
title: hexo教學
date: 2017-09-09 15:22:14
categories:
- tools
tags:
---
我之前一直想要自己寫blog，可以留下些記錄，但是一方面不想要自己架server，管理有點麻煩
另一方面又希望可以有markdown的功能，而這是google的blogger所欠缺的
後來搜尋了一下，找到了這篇[使用 Hexo+Github 建立個人網誌](http://lodur46.github.io/post/hexo-github/#more)，發現使用hexo+github對我而言根本是最佳選擇
github讓我不用自己架server，hexo讓我可以快速有個漂亮的介面，而且還可以用markdown來寫blog

# 第一次安裝
這邊一開始要先安裝好git和npm，兩者的使用就不在這邊多提了。

1. 先在github上創立一個新的repo，像我的話就是`evshary.github.io`
2. clone下來並且創立master和source兩個branch，這兩個branch分別有不同用途，master用來放顯示的網頁，source用來放產生網頁的原始檔
3. 首先先切到source的branch，然後開始安裝hexo(當然要先裝好npm)
```
npm install hexo
hexo init
npm install
npm install hexo-deployer-git
```
4. 修改`_config.yml`的deploy參數，branch改為master，這個代表的意思是我們會把產生的網頁放到master這個branch上
5. 執行`hexo g`來產生顯示的網頁
6. 當我們修改好blog，就可以把source的branch commit並且push上github
7. 最後執行`hexo d`就可以上傳網頁了，這個動作代表著把master push上github
8. 未來的使用都是在source的branch下commit並push，然後才用`hexo d`上傳

# 重裝
未來要在新電腦重建環境就不用像第一次那麼麻煩了

1. 首先在新電腦把blog的repo clone下來並切到source的branch，如下面指令
```
git clone -b source git@github.com:[你的github帳號]/[repo名稱].git
```
2. 重新安裝hexo，然後就可以直接開始使用了
```
npm install hexo
npm install
npm install hexo-deployer-git
```

# 使用
* 建立新文章
  一開始最重要的事怎麼建立新文章
```
hexo n "文章主題"
```
  這時候會在`source/_posts/`底下新增一個md檔案，打開它就可以開始寫blog了

* 根據markdown產生html頁面
```
hexo g
```
  產生結果會在`public`資料夾下

* local端預覽
  寫完之後的當然要產生頁面來看自己寫的如何，下面這個指令可以建立測試的server
```
hexo s
```
  這時候開瀏覽器連線`http://localhost:4000`應該就可以連上

* push到github上
```
hexo d
```

# 主題
使用hexo當然最重要的是漂亮的主題囉，hexo的github上已經有提供許多主題推薦，可以參考[Themes](https://github.com/hexojs/hexo/wiki/Themes)
不過我個人覺得[iissnan/hexo-theme-next](https://github.com/iissnan/hexo-theme-next)比較好看，所以就用這個了
安裝方法如下：

1. 先把喜歡的主題clone到themes資料夾下，然後把clone下來的資料夾改名，例如hexo-theme-next改成next
```
git clone https://github.com/iissnan/hexo-theme-next
```
2. 在`_config.yml`修改theme關鍵字，例如我們改成剛剛命名的next
```
theme: next
```

# 套件
當然hexo提供很多套件，我目前用到的是下面這兩個
## google analytics
可參考[如何讓google analytics追踪你的Hexo Blog](https://blog.marsen.me/2016/08/25/add_google_analytics_to_hexo_blog_1/)
安裝方法其實也很簡單，這個套件是跟theme綁在一起的，我們開啟`themes/[自己的主題]/_config.yml`，找到下列字串
```
google_analytics:
```
在後面填上自己申請的google analytics ID就可以了。

## Disqus的留言板功能
可參考[[Hexo] 加入 Disqus 讓 Blog多個留言功能](https://blog.ivanwei.co/2016/01/03/2016-01-03-add-disqus-to-blog-by-hexo/)
部署在github的hexo沒有讓訪客留言的功能，所以這時候就需要第三方的整合型留言板Disqus了
這個也是跟theme綁一起的，所以一樣開啟`themes/[自己的主題]/_config.yml`，找到
```
disqus_shortname:
```
後面填上自己在Disquz註冊的short name就可以囉！

## LocalSearch的搜尋功能
我們如果要blog支援搜尋功能，可參考[Hexo博客添加搜索功能](https://www.itfanr.cc/2017/10/27/add-search-function-to-hexo-blog/)，下面列出應該要做的步驟

1. 首先要安裝`hexo-generator-searchdb`套件
```
npm install hexo-generator-searchdb --save
```
2. 接著在`_config.yml`新增如下設定
```
# Search
search:
  path: search.xml
  field: post
```
3. 開啟`themes/[自己的主題]/_config.yml`enable local_search
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

1. 先檢查search.xml的語法，可使用[Validate an XML file](https://www.xmlvalidation.com/)這個線上網站
2. 網站會告訴你哪邊有錯誤的編碼，可以直接進去修改
3. 如果使用vscode的話可以從設定啟動renderControlCharacters，就會顯示錯誤的字元了
4. 如果有必要可以直接把該字元複製並且使用全域搜尋並修正(因為我們沒辦法打出該字元)

詳情可參考[HEXO-NexT的Local Search轉圈圈問題](https://guahsu.io/2017/12/Hexo-Next-LocalSearch-cant-work/)

## RSS
如果要在hexo上加上RSS訂閱，需要使用hexo-generator-feed套件

1. 先安裝hexo-generator-feed
```
npm install hexo-generator-feed
```
2. 在`_config.yml`內加上如下內容
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

可參考[为hexo博客添加RSS订阅功能](https://segmentfault.com/a/1190000012647294)

# 參考
[使用hexo，如果换了电脑怎么更新博客？使用hexo，如果换了电脑怎么更新博客？](https://www.zhihu.com/question/21193762)
