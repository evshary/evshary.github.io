---
title: gcc常用擴充功能
date: 2018-06-09 16:50:13
categories:
- 技術
tags:
- 系統程式
- GNU tool
---
## 簡介

GNU gcc其實在編譯時也可以帶許多特殊功能，讓程式更佳的彈性，並帶來優化或更好debug的效益。這邊我們主要介紹兩個功能，內建函式和屬性`__attribute__`。

## 內建函式

要特別注意的是，這些內建函數是跟CPU架構息息相關，所以並不是每個平台都可以順利使用。另外就是編譯的時候不能帶上`-fno-builtin`選項，通常`-fno-builtin`是為了幫助我們確保程式的結果是如同我們所想像的樣子呈現，而不會被一些最佳化改變樣子，方便設定breakpoint和debug。

### 找呼叫者

首先我們先來談談找呼叫者這件事，我想大家應該都有經驗曾經發現程式死在某一行，但是卻不知道是誰呼叫的，這時候只能痛苦地去從stack反推return address。但是其實gcc內是有特殊內建函式可以幫助我們的，這邊介紹下面兩個好用函式。

* `void *builtin_return_address(unsigned int LEVEL)`：找到函式的return address是什麼，參數的LEVEL代表要往上找幾層，填0的話代表呼叫當前函式者的下一個執行指令。
* `void *builtin_frame_address(unsigned int LEVEL)`：找到函式的frame pointer，參數的LEVEL代表要往上找幾層，填0的話代表呼叫當前函式者的frame pointer。

要注意的是LEVEL不能填變數，也就是編譯時必須確定該數字。

#### 範例

我們還是透過一個簡單的例子來說明一下

test.c

```c
#include <stdio.h>

void test3(void)
{
    void *ret_addr, *frame_addr;
    ret_addr = __builtin_return_address(0);
    frame_addr = __builtin_frame_address(0);
    printf("0: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    ret_addr = __builtin_return_address(1);
    frame_addr = __builtin_frame_address(1);
    printf("1: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    ret_addr = __builtin_return_address(2);
    frame_addr = __builtin_frame_address(2);
    printf("2: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    ret_addr = __builtin_return_address(3);
    frame_addr = __builtin_frame_address(3);
    printf("3: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    printf("test3\n");
}

void test2(void)
{
    void *ret_addr, *frame_addr;
    ret_addr = __builtin_return_address(0);
    frame_addr = __builtin_frame_address(0);
    printf("0: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    ret_addr = __builtin_return_address(1);
    frame_addr = __builtin_frame_address(1);
    printf("1: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    ret_addr = __builtin_return_address(2);
    frame_addr = __builtin_frame_address(2);
    printf("2: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    printf("test2\n");
    test3();
}

void test1(void)
{
    void *ret_addr, *frame_addr;
    ret_addr = __builtin_return_address(0);
    frame_addr = __builtin_frame_address(0);
    printf("0: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    ret_addr = __builtin_return_address(1);
    frame_addr = __builtin_frame_address(1);
    printf("1: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    printf("test1\n");
    test2();
}

void test(void)
{
    void *ret_addr, *frame_addr;
    ret_addr = __builtin_return_address(0);
    frame_addr = __builtin_frame_address(0);
    printf("0: ");
    printf("ret_addr=0x%x frame_addr=0x%x\n", ret_addr, frame_addr);
    printf("test\n");
    test1();
}

int main()
{
    test();
    return 0;
}
```

好，那我們來編譯並執行看看

```bash
$ make test
$ ./test
0: ret_addr=0x4007c8 frame_addr=0x2bba8ba0
test
0: ret_addr=0x4007bc frame_addr=0x2bba8b80
1: ret_addr=0x4007c8 frame_addr=0x2bba8ba0
test1
0: ret_addr=0x40076d frame_addr=0x2bba8b60
1: ret_addr=0x4007bc frame_addr=0x2bba8b80
2: ret_addr=0x4007c8 frame_addr=0x2bba8ba0
test2
0: ret_addr=0x4006e1 frame_addr=0x2bba8b40
1: ret_addr=0x40076d frame_addr=0x2bba8b60
2: ret_addr=0x4007bc frame_addr=0x2bba8b80
3: ret_addr=0x4007c8 frame_addr=0x2bba8ba0
test3
```

可以看到每層function所對應的return address和frame address都被列出來，但是要怎麼驗證是否真的是這樣呢？我們把程式逆向一下看位置。這邊我們鎖定test1()的return address，也就是0x4007bc，應該是test()函式的呼叫test1()的下一行。

```bash
$ objdump -d test
...
0000000000400770 <test>:
  400770:       55                      push   %rbp
  400771:       48 89 e5                mov    %rsp,%rbp
...
  4007b2:       e8 59 fc ff ff          callq  400410 <puts@plt>
  4007b7:       e8 28 ff ff ff          callq  4006e4 <test1>
  4007bc:       90                      nop
  4007bd:       c9                      leaveq
  4007be:       c3                      retq

00000000004007bf <main>:
...
```

的確，下一行nop的位置就是就是4007bc，符合我們的想法。

### 其他有用的builtin函式

除了上面的例子，其實還有其他有用的builtin函式，這邊就只是列出來提供參考：

* `int __builtin_types_compatible_p(TYPE1, TYPE2)`：檢查TYPE1和TYPE2是否是相同type，相同回傳1，否則為0。注意這邊const和非const會視為同種類型。
* `TYPE __builtin_choose_expr(CONST_EXP, EXP1, EXP2)`：同`CONST_EXP?EXP1:EXP2`的概念，但是這個寫法會在編譯時就決定結果。常用方式是在寫macro時可以搭配`__builtin_types_compatible_p`當作CONST_EXP，選擇要呼叫什麼函式。
* `int __builtin_constant_p(EXP)`：判斷EXP是否是常數。
* `long __builtin_expect(long EXP, long C)`：預先知道EXP的值很大機率會是C，藉此做最佳化，kernel的likely和unlikely也是靠這個實現的。
* `void __builtin_prefetch(const void *ADDR, int RW, int LOCALITY)`：把ADDR預先載入快取使用。
  * RW：1代表會寫入資料，0代表只會讀取
  * LOCALITY：範圍是0~3，0代表用了馬上就不用(不用關心time locality)、3代表之後還會常用到
* `int __builtin_ffs (int X)`：回傳X中從最小位數開始計算第一個1的位置，例如`__builtin_ffs(0xc)=3`，當X是0時，回傳0。
* `int __builtin_popcount (unsigned int X)`：在X中1的個數
* `int __builtin_ctz (unsigned int X)`：X末尾的0個數，X=0時undefined。
* `int __builtin_clz (unsigned int X)`：X前面的0個數，X=0時undefined。
* `int __builtin_parity (unsigned int x)`：Ｘ值的parity。

## `__attribute__`

### weak & alias

#### 測試是否支援某function

通常會使用`__attribute__(weak)`是為了避免有函式衝突的狀況，我們看個例子

a.c

```c
#include <stdio.h>

extern void printf_test(void) __attribute__((weak));

int main()
{
    printf("This is main function\n");
    if(printf_test)
    {
        printf("Here is printf_test result: \n");
        printf_test();
    }
    else
        printf("We don't support printf_test\n");
    return 0;
}
```

```bash
$ make a
$ ./a
This is main function
We don't support printf_test
```

雖然我們沒有printf_test，但是直接編譯是會通過的，因為printf_test被視為weak，假設在連結時找不到，是會被填0的。

那如果有printf_test的情況呢？我們加上b.c重新編譯看看

```c
#include <stdio.h>

void printf_test(void)
{
    printf("This is b function.\n");
}
```

```bash
$ gcc a.c b.c
$ ./a.out
This is main function
Here is printf_test result:
This is b function.
```

看起來就會執行printf_test了。這樣的功能對我們要動態看有無支援函式幫助很大。

#### 為函式加上default值

這邊我們會用到alias的attribute，alias的話通常會跟weak一起使用，最常被用到的是幫不確定有無支援的函式加上default值。

a.c

```c
#include <stdio.h>

void print_default(void)
{
    printf("Not support this function.\n");
}

void print_foo(void) __attribute__((weak, alias("print_default")));
void print_bar(void) __attribute__((weak, alias("print_default")));

int main()
{
    printf("This is main function\n");
    print_foo();
    print_bar();
    return 0;
}
```

b.c

```c
#include <stdio.h>

void print_foo(void)
{
    printf("foo function.\n");
}
```

```bash
$ gcc a.c b.c
$ ./a.out
This is main function
foo function.
Not support this function.
```

可以看到因為print_bar並沒有被宣告，所以最後會執行alias的print_default。

### 在main前後執行程式

有時候會想要在main的執行前後可以做些事，這時候就會用到下面兩個attribute

* constructor：main前做事
* destructor：main之後做事

讓我們看個範例

test.c

```c
#include <stdio.h>

__attribute__((constructor))
void before(void)
{
    printf("before main\n");
}

__attribute__((destructor))
void after(void)
{
    printf("after main\n");
}

int main()
{
    printf("This is main function\n");
    return 0;
}
```

```bash
$ make test
$ ./test
before main
This is main function
after main
```

結果的確如我們所料。另外這邊有點要注意，跟前面不一樣的是，`__attribute__((constructor))`和`__attribute__((destructor))`必須放在函式前面，不然會有`error: attributes should be specified before the declarator in a function definition`的錯誤。

### 其他attribute

剩下還有一些有機會會用到的attribute，這邊就不多談，只列出來參考。

* `__attribute__((section("section_name")))`：代表要把這個symbol放到`section_name`中
* `__attribute__((used))`：不管有沒有被引用，這個symbol都不會被優化掉
* `__attribute__((unused))`：沒有被引用到的時候也不會跳出警告
* `__attribute__((deprecated))`：用到的時候會跳出警告，用來警示使用者這個函式將要廢棄
* `__attribute__((stdcall))`：從右到左把參數放入stack，由callee(被呼叫者)把stack恢復正常
* `__attribute__((cdecl))`：C語言預設的作法，從右到左把參數放入stack，由caller把stack恢復正常
* `__attribute__((fastcall))`：頭兩個參數是用register來存放，剩下一樣放入stack

## 參考

* [BINARY HACKS：駭客秘傳技巧一百招](http://www.books.com.tw/products/0010587783)
* [gcc的__builtin_函数介绍](https://blog.csdn.net/jasonchen_gbd/article/details/44948523)
* [6.57 Other Built-in Functions Provided by GCC](https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html)
* [`__attribute__`之weak,alias属性](http://blog.sina.com.cn/s/blog_a9303fd90101d5su.html)
