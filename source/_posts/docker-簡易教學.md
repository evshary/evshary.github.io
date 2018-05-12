---
title: docker 簡易教學
date: 2018-05-12 10:10:01
categories:
- tools
tags:
---
# Installation
## MAC
* 安裝
以前安裝時需要安裝docker和boot2docker，但現在只要到官網下載DOCKER COMMUNITY EDITION (CE)就可以了。

> boot2docker是MAC下輕量的Linux VM，專門用來執行docker daemon

然後以前使用都會用[kitematic](https://kitematic.com/)這個GUI的操作介面，現在docker官方也已經整進去了，我們可以直接透過docker的應用程式下載kitematic(在上方工具列的選項裡)

安裝詳細流程可以參考[如何在 macOS 上安裝 Docker CE](http://blog.itist.tw/2017/06/how-to-install-docker-ce-with-mac-os-and-os-x.html)，寫得非常清楚。

## ubuntu
```sh
sudo apt-get install docker.io
sudo service docker start
```

# 常用指令
可以用一張圖職階概括大部分常用docker的指令，圖片來自[Docker —— 從入門到實踐  附錄一：命令查詢](https://philipzheng.gitbooks.io/docker_practice/content/appendix_command/)

![](https://philipzheng.gitbooks.io/docker_practice/content/_images/cmd_logic.png)

## images
* 尋找images
```sh
docker search XXX
```
* 把images抓下來
```sh
docker pull XXX
```
* 看目前有哪些images
```sh
docker images
```
* 刪除某images
```sh
docker rmi XXX
```

## container
* 看目前有哪些container正在跑
```sh
docker ps
```
* 看包括所有停止的container
```sh
docker ps -a
```
* 讓某個container開始/停止
```sh
docker start/stop XXX
```
* 刪除某container
```sh
docker rm XXX
```
* 看某個container資訊
```
docker inspect XXX
```

## RUN
執行部分其實可以加上很多參數：

* `-d`: 代表以daemon執行(背景執行)
* `-p port:port`: 代表port映射，例如`-p 8080:80`就是把 port 8080 對應到image的 port 80
* `-v dir:dir`: 代表映射目錄，例如`-v /home/share:/var/www:rw`就是把/home/share對應到image的/var/www，且權限為rw。路徑需要為絕對路徑。
* `--rm`：當有container存在時自動移除
* `-i`：互動模式
* `-t`：允許TTY
* `-w path`：設定進入container的工作路徑
* `-e key=value`：帶入環境變數

* 跑images
```sh
docker run --rm -i -t -p 8080:80 nginx
docker run -i -t ubuntu /bin/bash
```
* 背景執行
```sh
docker run -d -p 8080:80 -v shared_dir:/var/www:rw nginx
```

## COMMIT
* 看有甚麼改變
```sh
docker diff XXX
```
* 提交成新的images
```sh
docker commit -m="註解" -a="author" XXX repo_name
```
* 看歷史
```sh
docker history XXX
```

# Dockerfile
我們也可以用Dockerfile產生image，可參考[使用Dockerfile建置](https://peihsinsu.gitbooks.io/docker-note-book/content/docker-build.html)

下面是個範例
```
# base image
FROM ubuntu:14.04

# 執行的command
RUN apt-get update
RUN apt-get install -y nginx

# open port
EXPOSE 80

# 環境變數
ENV PATH $PATH:/home/bin
```

建立image
```
docker build .
```

## 範例
看完command可能還是不清楚怎麼用，這邊用安裝nginx的docker image來說明

### 取得image

首先我們先搜尋nginx
```
$ docker search nginx
NAME                                                   DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
nginx                                                  Official build of Nginx.                        8564                [OK]
jwilder/nginx-proxy                                    Automated Nginx reverse proxy for docker con…   1331                                    [OK]
richarvey/nginx-php-fpm                                Container running Nginx + PHP-FPM capable of…   547
....
```
我們先抓officical的images
```
$ docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
f2aa67a397c4: Pull complete
3c091c23e29d: Pull complete
4a99993b8636: Pull complete
Digest: sha256:0fb320e2a1b1620b4905facb3447e3d84ad36da0b2c8aa8fe3a5a81d1187b884
Status: Downloaded newer image for nginx:latest
```
現在local端就有nginx的image了
```
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              ae513a47849c        11 days ago         109MB
```

### 運行container

開始運行container，並且讓port 8080對應到nginx container的port 80，工作路徑為/home，然後執行bash
```
$ docker run --rm -i -t -p 8080:80 -w /home nginx bash
```
我們也可以選擇背景執行，並且把shared_dir對應到/var/www
```
$ docker run -d -p 8080:80 -v shared_dir:/var/www:rw nginx
```
一定有人會問這樣的情況下怎麼控制bash呢？我們可以用exec command
```
$ docker exec -i -t 78fc bash
```

### 操作運行中的container

看一下當前有的container
```
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
e2cf9ea13bb4        nginx               "nginx -g 'daemon of…"   2 minutes ago       Up 2 minutes        0.0.0.0:8080->80/tcp   priceless_murdock
$ docker inspect e2cf9ea13bb4
[
    {
        "Id": "e2cf9ea13bb477e49f1c0ff75a683555d1a75ef953529087375c83ee1a88b65f",
        "Created": "2018-05-12T06:17:14.979076095Z",
        "Path": "nginx",
        "Args": [
...
```
我們可以隨時中斷或啟動該container
```
$ docker stop e2cf9ea13bb4
$ docker start e2cf9ea13bb4
```

### 提交改變成為新的image

看看該container有什麼改變
```
$ docker diff e2cf9ea13bb4
C /run
A /run/nginx.pid
C /var
C /var/cache/nginx
A /var/cache/nginx/client_temp
A /var/cache/nginx/fastcgi_temp
A /var/cache/nginx/proxy_temp
A /var/cache/nginx/scgi_temp
A /var/cache/nginx/uwsgi_temp
A /var/www
```
commit我們所做的改變變成新的image
```
$ docker commit -m "New nginx" -a "evshary" e2cf new_nginx
sha256:ed66214b3e3a510a7cc47e341f64f6596560164d6f06a22f93dca8d05ecac081
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
new_nginx           latest              ed66214b3e3a        17 seconds ago      109MB
nginx               latest              ae513a47849c        11 days ago         109MB
```
可以從history看我們所做改變歷史
```
$ docker history new_nginx
IMAGE               CREATED              CREATED BY                                      SIZE                COMMENT
ed66214b3e3a        About a minute ago   nginx -g daemon off;                            2B                  New nginx
ae513a47849c        11 days ago          /bin/sh -c #(nop)  CMD ["nginx" "-g" "daemon…   0B
<missing>           11 days ago          /bin/sh -c #(nop)  STOPSIGNAL [SIGTERM]         0B
```

### 刪除container/images

玩膩了，可以刪除images，記得要先刪掉container才行刪images喔
```
$ docker rm e2cf9ea13bb4
$ docker rmi new_nginx
Untagged: new_nginx:latest
Deleted: sha256:ed66214b3e3a510a7cc47e341f64f6596560164d6f06a22f93dca8d05ecac081
$ docker rmi nginx
Deleted: sha256:ae513a47849c895a155ddfb868d6ba247f60240ec8495482eca74c4a2c13a881
Deleted: sha256:160a8bd939a9421818f499ba4fbfaca3dd5c86ad7a6b97b6889149fd39bd91dd
Deleted: sha256:f246685cc80c2faa655ba1ec9f0a35d44e52b6f83863dc16f46c5bca149bfefc
Deleted: sha256:d626a8ad97a1f9c1f2c4db3814751ada64f60aed927764a3f994fcd88363b659
```

# 參考
* [Docker —— 從入門到實踐](https://philipzheng.gitbooks.io/docker_practice/content/)
* [Docker學習筆記](https://peihsinsu.gitbooks.io/docker-note-book/content/)