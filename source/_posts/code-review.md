---
title: code review
date: 2017-08-27 17:32:24
categories:
- 軟體開發
tags:
---
# 前言
其實我一直對code review有點好奇，到底有什麼樣的好處。
所以統整了些資料，研究看看實行的好處以及如何實行code review。

**重要：這篇只是我想理解code review方式而整理出來的文章，不一定真的實用，之後會隨著我經驗增加而更新內容**

# 好處
1. 品質提升：開發者太熟悉流程了，可能會有盲點，其他人可能可以幫忙找到邏輯問題。
2. 更容易維護：其他人幫忙看code可以確保程式的可讀性，不會只有開發者才看得懂，開發者開發時也因為會有人來看，所以會思考我這樣是否可以讓review的人看懂邏輯。
3. 同步文化、設計理念：確保程式有符合團隊開發的風格、coding style、API使用習慣等等，也比較不會有開發了功能跟原來架構設計理念有落差的情況。
4. 經驗傳承和相互學習：資深員工把經驗傳給新進員工，或是大家彼此間可以學到寫程式的小技巧。
5. 備份功能：確保至少有兩個人知道code的意思。

# 成本
* 開發時需要多花費時間在上面code review上，但長遠來說會減少maintain時間
* 要有正確的心態來review，不然會造成團隊氣氛不佳

# 心態
* code和人是分開的：我們是針對code做討論，而不是質疑人的能力。
* 相互信任：信任團隊沒人會故意寫爛code，有問題是可能只是沒想到而已。
* 相互尊重：
  - 討論過程中是相互學習的關係，而不是監視和監視的關係。
  - review者討論態度語氣不能太尖銳，被review者也要能接受合理的意見
* 相互學習：做code review不只是要維護品質，更重要的是大家可以彼此學習，學會更好的技巧。

# 方法
## 前置作業
* 說明code review規則，以及建立正確的心態
* 事先訂定公司開發的文化，如coding style，命名規則
* 使用工具在處理機械化作業，如coding style統一，減少人為介入

## 開發功能前
* 開發時間需要預估code review的時間
* 先規劃如何將大功能切成小部分：
  - 控制在reviewer 15min內可以看完的程度，這樣reviewer可以在工作一段落時稍微看一下，不佔用太多時間
  - 如果功能出了大問題，也可以把風險控制在最小

## review前
* review前要先準備好環境，可以demo或讓reviewer測試
* 如果有使用分析工具，先使用工具產生報表
  - review時可以針對上面的重點討論
  - 減少review的effort

## review中
* 讓reviewer主導review的過程，這樣才能發現盲點
* code review時間不要超過半小時
* 利用checklist來檢查
  - 功能需求是什麼？設計方式是否有達到目的？
  - 是否可以做未來擴充？
  - 是否足夠安全？有沒有邏輯漏洞？
  - Error handling和corner case是否都有處理好？
  - 程式是否易讀？複雜地方是否有註解？可以再精簡嗎？
  - 有符合團隊coding style嗎？命名好嗎？有沒有通過工具測試？
  - 效能是否可以再提升？
* review過程不改code，用todo list先記錄

## review後
* 要留下reviewer是誰，不是要抓戰犯，而是當開發者不在時，可以知道有誰懂這段code
* review後要留下紀錄提供學習使用
* 定期開會評估code review流程和效用
  - review的方式要不要調整？
  - 工具是否要調整？
  - checklist是否要更新？

# 輔助工具
下面工具只是先整理起來，我並沒有每個都用過，等真正用過再來寫心得吧！
* 統一Glossary：
  - 可以使用wiki等文件建立
* 找重複程式碼：
  - Simian：商用需付費，可參考[CI Server 13 - 找出重複的程式碼 (Simian)](http://ithelp.ithome.com.tw/articles/10106013)
* 判斷複雜度：
  - SourceMonitor：免費，可參考[[Tool]SourceMonitor - 程式碼掃瞄](https://dotblogs.com.tw/hatelove/archive/2010/02/10/sourcemonitor.aspx)
  - Complexity：GNU tool，可參考[Complexity：一个测量 C 代码复杂性的工具](http://hao.jobbole.com/complexity/)
* 分析綜合品質：
  - FxCop：微軟出的，可參考[[Tool]靜態程式碼分析－FxCop](https://dotblogs.com.tw/hatelove/2011/12/18/introducing-fxcop-and-vs2010-static-code-analysis-tool)
  - Adlint：Open source，但似乎很久沒更新了
  - SonarQube：可參考[SonarQube 程式碼品質分析工具](https://poychang.github.io/sonarqube-csharp/)
* 程式法風格：
  - StyleCop：似乎只能用在C#，可參考[[如何提升系統品質-Day17]品質量測工具-StyleCop](http://ithelp.ithome.com.tw/articles/10079546)
  - Artistic Style：可以自動統一所有程式碼的風格，甚至可以綁在git的commit hook上，確保大家不會commit風格不對的code

# 如何實際落實
通常要在運作一段時間的團隊加入新機制並不是那麼的容易，特別是怕會影響正常業務。
所以可以試試沙盒的概念，先少部分的人開始測試使用，
而且也不要一下子就把所有機制加上去，以不一下子造成過多改變為主，慢慢調整
最後相信可以找到適合團隊的做法。

## 可以調整的選項
code review的基本概念是要讓其他人來看開發者的code，以客觀角度檢視，藉此提高品質和增進彼此相互學習
所以只要能達到這個目標的手段其實都是可以接受的，重點是要找到適合團隊的方式
這邊有幾項可以思考的方向：
* review的方式：網路上找到大部分的方式都是git的Pull Request功能，可以線上直接看code，不過或許直接到對方位置看也是個選項。
* review的頻率：這個可以隨團隊開發內容的性質作調整
* review的大小：有些review是多人一起，這個比較適合有很多新進人員，需要一起建立開發文化。不然一般是用peer review即可。

# 如何評估效用
當然code review一定是好處大於壞處才會讓大家採用，那要怎麼評估好處部分呢？
可以從下面幾個方向來想：
1. 執行前後，bug減少的數量(這是品質部分)
2. 執行前後，團隊多花費的時間(這是成本部分)
3. 大家在執行後的感想？是否有所學習？(畢竟學習這種東西很難用數據衡量)
4. 在code review中發現哪些問題？(bug減少數量如果不好統計，可以看有哪些潛在問題被發掘)
5. code品質部分？這部分可以用工具評分或是問問開發者的感受。

# 參考
[Code Review Guidance](https://msdn.microsoft.com/zh-tw/communitydocs/visual-studio/ta14052601)：這篇微軟的文章非常值得一看，該講的都有講出來。
[[如何提升系統品質-Day30]Code Review與總結](http://ithelp.ithome.com.tw/articles/10081797)：這邊有提到許多工具，可以研究看看
[你今天 code review 了嗎？](https://blog.mz026.rocks/20170812/did-you-code-review-today)：這篇也很推薦，對code review的本質和方法有不錯的論述
[參考腾讯Bugly的回答](https://www.zhihu.com/question/41089988)：這邊提到code review如何實現在不同種類團隊上，偏實務方面的文章
[Airbnb 資深工程師分享：怎樣才是正確、有效的 code review](https://buzzorange.com/techorange/2016/08/16/airbnb-code-review/)：提到了code review的正確態度
[我們是怎麼做Code Review的](https://read01.com/JmzyoG.html#.WaJAatOg_OQ)：別人實現code review的經驗
