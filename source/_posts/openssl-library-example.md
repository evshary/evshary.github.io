---
title: 使用 openssl 工具與函式庫
date: 2018-05-13 17:34:33
categories:
- protocol
tags:
---
# 安裝openssl
## MAC
```
$ brew install openssl
```
MAC上如果要使用library有點麻煩，需要先找到對應的路徑
```
$ find /usr/local/Cellar/ -name "libssl.*"  # 找到library的路徑
/usr/local/Cellar//openssl/1.0.2o_1/lib/pkgconfig/libssl.pc
/usr/local/Cellar//openssl/1.0.2o_1/lib/libssl.dylib
...
$ find /usr/local/Cellar/ -name "ssl.h"  # 找到header的路徑
/usr/local/Cellar//node/8.4.0/include/node/openssl/ssl.h
/usr/local/Cellar//openssl/1.0.2o_1/include/openssl/ssl.h
...
```
看起來路徑是在`/usr/local/Cellar/openssl/1.0.2o_1/`我們先記起來，後面編譯時會用到。

# 創造憑證
openssl本身就有提供很多好用的工具，我們最常用到的大概就是用來產生憑證吧！

這邊介紹產生兩種常見憑證(RSA,ECC)的方法。
## 產生RSA憑證
```
# 產生2048長度的key
$ openssl genrsa -out server.key 2048
# 用key產生CSR，指定用sha384簽CSR
$ openssl req -new -sha384 -key server.key -out server.csr
# 產生自簽名證書
$ openssl x509 -req -sha1 -days 3650 -signkey server.key -in server.csr -out server.crt
```
## 產生ECC憑證
```
# 產生ECC key
$ openssl ecparam -genkey -name secp384r1 -out ecc.key
# 用key產生CSR，指定用sha384簽CSR
$ openssl req -new -sha384 -key ecc.key -out ecc.csr
# 產生自簽名證書
$ openssl x509 -req -sha1 -days 3650 -signkey ecc.key -in ecc.csr -out ecc.crt
```

# 使用openssl內建的連線工具
有時候我們只是想要測試ssl連線而已，還要自己寫程式有點麻煩，還好我們可以使用openssl提供的連線工具

client和server都有提供，非常方便的！

## client
* `-msg`：看細節(hex格式)
* `-cipher`：決定要用哪種cipher連線
* `-showcerts`：把cert的chain也列出來
* `-curves`：指定要用的橢圓算法，client hello的extension中的elliptic_curves
* `-sigalgs`：指定交換key要用的簽名方式，client hello的extension中的signature_algorithms
* `-no_tls1 -no_ssl3`：加上後就可以只用tls1.2連線了
```
# 最基本連線
$ openssl s_client -connect [IP]:[port]
# 看連線細節
$ openssl s_client -msg -connect [IP]:[port]
# 指定連線方式
$ openssl s_client -connect sslanalyzer.comodoca.com:443 -cipher ECDHE-RSA-AES128-GCM-SHA256 -curves secp384r1 -sigals RSA+SHA512
# 限制只能用TLS1.2連線
$ openssl s_client -no_tls1 -no_ssl3 -connect [IP]:[port]
```
## server
```
# server開啟5678 port並且用server.key當private key，cert用server.pem
$ openssl s_server -accept 5678 -key server.key -cert server.pem
```
## 其他
```
# 如果要看有哪些連線方式，可使用如下指令
$ openssl ciphers ALL
```

# 函式庫使用
我們來介紹openssl的函式庫最基本的使用方式。
## 基本範例 - client & server
這邊寫了兩個client和server的基本範例當作參考，大家可以基於這兩者來拓展自己的程式。
### 程式碼
ssl_client.c
```c
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <openssl/ssl.h>

#define RECV_SIZE 256

SSL_CTX *create_sslcontext()
{
    const SSL_METHOD *method;
    SSL_CTX *ctx;
    // Support only TLSv1.2
    method = TLSv1_2_client_method();
    // Create context
    ctx = SSL_CTX_new(method);
    if (!ctx) 
        return NULL;
    return ctx;
}

int create_socket(char *ip, int port)
{
    int fd;
    struct sockaddr_in addr;

    // New socket
    if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0 )
        return -1;
    // TCP connect to server
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        return -1;

    return fd;
}

// Usage: ./ssl_client.out [IP] [port]
int main(int argc, char *argv[])
{
    int fd;
    SSL_CTX *ctx;
    int port;
    int len;
    SSL *ssl;
    char buf[RECV_SIZE];
 
    if (argc != 3)
        return -1;
    // Parse parameter
    port = atoi(argv[2]);
    printf("Connect to %s:%d\n", argv[1], port);

    // SSL init
    OpenSSL_add_ssl_algorithms();
    // Create SSL_CTX
    if ((ctx = create_sslcontext()) == NULL)
        return -1;
    // Create socket
    if ((fd = create_socket(argv[1], port)) < 0)
        return -1;
    // Start to build ssl connection
    ssl = SSL_new(ctx);
    SSL_set_fd(ssl, fd);
    if (SSL_connect(ssl) <= 0) 
        return -1;
    // SSL write/read
	do {
        printf("Write data to server (q for quit): ");
        memset(buf, 0, sizeof(buf));
        gets(buf);
        if (strcmp("q", buf) == 0)
            break;
        if (SSL_write(ssl, buf, strlen(buf)) < 0)
            break;
        memset(buf, 0, sizeof(buf));
        len = SSL_read(ssl, buf, RECV_SIZE);
        if (len < 0)
            break;
        else
            printf("Recv %d bytes: %s\n", len, buf);
    } while(1);
    // SSL close
    SSL_shutdown(ssl);
    // Free resource
    SSL_free(ssl);
    close(fd);
    SSL_CTX_free(ctx);
    EVP_cleanup();
    return 0;
}
```
ssl_server.c
```c
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <openssl/ssl.h>

#define SSL_CERT "server.crt"
#define SSL_KEY  "server.key"   

#define BUF_LEN  256

SSL_CTX *create_sslcontext()
{
    const SSL_METHOD *method;
    SSL_CTX *ctx;
    // Support only TLSv1.2
    method = TLSv1_2_server_method();
    // Create context
    ctx = SSL_CTX_new(method);
    if (!ctx) 
        return NULL;
    return ctx;
}

int configure_sslcertkey_file(SSL_CTX *ctx)
{
    SSL_CTX_set_ecdh_auto(ctx, 1);
    // Load certificate file
    if (SSL_CTX_use_certificate_file(ctx, SSL_CERT, SSL_FILETYPE_PEM) <= 0) 
        return -1;
    // Load private key file
    if (SSL_CTX_use_PrivateKey_file(ctx, SSL_KEY, SSL_FILETYPE_PEM) <= 0 )
        return -1;
    return 0;
}

int create_socket(int port)
{
    int fd;
    struct sockaddr_in addr;

    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0 )
        return -1;
    if (bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
        return -1;
    if (listen(fd, 1) < 0)
        return -1;

    return fd;
}

// Usage: ./ssl_server.out [port]
int main(int argc, char *argv[])
{
    int server_fd, client_fd;
    SSL_CTX *ctx;
    SSL *ssl;
    struct sockaddr_in addr;
    uint len = sizeof(addr);
    int port;
    char buf[BUF_LEN];
 
    if (argc != 2)
        return -1;
    port = atoi(argv[1]);
    printf("Listen port: %d\n", port);

    // SSL init
    OpenSSL_add_ssl_algorithms();
    // Create SSL_CTX
    if ((ctx = create_sslcontext()) == NULL)
        return -1;
    // Configure cert and key
    if (configure_sslcertkey_file(ctx) < 0)
        return -1;
    // Create socket
    if ((server_fd = create_socket(port)) < 0)
        return -1;
    // Accept connection
    if ((client_fd = accept(server_fd, (struct sockaddr*)&addr, &len)) < 0)
        return -1;
    // Build SSL connection
    ssl = SSL_new(ctx);
    SSL_set_fd(ssl, client_fd);
    if (SSL_accept(ssl) <= 0) 
        return -1;
    // SSL read/write
    while(1)
	{
        memset(buf, 0, sizeof(buf));
        len = SSL_read(ssl, buf, BUF_LEN);
        if (len <= 0)
            break;
        else
            SSL_write(ssl, buf, strlen(buf));
    }
    // Close client
    SSL_free(ssl);
    close(client_fd);
    // Close server and relase resource
    close(server_fd);
    SSL_CTX_free(ctx);
    EVP_cleanup();
    return 0;
}
```

### 編譯與執行
接下來寫個簡單的Makefile，這時候就要用到前面所找到的路徑了。
```mak
SSL_PATH=/usr/local/Cellar/openssl/1.0.2o_1/
CFLAGS=-I$(SSL_PATH)include -L$(SSL_PATH)lib/ -lcrypto -lssl
CC=gcc
BIN=ssl_server ssl_client

all: $(BIN)

ssl_server: ssl_server.c
        $(CC) $^ -o $@.out $(CFLAGS)

ssl_client: ssl_client.c
        $(CC) $^ -o $@.out $(CFLAGS)

clean:
        -rm *.o
        -rm *.out
```
**這邊要特別記住`-lcrypto -lssl`要放最後面，不然有些平台會有error**

然後就可以執行看看了
```
$ make
$ ./ssl_server 2222
Listen port: 2222
```
這時候另一邊再來執行client
```
./ssl_client.out 127.0.0.1 2222
Connect to 127.0.0.1:2222
Write data to server (q for quit): abcd
Recv 4 bytes: abcd
```
可以順利收送資料了！

# 參考
* [How to link OpenSSL library in macOS using gcc?](https://unix.stackexchange.com/questions/346864/how-to-link-openssl-library-in-macos-using-gcc)
* [Simple TLS Server](https://wiki.openssl.org/index.php/Simple_TLS_Server)