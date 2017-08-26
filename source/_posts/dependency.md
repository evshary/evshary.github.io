---
title: dependency
date: 2017-08-26 12:31:42
categories:
- GNU tool
tags:
- Makefile
---

# 問題
通常我們都會用Makefile來看相依性，如果有改動make會自動幫我們判別
但是有些情況，make可能無法判斷
以下面為例，我們有四個檔案：main.c, test.c, test.h, private.h

main.c
```c
#include "test.h"

int main() {
    test();
    return 0;
}
```
test.c
```c
#include <stdio.h>
#include "private.h"
#include "test.h"

void test()
{
    printf("test=%d\n", PRIV_VALUE);
    return;
}
```
test.h
```c
#ifndef _TEST_H
#define _TEST_H

void test();

#endif
```
private.h
```c
#ifndef _PRIVATE_H
#define _PRIVATE_H

#define PRIV_VALUE 3

#endif
```

然後假設我們的Makefile是這樣寫
```
CC=gcc
OBJ=$(patsubst %.c,%.o,$(wildcard *.c))
BIN=main.out

%.o: %.c
    $(CC) -c $^

all: $(OBJ)
    $(CC) $^ -o $(BIN)

clean:
    rm *.o $(BIN)
```
我們試著修改private.h的MACRO值，就會發現重新make結果還是不變，需要重新make clean

# 解法
可以使用gcc的特殊option

* gcc -M xxx.c: 找出所有相依檔
* gcc -MM xxx.c: 同-M，但不含系統檔
```
main.o: main.c test.h
```
* gcc -MP -MM xxx.c: 會加上其他header，避免某些compiler error
```
test.o: test.c test.h
          
test.h:
```
* -MF file: 輸出的dependency檔案名
* -MD: 同-M -MF
* -MMD: 同-MM -MF
* -MT: 可以更改dependency檔案內的目標，可參考[关于 gcc MT MF[转] ](http://blog.sina.com.cn/s/blog_717794b70101gjca.html)

因此只要把Makefile改成這樣即可
```
CC=gcc
OBJ=$(patsubst %.c,%.o,$(wildcard *.c))
BIN=main.out

all: $(OBJ)
    $(CC) $^ -o $(BIN)

-include $(OBJ:.o=.d)

%.o: %.c
    $(CC) -c $<
    $(CC) -MM $< > $*.d

clean:
    rm *.o $(BIN) *.d
```

`-`代表如果有錯誤不要停止執行，`$(OBJ:.o=.d)`代表把.o換成.d，因此會變成類似
```
test.o: test.c private.h test.h
main.o: main.c test.h
```

由於該rule底下沒有statement，所以會直接對應`%.o: %.c`

# 參考
* [Auto-Dependency Generation](http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/)
* [GCC 技术参考大全 附录D 命令行选项](http://www.ncpress.com.cn/zhuanti/0613_1360GCC/d-015.htm)
