---
title: GnuPG教學
date: 2018-10-14 11:37:34
categories:
- 技術
tags:
- tools
- GNU tool
---
## 簡介

GPG全名為Gnu Privacy Guard(GnuPG) ，最初的目的是為了加密通訊的加密軟體，是為了替代PGP並符合GPL而產生的。目前很多自由軟體社群要驗證身份也都會需要用到這套工具。

## 使用

### 安裝

* 指令

```bash
# Ubuntu
sudo apt-get install gnupg
# MAX
brew install gnupg
```

* GUI
  * 其實現在GUI介面都做得很好看了，而且也很容易上手，建議可以用GUI的tools。
  * MAC的GUI tools可從[gpgtools.org](https://gpgtools.org/gpgsuite.html)安裝

### 建立key

1. 先產生key
   * 可選擇"RSA & RSA"，key長度為4096
   * 真實姓名就填自己的英文名字，備註可填中文
   * 產生的key會放在`~/.gnupg`這個目錄下
   * 記得要輸入密碼，防止別人入侵系統時可以直接拿到私鑰
   * 最後會產生出user ID的hash(UID)

   ```bash
   gpg --full-generate-key
   # 如果gen key發生問題，可用如下指令後再一次
   gpgconf --kill gpg-agent
   ```

2. 接下來就是產生撤銷憑證，未來忘記密碼可以用來撤銷，因此要小心保管
   * 注意如果key有填utf-8，這步在MAC可能會出問題，不過如果是用GUI卻沒問題，原因並不清楚。

   ```bash
   gpg -o revocation.crt --gen-revoke [UID]
   # 也可以直接放到.gnupg內
   gpg --gen-revoke [UID] > ~/.gnupg/revocation-[UID].crt
   ```

3. 釋出公鑰，這個公鑰可以傳給朋友，或是上傳到server
   * -a：代表匯出明碼
   * -o：代表輸出檔名

   ```bash
   gpg -ao mypublic.asc --export [UID]
   ```

4. 如果是要把朋友的公鑰放入已知道人的清單

   ```bash
   gpg --import friends.asc
   ```

5. 可以用fingerprint顯示自已的公鑰後，弄到pdf上印出

   ```bash
   gpg -v --fingerprint [UID]
   ```

### 管理key

#### 查看、編輯與刪除key

1. 查看目前的鑰匙

   ```bash
   # 列出所有公鑰
   gpg --list-keys
   # 同時看簽名
   gpg --list-sigs
   # 列出所有私鑰
   gpg --list-secret-keys
   ```

2. 編輯key(對key簽名也是用同樣的方法)

   ```bash
   gpg --edit-key [UID]
   ```

3. 刪除已存入key的方式，如果有私鑰要先刪除

   ```bash
   # 先刪除私鑰
   gpg --delete-secret-key [UID]
   # 刪除公鑰
   gpg --delete-key [UID]
   ```

#### 搜尋

1. 首先先搜尋對象的public key
   * 這裡指定的key server是用MIT的，可以找其他也有公信力的Server，可參考[wiki](https://en.wikipedia.org/wiki/Key_server_(cryptographic))

   ```bash
   gpg --keyserver hkp://pgp.mit.edu --search-keys 'Linus Torvalds'
   ```

2. 得到對方的public key後，將其存入`~/.gnupg/pubring.gpg`

   ```bash
   gpg --keyserver hkp://pgp.mit.edu --recv-keys 79BE3E4300411886
   ```

3. 可查看與更新朋友的public key

   ```bash
   gpg --list-keys
   gpg --refresh-keys
   ```

#### import/export

1. 除了搜尋以外，也可以用import/export的方式管理朋友的公鑰

   ```bash
   gpg --import public_keys_list.txt
   gpg --export -ao public_keys_list.txt
   ```

2. import/export自己的金鑰

   ```bash
   # export 公鑰
   gpg --armor --output public-key.asc --export [UID]
   # export 私鑰
   gpg --armor --output private-key.asc --export-secret-keys [UID]
   # import
   gpg --import [金鑰]
   ```

### 用key傳送接收信件

1. 假設我們要傳送secret.tgz給朋友，可以先進行加密

   ```bash
   gpg -ear 朋友 < secret.tgz > secret.tgz.asc
   ```

2. 朋友收到secret.tgz.asc後可用如下指令變回secret.tgz

   ```bash
   gpg -d < secret.tgz.asc > secret.tgz
   ```

3. 如果要確認發信人身份

   ```bash
   # 先對檔案簽名
   gpg --clearsign file.txt
   # 驗證檔案身份
   gpg --verify < file.txt.asc
   ```

## 參考

* [使用 GnuPG 建立你的 PGP 金鑰， 讓別人能夠私密寄信給你](https://newtoypia.blogspot.com/2013/12/gnupg-pgp.html)
* [Debian關於Keysigning的教學](https://wiki.debian.org/Keysigning)
* [GnuPG (正體中文)-GnuPG](https://wiki.archlinux.org/index.php/GnuPG_(%E6%AD%A3%E9%AB%94%E4%B8%AD%E6%96%87))
* [GPG入门教程-阮一峰](http://www.ruanyifeng.com/blog/2013/07/gpg.html)
* [gpg 數位簽章](http://egret-bunjinw.blogspot.com/2013/08/gpg.html)
