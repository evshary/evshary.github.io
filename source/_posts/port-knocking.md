---
title: port knocking
date: 2017-08-27 10:21:28
categories:
- 技術
tags:
- tools
---
# 簡介
port knocking就像是敲門的暗號一樣，以特定順序碰觸port，server就會執行特定指令
我們可以把這個功能用來開port，就像阿里巴巴要用咒語才可以開門一樣。
詳情可參考[port knocking的定義](http://www.portknocking.org/view/about/summary)

# 安裝
我這邊server是用Ubuntu, client是MAC環境。
## server
```bash
sudo apt-get install knockd
```
## client
```bash
brew insrall knock
```

# 設定檔
通常在位置在`/etc/knockd.conf`
最初的設定檔，可參考[manual](http://linux.die.net/man/1/knockd)
這邊是客製化的設定，目的是可以開關port 22，防止有人亂連。
```
[options]
        UseSyslog

[openSSH]
        sequence    = 3389:udp,80:tcp,21:udp,53:tcp,23:udp
        seq_timeout = 5
        command     = /sbin/iptables -I INPUT 1 -s %IP% -p tcp --dport 22 -j ACCEPT
        tcpflags    = syn

[closeSSH]
        sequence    = 443:tcp,80:udp
        seq_timeout = 5
        command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
        tcpflags    = syn
```

功能大概看名字也可以猜出來
* sequence: 敲port的順序
* seq_timeout: 間隔時間
* command: 如果成功敲完，要執行什麼命令，這邊是用開ssh來當示範
* tcpflags: 如果是TCP連線，需要有什麼flag

# 使用
## server端
把`/etc/default/knockd`中的`START_KNOCKD`改成1
然後啟動
```
sudo service knockd start
```
記得防火牆要先設定不讓外面的人進入
```sh
/sbin/iptables -A INPUT --dport 8888 -j DROP
```

## client端
須先安裝knock
```sh
# 開啓
knock -v 192.168.0.1 3389:udp 80:tcp 21:udp 53:tcp 23:udp
# 關閉
knock -v 192.168.0.1 443:tcp 80:udp
```

# 注意
knock不一定要完全正確
例如說如果順序是7000,8000,9000
那麼我們用7000-9000依序敲過去仍然是可以打開
但是如果是分兩次knock就沒有用了
