---
title: HTTP header 安全設定
date: 2018-01-03 22:13:53
categories:
- security
tags:
- web
---
# 總覽
根據[DEVCORE](https://devco.re/blog/2014/03/10/security-issues-of-http-headers-1/)，相關HTTP header可以如下分類

- 防禦 XSS：
  - Content-Security-Policy
  - Set-Cookie: HttpOnly
  - X-XSS-Protection
  - X-Download-Options
- 防禦 Clickjacking：
  - X-Frame-Options
- 強化 HTTPS 機制：
  - Set-Cookie: Secure
  - Strict-Transport-Security
- 避免瀏覽器誤判文件形態：
  - X-Content-Type-Options
- 保護網站資源別被任意存取：
  - Access-Control-Allow-Origin
  - X-Permitted-Cross-Domain-Policies

# 防禦 XSS
## Content-Security-Policy
- 原理：
  - 用來控制不要讀取外部不可信賴資源，可以防止XSS或injection
- 啟動方式：
```
    Content-Security-Policy: policy # policy代表描述你的CSP的策略
```
  - 範例
```
    # 所有內容都來自同一個地方
    Content-Security-Policy: default-src 'self'
    # 比較複雜的設定，不擋image來源，但是設定media和script的來源，注意後方設定會蓋掉default-src的設定
    Content-SecContent-Security-Policy: default-src 'self'; img-src *; media-src media1.com media2.com; script-src userscripts.example.com
    # 推薦設定：因為預設會擋html裡有js,style，但是大部分都會用到，所以要加上unsafe-inline
    Content-Security-Policy: default-src 'self' 'unsafe-inline'
```
- 可參考
  - [内容安全策略( CSP )](https://developer.mozilla.org/zh-CN/docs/Web/Security/CSP/Using_Content_Security_Policy): 對CSP的基本解說
  - [Content-Security-Policy - HTTP Headers 的資安議題 (2)](https://devco.re/blog/2014/04/08/security-issues-of-http-headers-2-content-security-policy/): 對CSP非常詳細的解說，建議一定要看一下。

## Set-Cookie: HttpOnly
- 原理：
  - http only確保javascript無法直接存取cookie。
- 啟動方式：
  - 只要在Set-Cookie的header加上HttpOnly就可以生效了。

## X-XSS-Protection
- 原理：
  - 這是IE引進的功能，可以檢查XSS攻擊，不過firefox不支援。基本上CSP已經提供足夠防禦，但是可以讓不支援CSP舊版瀏覽器有比較高的安全性。
- 啟動方式：
```
    X-XSS-Protection: 0   # 禁止XSS過濾
    X-XSS-Protection: 1   # 允許XSS過濾，遇到XSS會清除頁面
    X-XSS-Protection: 1; mode=block  # 允許XSS過濾，遇到XSS會阻擋頁面加載
```
- 可參考：
  - [mozilla X-XSS-Protection](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/X-XSS-Protection): 詳細介紹這個header在哪些browser支援和有什麼選項
  - [資安JAVA(十一)：X-XSS-Protection](http://likewaylai.blogspot.tw/2012/03/javax-xss-protection.html): 這邊有提到X-XSS-Protection的由來，並且提到IE8之前在這個功能上的問題

## X-Download-Options
- 原理：
  - 在IE8加入了這個選項，防止使用者下載檔案的時候點選直接開啟，避免執行執行了程式而且沒有在下載管理員留下紀錄的問題。
- 啟動方式：
```
    X-Download-Options: noopen
```
- 可參考
  - [Microsoft-自訂下載體驗](https://msdn.microsoft.com/zh-tw/library/jj542450(v=vs.85).aspx): 為什麼要有這個選項
  -  [X-Download-Options: noopen equivalent](https://stackoverflow.com/questions/15299325/x-download-options-noopen-equivalent): 其他browser沒有想對應功能

# 防禦 Clickjacking
## X-Frame-Options
- 原理：
  - 控制frame和iframe顯示頁面的規則，不讓別人可以內嵌頁面。
- 啟動方式：
  - 在header加上X-Frame-Options: XXX，XXX可以是
    - DENY：禁止frame頁面
    - SAMEORIGIN：允許frame顯示同一網站頁面
    - ALLOW-FROM url：允許frame顯示某一網站頁面
```
    X-Frame-Options: SAMEORIGIN
```

# 強化 HTTPS 機制
## Set-Cookie: Secure
- 原理：
  - 強制讓cookie必須要在https的情況下才能傳輸
- 啟動方式：
  - 只要在Set-Cookie的header加上Secure就可以生效了。

## Strict-Transport-Security
- 原理：
  - 當使用者用http連線，強制轉成https連線，這個選項只有在https連線的情況下才有用，如果是http會被忽略(因為可能有MITM)
- 啟動方式：
```
    Strict-Transport-Security: max-age=expireTime [; includeSubdomains]
    # max-age=expireTime: browser要記住這個網站要用https連線的時間
    # includeSubdomains: 哪些subdomain也都要同樣設定
```
- 可參考
  - [Mozilla HTTP Strict Transport Security](https://developer.mozilla.org/zh-CN/docs/Security/HTTP_Strict_Transport_Security): 詳細介紹這個header在哪些browser支援和有什麼選項

# 避免瀏覽器誤判文件形態
## X-Content-Type-Options
- 原理：
  - 告訴client要遵守Content-Type的MIME設定，不要自行偵測，管理者必須要確保自己的設定是沒有錯誤的。
- 啟動方式：
```
    X-Content-Type-Options：nosniff
```
- 可參考
  - [Mozilla X-Content-Type-Options](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/X-Content-Type-Options): 詳細介紹這個header在哪些browser支援和有什麼選項

# 保護網站資源別被任意存取
## Access-Control-Allow-Origin
- 原理：
  - CORS是用來解決腳本的跨域資源請求問題，用來確保資源是否可以被其他網站存取，但是要注意它不能阻擋CSRF
  - 不能阻擋CSRF的原因：
    - CORS是阻擋js所發出的request，但是CSRF可以透過form, tag等發起請求
    - Acess-Control-Allow-Origin是由browser解析的，所以其實request已經發出了，只是response被browser阻擋
- 啟動方式：
```
    Access-Control-Allow-Origin: *
    Access-Control-Allow-Origin: <origin>
```
- 可參考
  - [Mozilla Access-Control-Allow-Origin](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Access-Control-Allow-Origin): 詳細介紹這個header的選項
  - [跨來源資源共享（CORS）](https://developer.mozilla.org/zh-TW/docs/Web/HTTP/CORS):詳細解釋CORS(Cross-Origin Resource Sharing)的功能
  - [實作 Cross-Origin Resource Sharing (CORS) 解決 Ajax 發送跨網域存取 Request](https://blog.toright.com/posts/3205/%E5%AF%A6%E4%BD%9C-cross-origin-resource-sharing-cros-%E8%A7%A3%E6%B1%BA-ajax-%E7%99%BC%E9%80%81%E8%B7%A8%E7%B6%B2%E5%9F%9F%E5%AD%98%E5%8F%96-request.html): 如何用CORS存取外部資源
  - [简单聊一聊 CSRF 与 CORS 的关系:](https://b1ngz.github.io/csrf-and-cors/) CORS並不能防禦CSRF，這篇有很詳細的介紹

## X-Permitted-Cross-Domain-Policies
- 原理：
  - 當不能把crossdomain.xml放在根目錄時需要設定該選項
  - crossdomain.xml: 從別的domain讀取flash時所需要的策略文件
- 啟動方式：
```
    X-Permitted-Cross-Domain-Policies: master-only # master-only代表只允許主策略文件(/crossdomain.xml)
```
- 可參考
  - [Cross Domain Policy](http://blog.xuite.net/fireworkgoldfish/CodeIndex/27179479-Cross+Domain+Policy): 提到關於crossdomain.xml的設定
  - [关于跨域策略文件crossdomain.xml文件](http://blog.csdn.net/summerhust/article/details/7721627): crossdomain.xml的範例
  - [如何使用 HTTP 响应头字段来提高 Web 安全性？](https://toutiao.io/posts/218856/app_preview): X-Permitted-Cross-Domain-Policies相關解說

# 參考
- [11個網站安全防護的 http Header 設定](http://www.qa-knowhow.com/?p=1467): 其他人提到的header設定


